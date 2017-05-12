use encoding 'utf8';
use strict;

use File::Spec;
use Test::More ('no_plan');

BEGIN {
    use_ok('CGI::Session');
    use_ok("CGI::Session::Driver");
    use_ok("CGI::Session::Driver::file");
}

my $id;
my $s;

{
    ok($s = CGI::Session->new('driver:file;serializer:default', undef), 'Created CGI::Session object successfully');

    $id = $s -> id();
}

diag("Warnings expected. Consult docs re 'utf8'");
ok($id, 'Session created successfully');

# Emulate CGI::Session::Driver::file.pm.

my $dir_name  = File::Spec->tmpdir();
my $file_name = File::Spec->catfile($dir_name, "cgisess_$id");

$s = undef;

{
    $s = CGI::Session->new('driver:file;serializer:default', $id);
}

if ($@) {
    print STDERR $@;
    ok(1, q|Warning: Failed to recreate session. Cannot "use 'utf8'; in conjunction with CGI::Session"|);
} else {
    ok($s, 'Recreated session succeeded');
}

# Clean up /tmp as per RT 29969.

unlink $file_name;
