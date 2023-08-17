#!perl

use warnings;
use strict;
use Test::More;

use App::FileComposer;


my $default_dir = "$ENV{HOME}/.app-filecomposer";
my $obj = App::FileComposer->new(filename => 'hello.pl');

#// Check for fake directory names
    eval{
     $obj->set_sourcePath('/vegeta-planet/house'),
	 	 $obj->load()
	} or my $att = $@;

    like($att, qr/directory does not exist/, 'prevent fake directories, thats ok!');
 
	#// Check the load() protect from bad filenames 
	eval{
		 $obj->set_filename('hello'),
	 	 $obj->load()
	} or  $att = $@;	
	 
	    like($att, qr/Bad Filename attribute/, 'Prevent from Bad filenames,looks ok..');


   
done_testing;
