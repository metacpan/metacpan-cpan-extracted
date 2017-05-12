#!/usr/local/bin/perl

###############################################################################
# Purpose : Unit test for Any::Template::Backend::HTML::Template
# Author  : Tony Henness(e)y
# Created : Mar 05
# CVS     : $Header: /home/cvs/software/cvsroot/any_template/t/html_template.t,v 1.3 2006/05/08 12:28:00 mattheww Exp $
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
eval { require HTML::Template };
if( $@ ) {
    plan skip_all => 'HTML::Template not available so not testing Any::Template::Backend::HTML::Template';
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
require Any::Template::Backend::HTML::Template;
ok($INC{'Any/Template/Backend/HTML/Template.pm'}, "Compiled Any::Template::Backend::HTML::Template version $Any::Template::Backend::HTML::Template::VERSION");

#Check options are passed through to underlying object
#greating is only available in the loop if global_vars is true
my $obj = new Any::Template::Backend::HTML::Template( {String=>'<TMPL_LOOP NAME=loop><TMPL_VAR greating> <TMPL_VAR place></TMPL_LOOP>',Options=>{global_vars=>1}} );
ok(ref $obj eq 'Any::Template::Backend::HTML::Template', "object created");
my $rv;
$obj->process_to_string({loop=>[{greating=>'Hello'}],place=>'world'}, \$rv);
ok($rv eq 'Hello world', "supplied option has expected effect");
