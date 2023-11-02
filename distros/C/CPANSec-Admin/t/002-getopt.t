use v5.38;
use Test2::V0;

plan 2;

use CPANSEC::Admin::Command;

subtest 'command without arguments' => \&test_command_without_args;
subtest 'command with arguments'    => \&test_command_with_args;

sub test_command_without_args {
    my $cmd = CPANSEC::Admin::Command->new();
    my @args;
    my %out = $cmd->get_options(\@args, {
        'triage-dir=s'    =>  './triage',
        'index-file=s'    => '{triage_dir}/last_visited_index',
    });
    is \%out, { triage_dir => './triage', index_file => './triage/last_visited_index' };
}

sub test_command_with_args {
    my $cmd = CPANSEC::Admin::Command->new(
        config => {foo => 'bar', bar => 'baz'}
    );

    my @args = qw( --foo=new --meep-moop-mop=lala cmd1 cmd2 --three );
    my %out = $cmd->get_options(\@args, {
        'foo=s'           => 123,
        'meep-moop-mop=s' => undef,
        'three'           => undef,
        'four'            => 321,
    });

    is \%out, {
        foo           => 'new',  # args override global config AND default
        meep_moop_mop => 'lala', # lowercased and triggered by args
        three         => 1,      # toggled by args
        four          => 321,    # our default
        bar           => 'baz',  # passed through from global config
    }, 'options parsed correctly';

    is \@args, [qw(cmd1 cmd2)], 'args keep extra params';
}