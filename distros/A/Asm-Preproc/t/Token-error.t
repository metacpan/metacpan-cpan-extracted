#!perl

# $Id: Token-error.t,v 1.1 2010/09/30 23:00:49 Paulo Exp $

use strict;
use warnings;

use Test::More;
use_ok 'Asm::Preproc::Line';
use_ok 'Asm::Preproc::Token';

my $warn; 
$SIG{__WARN__} = sub {$warn = shift};

my $token;

sub test_error { 
	my($error_msg, 
	   $expected_error, $expected_warning, 
	   $expected_error_notoken, $expected_warning_notoken) = @_;
	my $line_nr = (caller)[2];
	my $test_name = "[line $line_nr]";
		
	eval {	$token->error($error_msg) };
	is		$@, $expected_error, "$test_name error()";
	
	eval {	Asm::Preproc::Token->error_at($token, $error_msg) };
	is		$@, $expected_error, "$test_name error_at()";
	
	eval {	Asm::Preproc::Token->error_at(undef, $error_msg) };
	is		$@, $expected_error_notoken, "$test_name error_at(undef)";
	
			$warn = "";
			$token->warning($error_msg);
	is 		$warn, $expected_warning, "$test_name warning()";
	$warn = undef;
	
			$warn = "";
			Asm::Preproc::Token->warning_at($token, $error_msg);
	is 		$warn, $expected_warning, "$test_name warning_at()";
	$warn = undef;
	
			$warn = "";
			Asm::Preproc::Token->warning_at(undef, $error_msg);
	is 		$warn, $expected_warning_notoken, "$test_name warning_at()";
	$warn = undef;
}

isa_ok 	$token = Asm::Preproc::Token->new(),
		'Asm::Preproc::Token';

test_error(undef, 
			"error: at EOF\n", 
			"warning: at EOF\n",
			"error: at EOF\n", 
			"warning: at EOF\n");
test_error("test error", 
			"error: test error at EOF\n", 
			"warning: test error at EOF\n",
			"error: test error at EOF\n", 
			"warning: test error at EOF\n");
test_error("test error\n", 
			"error: test error at EOF\n", 
			"warning: test error at EOF\n",
			"error: test error at EOF\n", 
			"warning: test error at EOF\n");

$token->line->text("\tnop\n");
$token->line->file("f1.asm");
$token->line->line_nr(10);

test_error(undef, 
			"f1.asm(10) : error: at EOF\n", 
			"f1.asm(10) : warning: at EOF\n",
			"error: at EOF\n", 
			"warning: at EOF\n");
test_error("test error", 
			"f1.asm(10) : error: test error at EOF\n", 
			"f1.asm(10) : warning: test error at EOF\n",
			"error: test error at EOF\n", 
			"warning: test error at EOF\n");
test_error("test error\n", 
			"f1.asm(10) : error: test error at EOF\n", 
			"f1.asm(10) : warning: test error at EOF\n",
			"error: test error at EOF\n", 
			"warning: test error at EOF\n");

$token->type("\n");
test_error(undef, 
			"f1.asm(10) : error: at \"\\n\"\n", 
			"f1.asm(10) : warning: at \"\\n\"\n",
			"error: at EOF\n", 
			"warning: at EOF\n");
test_error("test error", 
			"f1.asm(10) : error: test error at \"\\n\"\n", 
			"f1.asm(10) : warning: test error at \"\\n\"\n",
			"error: test error at EOF\n", 
			"warning: test error at EOF\n");
test_error("test error\n", 
			"f1.asm(10) : error: test error at \"\\n\"\n", 
			"f1.asm(10) : warning: test error at \"\\n\"\n",
			"error: test error at EOF\n", 
			"warning: test error at EOF\n");

$token->type("hl");
test_error(undef, 
			"f1.asm(10) : error: at hl\n", 
			"f1.asm(10) : warning: at hl\n",
			"error: at EOF\n", 
			"warning: at EOF\n");
test_error("test error", 
			"f1.asm(10) : error: test error at hl\n", 
			"f1.asm(10) : warning: test error at hl\n",
			"error: test error at EOF\n", 
			"warning: test error at EOF\n");
test_error("test error\n", 
			"f1.asm(10) : error: test error at hl\n", 
			"f1.asm(10) : warning: test error at hl\n",
			"error: test error at EOF\n", 
			"warning: test error at EOF\n");


is $warn, undef, "no warnings";
done_testing();
