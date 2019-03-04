#!perl

# $Id: Preproc-stream.t,v 1.3 2013/07/23 11:27:40 Paulo Exp $

use strict;
use warnings;

use Test::More;
use File::Slurp;

use_ok 'Asm::Preproc';
use_ok 'Asm::Preproc::Line';
use_ok 'Iterator::Simple::Lookahead';

our $pp;

#------------------------------------------------------------------------------
# test eol normalization and joining continuation lines
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list(1..3);
isa_ok my $s = $pp->line_stream, 'Iterator::Simple::Lookahead';

is_deeply $s->next, Asm::Preproc::Line->new("1\n", 		"-", 	1);
is_deeply $s->next, Asm::Preproc::Line->new("2\n", 		"-", 	2);
is_deeply $s->next, Asm::Preproc::Line->new("3\n", 		"-", 	3);
is $s->next, undef;

done_testing();
