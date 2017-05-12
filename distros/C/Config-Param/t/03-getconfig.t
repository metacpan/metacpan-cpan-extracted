#!perl -T

use Test::More tests => 1;
use Config::Param;
use Storable qw(dclone);

use strict;

# Check if generated help messages match expectation.

my %default =
(
	 parm1=>'a string'
	,parm2=>'a multi-lined
value (with
EOT
)
that
goes
on without final line end'
	,parmA=>[1, 2, 'free', 'beer']
	,parmH=>{'key'=>3, 'donkey'=>'animal'}
	,parmX=>undef
);

my @pardef =
(
	 'parm1', $default{parm1}, 'a', 'help text for scalar 1'
	,'parm2', $default{parm2}, 'b', 'help text for scalar 2'
	,'parmA', $default{parmA}, 'A', 'help text for array A'
	,'parmH', $default{parmH}, 'H', 'help text for hash H'
	,'parmX', $default{parmX}, '',  'helptext for last one (scalar)'
);

my $output = "";
open my $oh, '>', \$output;

my @args = ('-I');
my %config = (info=>'just a program for testing', noexit=>1, linewidth=>50, output=>$oh, nofile=>1);

# no dclone of config because of the handle in it
Config::Param::get(\%config, dclone(\@pardef), \@args);

close $oh;

my $shouldbe = <<EOTTO;
# Configuration file for 03-getconfig.t
#
# Syntax:
# 
# 	name = value
# or
# 	name = "value"
#
# You can provide any number (including 0) of whitespaces before and after name and value. If you really want the whitespace in the value then use the second form and be happy;-)
# It is also possible to set multiline strings with
# name <<ENDSTRING
# ...
# ENDSTRING
#	
# (just like in Perl but omitting the ;)
# You can use .=, +=, /= and *= instead of = as operators for concatenation of strings or pushing to arrays/hashes, addition, substraction, division and multiplication, respectively.
# The same holds likewise for .<<, +<<, /<< and *<< .
#
# The short names are just provided as a reference; they're only working as real command line parameters, not in this file!
#
# The lines starting with "=" are needed for parsers of the file (other than 03-getconfig.t itself) and are informative to you, too.
# =param file (options) for program
# says for whom the file is and possibly some hints (options)
# =info INFO
# is the general program info (multiple lines, normally)
# =long NAME short S type TYPE
# says that now comes stuff for the parameter NAME and its short form is S. Data TYPE can be scalar, array or hash.
# =help SOME_TEXT
# gives a description for the parameter.
#
# If you don't like/need all this bloated text, the you can strip all "#", "=" - started and empty lines and the result will still be a valid configuration file for 03-getconfig.t.

=param file for 03-getconfig.t

=info just a program for testing

=long parm1 short a type scalar
=help help text for scalar 1

parm1 = "a string"

=long parm2 short b type scalar
=help help text for scalar 2

parm2 <<EOT1
a multi-lined
value (with
EOT
)
that
goes
on without final line end
EOT1

=long parmA short A type array
=help help text for array A

parmA  = "1"
parmA .= "2"
parmA .= "free"
parmA .= "beer"

=long parmH short H type hash
=help help text for hash H

parmH  = "donkey=animal"
parmH .= "key=3"

=long parmX type scalar
=help helptext for last one (scalar)

# parmX is undefined
EOTTO

ok( $output eq $shouldbe, 'normal help output' );
