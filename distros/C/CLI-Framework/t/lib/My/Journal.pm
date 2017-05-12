package My::Journal;
use base qw( CLI::Framework );

use strict;
use warnings;

use lib 't/lib';

use My::Journal::Model;

#-------

sub usage_text {
    q{
    OPTIONS
        --db [path]  : path to SQLite database file for your journal
        -v --verbose : be verbose
        -h --help    : show help

    COMMANDS
        entry       - work with journal entries
        publish     - publish a journal
        tree        - print a tree of only those commands that are currently-registered in your application
        dump        - examine the internals of your application object using Data::Dumper 
        menu        - print command menu
        help        - show application or command-specific help
        console     - start a command console for the application
        list        - list all commands available to the application
    }
}

#-------

sub option_spec {
    [ 'help|h'      => 'show help' ],
    [ 'verbose|v'   => 'be verbose' ],
    [ 'db=s'        => 'path to SQLite database file for your journal' ],
}

sub command_map {
    entry   => 'My::Journal::Command::Entry',
    publish => 'My::Journal::Command::Publish',
    menu    => 'My::Journal::Command::Menu',
    help    => 'CLI::Framework::Command::Help',
    list    => 'CLI::Framework::Command::List',
    tree    => 'CLI::Framework::Command::Tree',
    alias   => 'CLI::Framework::Command::Alias',
    'dump'  => 'CLI::Framework::Command::Dump',
    console => 'CLI::Framework::Command::Console',
}

sub command_alias {
    h   => 'help',

    e   => 'entry',
    p   => 'publish',

    'list-commands'   => 'list',
    l   => 'list',
    ls  => 'list',
    t   => 'tree',
    d   => 'dump',
    a   => 'alias',

    sh  => 'console',
    c   => 'console',
    m   => 'menu',
}

#-------

sub init {
    my ($app, $opts) = @_;

    # Command redirection for --help or -h options...
    $app->set_current_command('help') if $opts->{help};

    # Store App's verbose setting where it will be accessible to commands...
    $app->cache->set( 'verbose' => $opts->{verbose} );

    # Get object to work with database...
    my $db = My::Journal::Model->new( dbpath => 't/db/myjournal.sqlite' );
    
    # ...store object in the application cache...
    $app->cache->set( 'db' => $db );
}

#-------
1;

__END__

=pod

=head1 NAME

My::Journal - Demo CLIF application used as a documentation example and for
testing.

=cut
