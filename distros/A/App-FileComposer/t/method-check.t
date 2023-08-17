#!perl

use warnings;
use strict;
use Test::More;

use App::FileComposer;

my $obj = App::FileComposer->new(filename => 'hello.pl');




#// Check instance atributes
is($obj->{'filename'}, 'hello.pl', 'Instance attributes seem to work..');
is($obj->{'origin'}, "$ENV{HOME}/.app-filecomposer" ,'The default Path is set!');

#// Check instance methods
eval { $obj->load() } or my $err = $@;
ok($err, 'Have not yet installed the source directory. but load() is loading ...');

eval { $obj->write() } or $err = $@;
ok($err, 'Have not yet installed the source directory. write() is writing..' );



done_testing();
