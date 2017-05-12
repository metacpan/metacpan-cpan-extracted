
use strict;
use warnings;
use Test;
use App::MrShell;

plan tests => 3;

my $res = eval {
    my $shell = App::MrShell->new
        -> set_shell_command_option([$^X, "-e", '$"="."; open TOUCH, ">test_file.@ARGV"', '[%u]_u', '[]%u', '%h'])
        -> set_hosts('a@b')
        -> queue_command("c1")
        -> set_hosts('c')
        -> queue_command("c2")
        -> run_queue;
7};

ok( $res, 7 ) or warn $@;
ok( -f "test_file._u.a.b.c1" );
ok( -f "test_file.c.c2" );
