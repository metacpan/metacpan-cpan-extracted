package Data::Sah::Compiler::perl::TH::bool;

our $DATE = '2021-07-29'; # DATE
our $VERSION = '0.909'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::bool';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "!ref($dt)";
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "($dt ? 1:0) == ($ct ? 1:0)");
    } elsif ($which eq 'in') {
        if ($dt =~ /\$_\b/) {
            $c->add_ccl($cd, "do { my \$_sahv_dt = $dt; (grep { (\$_ ? 1:0) == (\$_sahv_dt ? 1:0) } \@{ $ct }) ? 1:0 }");
        } else {
            $c->add_ccl($cd, "(grep { (\$_ ? 1:0) == ($dt ? 1:0) } \@{ $ct }) ? 1:0");
        }
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'min') {
        $c->add_ccl($cd, "($dt ? 1:0) >= ($ct ? 1:0)");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "($dt ? 1:0) > ($ct ? 1:0)");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "($dt ? 1:0) <= ($ct ? 1:0)");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "($dt ? 1:0) < ($ct ? 1:0)");
    } elsif ($which eq 'between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "($dt ? 1:0) >= ($ct\->[0] ? 1:0) && ".
                            "($dt ? 1:0) <= ($ct\->[1] ? 1:0)");
        } else {
            # simplify code
            $c->add_ccl($cd, "($dt ? 1:0) >= ($cv->[0] ? 1:0) && ".
                            "($dt ? 1:0) <= ($cv->[1] ? 1:0)");
        }
    } elsif ($which eq 'xbetween') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "($dt ? 1:0) > ($ct\->[0] ? 1:0) && ".
                            "($dt ? 1:0) < ($ct\->[1] ? 1:0)");
        } else {
            # simplify code
            $c->add_ccl($cd, "($dt ? 1:0) > ($cv->[0] ? 1:0) && ".
                            "($dt ? 1:0) < ($cv->[1] ? 1:0)");
        }
    }
}

sub clause_is_true {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "($ct) ? $dt : !defined($ct) ? 1 : !$dt");
}

1;
# ABSTRACT: perl's type handler for type "bool"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl::TH::bool - perl's type handler for type "bool"

=head1 VERSION

This document describes version 0.909 of Data::Sah::Compiler::perl::TH::bool (from Perl distribution Data-Sah), released on 2021-07-29.

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
