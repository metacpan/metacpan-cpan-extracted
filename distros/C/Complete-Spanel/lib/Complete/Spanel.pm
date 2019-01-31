package Complete::Spanel;

our $DATE = '2019-01-30'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_spanel_site
                );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to Spanel',
};

$SPEC{complete_spanel_site} = {
    v => 1.1,
    summary => 'Complete from a list of sites in /home/spanel/site (/s)',
    description => <<'_',

Root will be able to read the content of this directory. Thus, when run as root,
this routine will return complete from list of sites on the system. Normal users
cannot; thus, when run as normal user, this routine will return empty answer.

_
    args => {
        %arg_word,
        wildcard => {
            schema => ['int*', in=>[0,1,2]],
            default => 0,
            summary => 'How to treat wildcard subdomain',
            description => <<'_',

0 means to skip it. 1 means to return it as-is (e.g. `_.example.com`) while 2
means to return it converting `_` to `*`, e.g. `*.example.com`.

_
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_spanel_site {
    require Complete::Util;

    my %args  = @_;
    my $word  = $args{word} // "";
    my $wildcard = $args{wildcard} // 0;

    my @sites;
    {
        opendir my $dh, "/home/sloki/site" or last;
        while (defined(my $e = readdir $dh)) {
            next if $e eq '.' || $e eq '..';
            if ($e =~ /^_/) {
                next if !$wildcard;
                s/^_/*/ if $wildcard == 2;
            }
            push @sites, $e;
        }
    }
    Complete::Util::complete_array_elem(
        word => $word,
        array => \@sites,
    );
}

1;
# ABSTRACT: Completion routines related to Spanel

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Spanel - Completion routines related to Spanel

=head1 VERSION

This document describes version 0.001 of Complete::Spanel (from Perl distribution Complete-Spanel), released on 2019-01-30.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_spanel_site

Usage:

 complete_spanel_site(%args) -> array

Complete from a list of sites in /home/spanel/site (/s).

Root will be able to read the content of this directory. Thus, when run as root,
this routine will return complete from list of sites on the system. Normal users
cannot; thus, when run as normal user, this routine will return empty answer.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<wildcard> => I<int> (default: 0)

How to treat wildcard subdomain.

0 means to skip it. 1 means to return it as-is (e.g. C<_.example.com>) while 2
means to return it converting C<_> to C<*>, e.g. C<*.example.com>.

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Spanel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Spanel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Spanel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
