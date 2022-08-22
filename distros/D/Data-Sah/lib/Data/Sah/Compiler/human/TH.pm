package Data::Sah::Compiler::human::TH;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::TH';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-20'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.912'; # VERSION

sub name { undef }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    # give the class name
    my $pkg = ref($self);
    $pkg =~ s/^Data::Sah::Compiler::human::TH:://;

    $c->add_ccl($cd, {type=>'noun', fmt=>$pkg});
}

# not translated

sub clause_name {}
sub clause_summary {}
sub clause_description {}
sub clause_comment {}
sub clause_tags {}
sub clause_examples {}
sub clause_invalid_examples {}

sub clause_prefilters {}
sub clause_postfilters {}

# ignored

sub clause_ok {}

# handled in after_all_clauses

sub clause_req {}
sub clause_forbidden {}

# default implementation

sub clause_default {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {expr=>1,
                      fmt => 'default value %s'});
}

sub before_clause_clause {
    my ($self, $cd) = @_;
    $cd->{CLAUSE_DO_MULTI} = 0;
}

sub before_clause_clset {
    my ($self, $cd) = @_;
    $cd->{CLAUSE_DO_MULTI} = 0;
}

sub before_clause_if {
    my ($self, $cd) = @_;
    $cd->{CLAUSE_DO_MULTI} = 0;
}

sub clause_if {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my ($cond, $then, $else) = @$cv;

    unless (!ref($cond) && ref($then) eq 'ARRAY' && !$else) {
        $c->_die($cd, "Sorry, for 'if' clause, I currently can only handle COND=str (expr), THEN=array (schema), and no ELSE");
    }

    # temporary. currently it sucks because it plasters schema and expr directly
    $c->add_ccl($cd, {
        expr => 0,
        vals => [$cond, $then],
        fmt => 'if the expression %s is true then the schema %s must be followed',
    });
}

1;
# ABSTRACT: Base class for human type handlers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::human::TH - Base class for human type handlers

=head1 VERSION

This document describes version 0.912 of Data::Sah::Compiler::human::TH (from Perl distribution Data-Sah), released on 2022-08-20.

=for Pod::Coverage ^(name|compiler|clause_.+|handle_.+|before_.+|after_.+)$

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
