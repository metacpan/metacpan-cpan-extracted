package Data::Sah::Compiler::js::TH::float;

our $DATE = '2016-09-14'; # DATE
our $VERSION = '0.87'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::js::TH::num';
with 'Data::Sah::Type::float';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{_ccl_check_type} = "(typeof($dt)=='number' || parseFloat($dt)==$dt)";
}

sub clause_is_nan {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl(
            $cd,
            join(
                "",
                "$ct ? isNaN($dt) : ",
                $self->expr_defined($ct), " ? !isNaN($dt) : true",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "isNaN($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!isNaN($dt)");
        }
    }
}

sub clause_is_pos_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl(
            $cd,
            join(
                "",
                "$ct ? $dt == Infinity : ",
                $self->expr_defined($ct), " ? $dt != Infinity : true",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "$dt == Infinity");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "$dt != Infinity");
        }
    }
}

sub clause_is_neg_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl(
            $cd,
            join(
                "",
                "$ct ? $dt == -Infinity : ",
                $self->expr_defined($ct), " ? $dt != -Infinity : true",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "$dt == -Infinity");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "$dt != -Infinity");
        }
    }
}

sub clause_is_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl(
            $cd,
            join(
                "",
                "$ct ? Math.abs($dt) == Infinity : ",
                $self->expr_defined($ct), " ? Math.abs($dt) != Infinity : true",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "Math.abs($dt) == Infinity");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "Math.abs($dt) != Infinity");
        }
    }
}

1;
# ABSTRACT: js's type handler for type "float"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::js::TH::float - js's type handler for type "float"

=head1 VERSION

This document describes version 0.87 of Data::Sah::Compiler::js::TH::float (from Perl distribution Data-Sah-JS), released on 2016-09-14.

=for Pod::Coverage ^(compiler|clause_.+|handle_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-JS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-JS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-JS>

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
