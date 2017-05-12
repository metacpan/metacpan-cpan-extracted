
use strict;
use warnings;
use Test;
use App::MrShell;

plan tests => 5;

my $res = eval {
    my $shell = App::MrShell->new
        -> set_shell_command_option([$^X, "-e", '$"="."; open TOUCH, ">test_file.@ARGV"', '%h', '%n'])
        -> set_hosts("a", "b")
        -> queue_command("c1")
        -> queue_command("c2")
        -> run_queue;
7};

ok( $res, 7 ) or warn $@;

ok( -f "test_file.a.1.c1" );
ok( -f "test_file.a.2.c2" );
ok( -f "test_file.b.1.c1" );
ok( -f "test_file.b.2.c2" );
