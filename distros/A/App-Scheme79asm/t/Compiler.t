#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('App::Scheme79asm::Compiler', qw/pretty_print/) };

sub is_sexp {
	my ($expr, $expected, $name) = @_;
	is pretty_print($expr), $expected, $name;
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
}

is_sexp new->process_quoted(to_sexp '5'), '(symbol 3)', 'process_quoted 5';
is_sexp new->process_quoted(to_sexp '()'), '(list 0)', 'process_quoted ()';
is_sexp new->process_quoted(to_sexp '(5 foo)'), '(list (list (list 0) (symbol 3)) (symbol 4))', 'process_quoted (5 foo)';
is_sexp new->process_quoted(to_sexp '(((5)))'), '(list (list 0) (list (list 0) (list (list 0) (symbol 3))))', 'process_quoted (((5)))';

is_toplevel '(quote 5)', '(symbol 3)';
is_toplevel '(if t \'(2 3) \'x)', '(if (list (symbol 5) (list (list (list 0) (symbol 3)) (symbol 4))) (symbol 2))';
is_toplevel '(car \'(1 2))', '(call (car 0) (list (list (list 0) (symbol 3)) (symbol 4)))';
is_toplevel '(lambda id (x) x)', '(proc (var -2))';
is_toplevel '((lambda id (x) x) 5)', '(call (more (funcall 0) (proc (var -2))) (symbol 3))';
is_toplevel '(lambda append (x y) (if (atom x) y (cons (car x) (append (cdr x) y))))', '(proc (if (list (call (more (cons 0) (call (more (more (funcall 0) (var -1)) (var -2)) (call (cdr 0) (var -3)))) (call (car 0) (var -3))) (var -2)) (call (atom 0) (var -3))))';
