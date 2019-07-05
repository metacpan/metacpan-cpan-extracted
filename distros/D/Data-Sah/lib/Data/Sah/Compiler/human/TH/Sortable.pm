package Data::Sah::Compiler::human::TH::Sortable;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::Sortable';

sub before_clause_between {
    my ($self, $cd) = @_;
    $cd->{CLAUSE_DO_MULTI} = 0;
}

sub before_clause_xbetween {
    my ($self, $cd) = @_;
    $cd->{CLAUSE_DO_MULTI} = 0;
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;
    my $cv = $cd->{cl_value};

    if ($which eq 'min') {
        $c->add_ccl($cd, {
            expr=>1,
            fmt => '%(modal_verb)s be at least %s',
        });
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, {
            expr=>1,
            fmt => '%(modal_verb)s be larger than %s',
        });
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, {
            expr=>1,
            fmt => '%(modal_verb)s be at most %s',
        });
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, {
            expr=>1,
            fmt => '%(modal_verb)s be smaller than %s',
        });
    } elsif ($which eq 'between') {
        $c->add_ccl($cd, {
            fmt => '%(modal_verb)s be between %s and %s',
            vals => $cv,
        });
    } elsif ($which eq 'xbetween') {
        $c->add_ccl($cd, {
            fmt => '%(modal_verb)s be larger than %s and smaller than %s',
            vals => $cv,
        });
    }
}

1;
# ABSTRACT: human's type handler for role "Sortable"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::human::TH::Sortable - human's type handler for role "Sortable"

=head1 VERSION

This document describes version 0.896 of Data::Sah::Compiler::human::TH::Sortable (from Perl distribution Data-Sah), released on 2019-07-04.

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$

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
