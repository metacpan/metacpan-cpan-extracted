#!/usr/local/bin/perl

###############################################################################
# Purpose : Unit test for Any::Template::Backend::Text::Template
# Author  : Tony Henness(e)y
# Created : Mar 05
# CVS     : $Header: /home/cvs/software/cvsroot/any_template/t/text_template.t,v 1.3 2006/05/08 12:28:00 mattheww Exp $
###############################################################################
#
# -t Trace
# -T Deep trace
# -s save output
#
###############################################################################

use strict;
BEGIN{ unshift @INC, "../lib" };;
use Log::Trace;
use Getopt::Std;
use File::Spec;
use File::Path;

use Test::More;
# only test if module is available
eval { require Text::Template };
if( $@ ) {
    plan skip_all => 'Text::Template not available so not testing Any::Template::Backend::Text::Template';
}
else {
    plan tests => 3;
}

use vars qw($opt_t $opt_T $opt_s);
getopts("tTs");

#Move into the t directory
chdir($1) if($0 =~ /(.*)(\/|\\)(.*)/);

#Log::Trace
import Log::Trace qw(print) if($opt_t);
deep_import Log::Trace qw(print) if($opt_T);

#Compilation
require Any::Template::Backend::Text::Template;
ok($INC{'Any/Template/Backend/Text/Template.pm'}, "Compiled Any::Template::Backend::Text::Template version $Any::Template::Backend::Text::Template::VERSION");

#Check options are passed through to underlying object
#we append to our greating by way of the PREPEND option
my $obj = new Any::Template::Backend::Text::Template( {String=>'{$text}',Options=>{PREPEND=>'$text.=" world";'}} );
ok(ref $obj eq 'Any::Template::Backend::Text::Template', "object created");
my $rv;
$obj->process_to_string({text=>"Hello"}, \$rv);
ok($rv eq 'Hello world', "supplied option has expected effect");
