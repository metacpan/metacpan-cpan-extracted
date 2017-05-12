package Canella::CLI;
use Moo;
use Canella::Context;
use Canella::Log;
use Getopt::Long ();
use Guard;

sub parse_argv {
    my ($self, $ctx, @argv) = @_;

    local @ARGV = @argv;
    my $p = Getopt::Long::Parser->new;
    $p->configure(qw(
        posix_default
        no_ignore_case
        auto_help
    ));
    my @optspec = qw(
        config|c=s
        set|s=s%
        concurrency|C=i
        mode=s
    );
    my $opts = {};
    if (! $p->getoptions($opts, @optspec)) {
        croakf("Failed to parse command line");
    }

    my $set_vars = delete $opts->{set} || {};
    foreach my $var_name (keys %$set_vars) {
        $ctx->override_parameters->set($var_name, $set_vars->{$var_name});
    }

    foreach my $key (keys %$opts) {
        $ctx->$key($opts->{$key});
    }

    return @ARGV; # remaining
}

sub run {
    my ($self, @argv) = @_;

    my $ctx = Canella::Context->new;
    local $Canella::Context::CTX = $ctx;
    my @remaining = $self->parse_argv($ctx, @argv);

    foreach my $key ($ctx->override_parameters->keys) {
        my $override = $ctx->override_parameters->get($key);
        # Don't use set_param
        $ctx->parameters->set($key, $override);
    }
    $ctx->load_config();

    if ($ctx->mode eq 'dump') {
        $ctx->dump_config();
        return;
    }
    if ($ctx->mode eq 'help') {
        $ctx->show_help();
        return;
    }

    if (@remaining < 2) {
        croakf("need a role and a task");
    }
    my $role_name = shift @remaining;
    my $role = $ctx->get_role($role_name);
    if (! $role) {
        croakf("Unknown role %s", $role_name);
    }
    my @tasks;
    foreach my $task_name (@remaining) {
        my $task = $ctx->get_task($task_name);
        if (! $task) {
            croakf("Unknown task %s", $task_name);
        }
        push @tasks, $task;
    }
    $ctx->set_param(role => $role_name);

    my $runner = $ctx->runner;
    $runner->execute($ctx, role => $role, tasks => \@tasks);
}

1;

__END__

=head1 NAME

Canella::CLI - CLI Component For Canella

=cut
