package Data::Sah::Compiler::perl::TH;

use 5.010;
use strict;
use warnings;
use Log::ger;

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::Prog::TH';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-20'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.912'; # VERSION

sub gen_each {
    my ($self, $cd, $indices_expr, $data_name, $data_term, $code_at_sub_begin) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;

    $c->add_runtime_module($cd, 'List::Util');
    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{data_name}            = $data_name;
    $iargs{data_term}            = $data_term;
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    $iargs{cache}                = $cd->{args}{cache};
    $iargs{indent_level}++;
    $iargs{data_term_includes_topic_var} = 1;
    my $icd = $c->compile(%iargs);
    my @code = (
        "!defined(List::Util::first(sub {", ($code_at_sub_begin // ''), "!(\n",
        ($c->indent_str($cd),
         "(\$_sahv_dpath->[-1] = \$_),\n") x !!$cd->{use_dpath},
         $icd->{result}, "\n",
         $c->indent_str($icd), ")}, ",
         $indices_expr,
         "))",
    );
    $c->add_ccl($cd, join("", @code), {subdata=>1});
}

1;
# ABSTRACT: Base class for perl type handlers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl::TH - Base class for perl type handlers

=head1 VERSION

This document describes version 0.912 of Data::Sah::Compiler::perl::TH (from Perl distribution Data-Sah), released on 2022-08-20.

=for Pod::Coverage ^(compiler|clause_.+|gen_.+)$

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
