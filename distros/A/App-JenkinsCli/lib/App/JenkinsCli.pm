package App::JenkinsCli;

# Created on: 2016-05-20 07:52:28
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Jenkins::API;
use Term::ANSIColor qw/colored/;
use File::ShareDir qw/dist_dir/;
use Path::Tiny;
use DateTime;

our $VERSION = "0.010";

has [qw/base_url api_key api_pass test/] => (
    is => 'rw',
);
has jenkins => (
    is   => 'rw',
    lazy => 1,
    builder => '_jenkins',
);
has colours => (
    is       => 'rw',
    required => 1,
);
has colour_map => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return {
            '' => ['reset'],
            map {
                ( $_ => [ split /\s+/, $self->colours->{$_} ] )
            }
            keys %{ $self->colours }
        };
    },
);
has opt => (
    is       => 'rw',
    required => 1,
);

sub _jenkins {
    my ($self) = @_;

    return Jenkins::API->new({
        base_url => $self->base_url,
        api_key  => $self->api_key,
        api_pass => $self->api_pass,
    });
};

sub _alpha_num {
    my $a1 = ref $a ? $a->{name} : $a;
    my $b1 = ref $b ? $b->{name} : $b;
    $a1 =~ s/(\d+)/sprintf "%05d", $1/egxms;
    $b1 =~ s/(\d+)/sprintf "%05d", $1/egxms;
    return $a1 cmp $b1;
}

sub ls { shift->list(@_) }
sub list {
    my ($self, $query) = @_;
    my $jenkins = $self->jenkins();

    if ( ! defined $self->opt->regexp ) {
        $self->opt->regexp(1);
    }

    $self->_action(0, $query, $self->_ls_job($jenkins));

    return;
}

sub start {
    my ($self, $job, @extra) = @_;
    my $jenkins = $self->jenkins();

    _error("Must start build with job name!\n") if !$job;

    my $result = $jenkins->_json_api(['job', $job, 'api', 'json']);
    if ( ! $result->{buildable} ) {
        warn "Job is not buildable!\n";
        return 1;
    }
    if ( $result->{inQueue} && ! $self->opt->force ) {
        warn $result->{queueItem}{why} . "\n";
        warn "View at $result->{url}\n";
        return 0;
    }

    $jenkins->trigger_build($job);

    sleep 1;

    $result = $jenkins->_json_api(['job', $job, 'api', 'json']);
    print "View at $result->{url}\n";
    print $result->{queueItem}{why}, "\n" if $result->{queueItem}{why};

    return;
}

sub delete {
    my ($self, @jobs) = @_;

    _error("Job name required for deleting jobs!\n") if !@jobs;

    for my $job (@jobs) {
        my $result = $self->jenkins->delete_project($job);
        print $result ? "Deleted $job\n" : "Errored deleting $job\n";
    }

    return;
}

sub status {
    my ($self, $job, @extra) = @_;
    my $jenkins = $self->jenkins();

    _error("Job name required to show job status!\n") if !$job;

    my $result = $jenkins->_json_api(['job', $job, 'api', 'json'], { extra_params => { depth => 1 } });

    my $color = $self->colour_map->{$result->{color}} || [$result->{color}];
    print colored($color, $job), "\n";

    if ($self->opt->verbose) {
        for my $build (@{ $result->{builds} }) {
            print "$build->{displayName}\t$build->{result}\t";
            if ( $self->opt->verbose > 1 ) {
                for my $action (@{ $build->{actions} }) {
                    if ( $action->{lastBuiltRevision} ) {
                        print $action->{lastBuiltRevision}{SHA1};
                    }
                }
            }
            print "\n";
        }
    }

    return;
}

sub conf { shift->config(@_) }
sub config {
    my ($self, $job) = @_;
    my $jenkins = $self->jenkins();

    _error("Must provide job name to get it's configuration!\n") if !$job;

    $self->_action(0, $job, sub {
        my $config = $jenkins->project_config($_->{name});
        if ( $self->opt->{out} ) {
            path($self->opt->{out}, "$_->{name}.xml")->spew($config);
        }
        else {
            print $config;
        }
    });

    return;
}

sub queue {
    my ($self, $job, @extra) = @_;
    my $jenkins = $self->jenkins();

    my $queue = $jenkins->build_queue();

    if ( @{ $queue->{items} } ) {
        for my $item (@{ $queue->{items} }) {
            print $item;
        }
    }
    else {
        print "The queue is empty\n";
    }

    return;
}

sub create {
    my ($self, $job, $config, @extra) = @_;
    my $jenkins = $self->jenkins();

    my $success = $jenkins->create_job($job, $config);

    print $success ? "Created $job\n" : "Error creating $job\n";

    return;
}

sub load {
    my ($self, $job, $config, @extra) = @_;
    my $jenkins = $self->jenkins();

    print Dumper $jenkins->load_statistics();

    return;
}

sub watch {
    my ($self, @jobs) = @_;
    my $jenkins = $self->jenkins();

    if ( ! defined $self->opt->regexp ) {
        $self->opt->regexp(1);
    }

    $self->opt->{sleep} ||= 30;
    my $query = join '|', @jobs;

    while (1) {
        my @out;
        my $ls = $self->_ls_job($jenkins, 1);
        print "\n...\n";

        $self->_action(0, $query, sub {
            push @out, $ls->(@_);
        });

        print "\e[2J\e[0;0H\e[K";
        print "Jenkins Jobs: ", (join ', ', @jobs), "\n\n";
        print sort _alpha_num @out;
        sleep $self->opt->{sleep};
    }

    return;
}

sub enable {
    my ($self, $query) = @_;

    my $xsl = path(dist_dir('App-JenkinsCli'), 'enable.xsl');
    $self->_xslt_actions($query, $xsl);

    return;
}

sub disable {
    my ($self, $query) = @_;

    my $xsl = path(dist_dir('App-JenkinsCli'), 'disable.xsl');
    $self->_xslt_actions($query, $xsl);

    return;
}

sub change {
    my ($self, $query, $xsl) = @_;

    $self->_xslt_actions($query, $xsl);

    return;
}

sub _xslt_actions {
    my ($self, $query, $xsl) = @_;
    require XML::LibXML;
    require XML::LibXSLT;

    my $xslt = XML::LibXSLT->new();
    my $style_doc = XML::LibXML->load_xml(location => $xsl);
    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    my $jenkins = $self->jenkins();

    my $data = $jenkins->_json_api([qw/api json/], { extra_params => { depth => 0 } });

    my %found;
    $self->_action(0, $query, sub {

        my $config = $jenkins->project_config($_->{name});
        my $dom = XML::LibXML->load_xml(string => $config);

        my $results = $stylesheet->transform($dom);
        my $output  = $stylesheet->output_as_bytes($results);

        warn "Updating $_->{name}\n" if $self->opt->{verbose};
        if ($self->opt->{test}) {
            print "$output\n";
        }
        else {
            my $success = $jenkins->set_project_config($_->{name}, $output);
            if (!$success) {
                warn "Error in updating $_->{name}\n";
                last;
            }
        }
    });

    return;
}

sub _action {
    my ($self, $depth, $query, $action) = @_;
    my $jenkins = $self->jenkins();

    my $data = eval {
        $jenkins->_json_api([qw/api json/], { extra_params => { depth => $depth } });
    };

    if ( ! $data || $@ ) {
        my $err = $@ ? ": $@" : '';
        confess "No data found! (can't talk to Jenkins Server? depth = $depth)$err";
    }

    my $re = $self->opt->regexp ? qr/$query/ : qr/\A\Q$query\E\Z/;

    for my $job (sort _alpha_num @{ $data->{jobs} }) {
        next if $query && $job->{name} !~ /$re/;

        local $_ = $job;

        if ( $self->opt->{recipient} ) {
            my $config = $jenkins->project_config($_->{name});
            require XML::Simple;
            local $Data::Dumper::Sortkeys = 1;
            local $Data::Dumper::Indent = 1;
            my $data = XML::Simple::XMLin($config);
            my $recipient = $self->opt->{recipient};
            next if $data->{publishers}{'hudson.tasks.Mailer'}{recipients} !~ /$recipient/;
        }

        $self->$action();
    }

    return;
}

sub _ls_job {
    my ($self, $jenkins, $return) = @_;
    my ($max, $space) = (0, 8);

    return sub {
        my $name = $_->{name};
        my ($extra_pre, $extra_post) = ('') x 2;

        if ( ! $_->{color} ) {
            $_->{color} = '';
        }
        elsif ( $_->{color} =~ s/_anime// ) {
            $extra_pre = '*';
        }

        if ( $self->opt->{verbose} ) {
            eval {
                my $details = $jenkins->_json_api(
                    ['job', $_->{name}, qw/api json/],
                    {
                        extra_params => {
                            depth => 1,
                            tree => 'lastBuild[timestamp,displayName,builtOn,duration]'
                        }
                    }
                );
                my $duration = 'Never run';
                if ( $details->{lastBuild}{duration} ) {
                    $duration = $details->{lastBuild}{duration} / 1_000;
                    if ( $duration > 2 * 60 * 60 ) {
                        $duration = int($duration / 60 / 60) . ' hrs';
                    }
                    elsif ( $duration >= 60 * 60 ) {
                        $duration = '1 hr ' . (int( ($duration - 60 * 60) / 60 )) . ' min';
                    }
                    elsif ( $duration > 2 * 60 ) {
                        $duration = int($duration / 60 ) . ' min';
                    }
                    elsif ( $duration >= 60 ) {
                        $duration = '1 min ' . ($duration - 60) . ' sec';
                    }
                    else {
                        $duration .= ' sec';
                    }
                }

                $extra_post .= DateTime->from_epoch( epoch => ( $details->{lastBuild}{timestamp} || 0 ) / 1000 );
                if ( $details->{lastBuild}{displayName} && $details->{lastBuild}{builtOn} ) {
                    $extra_post .= " ($duration / $details->{lastBuild}{displayName} / $details->{lastBuild}{builtOn})";
                }
                else {
                    $extra_post .= "Never run";
                }
                1;
            } or do {
                warn "Error getting job $_->{name}'s details: $@\n";
            };
            $name = $self->base_url . 'job/' . $name;
        }

        # map "jenkins" colours to real colours
        my $color = $self->colour_map->{$_->{color}} || [$_->{color}];

        if ( !$max ) {
            $max = $space + length $name . " $extra_pre";
        }
        elsif ( length $name > $max ) {
            $max = $space + length $name . " $extra_pre";
            $space -= 2 if $space > 2;
        }

        my $out = colored($color, sprintf "% -${max}s", "$name $extra_pre") . " $extra_post\n";

        if ( $self->opt->{long} ) {
            $out = "$_->{color} $out";
        }

        if ($return) {
            return $out;
        }
        print $out;
    };
}

1;

__END__

=head1 NAME

App::JenkinsCli - Command line tool for interacting with Jenkins

=head1 VERSION

This documentation refers to App::JenkinsCli version 0.010

=head1 SYNOPSIS

   use App::JenkinsCli;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<ls ($query)>

=head2 C<list ($query)>

List all jobs, optionally filtering with C<$query>

=head2 C<start ($job)>

Start C<$job>

=head2 C<delete ($job)>

Delete C<$job>

=head2 C<status ($job)>

Status of C<$job>

=head2 C<enable ($job)>

enable C<$job>

=head2 C<disable ($job)>

disable C<$job>

=head2 C<conf ($job)>

=head2 C<config ($job)>

Show the config of C<$job>

=head2 C<queue ()>

Show the queue of running jobs

=head2 C<create ($job)>

Create a new Jenkins job

=head2 C<load ()>

Show the load stats for the server

=head2 C<change ($query, $xsl)>

Run the XSLT file (C<$xsl>) over each job matching C<$query> to generate a
new config which is then sent back to Jenkins.

=head2 C<watch ($job)>

Watch jobs to track changes.

=head1 ATTRIBUTES

=over 4

=item base_url

The base URL of Jenkins

=item api_key

The username to access jenkins by

=item api_pass

The password to access jenkins by

=item test

Flag to not actually perform changes

=item jenkins

Internal L<Jenkins::API> object

=item colours

Mapping of Jenkins states to L<Term::ANSIColor>s

=item opt

User options

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 ALSO SEE

Inspired by https://github.com/Netflix-Skunkworks/jenkins-cli

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
