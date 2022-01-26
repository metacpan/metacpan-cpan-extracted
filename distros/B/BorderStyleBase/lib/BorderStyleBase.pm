package BorderStyleBase;

use strict 'subs', 'vars';
#use warnings;
use parent 'BorderStyleBase::Constructor';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-24'; # DATE
our $DIST = 'BorderStyleBase'; # DIST
our $VERSION = '0.010'; # VERSION

sub get_struct {
    my $self_or_class = shift;
    if (ref $self_or_class) {
        \%{"$self_or_class->{orig_class}::BORDER"};
    } else {
        \%{"$self_or_class\::BORDER"};
    }
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
    if (!defined($c)) {
        if    ($y == 4 && $x == 6) { $c = $bs_struct->{chars}[4][0]  }
        elsif ($y == 4 && $x == 7) { $c = $bs_struct->{chars}[4][3]  }
        elsif ($y == 6)            { $c = $bs_struct->{chars}[0][$x] }
        elsif ($y == 7)            { $c = $bs_struct->{chars}[5][$x] }
        elsif ($y == 8)            {
            $c = $bs_struct->{chars}[4][$x];
            if (!defined($c)) {
                if    ($x == 6) { $c = $bs_struct->{chars}[4][0]  }
                elsif ($x == 7) { $c = $bs_struct->{chars}[4][3]  }
            }
        }
    }
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

This document describes version 0.010 of BorderStyleBase (from Perl distribution BorderStyleBase), released on 2022-01-24.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyleBase>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyleBase>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyleBase>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
