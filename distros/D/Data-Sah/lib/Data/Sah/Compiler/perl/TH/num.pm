package Data::Sah::Compiler::perl::TH::num;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::num';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    if ($cd->{args}{core} || $cd->{args}{no_modules}) {
        $cd->{_ccl_check_type} = "$dt =~ ".'/\A(?:[+-]?(?:0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?|((?i)\s*nan\s*)|((?i)\s*[+-]?inf(inity)?)\s*)\z/';
    } else {
        $c->add_sun_module($cd);
        $cd->{_ccl_check_type} = "$cd->{_sun_module}::isnum($dt)";
    }
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "$dt == $ct");
    } elsif ($which eq 'in') {
        $c->add_runtime_smartmatch_pragma($cd);
        $c->add_ccl($cd, "$dt ~~ $ct");
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'min') {
        $c->add_ccl($cd, "$dt >= $ct");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "$dt > $ct");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "$dt <= $ct");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "$dt < $ct");
    } elsif ($which eq 'between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "$dt >= $ct\->[0] && $dt <= $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl($cd, "$dt >= $cv->[0] && $dt <= $cv->[1]");
        }
    } elsif ($which eq 'xbetween') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "$dt > $ct\->[0] && $dt < $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl($cd, "$dt > $cv->[0] && $dt < $cv->[1]");
        }
    }
}

1;
# ABSTRACT: perl's type handler for type "num"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl::TH::num - perl's type handler for type "num"

=head1 VERSION

This document describes version 0.897 of Data::Sah::Compiler::perl::TH::num (from Perl distribution Data-Sah), released on 2019-07-19.

=for Pod::Coverage ^(clause_.+|superclause_.+)$

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
