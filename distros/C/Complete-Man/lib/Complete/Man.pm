package Complete::Man;

our $DATE = '2017-07-29'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

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
    _complete_manpage_or_section('section', @_);
}

1;
# ABSTRACT: Complete from list of available manpages

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Man - Complete from list of available manpages

=head1 VERSION

This document describes version 0.09 of Complete::Man (from Perl distribution Complete-Man), released on 2017-07-29.

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

=item * B<word>* => I<str>

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

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Man>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Man>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Man>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
