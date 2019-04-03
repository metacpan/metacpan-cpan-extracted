use Test::More tests => 2;

BEGIN {
    use_ok('App::Task');
}

diag("Testing App::Task $App::Task::VERSION");

ok( defined &task, "export task()" );
