use File::Spec;
use Test::More qw/no_plan/;
use strict;

use CGI::Session;
my $dir = File::Spec->tmpdir();
my $id;
{
    my $ses = CGI::Session->new(undef,undef,{Directory=> $dir });
    $id = $ses->id();
    ok($id, "found session id");
}

my $file = "$dir/cgisess_".$id;
ok(-r $file, "found session data file");
unlink $file;


