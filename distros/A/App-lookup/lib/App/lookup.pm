package App::lookup;

use strict;
use warnings;

use File::Spec;
use Getopt::Long qw(:config bundling no_ignore_case);
use Text::Abbrev 'abbrev';
use Text::Wrap 'wrap';

our $VERSION = '0.06';

sub parse_command_line {
    GetOptions(\my %opts, 'help|h|?', 'man|m', 'version|v',
        'sites|s', 'abbrevs|a', 'config-file|c=s', 'web-browser|w=s')
      or print_usage(-verbose => 0, -exitval => 1);

    if ($opts{help}) {
        print_usage(
            -verbose  => 99,
            -sections => [qw(USAGE EXAMPLES OPTIONS)],
            -exitval  => 0,
        );
    }
    elsif ($opts{man}) {
        print_usage(-verbose => 2, -exitval => 0);
    }
    elsif ($opts{version}) {
        print_version() and exit;
    }

    die "The config file '$opts{'config-file'}' does not exist\n"
      if $opts{'config-file'} and not -f $opts{'config-file'};

    $opts{sitename} = shift @ARGV;
    $opts{query} = join ' ', @ARGV;

    return \%opts;
}

# thin wrapper around Pod::Usage::pod2usage since Pod::Usage causes
# insignificant-but-noticable-enough-to-be-annoying delay in startup time.
sub print_usage {
    require Pod::Usage;
    Pod::Usage::pod2usage(@_);
}

sub print_version {
    require File::Basename;
    my $progname = File::Basename::basename($0);
    print "This is $progname version $VERSION running on perl $]\n";
    return 1;
}

sub read_config_file {
    my $config_file = shift;

    require Config::Tiny;
    Config::Tiny->read($config_file)
      or die wrap(
        '', '',
        sprintf(
            "Error when reading configuration file %s: %s\n",
            $config_file, Config::Tiny->errstr
        ));
}

sub initialize_sites {
    my $config_file = shift || File::Spec->catfile($ENV{HOME}, '.lookuprc');
    my %predefined_sites = (google => 'http://google.com/search?q=%(query)');

    return \%predefined_sites unless -f $config_file;

    my $config     = read_config_file($config_file);
    my $aliases    = $config->{alias} || {};
    my $user_sites = $config->{sites} || {};

    # merge the hashes, user defined sites take precedence over the predefined
    # ones (we only have one predefined site anyway)
    my %sites = (%$user_sites, %predefined_sites);

    while (my ($alias, $original) = each %$aliases) {
        if (exists $sites{$original}) {
            $sites{$alias} = $sites{$original};
            delete $sites{$original};
        }
        else {
            warn "The alias '$alias' doesn't match any site\n";
        }
    }
    return \%sites;
}

sub find_max_length {
    require List::Util;
    List::Util::max(map { length $_ } @_);
}

sub print_sites {
    my $sites  = shift;
    my $maxlen = find_max_length(keys %$sites);

    for my $site (sort keys %$sites) {
        printf "- %-${maxlen}s : %s\n", $site, $sites->{$site};
    }

    return 1;
}

sub print_abbrevs {
    my ($abbrevs, $sites) = @_;
    my $data;

    while (my ($abbr, $sitename) = each %$abbrevs) {
        push @{ $data->{$sitename} }, $abbr if $sites->{$sitename};
    }

    for my $sitename (sort keys %$data) {
        my $site   = "Name";
        my $url    = "URL";
        my $abstr  = "Abbrev(s)";
        my $maxlen = find_max_length($site, $url, $abstr);

        printf "%-${maxlen}s : %s\n", $site, $sitename;
        printf "%-${maxlen}s : %s\n", $url,  $sites->{$sitename};

        my $joined_abbrevs = sprintf("%-${maxlen}s : %s",
            $abstr, join ', ', sort @{ $data->{$sitename} });

        # + 3 to adjust the addition of colon and whitespace
        print wrap('', ' ' x ($maxlen + 3), $joined_abbrevs);
        print "\n\n";
    }

    return 1;
}

sub browse_url {
    my ($url, $browser) = @_;

    require URI::Encode;
    $url = URI::Encode::uri_encode($url);

    if ($browser) {
        require IPC::System::Simple;
        IPC::System::Simple::systemx(split(/\s/, $browser), $url);
    }
    else {
        require Browser::Open;
        if (defined(my $status = Browser::Open::open_browser($url))) {
            if ($status != 0) {
                die "Error when opening $url with web browser\n";
            }
        }
        else {
            die "Could not found the command to execute the web browser\n";
        }
    }

}

sub run {
    my $opts     = parse_command_line();
    my $sites    = initialize_sites($opts->{'config-file'});
    my $abbrevs  = abbrev(keys %$sites);
    my $sitename = $opts->{sitename};

    if ($opts->{sites}) {
        print_sites($sites) and exit;
    }
    elsif ($opts->{abbrevs}) {
        print_abbrevs($abbrevs, $sites) and exit;
    }
    elsif (not $sitename or not $opts->{query}) {
        print_usage('Too few arguments');
    }

    if (my $valid_site = $abbrevs->{$sitename}) {
        my $url = $sites->{$valid_site};

        $url =~ s{%\(query\)}{$opts->{query}};

        browse_url($url, $opts->{'web-browser'});
    }
    else {
        if (my @ambiguous = grep { /^$sitename/ } sort keys %$abbrevs) {
            print wrap(
                '', '',
                sprintf(
                    "Ambiguous site name: '$sitename'. Did you mean one of "
                      . "the following sites/abbreviations: %s?\n",
                    join(', ', @ambiguous)));
        }
        else {
            print "Could not find sites that match '$sitename'\n";
        }
        exit 1;
    }
}

1;

__END__

=pod

=head1 NAME

App::lookup - search the internet from your terminal

=head1 VERSION

Version 0.06.

=head1 SYNOPSIS

  use App::lookup;
  App::lookup->run;

=head1 DESCRIPTION

See the documentation of B<lookup(1)>.

=head1 AUTHOR

Ahmad Syaltut <syaltut@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ahmad Syaltut.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
