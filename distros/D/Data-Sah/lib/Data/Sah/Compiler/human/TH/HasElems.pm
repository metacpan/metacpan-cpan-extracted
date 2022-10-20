package Data::Sah::Compiler::human::TH::HasElems;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::HasElems';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-19'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.914'; # VERSION

sub before_clause {
    my ($self_th, $which, $cd) = @_;
}

sub before_clause_len_between {
    my ($self, $cd) = @_;
    $cd->{CLAUSE_DO_MULTI} = 0;
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};

    if ($which eq 'len') {
        $c->add_ccl($cd, {
            expr  => 1,
            fmt   => q[length %(modal_verb)s be %s],
        });
    } elsif ($which eq 'min_len') {
        $c->add_ccl($cd, {
            expr  => 1,
            fmt   => q[length %(modal_verb)s be at least %s],
        });
    } elsif ($which eq 'max_len') {
        $c->add_ccl($cd, {
            expr  => 1,
            fmt   => q[length %(modal_verb)s be at most %s],
        });
    } elsif ($which eq 'len_between') {
        $c->add_ccl($cd, {
            fmt   => q[length %(modal_verb)s be between %s and %s],
            vals  => $cv,
        });
    } elsif ($which eq 'has') {
        $c->add_ccl($cd, {
            expr=>1, multi=>1,
            fmt => "%(modal_verb)s have %s in its elements"});
    } elsif ($which eq 'each_index') {
        $self_th->clause_each_index($cd);
    } elsif ($which eq 'each_elem') {
        $self_th->clause_each_elem($cd);
    } elsif ($which eq 'check_each_index') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'check_each_elem') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'uniq') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'exists') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    }
}

1;
# ABSTRACT: human's type handler for role "HasElems"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::human::TH::HasElems - human's type handler for role "HasElems"

=head1 VERSION

This document describes version 0.914 of Data::Sah::Compiler::human::TH::HasElems (from Perl distribution Data-Sah), released on 2022-10-19.

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$

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
