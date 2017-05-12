use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More tests => 1;
use File::Spec;

#~~~~~~
# Send STDOUT, STDERR to null device...
close STDOUT;
open ( STDOUT, '>', File::Spec->devnull() );
close STDERR;
open( STDERR, '>', File::Spec->devnull() );
#~~~~~~

ok( My::App->run() );

###################################
#
#   INLINE APPLICATION DEFINITION...
#
###################################

package My::App;
use base qw( CLI::Framework );

use strict;
use warnings;

#-------

sub usage_text {
    q{
    OPTIONS
        --db [path]  : db
        -v --verbose : be verbose
        -h --help    : show help

    COMMANDS
        x
    }
}

#-------

sub option_spec {
    [ 'help|h'      => 'show help' ],
    [ 'verbose|v'   => 'be verbose' ],
    [ 'db=s'        => 'db' ],
}

sub command_map {
    console => 'CLI::Framework::Command::Console',
    list    => 'CLI::Framework::Command::List',
    menu    => 'CLI::Framework::Command::Menu',
    'dump'  => 'CLI::Framework::Command::Dump',
    tree    => 'CLI::Framework::Command::Tree',
    x       => 'My::App::Command::X',
#    x       => 'My::Command::Shared::X',
}

sub command_alias {
    h   => 'help',

    t   => 'tree',
    d   => 'dump',

    sh  => 'console',
    c   => 'console',
    m   => 'menu',
}

#-------

sub init {
    my ($app, $opts) = @_;

    print __PACKAGE__.'::init()', "\n";
}

###################################
#
#   INLINE COMMAND DEFINITIONS...
#
###################################

package My::App::Command::X;
use base qw( CLI::Framework::Command );

use strict;
use warnings;

#-------

sub usage_text {
    q{
    x [--date=yyyy-mm-dd] [subcommands...]

    OPTIONS
       --date=yyyy-mm-dd:       date
   
    ARGUMENTS (subcommands)
        search:                    ...
    }
}

sub option_spec {
    return unless ref $_[0] eq __PACKAGE__; # non-inheritable behavior
    (
        [ 'date=s' => 'date that entry applies to' ],
    )
}

sub subcommand_alias {
    return unless ref $_[0] eq __PACKAGE__; # non-inheritable behavior
    (
        d   => 'do',
        a   => 'add',
        s   => 'search',
    )
}

sub validate {
    my ($self, $opts, @args) = @_;
    return unless ref $_[0] eq __PACKAGE__; # non-inheritable behavior

    # ...
}

sub notify_of_subcommand_dispatch {
    my ($self, $subcommand, $opts, @args ) = @_;
    return unless ref $_[0] eq __PACKAGE__; # non-inheritable behavior

warn __PACKAGE__.'::notify_of_subcommand_dispatch', "\n";
#require Data::Dumper; warn Data::Dumper::Dumper( [ $subcommand, $opts, \@args ] );

    # ...
}

#-------

package My::App::Command::X::Search;
use base qw( My::App::Command::X );

use strict;
use warnings;

sub usage_text {
    q{
    x search --regex=<regex> [--tag=<tag>]: search
    }
}

sub option_spec {
    (
        [ 'regex=s'  => 'regex' ],
        [ 'tag=s@'   => 'tag' ],
    )
}

sub validate {
    my ($self, $opts, @args) = @_;
    die "missing required option 'regex'\n" unless $opts->{regex};
}

sub run {
    my ($self, $opts, @args) = @_;

    my $regex = $opts->{regex};
    my $tags = $opts->{tag};

warn __PACKAGE__.'::run()', "\n";
    warn "searching...\n";# if $self->session('verbose');

    return '';
}

__END__
