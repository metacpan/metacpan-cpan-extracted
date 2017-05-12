use strict;
use Test::More 'no_plan';

#  This test is about checking {Directory=>/not_tmp} actually works;
#  Reference: http://rt.cpan.org/Public/Bug/Display.html?id=24285

use CGI::Session;
use CGI::Session::Driver;
use CGI::Session::Driver::file;

my $opt_dsn;
my $id;
my $file_name;

 my($dir_name) = File::Spec->catdir('t', 'sessiondata');

{
    $opt_dsn = {Directory=>$dir_name};

    ok(my $s = CGI::Session->new('driver:file;serializer:default', undef, $opt_dsn), 'Created CGI::Session object successfully');

    $id        = $s -> id();
    $file_name = File::Spec->catdir($dir_name, "cgisess_$id");
}

ok(-e $file_name, 'Created file outside /tmp successfully');
unlink $file_name;
