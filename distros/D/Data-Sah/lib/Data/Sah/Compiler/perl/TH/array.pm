package Data::Sah::Compiler::perl::TH::array;

use 5.010;
use strict;
use warnings;
use Log::ger;

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::array';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-19'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.914'; # VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "ref($dt) eq 'ARRAY'";
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_runtime_module($cd, $cd->{args}{dump_module});

    if ($which eq 'is') {
        $c->add_ccl($cd, $c->expr_dump($cd, $dt).' eq '.$c->expr_dump($cd, $ct));
    } elsif ($which eq 'in') {
        $c->add_ccl($cd, "do { my \$_sahv_dt_str = ".$c->expr_dump($cd, $dt)."; my \$_sahv_res = 0; " .
                        "for my \$_sahv_el (\@{ $ct }) { my \$_sahv_el_str = ".$c->expr_dump($cd, "\$_sahv_el")."; ".
                        "if (\$_sahv_dt_str eq \$_sahv_el_str) { \$_sahv_res = 1; last } } \$_sahv_res }");
    }
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'len') {
        $c->add_ccl($cd, "\@{$dt} == $ct");
    } elsif ($which eq 'min_len') {
        $c->add_ccl($cd, "\@{$dt} >= $ct");
    } elsif ($which eq 'max_len') {
        $c->add_ccl($cd, "\@{$dt} <= $ct");
    } elsif ($which eq 'len_between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl(
                $cd, "\@{$dt} >= $ct\->[0] && \@{$dt} >= $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl(
                $cd, "\@{$dt} >= $cv->[0] && \@{$dt} <= $cv->[1]");
        }
    } elsif ($which eq 'has') {
        $c->add_runtime_module($cd, $cd->{args}{dump_module});
        $c->add_ccl($cd, "do { my \$_sahv_ct_str = ".$c->expr_dump($cd, $ct)."; my \$_sahv_res = 0; " .
                        "for my \$_sahv_el (\@{ $dt }) { my \$_sahv_el_str = ".$c->expr_dump($cd, "\$_sahv_el")."; ".
                        "if (\$_sahv_ct_str eq \$_sahv_el_str) { \$_sahv_res = 1; last } } \$_sahv_res }");
    } elsif ($which eq 'each_index') {
        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        $self_th->gen_each($cd, "0..\@{$cd->{data_term}}-1", '_', '$_');
        $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
    } elsif ($which eq 'each_elem') {
        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        $self_th->gen_each($cd, "0..\@{$cd->{data_term}}-1", '_', "$cd->{data_term}\->[\$_]");
        $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
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

sub clause_elems {
    my ($self_th, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;

    my $jccl;
    {
        local $cd->{ccls} = [];

        my $cdef = $cd->{clset}{"elems.create_default"} // 1;
        delete $cd->{uclset}{"elems.create_default"};

        for my $i (0..@$cv-1) {
            local $cd->{spath} = [@{$cd->{spath}}, $i];
            my $nsch = $c->main->normalize_schema($cv->[$i]);
            my $edt = "$dt\->[$i]";
            my %iargs = %{$cd->{args}};
            $iargs{outer_cd}             = $cd;
            $iargs{data_name}            = "$cd->{args}{data_name}_$i";
            $iargs{data_term}            = $edt;
            $iargs{schema}               = $nsch;
            $iargs{schema_is_normalized} = 1;
            $iargs{cache}                = $cd->{args}{cache};
            $iargs{indent_level}++;
            my $icd = $c->compile(%iargs);
            my @code = (
                ($c->indent_str($cd), "(\$_sahv_dpath->[-1] = $i),\n") x !!$cd->{use_dpath},
                $icd->{result}, "\n",
            );
            my $ires = join("", @code);
            local $cd->{_debug_ccl_note} = "elem: $i";
            if ($cdef && defined($nsch->[1]{default})) {
                $c->add_ccl($cd, $ires);
            } else {
                $c->add_ccl($cd, "\@{$dt} < ".($i+1)." || ($ires)");
            }
        }
        $jccl = $c->join_ccls(
            $cd, $cd->{ccls}, {err_msg => ''});
    }
    $c->add_ccl($cd, $jccl, {subdata=>1});
}

1;
# ABSTRACT: perl's type handler for type "array"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl::TH::array - perl's type handler for type "array"

=head1 VERSION

This document describes version 0.914 of Data::Sah::Compiler::perl::TH::array (from Perl distribution Data-Sah), released on 2022-10-19.

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
