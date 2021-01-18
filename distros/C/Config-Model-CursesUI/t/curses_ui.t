# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model ;
use Config::Model::Tester::Setup qw/init_test/;
use Config::Model::CursesUI ;
use Curses::UI ;

use strict ;
use warnings;
use lib 't/lib';

my ($model, $trace, $args) = init_test('interactive');

note("You can run the GUI with 'i' argument. E.g. 'perl t/curses_ui.t i'");

my $inst = $model->instance (
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok($inst,"created dummy instance") ;

# re-direct errors
open (FH,">>stderr.log") || die $! ;
open STDERR, ">&FH";

warn "----\n";

$inst->config_root->load("hash_a:foo=bar") ;

if ($args->{interactive} ) {
    my $dialog = Config::Model::CursesUI-> new (
        permission => 'advanced',
        debug => 1,
    ) ;
    $dialog->start( $model )  ;
}

close FH ;

ok(1,"done") ;

done_testing;
