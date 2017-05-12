package Complete::Dist;

our $DATE = '2015-11-30'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Common qw(:all);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_dist);

$SPEC{complete_dist} = {
    v => 1.1,
    summary => 'Complete from list of installed Perl distributions',
    description => <<'_',

Installed Perl distributions are listed using `Dist::Util::list_dists()`.

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
sub complete_dist {
    require Complete::Util;
    require Dist::Util;

    my %args = @_;

    my $word = $args{word} // '';

    $word =~ s!(::|-|/|\.)!-!g;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => [Dist::Util::list_dists()],
    );
}

1;
# ABSTRACT: Complete from list of installed Perl distributions

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Dist - Complete from list of installed Perl distributions

=head1 VERSION

This document describes version 0.07 of Complete::Dist (from Perl distribution Complete-Dist), released on 2015-11-30.

=head1 SYNOPSIS

 use Complete::Dist qw(complete_dist);
 my $res = complete_dist(word => 'Text-AN');
 # -> ['Text-ANSI-Util', 'Text-ANSITable']

=head1 FUNCTIONS


=head2 complete_dist(%args) -> any

Complete from list of installed Perl distributions.

Installed Perl distributions are listed using C<Dist::Util::list_dists()>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Dist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Dist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Dist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
