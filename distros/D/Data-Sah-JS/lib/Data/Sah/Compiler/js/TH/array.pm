package Data::Sah::Compiler::js::TH::array;

our $DATE = '2016-09-14'; # DATE
our $VERSION = '0.87'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::array';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "$dt instanceof Array";
}

my $STR = "JSON.stringify";

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "$STR($dt) == $STR($ct)");
    } elsif ($which eq 'in') {
        $c->add_ccl(
            $cd,
            "!($ct).every(function(x){return $STR(x) != $STR($dt) })");
    }
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'len') {
        $c->add_ccl($cd, "($dt).length == $ct");
    } elsif ($which eq 'min_len') {
        $c->add_ccl($cd, "($dt).length >= $ct");
    } elsif ($which eq 'max_len') {
        $c->add_ccl($cd, "($dt).length <= $ct");
    } elsif ($which eq 'len_between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl(
                $cd, "($dt).length >= $ct\->[0] && ($dt).length >= $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl(
                $cd, "($dt).length >= $cv->[0] && ($dt).length <= $cv->[1]");
        }
    } elsif ($which eq 'has') {
        $c->add_ccl(
            $cd,
            "($dt).map(function(x){return $STR(x)}).indexOf($STR($ct)) > -1");
    } elsif ($which eq 'each_index') {
        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        $self_th->gen_each($cd,
                           $c->expr_array_0_nmin1("($cd->{data_term}).length"), '_x', '_x');
        $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
    } elsif ($which eq 'each_elem') {
        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        $self_th->gen_each($cd,
                           $c->expr_array_0_nmin1("($cd->{data_term}).length"), '_x', "$cd->{data_term}\[_x]");
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
            my $sch = $c->main->normalize_schema($cv->[$i]);
            my $edt = "$dt\[$i]";
            my %iargs = %{$cd->{args}};
            $iargs{outer_cd}             = $cd;
            $iargs{data_name}            = "$cd->{args}{data_name}_$i";
            $iargs{data_term}            = $edt;
            $iargs{schema}               = $sch;
            $iargs{schema_is_normalized} = 1;
            $iargs{indent_level}++;
            my $icd = $c->compile(%iargs);
            my @code = (
                ($c->indent_str($cd),
                 "(_sahv_dpath[-1] = $i),\n") x !!$cd->{use_dpath},
                $icd->{result}, "\n",
            );
            my $ires = join("", @code);
            local $cd->{_debug_ccl_note} = "elem: $i";
            if ($cdef && defined($sch->[1]{default})) {
                $c->add_ccl($cd, $ires);
            } else {
                $c->add_ccl($cd, "($dt).length < ".($i+1)." || ($ires)");
            }
        }
        $jccl = $c->join_ccls(
            $cd, $cd->{ccls}, {err_msg => ''});
    }
    $c->add_ccl($cd, $jccl, {subdata=>1});
}

1;
# ABSTRACT: js's type handler for type "array"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::js::TH::array - js's type handler for type "array"

=head1 VERSION

This document describes version 0.87 of Data::Sah::Compiler::js::TH::array (from Perl distribution Data-Sah-JS), released on 2016-09-14.

=for Pod::Coverage ^(clause_.+|superclause_.+)$

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
