package BorderStyleBase;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-11'; # DATE
our $DIST = 'BorderStyleBase'; # DIST
our $VERSION = '0.002'; # VERSION

use strict 'subs', 'vars';
#use warnings;
use parent 'BorderStyleBase::Constructor';

sub get_struct {
    my $self = shift;
    \%{"$self->{orig_class}::BORDER"};
}

sub get_args {
    my $self = shift;
    $self->{args};
}

sub get_border_char {
    my ($self, $y, $x, $n, $args) = @_;
    $n = 1 unless defined $n;

    my $bs_struct = $self->get_struct;

    my $c = $bs_struct->{chars}[$y][$x];
    return unless defined $c;

    if (ref $c eq 'CODE') {
        my $c2 = $c->($self, $y, $x, $n, $args);
        if (ref $c2 eq 'CODE') {
            die "Border character ($y, $x) of style $self->{orig_class} returns coderef, ".
                "which after called still returns a coderef";
        }
        return $c2;
    } else {
        $c = $c x $n if $n != 1;
        $c = "\e(0$c\e(B" if $bs_struct->{box_chars};
    }
    $c;
}

1;
# ABSTRACT: A suitable base class for most BorderStyle::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyleBase - A suitable base class for most BorderStyle::* modules

=head1 VERSION

This document describes version 0.002 of BorderStyleBase (from Perl distribution BorderStyleBase), released on 2020-06-11.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyleBase>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyleBase>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyleBase>

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
