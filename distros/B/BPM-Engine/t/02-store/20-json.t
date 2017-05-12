use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use BPM::Engine;
use JSON;
use t::TestUtils;

my $engine     = BPM::Engine->new( schema => schema() );
my $package    = $engine->create_package('./t/var/01-basic.xpdl');
my $process    = $package->processes({ process_uid => 'wcp1' })->first    or die "Process not found";
my $activity   = $process->activities->first   or die "Activity not found";
my $transition = $activity->transitions->first or die "Transition not found";
my $pi = $process->new_instance;
my $ai = $activity->new_instance({ process_instance_id => $pi->id  });

my $json = JSON->new->utf8->allow_nonref->convert_blessed;

foreach my $entity($package, $process, $pi, $activity, $ai, $transition) {
    my $data = $entity->TO_JSON;
    my $json_text = $json->encode($data);
    my $roundtrip = $json->decode($json_text);
    is_deeply($data, $roundtrip);
    }

done_testing;

