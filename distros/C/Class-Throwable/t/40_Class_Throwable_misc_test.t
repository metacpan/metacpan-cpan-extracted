#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

# check bad inline names

eval "use Class::Throwable '+';";
like($@, 
    qr/An error occured while constructing Class\:\:Throwable exception \(\+\)/, 
    '... got the exception we expected');
    
# these should all get ignored
    
use_ok('Class::Throwable', 0, "", undef);    

# test this exception

{
	package Broken::Exception;
	our @ISA = ('Class::Throwable');
}

eval { 
	Broken::Exception->import('This::Will::Not::Work') 
};
like($@, 
	qr/Inline Exceptions can only be created with Class\:\:Throwable/,
	'... got the error we expected');
	
# and this exception
	
eval {
	Class::Throwable->import("VERBOSE");
};
like($@,
	qr/You must specify a level of verbosity with Class\:\:Throwable/,
	'... got the error we expected');
  
 # and ...   
        
eval {
    my $e = Class::Throwable->new();
    $e->setVerbosity(1);
};    
like($@,
    qr/setVerbosity is a class method only, it cannot be used on an instance/,
    '... got the error we expected');
    
eval {
    Class::Throwable->setVerbosity();
};    
like($@,
    qr/You must specify a level of verbosity with Class\:\:Throwable/,
    '... got the error we expected');    