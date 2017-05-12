package Canella::TaskRunner;
use Moo;
use Coro;
use Coro::Select;
use Canella::Log;
use Guard;

sub execute {
    my ($self, $ctx, %args) = @_;

    my $role = $args{role};
    my $tasks = $args{tasks};

    my $hosts = $role->get_hosts();
    my $concurrency = $ctx->concurrency > 0 ?
        $ctx->concurrency : scalar @$hosts;

    # Register per-role parameters, only if they are not set
    my %has_key = map { ($_ => 1) } $ctx->parameters->keys;
    my %tmp_key;
    foreach my $param_key ($role->parameters->keys) {
        if ($has_key{$param_key}) {
            next;
        }
        debugf("Applying role default parameter %s", $param_key);
        $tmp_key{$param_key} = $ctx->parameters->get($param_key);
        $ctx->parameters->set($param_key, $role->parameters->get($param_key));
    }
    my $block_ctx = guard {
        my $params = $ctx->parameters;
        foreach my $param_key (keys %tmp_key) {
            debugf("Restoring paramter value for %s", $param_key);
            $params->set($param_key, $tmp_key{$param_key});
        }
    };

    my @coros;
    foreach my $host (@$hosts) {
        push @coros, async {
            my ($ctx, $host, $tasks) = @_;
            $ctx->stash(current_host => $host);
            foreach my $task (@$tasks) {
                $ctx->call_task($task);
            }
        } $ctx, $host, $tasks;

        if (@coros >= $concurrency) {
            $_->join for @coros;
            @coros = ();
        }
    }

    $_->join for @coros;
    infof "All done!";
}

1;
