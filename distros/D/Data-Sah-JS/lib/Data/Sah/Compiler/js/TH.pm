package Data::Sah::Compiler::js::TH;

our $DATE = '2016-09-14'; # DATE
our $VERSION = '0.87'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);

extends 'Data::Sah::Compiler::Prog::TH';

sub gen_each {
    my ($self, $cd, $indices_expr, $data_name, $data_term, $code_at_sub_begin) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{data_name}            = $data_name,
    $iargs{data_term}            = $data_term,
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    $iargs{indent_level}++;
    $iargs{data_term_includes_topic_var} = 1;
    my $icd = $c->compile(%iargs);
    my @code = (
        "(", $indices_expr, ").every(function(_x){", ($code_at_sub_begin // ''), " return(\n",
        # if ary == [], then set ary[0] = 0, else set ary[-1] = ary[-1]+1
        ($c->indent_str($cd), "(_sahv_dpath[_sahv_dpath.length ? _sahv_dpath.length-1 : 0] = _x),\n") x !!$cd->{use_dpath},
        $icd->{result}, "\n",
        $c->indent_str($icd), ")})",
    );
    $c->add_ccl($cd, join("", @code), {subdata=>1});
}

1;
# ABSTRACT: Base class for js type handlers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::js::TH - Base class for js type handlers

=head1 VERSION

This document describes version 0.87 of Data::Sah::Compiler::js::TH (from Perl distribution Data-Sah-JS), released on 2016-09-14.

=for Pod::Coverage ^(compiler|clause_.+|gen_.+)$

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
