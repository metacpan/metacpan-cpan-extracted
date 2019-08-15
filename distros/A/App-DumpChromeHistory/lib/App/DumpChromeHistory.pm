package App::DumpChromeHistory;

our $DATE = '2019-08-14'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{dump_chrome_history} = {
    v => 1.1,
    summary => 'Dump Chrome history',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        profile => {
            summary => 'Select profile to use',
            schema => 'str*',
            default => 'Default',
            description => <<'_',

You can either provide a name, e.g. `Default`, the profile directory of which
will be then be searched in `~/.config/google-chrome/<name>`. Or you can also
provide a directory name.

_
        },
        copy_size_limit => {
            schema => 'posint*',
            default => 100*1024*1024,
            description => <<'_',

Chrome often locks the History database for a long time. If the size of the
database is not too large (determine by checking against this limit), then the
script will copy the file to a temporary file and extract the data from the
copied database.

_
        },
    },
};
sub dump_chrome_history {
    require DBI;

    my %args = @_;

    my ($profile, $profile_dir, $hist_path);
    $profile = $args{profile} // 'default';

  GET_PROFILE_DIR:
    {
        if ($profile =~ /\A\w+\z/) {
            # search profile name in profiles directory
            $profile_dir = "$ENV{HOME}/.config/google-chrome/$profile";
            return [412, "No such directory '$profile_dir'"]
                unless -d $profile_dir;
        } elsif (-d $profile) {
            $profile_dir = $profile;
        } else {
            return [412, "No such profile/profile directory '$profile'"];
        }
        $hist_path = "$profile_dir/History";
        return [412, "Not a profile directory '$profile_dir': no History inside"]
            unless -f $hist_path;
    }

    my @rows;
    my $resmeta = {};
  SELECT: {
        eval {
            my $dbh = DBI->connect("dbi:SQLite:dbname=$hist_path", "", "", {RaiseError=>1});
            $dbh->sqlite_busy_timeout(3*1000);
            my $sth = $dbh->prepare("SELECT url,last_visit_time,visit_count FROM urls ORDER BY last_visit_time");
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
        if ($err && $err =~ /database is locked/ && (-s $hist_path) <= $args{copy_size_limit}) {
            require File::Copy;
            require File::Temp;
            my ($temp_fh, $temp_path) = File::Temp::tempfile();
            File::Copy::copy($hist_path, $temp_path) or die $err;
            $hist_path = $temp_path;
            redo SELECT;
        }
    }

    $resmeta->{'table.fields'} = [qw/url title last_visit_time visit_count/]
        if $args{detail};
    [200, "OK", \@rows, $resmeta];
}

1;
# ABSTRACT: Dump Chrome history

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DumpChromeHistory - Dump Chrome history

=head1 VERSION

This document describes version 0.002 of App::DumpChromeHistory (from Perl distribution App-DumpChromeHistory), released on 2019-08-14.

=head1 SYNOPSIS

See the included script L<dump-chrome-history>.

=head1 FUNCTIONS


=head2 dump_chrome_history

Usage:

 dump_chrome_history(%args) -> [status, msg, payload, meta]

Dump Chrome history.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<copy_size_limit> => I<posint> (default: 104857600)

Chrome often locks the History database for a long time. If the size of the
database is not too large (determine by checking against this limit), then the
script will copy the file to a temporary file and extract the data from the
copied database.

=item * B<detail> => I<bool>

=item * B<profile> => I<str> (default: "Default")

Select profile to use.

You can either provide a name, e.g. C<Default>, the profile directory of which
will be then be searched in C<< ~/.config/google-chrome/E<lt>nameE<gt> >>. Or you can also
provide a directory name.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-DumpChromeHistory>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DumpChromeHistory>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DumpChromeHistory>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::DumpFirefoxHistory>

L<App::DumpOperaHistory>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
