use strict;
use warnings;
use Test::More;
use t::TestUtils;
#use Data::Dumper;

{
package WAss;
use Moose;
use Test::More;
has 'process' => ( is => 'ro' );
has 'process_instance' => ( is => 'ro' );
with 'BPM::Engine::Role::HandlesIO';
#use Data::Dumper;

sub _execute_implementation {
    my ($self, $activity, $instance) = @_;
    ok($instance->inputset);
    #warn Dumper $instance->inputset;
    }

}


package main;

my $schema = schema();
my $package = $schema->resultset('Package')->create_from_xpdl('./t/var/09-data.xpdl');

my $process = $package->processes->first; # $schema->resultset('Process')->search->first;
my $pi = $process->new_instance();

ok(my $wa = WAss->new(process => $process, process_instance => $pi));
ok($wa->process->id);
ok($wa->process_instance->id);

my $activity = $process->start_activity;
my $instance = $activity->new_instance({ process_instance_id => $pi->id });

ok(!$instance->inputset);
$wa->_execute_implementation($activity, $instance);

#warn Dumper $instance->attribute_hash;

done_testing();
