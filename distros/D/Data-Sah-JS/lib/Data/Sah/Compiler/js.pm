package Data::Sah::Compiler::js;

our $DATE = '2016-09-14'; # DATE
our $VERSION = '0.87'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use String::Indent ();

extends 'Data::Sah::Compiler::Prog';

sub BUILD {
    my ($self, $args) = @_;

    $self->comment_style('cpp');
    $self->indent_character(" " x 4);
    $self->var_sigil("");
    $self->concat_op("+");
}

sub name { "js" }

sub expr {
    my ($self, $expr) = @_;
    $self->expr_compiler->js($expr);
}

sub literal {
    my ($self, $val) = @_;

    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new->allow_nonref;
    };

    # we need cleaning since json can't handle qr//, for one.
    state $cleanser = do {
        require Data::Clean::JSON;
        Data::Clean::JSON->get_cleanser;
    };

    $json->encode($cleanser->clone_and_clean($val));
}

sub compile {
    my ($self, %args) = @_;

    #$self->expr_compiler->compiler->hook_var(
    # ...
    #);

    #$self->expr_compiler->compiler->hook_func(
    # ...
    #);

    $self->SUPER::compile(%args);
}

sub true { "true" }

sub false { "false" }

sub expr_defined {
    my ($self, $t) = @_;
    "!($t === undefined || $t === null)";
}

sub expr_array {
    my ($self, @t) = @_;
    "[".join(",", @t)."]";
}

sub expr_array_subscript {
    my ($self, $at, $idxt) = @_;
    "$at\[$idxt]";
}

sub expr_last_elem {
    my ($self, $at, $idxt) = @_;
    "$at\[($at).length-1]";
}

sub expr_array_0_nmin1 {
    my ($self, $n) = @_;
    "Array($n).join().split(',').map(function(e,i){return i})";
}

sub expr_array_1_n {
    my ($self, $n) = @_;
    "Array($n).join().split(',').map(function(e,i){return i+1})";
}

sub expr_push {
    my ($self, $at, $elt) = @_;
    "($at).push($elt)";
}

sub expr_pop {
    my ($self, $at, $elt) = @_;
    "($at).pop()";
}

sub expr_push_and_pop_dpath_between_expr {
    my ($self, $et) = @_;
    join(
        "",
        "[",
        $self->expr_push('_sahv_dpath', $self->literal(undef)), ", ", # 0
        $self->enclose_paren($et), ", ", #1
        $self->expr_pop('_sahv_dpath'), # 2
        "][1]",
    );
}

sub expr_prefix_dpath {
    my ($self, $t) = @_;
    '(_sahv_dpath.length ? "@" + _sahv_dpath.map(function(e,i){return "["+e+"]"}).join("") + ": " : "") + ' . $t;
}

# $l = $r
sub expr_set {
    my ($self, $l, $r) = @_;
    "($l = $r)";
}

# $l //= $r
sub expr_setif {
    my ($self, $l, $r) = @_;
    "$l = " . $self->expr_defined($l) . " ? $l : $r";
}

sub expr_set_err_str {
    my ($self, $et, $err_expr) = @_;
    $self->expr_setif($et, $err_expr);
}

sub expr_set_err_full {
    my ($self, $et, $k, $err_expr) = @_;
    join(
        "",
        "(",
        $self->expr_setif("$et\['$k']", "{}"),
        ",",
        $self->expr_setif("$et\['$k'][_sahv_dpath.join('/')]", $err_expr),
        ")",
    );
}

sub expr_reset_err_str {
    my ($self, $et, $err_expr) = @_;
    "($et = null, true)";
}

sub expr_reset_err_full {
    my ($self, $et) = @_;
    join(
        "",
        "(",
        $self->expr_setif("$et\['errors']", "{}"),
        ",",
        "delete($et\['errors'][_sahv_dpath.join('/')])",
        ")",
    );
}

# $cond_term ? $true_term : $false_term
sub expr_ternary {
    my ($self, $cond_term, $true_term, $false_term) = @_;
    "$cond_term ? $true_term : $false_term";
}

sub expr_log {
    my ($self, $cd, $ccl) = @_;
    # currently not supported
    "";
}

sub expr_block {
    my ($self, $code) = @_;
    join(
        "",
        "(function() {\n",
        String::Indent::indent(
            $self->indent_character,
            $code,
        ),
        "})()",
    );
}

# whether block is implemented using function
sub block_uses_sub { 1 }

sub stmt_declare_local_var {
    my $self = shift;
    my $v = shift;
    if (@_) {
        "var $v = $_[0];";
    } else {
        "var $v;";
    }
}

sub expr_anon_sub {
    my ($self, $args, $code) = @_;
    join(
        "",
        "function(".join(", ", @$args).") {\n",
        String::Indent::indent(
            $self->indent_character,
            $code,
        ),
        "}"
    );
}

# enclose $stmt in an eval/try block, return true if succeeds, false if error
# was thrown. XXX error message was not recorded yet.
sub expr_eval {
    my ($self, $stmt) = @_;
    "(function(_err) { try { $stmt } catch (e) { _err = e }; return !_err })()";
}

sub stmt_require_module {
    my ($self, $mod_record) = @_;
    # currently loading module is not supported by js?
    #"require $mod_record->{name};";
    '';
}

sub stmt_require_log_module {
    my ($self) = @_;
    # currently logging is not supported by js
    '';
}

sub stmt_assign_hash_value {
    my ($self, $ht, $kt, $vt) = @_;
    "$ht\[$kt] = $vt;";
}

sub stmt_return {
    my $self = shift;
    if (@_) {
        "return($_[0]);";
    } else {
        'return;';
    }
}

sub expr_validator_sub {
    my ($self, %args) = @_;

    $args{data_term} = 'data';
    $self->SUPER::expr_validator_sub(%args);
}

sub _str2reliteral {
    my ($self, $cd, $str) = @_;

    my $re;
    if (ref($str) eq 'Regexp') {
        $re = "$str";
    } else {
        eval { qr/$str/ };
        $self->_die($cd, "Invalid regex $str: $@") if $@;
        $re = $str;
    }

    # i don't know if this is safe?
    $re = "$re";
    $re =~ s!/!\\/!g;
    "/$re/";
}

1;
# ABSTRACT: Compile Sah schema to JavaScript code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::js - Compile Sah schema to JavaScript code

=head1 VERSION

This document describes version 0.87 of Data::Sah::Compiler::js (from Perl distribution Data-Sah-JS), released on 2016-09-14.

=head1 SYNOPSIS

 # see Data::Sah

=head1 DESCRIPTION

Derived from L<Data::Sah::Compiler::Prog>.

=for Pod::Coverage BUILD ^(after_.+|before_.+|name|expr|true|false|literal|expr_.+|stmt_.+|block_uses_sub)$

=head1 DEVELOPER NOTES

To generate expression code that says "all subexpression must be true", you can
do:

 ARRAY.every(function(x) { return blah(x) })

which shortcuts to false after the first item failure.

To say "at least one subexpression must be true":

 !ARRAY.every(function(x) { return !blah(x) })

=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from Prog's arguments, this class supports these arguments:

=over

=back

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
