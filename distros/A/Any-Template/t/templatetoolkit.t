#!/usr/local/bin/perl

###############################################################################
# Purpose : Unit test for Any::Template::Backend::TemplateToolkit
# Author  : Tony Henness(e)y
# Created : Mar 05
# CVS     : $Header: /home/cvs/software/cvsroot/any_template/t/templatetoolkit.t,v 1.3 2006/05/08 12:28:00 mattheww Exp $
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
eval { require Template };
if( $@ ) {
    plan skip_all => 'Template not available so not testing Any::Template::Backend::TemplateToolkit';
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
require Any::Template::Backend::TemplateToolkit;
ok($INC{'Any/Template/Backend/TemplateToolkit.pm'}, "Compiled Any::Template::Backend::TemplateToolkit version $Any::Template::Backend::TemplateToolkit::VERSION");

#Check options are passed through to underlying object
#create the output with perl is allowed by EVAL_PERL option
my $obj = new Any::Template::Backend::TemplateToolkit( {String=>'[% RAWPERL %]$stash->set("greating", "Hello world");[% END %][% GET greating %]',Options=>{EVAL_PERL=>1}} );
ok(ref $obj eq 'Any::Template::Backend::TemplateToolkit', "object created");
my $rv;
$obj->process_to_string({}, \$rv);
ok($rv eq 'Hello world', "supplied option has expected effect");
