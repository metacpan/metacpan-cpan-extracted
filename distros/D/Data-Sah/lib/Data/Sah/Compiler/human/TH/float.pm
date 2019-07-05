package Data::Sah::Compiler::human::TH::float;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::Sortable';
with 'Data::Sah::Type::float';

sub name { "decimal number" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        type=>'noun',
        fmt => ["decimal number", "decimal numbers"],
    });
}

sub clause_is_nan {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, {});
    } else {
        $c->add_ccl($cd, {
            fmt => $cv ?
                q[%(modal_verb)s be a NaN] :
                    q[%(modal_verb_neg)s be a NaN],
        });
    }
}

sub clause_is_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, {});
    } else {
        $c->add_ccl($cd, {
            fmt => $cv ?
                q[%(modal_verb)s an infinity] :
                    q[%(modal_verb_neg)s an infinity],
        });
    }
}

sub clause_is_pos_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, {});
    } else {
        $c->add_ccl($cd, {
            fmt => $cv ?
                q[%(modal_verb)s a positive infinity] :
                    q[%(modal_verb_neg)s a positive infinity],
        });
    }
}

sub clause_is_neg_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, {});
    } else {
        $c->add_ccl($cd, {
            fmt => $cv ?
                q[%(modal_verb)s a negative infinity] :
                    q[%(modal_verb_neg)s a negative infinity],
        });
    }
}

1;
# ABSTRACT: human's type handler for type "num"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::human::TH::float - human's type handler for type "num"

=head1 VERSION

This document describes version 0.896 of Data::Sah::Compiler::human::TH::float (from Perl distribution Data-Sah), released on 2019-07-04.

=for Pod::Coverage ^(name|clause_.+|superclause_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
