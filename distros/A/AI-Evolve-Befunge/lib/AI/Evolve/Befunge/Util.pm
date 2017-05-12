package AI::Evolve::Befunge::Util;
use strict;
use warnings;

use Carp;
use IO::Socket;
use Language::Befunge::Vector;
use Perl6::Export::Attrs;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use YAML qw(LoadFile Load Dump);

use aliased 'AI::Evolve::Befunge::Util::Config' => 'Config';

$ENV{HOST} = global_config("hostname", `hostname`);
$ENV{HOST} = "unknown-host-$$-" . int rand 65536 unless defined $ENV{HOST};
chomp $ENV{HOST};

my @quiet   = 0;
my @verbose = 0;
my @debug   = 0;


=head1 NAME

    AI::Evolve::Befunge::Util - common utility functions


=head1 DESCRIPTION

This is a place for miscellaneous stuff that is used elsewhere
throughout the AI::Evolve::Befunge codespace.


=head1 FUNCTIONS

=head2 push_quiet

    push_quiet(1);

Add a new value to the "quiet" stack.

=cut

sub push_quiet :Export(:DEFAULT) {
    my $new = shift;
    push(@quiet, $new);
}


=head2 pop_quiet

    pop_quiet();

Remove the topmost entry from the "quiet" stack, if more than one
item exists on the stack.

=cut

sub pop_quiet :Export(:DEFAULT) {
    my $new = shift;
    pop(@quiet) if @quiet > 1;
}


=head2 get_quiet

    $quiet = get_quiet();

Returns the topmost entry on the "quiet" stack.

=cut

sub get_quiet :Export(:DEFAULT) {
    return $quiet[-1];
}


=head2 push_verbose

    push_verbose(1);

Add a new value to the "verbose" stack.

=cut

sub push_verbose :Export(:DEFAULT) {
    my $new = shift;
    push(@verbose, $new);
}


=head2 pop_verbose

    pop_verbose();

Remove the topmost entry from the "verbose" stack, if more than one
item exists on the stack.

=cut

sub pop_verbose :Export(:DEFAULT) {
    my $new = shift;
    pop(@verbose) if @verbose > 1;
}


=head2 get_verbose

    $quiet = get_verbose();

Returns the topmost entry on the "verbose" stack.

=cut

sub get_verbose :Export(:DEFAULT) {
    return $verbose[-1];
}


=head2 push_debug

    push_debug(1);

Add a new value to the "debug" stack.

=cut

sub push_debug :Export(:DEFAULT) {
    my $new = shift;
    push(@debug, $new);
}


=head2 pop_debug

    pop_debug();

Remove the topmost entry from the "debug" stack, if more than one
item exists on the stack.

=cut

sub pop_debug :Export(:DEFAULT) {
    my $new = shift;
    pop(@debug) if @debug > 1;
}


=head2 get_debug

    $quiet = get_debug();

Returns the topmost entry on the "debug" stack.

=cut

sub get_debug :Export(:DEFAULT) {
    return $debug[-1];
}


=head2 verbose

    verbose("Hi!  I'm in verbose mode!\n");

Output a message if get_verbose() is true.

=cut

sub verbose :Export(:DEFAULT) {
    print(@_) if $verbose[-1];
}


=head2 debug

    verbose("Hi!  I'm in debug mode!\n");

Output a message if get_debug() is true.

=cut

sub debug :Export(:DEFAULT) {
    print(@_) if $debug[-1];
}


=head2 quiet

    quiet("Hi!  I'm in quiet mode!\n");

Output a message if get_quiet() is true.  Note that this probably
isn't very useful.

=cut

sub quiet :Export(:DEFAULT) {
    print(@_) if $quiet[-1];
}


=head2 nonquiet

    verbose("Hi!  I'm not in quiet mode!\n");

Output a message if get_quiet() is false.

=cut

sub nonquiet :Export(:DEFAULT) {
    print(@_) unless $quiet[-1];
}


=head2 v

    my $vector = v(1,2);

Shorthand for creating a Language::Befunge::Vector object.

=cut

sub v :Export(:DEFAULT) {
    return Language::Befunge::Vector->new(@_);
}


=head2 code_print

    code_print($code, $x_size, $y_size);

Pretty-print a chunk of code to stdout.

=cut

sub code_print :Export(:DEFAULT) {
    my ($code, $sizex, $sizey) = @_;
    my $usage = 'Usage: code_print($code, $sizex, $sizey)';
    croak($usage) unless defined $code;
    croak($usage) unless defined $sizex;
    croak($usage) unless defined $sizey;
    my $charlen = 1;
    my $hex = 0;
    foreach my $char (split("",$code)) {
        if($char ne "\n") {
            if($char !~ /[[:print:]]/) {
                $hex = 1;
            }
            my $len = length(sprintf("%x",ord($char))) + 1;
            $charlen = $len if $charlen < $len;
        }
    }
    $code =~ s/\n//g unless $hex;
    $charlen = 1 unless $hex;
    my $space = " " x ($charlen);
    if($sizex > 9) {
        print("   ");
        for my $x (0..$sizex-1) {
            unless(!$x || ($x % 10)) {
                printf("%${charlen}i",$x / 10);
            } else {
                print($space);
            }
        }
        print("\n");
    }
    print("   ");
    for my $x (0..$sizex-1) {
        printf("%${charlen}i",$x % 10);
    }
    print("\n");
    foreach my $y (0..$sizey-1) {
        printf("%2i ", $y);
        if($hex) {
            foreach my $x (0..$sizex-1) {
                my $val;
                $val = substr($code,$y*$sizex+$x,1)
                    if length($code) >= $y*$sizex+$x;
                if(defined($val)) {
                    $val = ord($val);
                } else {
                    $val = 0;
                }
                $val = sprintf("%${charlen}x",$val);
                print($val);
            }
        } else {
            print(substr($code,$y*$sizex,$sizex));
        }
        printf("\n");
    }
}


=head2 setup_configs

    setup_configs();

Load the config files from disk, set up the various data structures
to allow fetching global and overrideable configs.  This is called
internally by L</global_config> and L</custom_config>, so you never
have to call it directly.

=cut

my $loaded_config_before = 0;
my @all_configs = {};
my $global_config;
sub setup_configs {
    return if $loaded_config_before;
    my %global_config;
    my @config_files = (
        "/etc/ai-evolve-befunge.conf",
        $ENV{HOME}."/.ai-evolve-befunge",
    );
    push(@config_files, $ENV{AIEVOLVEBEFUNGE}) if exists $ENV{AIEVOLVEBEFUNGE};
    foreach my $config_file (@config_files) {
        next unless -r $config_file;
        push(@all_configs, LoadFile($config_file));
    }
    foreach my $config (@all_configs) {
        my %skiplist = (byhost => 1, bygen => 1, byphysics => 1);
        foreach my $keyword (keys %$config) {
            next if exists $skiplist{$keyword};
            $global_config{$keyword} = $$config{$keyword};
        }
    }
    $global_config = Config->new({hash => \%global_config});
    $loaded_config_before = 1;
}


=head2 global_config

    my $value = global_config('name');
    my $value = global_config('name', 'default');
    my @list  = global_config('name', 'default');
    my @list  = global_config('name', ['default1', 'default2']);

Fetch some config from the config file.  This queries the global
config database - it will not take local overrides (for host,
generation, or physics plugin) into account.  For more specific
(and flexible) config, see L</custom_config>, below.

=cut

sub global_config :Export(:DEFAULT) {
    setup_configs();
    return $global_config->config(@_);
}


=head2 custom_config

    my $config = custom_config(host => $host, physics => $physics, gen => $gen);
    my $value = $config('name');
    my $value = $config('name', 'default');
    my @list  = $config('name', 'default');
    my @list  = $config('name', ['default1', 'default2']);

Generate a config object from the config file.  This queries the
global config database, but allows for overrides by various criteria -
it allows you to specify overridden values for particular generations
(if the current generation is greater than or equal to the ones in the
config file, with inheritance), for particular physics engines, and
for particular hostnames.

This is more specific than L</global_config> can be.  This is the
interface you should be using in almost all cases.

If you don't specify a particular attribute, overrides by that
attribute will not show up in the resulting config.  This is so you
can (for instance) specify a host-specific override for the physics
engine, and query that successfully before knowing which physics
engine you will be using.

Note that you can recurse these, but if you have two paths to the same
value, you should not rely on which one takes precedence.  In other
words, if you have a "byhost" clause within a "bygen" section, and you
also have a "bygen" clause within a "byhost" section, either one may
eventually be used.  When in doubt, simplify your config file.

=cut

sub custom_config :Export(:DEFAULT) {
    my %args = @_;
    setup_configs();
    # deep copy
    my @configs = Load(Dump(@all_configs));

    my $redo = 1;
    while($redo) {
        $redo = 0;
        foreach my $config (@configs) {
            if(exists($args{host})) {
                my $host = $args{host};
                if(exists($$config{byhost}) && exists($$config{byhost}{$host})) {
                    push(@configs, $$config{byhost}{$host});
                    $redo = 1;
                }
            }
            delete($$config{byhost});

            if(exists($args{physics})) {
                my $physics = $args{physics};
                if(exists($$config{byphysics}) && exists($$config{byphysics}{$physics})) {
                    push(@configs, $$config{byphysics}{$physics});
                    $redo = 1;
                }
            }
            delete($$config{byphysics});

            if(exists($args{gen})) {
                my $mygen = $args{gen};
                if(exists($$config{bygen})) {
                    # sorted, so that later gens override earlier ones.
                    foreach my $gen (sort {$a <=> $b} keys %{$$config{bygen}}) {
                        if($mygen >= $gen) {
                            push(@configs, $$config{bygen}{$gen});
                            $redo = 1;
                        }
                    }
                }
            }
            delete($$config{bygen});
        }
    }

    # tally up the values
    my %config = ();
    foreach my $config (@configs) {
        foreach my $keyword (keys %$config) {
            $config{$keyword} = $$config{$keyword};
        }
    }
    return Config->new({ %args, hash => \%config });
}

1;
