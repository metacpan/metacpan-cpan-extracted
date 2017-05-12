#!/usr/local/bin/perl

###############################################################################
# Purpose : Unit test for Any::Template::Backend::Text::MicroMason
# Author  : Tony Henness(e)y
# Created : Mar 05
# CVS     : $Header: /home/cvs/software/cvsroot/any_template/t/text_micromason.t,v 1.4 2006/05/08 12:28:00 mattheww Exp $
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
eval { require Text::MicroMason };
if( $@ ) {
    plan skip_all => 'Text::MicroMason not available so not testing Any::Template::Backend::Text::MicroMason';
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
require Any::Template::Backend::Text::MicroMason;
ok($INC{'Any/Template/Backend/Text/MicroMason.pm'}, "Compiled Any::Template::Backend::Text::MicroMason version $Any::Template::Backend::Text::MicroMason::VERSION");

#Check options are passed through to underlying object
#here we use emulation of HTML::Template (see the html_template.t for test explanation
my $obj = new Any::Template::Backend::Text::MicroMason( {String=>'<TMPL_LOOP
NAME=loop><TMPL_VAR greating> <TMPL_VAR place></TMPL_LOOP>',Options=>{Attributes=>{loop_global_vars=>1},Mixins=>[qw(-HTMLTemplate -Filters)]}} );
ok(ref $obj eq 'Any::Template::Backend::Text::MicroMason', "object created");
my $rv;
$obj->process_to_string({loop=>[{greating=>'Hello'}],place=>'world'}, \$rv);
ok($rv eq 'Hello world', "supplied option has expected effect");

