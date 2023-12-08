package App::perlmv::scriptlet::add_prefix_datestamp;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-25'; # DATE
our $DIST = 'App-perlmv-scriptlet-add_prefix_datestamp'; # DIST
our $VERSION = '0.003'; # VERSION

sub main::_parse_date {
    my $date = shift;
    if ($date =~ /^\A(\d{4})-?(\d{2})-?(\d{2})(?:[T ]?(\d{2}):?(\d{2}):?(\d{2}))?\z/) {
        require Time::Local;
        return Time::Local::timelocal_posix($6 // 0, $5 // 0, $4 // 0, $3, $2-1, $1 - 1900);
    } else {
        die "Can't parse date '$date'";
    }
}

our $SCRIPTLET = {
    summary => 'Add datestamp prefix (YYYYMMDD-) to filenames, using files\' modification time as date',
    args => {
        date => {
            summary => "Use this date instead of file's modification time",
            schema => 'date*',
        },
        avoid_duplicate_prefix => {
            summary => 'Avoid adding prefix when filename already has prefix that looks like datestamp (1xxxxxxx- to 2xxxxxxx)',
            schema => 'bool*',
        },
        prefix_regex => {
            summary => 'Specify how existing datestamp prefix should be recognized',
            schema => 're_from_str',
            description => <<'_',

This regex is used to check for the existence of datestamp (if you use the
`avoid_duplicate_prefix` option. The default is `qr/^\d{8}(?:T\d{6})?-/` but if
your existing datestamps are in different syntax you can accommodate them here.

_
        },
        prefix_format => {
            summary => 'Specify datestamp format, in the form of strftime() template',
            schema => 'str*',
            description => <<'_',

The default format is `"%Y%m%d-"` or `"%Y%m%dT%H%M%S-"` if you enable the
`with_time` option. But you can customize it here.

_
        },
        with_time => {
            summary => 'Whether to add time (YYYYMMDD"T"hhmmss instead of just date (YYYYMMDD)',
            schema => 'bool*',
        },
    },
    code => sub {
        package
            App::perlmv::code;

        require POSIX;

        use vars qw($ARGS);

        my $re = $ARGS->{prefix_regex} // qr/\A[12][0-9]{3}(0[1-9]|10|11|12)([0-2][0-9]|30|31)-/;

        if ($ARGS->{avoid_duplicate_prefix} && $_ =~ $re) {
            return $_;
        }
        my @stat = stat($_);
        my $time   = defined $ARGS->{date} ? main::_parse_date($ARGS->{date}) : $stat[9];
        my $format = $ARGS->{prefix_format}  // ($ARGS->{with_time} ? '%Y%m%dT%H%M%S-' : '%Y%m%d-');
        my $prefix = POSIX::strftime($format, localtime($time));

        "$prefix$_";
    },
};

1;

# ABSTRACT: Add datestamp prefix (YYYYMMDD-) to filenames, using files' modification time as date

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::add_prefix_datestamp - Add datestamp prefix (YYYYMMDD-) to filenames, using files' modification time as date

=head1 VERSION

This document describes version 0.003 of App::perlmv::scriptlet::add_prefix_datestamp (from Perl distribution App-perlmv-scriptlet-add_prefix_datestamp), released on 2023-08-25.

=head1 SYNOPSIS

With filenames:

 foo.txt
 new-bar.txt

This command:

 % perlmv add-prefix -a prefix=new- *

will rename the files as follow:

 foo.txt -> new-foo.txt
 new-bar.txt -> new-new-bar.txt

This command:

 % perlmv add-prefix -a prefix=new- -a avoid_duplicate_prefix=1 *

will rename the files as follow:

 foo.txt -> new-foo.txt

=head1 DESCRIPTION

Adding a datestamp prefix on filenames is one of the ways I often use to
organize documents. There is file modification time supplied by the filesystem,
but this information does not survive through git repository or sharing across
the web/mobile application. Hence putting the information in the filename.

=head1 SCRIPTLET ARGUMENTS

Arguments can be passed using the C<-a> (C<--arg>) L<perlmv> option, e.g. C<< -a name=val >>.

=head2 avoid_duplicate_prefix

Avoid adding prefix when filename already has prefix that looks like datestamp (1xxxxxxx- to 2xxxxxxx). 

=head2 date

Use this date instead of file's modification time. 

=head2 prefix_format

Specify datestamp format, in the form of strftime() template. 

The default format is C<"%Y%m%d-"> or C<"%Y%m%dT%H%M%S-"> if you enable the
C<with_time> option. But you can customize it here.


=head2 prefix_regex

Specify how existing datestamp prefix should be recognized. 

This regex is used to check for the existence of datestamp (if you use the
C<avoid_duplicate_prefix> option. The default is C<qr/^\d{8}(?:T\d{6})?-/> but if
your existing datestamps are in different syntax you can accommodate them here.


=head2 with_time

Whether to add time (YYYYMMDD"T"hhmmss instead of just date (YYYYMMDD). 

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv-scriptlet-add_prefix_datestamp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv-scriptlet-add_prefix_datestamp>.

=head1 SEE ALSO

L<App::perlmv::scriptlet::add_suffix>

The C<remove-common-prefix> scriptlet

L<perlmv> (from L<App::perlmv>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv-scriptlet-add_prefix_datestamp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
