#!/usr/bin/perl -w
use strict;
use Test::More tests => 11;
use lib qw(t/lib);
use CLITest;

use_ok ('MyApp');

eval {
    local *ARGV = ['--help'];
    MyApp->dispatch;
};
ok ($@);

is_deeply ([MyApp->commands],
	   ['help', 'test']);

{
    local *ARGV = ['test'];
    MyApp->dispatch;
    is_deeply (clicheck, [qw(MyApp::Test MyApp::Test::run), ''], 'simple dispatch');
}

{
    local *ARGV = ['te', 'arg'];
    MyApp->dispatch;
    is_deeply (clicheck, [qw(MyApp::Test MyApp::Test::run), '', 'arg'], 'alias dispatch with arg');
}

{
    local *ARGV = ['test', '--verbose'];
    MyApp->dispatch;
    is_deeply (clicheck, [qw(MyApp::Test MyApp::Test::run), 'v'], 'with option');
}

{
    local *ARGV = ['test', 'arg', '--verbose'];
    MyApp->dispatch;
    is_deeply (clicheck, [qw(MyApp::Test MyApp::Test::run), 'v', 'arg'], 'with option and arg');
}

{
    # this kind of subcommand should be deprecated
    # because it makes people confused which is option and which is subcommand
    local *ARGV = ['test', '--hate', 'arg', '--verbose'];
    MyApp->dispatch;
    is_deeply (clicheck, [qw(MyApp::Test::hate MyApp::Test::hate::run), 'v', 'hate', 'arg'],
	       'subcommand with option and arg');
}

{
    local *ARGV = ["test", "cascading"];
    MyApp->dispatch;
    is_deeply (clicheck, [qw(MyApp::Test::Cascading MyApp::Test::Cascading::run)],
               'cascading subcommand');
}

{
    local *ARGV = [qw(test cascading infinite)];
    MyApp->dispatch;
    is_deeply (clicheck, [qw(MyApp::Test::Cascading::Infinite MyApp::Test::Cascading::Infinite::run)],
               'cascading more subcommands');
}

{
    local *ARGV = [qw(test cascading infinite subcommands --name shelling --help)];
    MyApp->dispatch;
    is_deeply(clicheck, [qw(MyApp::Test::Cascading::Infinite::Subcommands MyApp::Test::Cascading::Infinite::Subcommands::run), "shelling", "help"],
              'cascading with options');
}
