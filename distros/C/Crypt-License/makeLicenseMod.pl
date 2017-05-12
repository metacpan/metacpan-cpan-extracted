#!/usr/bin/perl

use strict;

my $ENCRYPT_IT = 1;		# do /don't encrypt

my ($id,$module) = @ARGV;
undef @ARGV;

my $syntax = <<EOF;

syntax:	$0 ID: module_name

  do NOT use with C or xs files
  do NOT use with AUTOLOADER

  use only on plain single file
  perl modules.

  set up the SOURCE perl module as:
  Module.PM -- the output will be
  Module.pm
EOF

unless ($id && $module) {
  print $syntax;
  exit;
}

@_ = split(/::/,$module);
my $in = $_[$#_] . '.PM';
my $out = $_[$#_] . '.pm';


@_ = split('/', (@_=&{sub{caller;};})[1]);
$_[$#_] = 'mod_parser.pl';

my $parser = join('/',@_);

$_ = !$ENCRYPT_IT;
#exec qq{$parser $in $out trim_end $id $_};
do $parser;
&crypt_mod($in, $out, 'trim_end', $id, $_);
