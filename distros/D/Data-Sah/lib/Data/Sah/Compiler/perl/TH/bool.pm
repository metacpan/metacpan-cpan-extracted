package Data::Sah::Compiler::perl::TH::bool;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::bool';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-19'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.914'; # VERSION

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

This document describes version 0.914 of Data::Sah::Compiler::perl::TH::bool (from Perl distribution Data-Sah), released on 2022-10-19.

=for Pod::Coverage ^(clause_.+|superclause_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
