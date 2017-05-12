package App::RepoSync::Script;
use warnings;
use strict;
use App::RepoSync::Command::Export;
use App::RepoSync::Command::Import;
use base qw( CLI::Framework );

sub option_spec {
    [ 'help|h'      => 'show help' ],
    # [ 'verbose|v'   => 'be verbose' ],
    # [ 'db=s'        => 'path to SQLite database file' ],
}

sub usage_text { qq{
    $0 [--verbose|v]

    OPTIONS
        -h --help    : show help

    COMMANDS
        help        - show application or command-specific help
        console     - start a command console for the application
        export      - scan and export repositories
        import      - import repositories to current directory
} }

sub command_map {
    export  => 'App::RepoSync::Command::Export',
    import  => 'App::RepoSync::Command::Import',
    sync    => 'App::RepoSync::Command::Sync',
    help    => 'CLI::Framework::Command::Help',
    list    => 'CLI::Framework::Command::List',
    console => 'CLI::Framework::Command::Console',
}

sub init {
    my ($self, $opts,$command) = @_;
    return 1;
}

1;
