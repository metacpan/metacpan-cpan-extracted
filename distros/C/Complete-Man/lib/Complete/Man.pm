package Complete::Man;

our $DATE = '2016-10-20'; # DATE
our $VERSION = '0.07'; # VERSION

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

    my $which = shift;
    my %args = @_;

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

    require Filename::Compressed;

    my @res;
    my %res;
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
                my $chkres = Filename::Compressed::check_compressed_filename(
                    filename => $file,
                );
                my $name = $chkres ? $chkres->{uncompressed_filename} : $file;
                if ($which eq 'section') {
                    $name =~ /\.(\w+)\z/ and $res{$1}++; # extract section name
                } else {
                    $name =~ s/\.\w+\z//; # strip section name
                    push @res, $name;
                }
            }
        }
    }
    if ($which eq 'section') {
        Complete::Util::complete_hash_key(
            word => $args{word},
            hash => \%res,
        );
    } else {
        Complete::Util::complete_array_elem(
            word => $args{word},
            array => \@res,
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

This document describes version 0.07 of Complete::Man (from Perl distribution Complete-Man), released on 2016-10-20.

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


=head2 complete_manpage(%args) -> any

Complete from list of available manpages.

For each directory in C<MANPATH> environment variable, search man section
directories and man files.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<section> => I<str>

Only search from specified section(s).

Can also be a comma-separated list to allow multiple sections.

=item * B<word>* => I<str>

=back

Return value:  (any)


=head2 complete_manpage_section(%args) -> any

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

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
