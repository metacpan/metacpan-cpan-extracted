
use ExtUtils::testlib;
use Test::More ;
use Config::Model 2.138;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

use Config::Model::Itself ;
use Test::Memory::Cycle;
use Test::Exception;

use warnings;
use strict;

my ($meta_model, $trace) = init_test();

my $wr_root = setup_test_dir;

my $meta_inst = $meta_model-> instance (
    root_class_name   => 'Itself::Model',
    instance_name     => 'itself_instance',
    root_dir          => "data",
);
ok($meta_inst,"Read Itself::Model and created instance") ;

my $meta_root = $meta_inst -> config_root ;

$meta_root->load('class:Test');
ok(1,"Created dummy Test class");

throws_ok {
    $meta_root->load('class:Test class="Foo::Bar"');
}
    qr!Can't locate Foo/Bar.pm in \@INC!,
    "test explicit error message when attaching Config class to unknown Perl class";
print "normal error:\n", $@, "\n" if $trace;

note("testing memory cycles. Please wait...");
memory_cycle_ok($meta_model, "Check memory cycle");

done_testing;
