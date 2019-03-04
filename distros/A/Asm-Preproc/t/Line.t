#!perl

# $Id: Line.t,v 1.2 2010/09/30 22:59:45 Paulo Exp $

use strict;
use warnings;

use Test::More;
use_ok 'Asm::Preproc::Line';

my $line;
my $line1;
my $line2;

#------------------------------------------------------------------------------
# new / clone
isa_ok 	$line = Asm::Preproc::Line->new(),
		'Asm::Preproc::Line';

is		$line->text, 	undef, 		"no text";
is		$line->file, 	undef, 		"no file";
is		$line->line_nr, undef, 		"no line_nr";


isa_ok 	$line = Asm::Preproc::Line->new("text\n", "f1", 3),
		'Asm::Preproc::Line';
is		$line->text, 	"text\n", 	"text";
is		$line->file, 	"f1", 		"file";
is		$line->line_nr, 3, 			"line_nr";

isa_ok	$line2 = $line->clone,
		'Asm::Preproc::Line';
is		$line2->text, 	"text\n", 	"text";
is		$line2->file, 	"f1", 		"file";
is		$line2->line_nr, 3,			"line_nr";

$line->text('');
$line->line_nr('');
$line->file('');

is		$line->text, 	'', 		"no text";
is		$line->line_nr, '', 		"no line_nr";
is		$line->file, 	'', 		"no file";

is		$line2->text, 	"text\n", 	"text";
is		$line2->line_nr, 3,			"line_nr";
is		$line2->file, 	"f1", 		"file";

$line->text("ola");

is		$line->text, 	"ola", 		"no text";
is		$line->line_nr, '', 		"no line_nr";
is		$line->file, 	'', 		"no file";

$line->text(undef);

is		$line->text, 	undef, 		"no text";
is		$line->line_nr, '', 		"no line_nr";
is		$line->file, 	'', 		"no file";


#------------------------------------------------------------------------------
# regexp match on text
isa_ok 	$line = Asm::Preproc::Line->new("text\n", "f1", 3),
		'Asm::Preproc::Line';
ok $line->{text} =~ /\G(.)/gcxs, "match";
is $1, "t", "t";
ok $line->{text} =~ /\G(.)/gcxs, "match";
is $1, "e", "e";
ok $line->{text} =~ /\G(.)/gcxs, "match";
is $1, "x", "x";
ok $line->{text} =~ /\G(.)/gcxs, "match";
is $1, "t", "t";
ok $line->{text} =~ /\G(.)/gcxs, "match";
is $1, "\n", "newline";
ok $line->{text} =~ /\G\z/gcxs, "match";

#------------------------------------------------------------------------------
# error
my $warn; 
$SIG{__WARN__} = sub {$warn = shift};

sub test_error { 
	my($error_msg, $expected_error, $expected_warning) = @_;
	my $line_nr = (caller)[2];
	my $test_name = "[line $line_nr]";
		
	eval {	$line->error($error_msg) };
	is		$@, $expected_error, "$test_name die()";
	
			$warn = "";
			$line->warning($error_msg);
	is 		$warn, $expected_warning, "$test_name warning()";
	$warn = undef;
}
	
isa_ok 	$line = Asm::Preproc::Line->new(),
		'Asm::Preproc::Line';

test_error(undef, "error: \n", "warning: \n");
test_error("test error", "error: test error\n", "warning: test error\n");
test_error("test error\n", "error: test error\n", "warning: test error\n");

$line->text("");
test_error("test error", "error: test error\n", "warning: test error\n");

$line->text("0");
test_error("test error", "error: test error\n", "warning: test error\n");

$line->text("this line");
test_error("test error","error: test error\n", "warning: test error\n");

$line->line_nr(1);
test_error("test error","(1) : error: test error\n", "(1) : warning: test error\n");

$line->file("f1.asm");
test_error("test error","f1.asm(1) : error: test error\n", "f1.asm(1) : warning: test error\n");

$line->line_nr(0);
test_error("test error","f1.asm : error: test error\n", "f1.asm : warning: test error\n");

is $warn, undef, "no warnings";

#------------------------------------------------------------------------------
# is_equal, is_different
sub is_equal {
	my $line = "(line ". (caller)[2] .")";
	ok	  $line1 == $line2,  "  == $line";
	ok	!($line1 != $line2), "! != $line";
}

sub is_different {
	my $line = "(line ". (caller)[2] .")";
	ok	  $line1 != $line2,  "  != $line";
	ok	!($line1 == $line2), "! == $line";
}

isa_ok 	$line1 = Asm::Preproc::Line->new(),
		'Asm::Preproc::Line';
isa_ok 	$line2 = Asm::Preproc::Line->new(),
		'Asm::Preproc::Line';

is_equal;

$line1->text("hello");
is_different;
$line2->text("hello world");
is_different;
$line1->text("hello world");
is_equal;

$line1->line_nr(11);
is_different;
$line2->line_nr(12);
is_different;
$line1->line_nr(12);
is_equal;

$line1->file("hello");
is_different;
$line2->file("hello world");
is_different;
$line1->file("hello world");
is_equal;

#------------------------------------------------------------------------------
# overload fallback
isa_ok 	$line = Asm::Preproc::Line->new("text\n", "f1", 3),
		'Asm::Preproc::Line';
like "$line", qr/^Asm::Preproc::Line=HASH\(0x[0-9a-f]+\)$/i, "overload fallback";

done_testing();
