package CPAN::Digger;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.04';

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use Data::Dumper qw(Dumper);
use Exporter qw(import);
use File::Spec ();
use File::Temp qw(tempdir);
use Log::Log4perl ();
use LWP::UserAgent ();
use MetaCPAN::Client ();
use DateTime         ();
use Template ();

my @ci_names = qw(travis github_actions circleci appveyor azure_pipeline gitlab_pipeline);


use CPAN::Digger::DB qw(get_fields);

my $tempdir = tempdir( CLEANUP => ($ENV{KEEP_TEMPDIR} ? 0 : 1) );

my %known_licenses = map {$_ => 1} qw(apache_2_0 artistic_2 bsd gpl_2 gpl_3 lgpl_2_1 lgpl_3_0 perl_5); # open_source, unknown

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    for my $key (keys %args) {
        $self->{$key} = $args{$key};
    }
    $self->{log} = uc $self->{log};
    $self->{check_vcs} = delete $self->{vcs};
    $self->{total} = 0;

    my $dt = DateTime->now;
    $self->{end_date}       = $dt->ymd;
    if ($self->{days}) {
        $self->{start_date}     = $dt->add( days => -$self->{days} )->ymd;
    }

    $self->{db} = CPAN::Digger::DB->new(db => $self->{db});

    return $self;
}

sub read_dashboards {
    my ($self) = @_;
    my @pathes = ('dashboard', '/home/gabor/cpan/dashboard');
    for my $path (@pathes) {
        if (-e $path) {
            $self->{dashboards} = { map { m{.*/([^/]+)\.json$}; $1 => 1 } glob "$path/authors/*.json" };
        }
    }
}

sub get_vcs {
    my ($repository) = @_;
    if ($repository) {
        #        $html .= sprintf qq{<a href="%s">%s %s</a><br>\n}, $repository->{$k}, $k, $repository->{$k};
        # Try to get the web link
        my $url = $repository->{web};
        if (not $url) {
            $url = $repository->{url};
            $url =~ s{^git://}{https://};
            $url =~ s{\.git$}{};
        }
        my $name = "repository";
        if ($url =~ m{^https?://github.com/}) {
            $name = 'GitHub';
        }
        if ($url =~ m{^https?://gitlab.com/}) {
            $name = 'GitLab';
        }
        return $url, $name;
    }
}

sub get_data {
    my ($self, $item) = @_;

    my $logger = Log::Log4perl->get_logger();
    my %data = (
        distribution => $item->distribution,
        version      => $item->version,
        author       => $item->author,
        date         => $item->date,
    );
    #die Dumper $item;

    $logger->debug('dist: ', $item->distribution);
    $logger->debug('      ', $item->author);
    my @licenses = @{ $item->license };
    $data{licenses} = join ' ', @licenses;
    $logger->debug('      ',  $data{licenses});
    for my $license (@licenses) {
        if ($license eq 'unknown') {
            $logger->error("Unknown license '$license'");
        } elsif (not exists $known_licenses{$license}) {
            $logger->warn("Unknown license '$license'. Probably CPAN::Digger needs to be updated");
        }
    }
    # if there are not licenses =>
    # if there is a license called "unknonws"
    # check against a known list of licenses (grow it later, or look it up somewhere?)
    my %resources = %{ $item->resources };
    #say '  ', join ' ', keys %resources;
    if ($resources{repository}) {
        my ($vcs_url, $vcs_name) = get_vcs($resources{repository});
        if ($vcs_url) {
            $data{vcs_url} = $vcs_url;
            $data{vcs_name} = $vcs_name;
            $logger->debug("      $vcs_name: $vcs_url");
        }
    } else {
        $logger->error('No repository for ', $item->distribution);
    }
    return %data;
}


sub analyze_vcs {
    my ($data) = @_;
    my $logger = Log::Log4perl->get_logger();

    my $vcs_url = $data->{vcs_url};
    my $repo_name = (split '\/', $vcs_url)[-1];
    $logger->info("Analyze GitHub repo '$vcs_url' in directory $repo_name");

    my $ua = LWP::UserAgent->new(timeout => 5);
    my $response = $ua->get($vcs_url);
    my $status_line = $response->status_line;
    if ($status_line eq '404 Not Found') {
        $logger->error("Repository '$vcs_url' Received 404 Not Found. Please update the link in the META file");
        return;
    }
    if ($response->code != 200) {
        $logger->error("Repository '$vcs_url'  got a response of '$status_line'. Please report this to the maintainer of CPAN::Digger.");
        return;
    }
    if ($response->redirects) {
        $logger->error("Repository '$vcs_url' is being redirected. Please update the link in the META file");
    }

    my $git = 'git';

    my @cmd = ($git, "clone", "--depth", "1", $data->{vcs_url});
    my $cwd = getcwd();
    chdir($tempdir);
    my ($out, $err, $exit_code) = capture {
        system(@cmd);
    };
    chdir($cwd);
    my $repo = "$tempdir/$repo_name";
    $logger->debug("REPO path '$repo'");

    if ($exit_code != 0) {
        # TODO capture stderr and include in the log
        $logger->error("Failed to clone $vcs_url");
        return;
    }

    if ($data->{vcs_name} eq 'GitHub') {
        analyze_github($data, $repo);
    }
    if ($data->{vcs_name} eq 'GitLab') {
        analyze_gitlab($data, $repo);
    }

    for my $ci (@ci_names) {
        $logger->debug("Is CI '$ci'?");
        if ($data->{$ci}) {
            $logger->debug("CI '$ci' found!");
            $data->{has_ci} = 1;
        }
    }
}

sub analyze_gitlab {
    my ($data, $repo) = @_;

    $data->{gitlab_pipeline} = -e "$repo/.gitlab-ci.yml";
}

sub analyze_github {
    my ($data, $repo) = @_;

    $data->{travis} = -e "$repo/.travis.yml";
    my @ga = glob("$repo/.github/workflows/*");
    $data->{github_actions} = (scalar(@ga) ? 1 : 0);
    $data->{circleci} = -e "$repo/.circleci";
    $data->{appveyor} = (-e "$repo/.appveyor.yml") || (-e "$repo/appveyor.yml");
    $data->{azure_pipeline} = -e "$repo/azure-pipelines.yml";
}

sub html {
    my ($self) = @_;

    return if not $self->{html};
    if (not -d $self->{html}) {
        mkdir $self->{html};
    }

    $self->read_dashboards;

    my @distros = @{ $self->{db}->db_get_every_distro() };
    my %stats = (
        total => scalar @distros,
        has_vcs => 0,
        vcs => {},
        has_ci => 0,
        ci => {},
    );
    for my $ci (@ci_names) {
        $stats{ci}{$ci} = 0;
    }
    for my $dist (@distros) {
        $dist->{dashboard} = $self->{dashboards}{ $dist->{author} };
        if ($dist->{vcs_name}) {
            $stats{has_vcs}++;
            $stats{vcs}{ $dist->{vcs_name} }++;
        }
        if ($dist->{has_ci}) {
            $stats{has_ci}++;
            for my $ci (@ci_names) {
                $stats{ci}{$ci}++ if $dist->{$ci};
            }
        }
    }
    if ($stats{total}) {
        $stats{has_vcs_percentage} = int(100 * $stats{has_vcs} / $stats{total});
        $stats{has_ci_percentage} = int(100 * $stats{has_ci} / $stats{total});
    }


    my $tt = Template->new({
        INCLUDE_PATH => './templates',
        INTERPOLATE  => 1,
        WRAPPER      => 'wrapper.tt',
    }) or die "$Template::ERROR\n";

    my $report;
    $tt->process('main.tt', {
        distros => \@distros,
        version => $VERSION,
        timestamp => DateTime->now,
        stats => \%stats,
    }, \$report) or die $tt->error(), "\n";
    my $html_file = File::Spec->catfile($self->{html}, 'index.html');
    open(my $fh, '>', $html_file) or die "Could not open '$html_file'";
    print $fh $report;
    close $fh;
}


sub report {
    my ($self) = @_;

    return if not $self->{report};

    print "Report\n";
    print "------------\n";
    my @distros = @{ $self->{db}->db_get_every_distro() };
    if ($self->{limit} and @distros > $self->{limit}) {
        @distros = @distros[0 .. $self->{limit}-1];
    }
    for my $distro (@distros) {
        #die Dumper $distro;
        printf "%s %-40s %-7s", $distro->{date}, $distro->{distribution}, ($distro->{vcs_url} ? '' : 'NO VCS');
        if ($self->{check_vcs}) {
            printf "%-7s", ($distro->{has_ci} ? '' : 'NO CI');
        }
        print "\n";
    }

    if ($self->{days}) {
        my $distros = $self->{db}->get_distro_count($self->{start_date}, $self->{end_date});
        my $authors = $self->{db}->get_author_count($self->{start_date}, $self->{end_date});
        my $vcs_count = $self->{db}->get_vcs_count($self->{start_date}, $self->{end_date});
        my $ci_count = $self->{db}->get_ci_count($self->{start_date}, $self->{end_date});
        printf
            "Last week there were a total of %s uploads to CPAN of %s distinct distributions by %s different authors. Number of distributions with link to VCS: %s. Number of distros with CI: %s.\n",
            $self->{total}, $distros, $authors, $vcs_count,
            $ci_count;
    }
}

sub collect {
    my ($self) = @_;

    my @all_the_distributions;

    my $log_level = $self->{log}; # TODO: shall we validate?
    Log::Log4perl->easy_init({
        level => $log_level,
        layout   => '%d{yyyy-MM-dd HH:mm:ss} - %p - %m%n',
    });

    my $logger = Log::Log4perl->get_logger();
    $logger->info('Starting');
    $logger->info("Tempdir: $tempdir");
    $logger->info("Recent: $self->{recent}") if $self->{recent};
    $logger->info("Author: $self->{author}") if $self->{author};

    my $mcpan = MetaCPAN::Client->new();
    my $rset;
    if ($self->{author}) {
        my $author = $mcpan->author($self->{author});
        #print $author;
        $rset = $author->releases;
    } else {
        $rset  = $mcpan->recent($self->{recent});
    }
    $logger->info("MetaCPAN::Client::ResultSet received with a total of $rset->{total} items");
    my %distros;
    my @fields = get_fields();
    while ( my $item = $rset->next ) {
            if ($self->{days}) {
	            next if $item->date lt $self->{start_date};
	            next if $self->{end_date} le $item->date;
            }

            $self->{total}++;

    		next if $distros{ $item->distribution }; # We have already deal with this in this session
            $distros{ $item->distribution } = 1;

            my $row = $self->{db}->db_get_distro($item->distribution);
            next if $row and $row->{version} eq $item->version; # we already have this in the database (shall we call last?)
            my %data = $self->get_data($item);
            #die Dumper \%data;
            $self->{db}->db_insert_into(@data{@fields});
            push @all_the_distributions, \%data;
    }

    if ($self->{author}) {
        @all_the_distributions = reverse sort {$a->{date} cmp $b->{date}} @all_the_distributions;
        if ($self->{limit} and @all_the_distributions > $self->{limit}) {
            @all_the_distributions = @all_the_distributions[0 .. $self->{limit}-1];
        }
    }

    # Check on the VCS
    if ($self->{check_vcs}) {
        $logger->info("Starting to check GitHub");
        for my $data (@all_the_distributions) {
            my $distribution = $data->{distribution};
            my $data_ref = $self->{db}->db_get_distro($distribution);
            next if not $data_ref->{vcs_name};

            analyze_vcs($data_ref);

            my %data = %$data_ref;
            $self->{db}->db_update($distribution, @data{@fields});
            sleep $self->{sleep} if $self->{sleep};
        }
    }


    $self->report;
    $self->html;
}


42;


=head1 NAME

CPAN::Digger - To dig CPAN

=head1 SYNOPSIS

    cpan-digger

=head1 DESCRIPTION

This is a command line program to collect some meta information about CPAN modules.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by L<Gabor Szabo|https://szabgab.com/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

