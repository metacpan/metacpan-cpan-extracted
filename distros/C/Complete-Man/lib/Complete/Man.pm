package Complete::Man;

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Complete-Man'; # DIST
our $VERSION = '0.100'; # VERSION

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_manpage complete_manpage_section);

sub _complete_manpage_or_section {
    require Complete::Util;
    require File::Which;

    my $which = shift;
    my %args = @_;
    my $use_mandb = $args{use_mandb} // 1;

    if ($which eq 'section' && $ENV{MANSECT}) {
        return Complete::Util::complete_array_elem(
            word => $args{word},
            array => [split(/\s+/, $ENV{MANSECT})],
        );
    }

    my $sect = $args{section};
    if (defined $sect) {
        $sect = [map {/\Aman/ ? $_ : "man$_"} split /\s*,\s*/, $sect];
    }

    return [] unless $ENV{MANPATH};

    my @manpages;
    my %sections;

    if ($use_mandb && File::Which::which("apropos")) {
        # it's simpler to just use 'apropos' to read mandb, instead of directly
        # reading dbm file and the screwed up situation of the availability of
        # *DBM_File.
        for my $line (`apropos -r .`) {
            $line =~ /^(\S+?) \(([^)]+)\)\s*-/ or next;
            push @manpages, $1;
            $sections{$2}++;
        }
    } else {
        # in the absence of 'apropos', list the man files. slooow.
        require Filename::Compressed;

        for my $dir (split /:/, $ENV{MANPATH}) {
            next unless -d $dir;
            opendir my($dh), $dir or next;
            for my $sectdir (readdir $dh) {
                next unless $sectdir =~ /\Aman/;
                next if $sect && !grep {$sectdir eq $_} @$sect;
                opendir my($dh), "$dir/$sectdir" or next;
                my @files = readdir($dh);
                for my $file (@files) {
                    next if $file eq '.' || $file eq '..';
                    my $chkres =
                        Filename::Compressed::check_compressed_filename(
                            filename => $file,
                        );
                    my $name = $chkres ?
                        $chkres->{uncompressed_filename} : $file;
                    if ($which eq 'section') {
                        # extract section name
                        $name =~ /\.(\w+)\z/ and $sections{$1}++;
                    } else {
                        # strip section name
                        $name =~ s/\.\w+\z//;
                        push @manpages, $name;
                    }
                }
            }
        }
    }

    if ($which eq 'section') {
        Complete::Util::complete_hash_key(
            word  => $args{word},
            hash  => \%sections,
        );
    } else {
        Complete::Util::complete_array_elem(
            word  => $args{word},
            array => \@manpages,
        );
    }
}

$SPEC{complete_manpage} = {
    v => 1.1,
    summary => 'Complete from list of available manpages',
    description => <<'_',

For each directory in `MANPATH` environment variable, search man section
directories and man files.

_
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        section => {
            summary => 'Only search from specified section(s)',
            schema  => 'str*',
            description => <<'_',

Can also be a comma-separated list to allow multiple sections.

_
        },
        use_mandb => {
            schema => ['bool*'],
            default => 1,
        },
    },
    result_naked => 1,
};
sub complete_manpage {
    _complete_manpage_or_section('manpage', @_);
}

$SPEC{complete_manpage_section} = {
    v => 1.1,
    summary => 'Complete from list of available manpage sections',
    description => <<'_',

If `MANSECT` is defined, will use that.

Otherwise, will collect section names by going through each directory in
`MANPATH` environment variable, searching man section directories and man files.

_
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub complete_manpage_section {
    my $res = _complete_manpage_or_section('section', @_);
    # fill in summary for standard sections
    {
        my %sections = (
            '1' => 'User Commands',
            '2' => 'System Calls',
            '3' => 'C Library Functions',
            '4' => 'Devices and Special Files',
            '5' => 'File Formats and Conventions',
            '6' => 'Games et. al.',
            '7' => 'Miscellanea',
            '8' => 'System Administration tools and Daemons',
        );
        for (@$res) {
            $_ = {word=>$_, summary=>$sections{$_}} if defined $sections{$_};
        }
    }
    $res;
}

1;
# ABSTRACT: Complete from list of available manpages

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Man - Complete from list of available manpages

=head1 VERSION

This document describes version 0.100 of Complete::Man (from Perl distribution Complete-Man), released on 2023-01-17.

=head1 SYNOPSIS

 use Complete::Man qw(complete_manpage complete_manpage_section);

 my $res = complete_manpage(word => 'gre');
 # -> ['grep', 'grep-changelog', 'greynetic', 'greytiff']

 # only from certain section
 $res = complete_manpage(word => 'gre', section => 1);
 # -> ['grep', 'grep-changelog', 'greytiff']

 # complete section
 $res = complete_manpage_section(word => '3');
 # -> ['3', '3perl', '3pm', '3readline']

=head1 FUNCTIONS


=head2 complete_manpage

Usage:

 complete_manpage(%args) -> any

Complete from list of available manpages.

For each directory in C<MANPATH> environment variable, search man section
directories and man files.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<section> => I<str>

Only search from specified section(s).

Can also be a comma-separated list to allow multiple sections.

=item * B<use_mandb> => I<bool> (default: 1)

(No description)

=item * B<word>* => I<str>

(No description)


=back

Return value:  (any)



=head2 complete_manpage_section

Usage:

 complete_manpage_section(%args) -> any

Complete from list of available manpage sections.

If C<MANSECT> is defined, will use that.

Otherwise, will collect section names by going through each directory in
C<MANPATH> environment variable, searching man section directories and man files.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Man>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Man>.

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

This software is copyright (c) 2023, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Man>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
