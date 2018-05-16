#!/usr/bin/perl
use strict;
use warnings;

use Data::Dump::Sexp;
use Test::More tests => 32;

BEGIN { use_ok('App::Scheme79asm::Compiler') };

sub is_sexp {
	my ($expr, $expected, $name) = @_;
	is dump_sexp($expr), $expected, $name;
}

sub to_sexp {
	my ($string) = @_;
	scalar Data::SExpression->new({fold_lists => 0, use_symbol_class => 1})->read($string)
}

sub new {
	App::Scheme79asm::Compiler->new;
}

sub is_toplevel {
	my ($string, $expected) = @_;
	is_sexp new->process_toplevel(to_sexp $string), $expected, "process_toplevel $string";
	is_sexp new->compile_string($string), $expected, "compile_string $string";
}

is_sexp new->process_quoted(to_sexp '5'), '(SYMBOL 3)', 'process_quoted 5';
is_sexp new->process_quoted(to_sexp 'NIL'), '(LIST 0)', 'process_quoted NIL';
is_sexp new->process_quoted(to_sexp '()'), '(LIST 0)', 'process_quoted ()';
is_sexp new->process_quoted(to_sexp '(5 foo)'), '(LIST (LIST (LIST 0) (SYMBOL 3)) (SYMBOL 4))', 'process_quoted (5 foo)';
is_sexp new->process_quoted(to_sexp '(((5)))'), '(LIST (LIST 0) (LIST (LIST 0) (LIST (LIST 0) (SYMBOL 3))))', 'process_quoted (((5)))';

is_toplevel '()', '(LIST 0)';
is_toplevel 'NIL', '(LIST 0)';
is_toplevel 'T', '(SYMBOL 2)';
is_toplevel '(quote 5)', '(SYMBOL 3)';
is_toplevel '(reverse-list \'a \'a \'b)', '(CALL (MORE (MORE (REVERSE-LIST 0) (SYMBOL 4)) (SYMBOL 3)) (SYMBOL 3))';
is_toplevel '(if t \'(2 3) \'x)', '(IF (LIST (SYMBOL 5) (LIST (LIST (LIST 0) (SYMBOL 3)) (SYMBOL 4))) (SYMBOL 2))';
is_toplevel '(car \'(1 2))', '(CALL (CAR 0) (LIST (LIST (LIST 0) (SYMBOL 3)) (SYMBOL 4)))';
is_toplevel '(lambda id (x) x)', '(PROC (VAR -2))';
is_toplevel '((lambda id (x) x) 5)', '(CALL (MORE (FUNCALL 0) (PROC (VAR -2))) (SYMBOL 3))';
is_toplevel '(lambda append (x y) (if (atom x) y (cons (car x) (append (cdr x) y))))', '(PROC (IF (LIST (CALL (MORE (CONS 0) (CALL (MORE (MORE (FUNCALL 0) (VAR -1)) (VAR -2)) (CALL (CDR 0) (VAR -3)))) (CALL (CAR 0) (VAR -3))) (VAR -2)) (CALL (ATOM 0) (VAR -3))))';

sub pp_roundtrip {
	my ($string) = @_;
	my $pp = uc dump_sexp(to_sexp $string);
	is $pp, uc($string), "dump_sexp roundtrip $string";
}

pp_roundtrip '()';
pp_roundtrip 't';
pp_roundtrip '(lambda append (x y) (if (atom x) y (cons (car x) (append (cdr x) y))))';

sub expect_error_like (&$) {
	my ($block, $error_re) = @_;
	my $name = "test error like /$error_re/";
	my $result = eval { $block->(); 1 };
	if ($result) {
		note 'Block did not throw an exception, failing test';
		fail $name;
	} else {
		like $@, qr/$error_re/, $name;
	}
}

expect_error_like { new->process_quoted([]) } 'argument to process_quoted is not a scalar, cons, or nil';
expect_error_like { is_toplevel 'x' } 'Variable x not in environment';
expect_error_like { is_toplevel '(car)' } 'Cannot call primitive car with no arguments';
