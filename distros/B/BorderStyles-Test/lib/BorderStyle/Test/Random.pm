package BorderStyle::Test::Random;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-11'; # DATE
our $DIST = 'BorderStyles-Test'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;
use parent 'BorderStyleBase';

our %BORDER = (
    v => 2,
    summary => 'A border style that uses random characters',
    dynamic => 1,
    args => {
        cache => {
            schema => 'bool*',
            default => 1,
        },
    },
);

my @chars = map {chr($_)} 32 .. 127;

sub get_border_char {
    my ($self, $y, $x, $n, $args) = @_;
    $n = 1 unless defined $n;

    my $c;
    if ($self->{args}{cache}) {
        if (defined $self->{_cache}) {
            $c = $self->{_cache};
        } else {
            $self->{_cache} = $c = $chars[@chars * rand()];
        }
    } else {
        $c = $chars[@chars * rand()];
    }

    $c x $n;
}

1;
# ABSTRACT: A border style that uses random characters

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Test::Random - A border style that uses random characters

=head1 VERSION

This document describes version 0.002 of BorderStyle::Test::Random (from Perl distribution BorderStyles-Test), released on 2020-06-11.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyles-Test>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyles-Test>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyles-Test>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
