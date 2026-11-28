use v5.40;
use blib;
use Acme::Parataxis;
#
say 'Main thread (TID: ' . Acme::Parataxis->tid . ')';

# Create a worker parataxis
my $worker = Acme::Parataxis->new(
    code => sub ($name) {
        say "---> Worker '$name' started (FID: " . Acme::Parataxis->current_fid . ")";
        for my $i ( 1 .. 3 ) {
            say "---> Worker '$name' processing step $i";
            my $input = Acme::Parataxis->yield( 'Result from step ' . $i );
            say "---> Worker '$name' received: $input";
        }
        return 'Final success';
    }
);

# Drive the worker
say 'Main: Starting worker...';
my $res = $worker->call('Alice');
say 'Main: Worker yielded: ' . $res;
say 'Main: Sending more data...';
$res = $worker->call('Command A');
say 'Main: Worker yielded: ' . $res;
say 'Main: Finishing up...';
$res = $worker->call('Final Command');
say 'Main: Worker yielded: ' . $res;
$res = $worker->call('Done');
say 'Main: Worker returned: ' . $res;
say 'Main: Worker is officially finished.' if $worker->is_done;
