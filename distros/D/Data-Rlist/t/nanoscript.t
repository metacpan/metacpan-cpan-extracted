#!/usr/bin/perl
#
# nanoscript.t
#
# Test bas64-encoded binaries.
#
# $Writestamp: 2008-07-24 16:42:44 eh2sper$
# $Compile: perl -M'constant standalone => 1' nanoscript.t$

BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use warnings;
use strict;
use constant;

use Test::More tests => 138;
#use Test::More 'no_plan';

use Data::Rlist qw/:strings/;
use MIME::Base64;

our $nanotok = 'perl';
our $tempfile = "$0.tmp";
our $temp;
our @text;

#########################

if (1) {
	@text = (<<__0, <<__1, <<__2);
(<<perl)
 "Hello World!\n"
perl
__0
{ sentinel = <<perl; }
 "Hello World!\n"
perl
__1
( <<perl, <<perl, <<perl, <<perl )
 "Hello World!\n"				# english
perl
 "Hallo Welt!\n"				# german
perl
 "Bonjour le monde!\n"			# french
perl
 "Olá mundo!\n"					# spanish
perl
__2

	@text = map { $_->read; $_ } map { new Data::Rlist(-input => \$_) } @text;
	ok($_->result) foreach @text;
	ok($_->has(-nanoscripts=>)) foreach @text;
	ok($_->get(-nanoscripts=>)) foreach @text;
	ok($_->nanoscripts) foreach @text;
	#$Data::Rlist::DEBUG = 1;
	ok($_->evaluate_nanoscripts) foreach @text;
	#use Data::Dumper; print Dumper $text[2]->result;
	ok(not CompareData($text[2]->result, ["Hello World!\n", "Hallo Welt!\n", "Bonjour le monde!\n", "Olá mundo!\n"]));
}

#########################

if (1) {
	@text = (<<__0, <<__1, <<__2);
{
	test;
	foo = (<<perl);
						6 * 7
perl
}
__0
    ( <<x, <<abc, 7, <<perl )
x
abc
perl
__1
    ( 0, <<$nanotok, <<$nanotok, <<$nanotok, <<$nanotok )
	"Hello World!\n"
$nanotok
	"Hallo Welt!\n"
$nanotok
	"Bonjour le monde!\n"
$nanotok
	"Olá mundo!\n"
$nanotok
__2

	#$Data::Rlist::DEBUG = 1;
	ok(ReadData \$text[0]);
	ok(@{Data::Rlist::nanoscripts()} == 1);

	for my $i (0..$#text) {
		my $text = $text[$i];
		for my $opts (undef, qw/default string squeezed outlined/) {
			my $rl = new Data::Rlist(-input => \$text, -options => $opts, -DEBUG => 0);
			my $data = $rl->read;
			my $ns = $rl->nanoscripts; # get an array of scripts

			ok( $data);
			ok(!$rl->errors);
			ok( $rl->result);
			ok( $rl->result eq $data);
			ok(((!defined $ns) || $rl->has(-nanoscripts=>)) ||
			   (( defined $ns) && $rl->has(-nanoscripts=>)));
			ok(@{$rl->nanoscripts} == 1) if $i == 0;
			ok(@{$rl->nanoscripts} == 1) if $i == 1;
			ok(@{$rl->nanoscripts} == 4) if $i == 2;
			ok(  $rl->evaluate_nanoscripts);

			ok(not CompareData($rl->result, { test => "", foo => [42] })) if $i == 0;
			ok(not CompareData($rl->result, ["\n", "\n", 7, undef])) if $i == 1;
			ok(not CompareData($rl->result, [0,
											 "Hello World!\n", "Hallo Welt!\n",
											 "Bonjour le monde!\n", "Olá mundo!\n"])) if $i == 2;
		}
	}
}

#unlink $tempfile;

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### End:
