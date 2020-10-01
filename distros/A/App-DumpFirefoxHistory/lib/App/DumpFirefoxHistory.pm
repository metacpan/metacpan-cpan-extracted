package App::DumpFirefoxHistory;

our $DATE = '2020-05-24'; # DATE
our $DIST = 'App-DumpFirefoxHistory'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;

our %SPEC;

$SPEC{dump_firefox_history} = {
    v => 1.1,
    summary => 'Dump Firefox history',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        profiles => {
            summary => 'Select profile(s) to dump',
            schema => ['array*', of=>'firefox::profile_name*', 'x.perl.coerce_rules'=>['From_str::comma_sep']],
            description => <<'_',

You can choose to dump history for only some profiles. By default, if this
option is not specified, history from all profiles will be dumped.

_
        },
        attempt_orig_first => {
            schema => 'bool*',
            default => 0,
            'summary' => 'Attempt to open the original history database '.
                'first instead of directly copying the database',
            'summary.alt.bool.not' => 'Do not attempt to open the original history database '.
                '(and possibly get a "locked" error), proceed directly to copy it',
        },
        copy_size_limit => {
            schema => 'posint*',
            default => 100*1024*1024,
            description => <<'_',

Firefox often locks the History database for a long time. If the size of the
database is not too large (determine by checking against this limit), then the
script will copy the file to a temporary file and extract the data from the
copied database.

_
        },
    },
};
sub dump_firefox_history {
    require DBI;
    require Firefox::Util::Profile;
    require List::Util;

    my %args = @_;

    # list all available firefox profiles
    my $available_profiles;
    {
        my $res = Firefox::Util::Profile::list_firefox_profiles(detail=>1);
        return $res unless $res->[0] == 200;
        $available_profiles = $res->[2];
    }

    my $num_profiles_success = 0;
    my $profiles = $args{profiles} // [map {$_->{name}} @$available_profiles];

    my @rows;
    my $resmeta = {};

  PROFILE:
    for my $profile (@$profiles) {
        log_trace "Dumping history for profile %s ...", $profile;
        my $profile_data = List::Util::first(sub { $_->{name} eq $profile }, @$available_profiles);
        unless ($profile_data) {
            log_error "Profile %s is unknown, skipped", $profile;
            next PROFILE;
        }

        my $profile_dir = $profile_data->{path};
        unless (-d $profile_dir) {
            log_error "Cannot find directory '%d' for profile %s, profile skipped", $profile_dir, $profile;
            next PROFILE;
        }

        local $CWD = $profile_dir;

        my $history_path = "places.sqlite";
        unless (-f $history_path) {
            log_error "Cannot find history database file '%s' for profile %s, profile skipped", $history_path, $profile;
            next PROFILE;
        }

        my $num_attempts;
      SELECT: {
            $num_attempts++;
            goto COPY if $num_attempts == 1 && !$args{attempt_orig_first};

            eval {
                my $dbh = DBI->connect("dbi:SQLite:dbname=$history_path", "", "", {RaiseError=>1});
                my $sth = $dbh->prepare("SELECT url,title,last_visit_date,visit_count,frecency FROM moz_places ORDER BY last_visit_date");
                $sth->execute;
                while (my $row = $sth->fetchrow_hashref) {
                    if ($args{detail}) {
                        push @rows, $row;
                    } else {
                        push @rows, $row->{url};
                    }
                }
            };
            my $err = $@;
            log_info "Got DBI error: $@" if $err;
          COPY: {
                unless (!$args{attempt_orig_first} && $num_attempts == 1 || $err && $err =~ /database is locked/) {
                    last;
                }
                my $size = -s $history_path;
                unless ($size <= $args{copy_size_limit}) {
                    log_trace "Not copying history database to tempfile, size too large (%.1fMB)", $size/1024/1024;
                }
                require File::Copy;
                require File::Temp;
                my ($temp_fh, $temp_path) = File::Temp::tempfile();
                log_trace "Copying $history_path to $temp_path ...";
                File::Copy::copy($history_path, $temp_path) or die $err;
                $history_path = $temp_path;
                redo SELECT;
            }
        } # SELECT
        $num_profiles_success++;
    } # for profile

    $resmeta->{'table.fields'} = [qw/url title last_visit_date visit_count frecency/]
        if $args{detail};

    unless ($num_profiles_success) {
        return [500, "There are no profiles that I can successully dump the history of"];
    }

    [200, "OK", \@rows, $resmeta];
}

1;
# ABSTRACT: Dump Firefox history

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DumpFirefoxHistory - Dump Firefox history

=head1 VERSION

This document describes version 0.008 of App::DumpFirefoxHistory (from Perl distribution App-DumpFirefoxHistory), released on 2020-05-24.

=head1 SYNOPSIS

See the included script L<dump-firefox-history>.

=head1 FUNCTIONS


=head2 dump_firefox_history

Usage:

 dump_firefox_history(%args) -> [status, msg, payload, meta]

Dump Firefox history.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attempt_orig_first> => I<bool> (default: 0)

Attempt to open the original history database first instead of directly copying the database.

=item * B<copy_size_limit> => I<posint> (default: 104857600)

Firefox often locks the History database for a long time. If the size of the
database is not too large (determine by checking against this limit), then the
script will copy the file to a temporary file and extract the data from the
copied database.

=item * B<detail> => I<bool>

=item * B<profiles> => I<array[firefox::profile_name]>

Select profile(s) to dump.

You can choose to dump history for only some profiles. By default, if this
option is not specified, history from all profiles will be dumped.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DumpFirefoxHistory>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DumpFirefoxHistory>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DumpFirefoxHistory>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::DumpChromeHistory>, L<App::DumpOperaHistory>

Other utilities for Firefox: L<App::FirefoxUtils>,
L<App::FirefoxMultiAccountContainersUtils>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
