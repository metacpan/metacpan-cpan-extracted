# $Id$

use strict;


use Test::More;
use File::Spec;
use CGI::Session::Test::Default;

eval { require FreezeThaw };
plan skip_all=>"FreezeThaw is NOT available" if $@;


my $ses_dir = File::Spec->catdir('t', 'sessiondata');
my $t = CGI::Session::Test::Default->new(
    dsn => "Driver:file;serial:FreezeThaw",
    args=>{Directory=> $ses_dir });

plan tests => $t->number_of_tests;
$t->run();

#TODO: {
#    local $TODO = 'figure out how to test that $CGI::Session::Driver::file::FileName 
#                    is being handled correctly.';
#    local $CGI::Session::Driver::file::FileName = 'set_by_var.txt';
#    ok(0,'STUB');
#    #my $s = CGI::Session->new('Driver:file;serial:FreezeThaw',undef, { Directory=>$ses_dir } );
#}
#
#$CGI::Session::File::FileName = 'test_%s.txt';
#{
#    
#    ok(my $s = CGI::Session->new('Driver:file;serial:FreezeThaw',undef,
#            { Directory=> $ses_dir } ));
#    is( $CGI::Session::Driver::file::FileName,
#        $CGI::Session::File::FileName,
#        'compatibility with $CGI::Session::File::FileName has been preserved');
#}
