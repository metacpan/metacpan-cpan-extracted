package App::Rad;
use 5.006;
use App::Rad::Help;
use Carp                ();
use warnings;
use strict;

our $VERSION = '1.05';
{

#========================#
#   INTERNAL FUNCTIONS   #
#========================#

my @OPTIONS = ();

sub _init {
    my $c = shift;

    # instantiate references for the first time
    $c->{'_ARGV'    } = [];
    $c->{'_options'} = {};
    $c->{'_stash'  } = {};
    $c->{'_config' } = {};
    $c->{'_plugins'} = [];

    # this internal variable holds
    # references to all special
    # pre-defined control functions
    $c->{'_functions'} = {
        'setup'        => \&setup,
        'pre_process'  => \&pre_process,
        'post_process' => \&post_process,
        'default'      => \&default,
        'invalid'      => \&invalid,
        'teardown'     => \&teardown,
    };
    
    #load extensions
    App::Rad::Help->load($c);
    foreach (@OPTIONS) {
        if ($_ eq 'include') {
            eval 'use App::Rad::Include; App::Rad::Include->load($c)';
            Carp::croak 'error loading "include" extension.' if ($@);
        }
        elsif ($_ eq 'exclude') {
            eval 'use App::Rad::Exclude; App::Rad::Exclude->load($c)';
            Carp::croak 'error loading "exclude" extension.' if ($@);
        }
        elsif ($_ eq 'debug') {
            $c->{'debug'} = 1;
        }
        else {
        	$c->load_plugin($_);
        }
	}
	
    # tiny cheat to avoid doing a lot of processing
    # when not in debug mode. If needed, I'll create
    # an actual is_debugging() method or something
    if ($c->{'debug'}) {
        $c->debug('initializing: default commands are: '
            . join ( ', ', $c->commands() )
        );
    }
}

sub import {
    my $class = shift;
    @OPTIONS  = @_;
}

sub load_plugin {
    my $c      = shift;
    my $plugin = shift;
	my $class  = ref $c;

    my $plugin_fullname = '';    
	if ($plugin =~ s{^\+}{} ) {
		$plugin_fullname = $plugin;
	}
    else {
        $plugin_fullname = "App::Rad::Plugin::$plugin";
    }
	eval "use $plugin_fullname ()";
    Carp::croak "error loading plugin '$plugin_fullname': $@\n"
        if $@;
    my %methods = _get_subs_from($plugin_fullname);

    Carp::croak "No methods found for plugin '$plugin_fullname'\n"
		unless keys %methods > 0;

	no strict 'refs';
	foreach my $method (keys %methods) {
        # don't add plugin's internal methods
        next if substr ($method, 0, 1) eq '_';

		*{"$class\::$method"} = $methods{$method};
		$c->debug("-- method '$method' added [$plugin_fullname]");

        # fill $c->plugins()
        push @{ $c->{'_plugins'} }, $plugin;
	}
}

# this function browses a file's
# symbol table (usually 'main') and maps
# each function to a hash
#
# FIXME: if I create a sub here (Rad.pm) and
# there is a global variable with that same name
# inside the user's program (e.g.: sub ARGV {}),
# the name will appear here as a command. It really 
# shouldn't...
sub _get_subs_from {
    my $package = shift || 'main';
    $package .= '::';
    
    my %subs = ();

    no strict 'refs';
    while (my ($key, $value) = ( each %{*{$package}} )) {
        local (*SYMBOL) = $value;
        if ( defined $value && defined *SYMBOL{CODE} ) {
            $subs{$key} = $value;
        }
    }
    return %subs;
}


# overrides our pre-defined control
# functions with any available
# user-defined ones
sub _register_functions {
    my $c = shift;
    my %subs = _get_subs_from('main');

    # replaces only if the function is
    # in 'default', 'pre_process' or 'post_process'
    foreach ( keys %{$c->{'_functions'}} ) {
        if ( defined $subs{$_} ) {
            $c->debug("overriding $_ with user-defined function.");
            $c->{'_functions'}->{$_} = $subs{$_};
        }
    }
}

# retrieves command line arguments
# to be executed by the main program
sub _get_input {
    my $c = shift;

    my $cmd = (defined ($ARGV[0]) and substr($ARGV[0], 0, 1) ne '-')
            ? shift @ARGV
            : ''
            ;

    @{$c->argv} = @ARGV;
    $c->{'cmd'} = $cmd;

    $c->debug('received command: ' . $c->{'cmd'});
    $c->debug('received parameters: ' . join (' ', @{$c->argv} ));

    $c->_tinygetopt();
}

# stores arguments passed to a
# command via --param[=value] or -p
sub _tinygetopt {
    my $c = shift;

    my @argv = ();
    foreach ( @{$c->argv} ) {

        # single option (could be grouped)
        if ( m/^\-([^\-\=]+)$/o) {
            my @args = split //, $1;
            foreach (@args) {
				if ($c->options->{$_}) {
					$c->options->{$_}++;
				}
				else {
					$c->options->{$_} = 1;
				}
            }
        }
        # long option: --name or --name=value
        elsif (m/^\-\-([^\-\=]+)(?:\=(.+))?$/o) {
            $c->options->{$1} = defined $2 ? $2 
			                  : 1
                              ;
        }
        else {
            push @argv, $_;
        }
    }
    @{$c->argv} = @argv;
}


#========================#
#     PUBLIC METHODS     #
#========================#

sub load_config {
    require App::Rad::Config;
    App::Rad::Config::load_config(@_);
}


#TODO: this code probably could use some optimization
sub register_commands {
    my $c = shift;
    my %help_for_sub = ();
    my %rules = ();

    # process parameters
    foreach my $item (@_) {
        if ( ref ($item) ) {
            Carp::croak '"register_commands" may receive only HASH references'
                unless ref ($item) eq 'HASH';
            foreach my $params (keys %{$item}) {
                if ($params eq '-ignore_prefix'
                 or $params eq '-ignore_suffix'
                 or $params eq '-ignore_regexp'
                ) {
                    $rules{$params} = $item->{$params};
                }
                else {
                    $help_for_sub{$params} = $item->{$params};
                }
            }
        }
        else {
            $help_for_sub{$item} = undef; # no help text
        }
    }

    my %subs = _get_subs_from('main');

    foreach (keys %help_for_sub) {

        # we only add the sub to the commands
        # list if it's *not* a control function
        if ( not defined $c->{'_functions'}->{$_} ) {

            # user want to register a valid (existant) sub
            if ( exists $subs{$_} ) {
                $c->debug("registering $_ as a command.");
                $c->{'_commands'}->{$_}->{'code'} = $subs{$_};
                App::Rad::Help->register_help($c, $_, $help_for_sub{$_});
            }
            else {
                Carp::croak "'$_' does not appear to be a valid sub. Registering seems impossible.\n";
            }
        }
    }

    # no parameters, or params+rules: try to register everything
    if ((!%help_for_sub) or %rules) {
        foreach my $subname (keys %subs) {

            # we only add the sub to the commands
            # list if it's *not* a control function
            if ( not defined $c->{'_functions'}->{$subname} ) {

                if ( $rules{'-ignore_prefix'} ) {  
                    next if ( substr ($subname, 0, length($rules{'-ignore_prefix'}))
                           eq $rules{'-ignore_prefix'}
                            );
                }
                if ( $rules{'-ignore_suffix'} ) {
                    next if ( substr ($subname, 
                                      length($subname) - length($rules{'-ignore_suffix'}),
                                      length($rules{'-ignore_suffix'})
                                     )
                              eq $rules{'-ignore_suffix'}
                            );
                }
                if ( $rules{'-ignore_regexp'} ) {
                    my $re = $rules{'-ignore_regexp'};
                    next if $subname =~ m/$re/o;
                }

                # avoid duplicate registration
                if ( !exists $help_for_sub{$subname} ) {
                    $c->{'_commands'}->{$subname}->{'code'} = $subs{$subname};
                    App::Rad::Help->register_help($c, $subname, undef);
                }
            }
        }
    }
}


sub register_command { return register(@_) }
sub register {
    my ($c, $command_name, $coderef, $helptext) = @_;
    $c->debug("got: " . ref $coderef);
    return undef
        unless ( (ref $coderef) eq 'CODE' );

    $c->debug("registering $command_name as a command.");
    $c->{'_commands'}->{$command_name}->{'code'} = $coderef;
    App::Rad::Help->register_help($c, $command_name, $helptext);
    return $command_name;
}

sub unregister_command { return unregister(@_) }
sub unregister {
    my ($c, $command_name) = @_;

    if ( $c->{'_commands'}->{$command_name} ) {
        delete $c->{'_commands'}->{$command_name};
    }
    else {
        return undef;
    }
}


sub create_command_name {
    my $id = 0;
    foreach (commands()) {
        if ( m/^cmd(\d+)$/ ) {
            $id = $1 if ($1 > $id);
        }
    }
    return 'cmd' . ($id + 1);
}


sub commands {
    return ( keys %{$_[0]->{'_commands'}} );
}


sub is_command {
    my ($c, $cmd) = @_;
    return (defined $c->{'_commands'}->{$cmd}
            ? 1
            : 0
           );
}

sub command :lvalue { cmd(@_) }
sub cmd :lvalue {
    $_[0]->{'cmd'};
}


sub run {
    my $class = shift;
    my $c = {};
    bless $c, $class;

    $c->_init();

    # first we update the control functions
    # with any overriden value
    $c->_register_functions();

    # then we run the setup to register
    # some commands
    $c->{'_functions'}->{'setup'}->($c);

    # now we get the actual input from
    # the command line (someone using the app!)
    $c->_get_input();

    # run the specified command
    $c->execute();

    # that's it. Tear down everything and go home :)
    $c->{'_functions'}->{'teardown'}->($c);

    return 0;
}

# run operations 
# in a shell-like environment
#sub shell {
#    my $class = shift;
#    App::Rad::Shell::shell($class);
#}

sub execute {
    my ($c, $cmd) = @_;

    # given command has precedence
    if ($cmd) {
        $c->{'cmd'} = $cmd;
    }
    else {
        $cmd = $c->{'cmd'};  # now $cmd always has the called cmd
    }

    $c->debug('calling pre_process function...');
    $c->{'_functions'}->{'pre_process'}->($c);

    $c->debug("executing '$cmd'...");

    # valid command, run it
    if ($c->is_command($c->{'cmd'}) ) {
        $c->{'output'} = $c->{'_commands'}->{$cmd}->{'code'}->($c);
    }
    # no command, run default()
    elsif ( $cmd eq '' ) {
        $c->debug('no command detected. Falling to default');
        $c->{'output'} = $c->{'_functions'}->{'default'}->($c);
    }
    # invalid command, run invalid()
    else {
        $c->debug("'$cmd' is not a valid command. Falling to invalid.");
        $c->{'output'} = $c->{'_functions'}->{'invalid'}->($c);
    }

    # 3: post-process the result
    # from the command
    $c->debug('calling post_process function...');
    $c->{'_functions'}->{'post_process'}->($c);

    $c->debug('reseting output');
    $c->{'output'} = undef;
}

sub argv    { return $_[0]->{'_ARGV'}     }
sub options { return $_[0]->{'_options'} }
sub stash   { return $_[0]->{'_stash'}   }   
sub config  { return $_[0]->{'_config'}  }

# $c->plugins is sort of "read-only" externally
sub plugins { 
    my @plugins = @{$_[0]->{'_plugins'}};
    return @plugins;
}


sub getopt {
    require Getopt::Long;
    Carp::croak "Getopt::Long needs to be version 2.36 or above"
        unless $Getopt::Long::VERSION >= 2.36;

    my ($c, @options) = @_;

    # reset values from tinygetopt
    $c->{'_options'} = {};

    my $parser = new Getopt::Long::Parser;
    $parser->configure( qw(bundling) );

    my @tARGV = @ARGV; # we gotta stick to our API
    my $ret = $parser->getoptions($c->{'_options'}, @options);
    @{$c->argv} = @ARGV;
    @ARGV = @tARGV;

    return $ret;
}

sub debug {
    if (shift->{'debug'}) {
        print "[debug]   @_\n";
    }
}

# gets/sets the output (returned value)
# of a command, to be post processed
sub output {
    my ($c, @msg) = @_;
    if (@msg) {
        $c->{'output'} = join(' ', @msg);
    }
    else {
        return $c->{'output'};
    }
}


#=========================#
#     CONTROL FUNCTIONS   #
#=========================#

sub setup { $_[0]->register_commands( {-ignore_prefix => '_'} ) }

sub teardown {}

sub pre_process {}

sub post_process {
    my $c = shift;

    if ($c->output()) {
        print $c->output() . $/;
    }
}


sub default {
    my $c = shift;
    return $c->{'_commands'}->{'help'}->{'code'}->($c);
}


sub invalid {
    my $c = shift;
    return $c->{'_functions'}->{'default'}->($c);
}


}
42; # ...and thus ends thy module  ;)
__END__

=head1 NAME

App::Rad - Rapid (and easy!) creation of command line applications

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

This is your smallest working application (let's call it I<myapp.pl>)

    use App::Rad;
    App::Rad->run();

That's it, your program already works and you can use it directly via the command line (try it!)

    [user@host]$ ./myapp.pl
    Usage: myapp.pl command [arguments]
    
    Available Commands:
        help    show syntax and available commands

Next, start creating your own functions (e.g.) inside I<myapp.pl>:

    sub hello {
        return "Hello, World!";
    }

And now your simple command line program I<myapp.pl> has a 'hello' command!

    [user@host]$ ./myapp.pl
    Usage: myapp.pl command [arguments]
    
    Available Commands:
        hello
        help    show syntax and available commands


   [user@host]$ ./myapp.pl hello
   Hello, World!

You could easily add a customized help message for your command through the 'Help()' attribute:

    sub hello 
    :Help(give a nice compliment)
    {
        return "Hello, World!";
    }

And then, as expected:

    [user@host]$ ./myapp.pl
    Usage: myapp.pl command [arguments]
    
    Available Commands:
        hello   give a nice compliment
        help    show syntax and available commands


App::Rad also lets you expand your applications, providing a lot of flexibility for every command, with embedded help, argument and options parsing, configuration file, default behavior, and much more:

    use App::Rad;
    App::Rad->run();

    sub setup {
        my $c = shift;

        $c->register_commands( {
                foo => 'expand your foo!',
                bar => 'have a drink! arguments: --drink=DRINK',
            });
    }

    sub foo {
        my $c = shift;
        $c->load_config('myapp.conf');

        return 'foo expanded to ' . baz() * $c->config->{'myfoo'};
    }

    # note that 'baz' was not registered as a command,
    # so it can't be called from the outside.
    sub baz { rand(10) }

    sub bar {
        my $c = shift;
        if ( $c->options->{'drink'} ) {
            return 'you asked for a ' . $c->options->{'drink'};
        }
        else {
            return 'you need to ask for a drink';
        }
    }

        

You can try on the command line:

   [user@host]$ ./myapp.pl
    Usage: myapp.pl command [arguments]
    
    Available Commands:
        bar 	have a drink! arguments: --drink=DRINK
        foo 	expand your foo!
        help	show syntax and available commands


   [user@host]$ ./myapp.pl bar --drink=martini
    you asked for a martini


=head1 WARNING

This module is very young, likely to change in strange ways and to have some bugs (please report if you find any!). I will try to keep the API stable, but even that is subject to change (let me know if you find anything annoying or have a wishlist). You have been warned!


=head1 DESCRIPTION

App::Rad aims to be a simple yet powerful framework for developing your command-line applications. It can easily transform your Perl I<one-liners> into reusable subroutines than can be called directly by the user of your program.

It also tries to provide a handy interface for your common command-line tasks. B<If you have a feature request to easen out your tasks even more, please drop me an email or a RT feature request.>

=head2 Extending App::Rad - Plugins!

App::Rad plugins can be loaded by naming them as arguments to the C<< use App::Rad >> statement. Just ommit the C<< App::Rad::Plugin >> prefix from the plugin name. For example:

   use App::Rad  qw(My::Module);

will load the C<< App::Rad::Plugin::My::Module >> plugin for you!

Developers are B<strongly> encouraged to publish their App::Rad plugins under the C<< App::Rad::Plugin >> namespace. But, if your plugin start with a name other than that, you can fully qualify the name by using an unary plus sign:

  use App::Rad  qw(
          My::Module
          +Fully::Qualified::Plugin::Name
  );

Note that plugins are loaded in the order in which they appear.

B<Please refer to the actual plugin documentation for specific usage>. And check out L<< App::Rad::Plugin >> if you want to create your own plugins.


=head1 INSTANTIATION

These are the main execution calls for the application. In your App::Rad programs, the B<*ONLY*> thing your script needs to actually (and actively) call is one of the instantiation (or dispatcher) methods. Leave all the rest to your subs. Currently, the only available dispatcher is run():

=head2 run()

You'll be able to access all of your program's commands directly through the command line, as shown in the synopsis.


=head1 BUILT-IN COMMANDS

This module comes with the following default commands. You are free to override them as you see fit.


=head2 help

Shows help information for your program. This built-in function displays the program name and all available commands (including the ones you added yourself) if a user types the 'help' command, or no command at all, or any command that does not exist (as they'd fall into the 'default' control function which (by default) calls 'help').

You can also display specific embedded help for your commands, either explicitly registering them with C<< $c->register() >> or C<< $c->register_commands() >> inside C<< $c->setup() >> (see respective sections below) or with the Help() attribute:

    use App::Rad;
    App::Rad->run();
    
    sub mycmd 
    :Help(display a nice welcome message) 
    {
        return "Welcome!";
    }

the associated help text would go like this:

    [user@host]$ ./myapp.pl
    Usage: myapp.pl command [arguments]

    Available Commands:
        help 	show syntax and available commands
        mycmd	display a nice welcome message
    

=head1 OTHER BUILT IN COMMANDS (OPT-IN)

The 'include' and 'exclude' commands below let the user include and exclude commands to your program and, as this might be dangerous when the user is not yourself, you have to opt-in on them:

   use App::Rad qw(include);  # add the 'include' command
   use App::Rad qw(exclude);  # add the 'exclude' command

though you'll probably want to set them both:

   use App::Rad qw(include exclude);


=head2 include I<[command_name]> I<-perl_params> I<'your subroutine code'>

Includes the given subroutine into your program on-the-fly, just as you would writing it directly into your program.

Let's say you have your simple I<'myapp.pl'> program that uses App::Rad sitting on your system quietly. One day, perhaps during your sysadmin's tasks, you create a really amazing one-liner to solve a really hairy problem, and want to keep it for posterity (reusability is always a good thing!). 

For instance, to change a CSV file in place, adding a column on position #2 containing the line number, you might do something like this (this is merely illustrative, it's not actually the best way to do it):

    $ perl -i -paF, -le 'splice @F,1,0,$.; $_=join ",",@F' somesheet.csv

And you just found out that you might use this other times. What do you do? App::Rad to the rescue!

In the one-liner above, just switch I<'perl'> to I<'myapp.pl include SUBNAME'> and remove the trailing parameters (I<somesheet.csv>):

    $ myapp.pl include addcsvcol -i -paF, -le 'splice @F,1,0,$.; $_=join ",",@F'

That's it! Now myapp.pl has the 'addcsvcol' command (granted, not the best name) and you can call it directly whenever you want:

    $ myapp.pl addcsvcol somesheet.csv

App::Rad not only transforms and adjusts your one-liner so it can be used inside your program, but also automatically formats it with Perl::Tidy (if you have it). This is what the one-liner above would look like inside your program:

    sub addcsvcol {
        my $c = shift;
    
        local ($^I) = "";
        local ($/)  = "\n";
        local ($\)  = "\n";
      LINE: while ( defined( $_ = <ARGV> ) ) {
            chomp $_;
            our (@F) = split( /,/, $_, 0 );
            splice @F, 1, 0, $.;
            $_ = join( ',', @F );
        }
        continue {
            die "-p destination: $!\n" unless print $_;
        }
    }

With so many arguments (-i, -p, -a -F,, -l -e), this is about as bad as it gets. And still one might find this way easier to document and mantain than a crude one-liner stored in your ~/.bash_history or similar.

B<Note:> If you don't supply a name for your command, App::Rad will make one up for you (cmd1, cmd2, ...). But don't do that, as you'll have a hard time figuring out what that specific command does.

B<Another Note: App::Rad tries to adjust the command to its interface, but please keep in mind this module is still in its early stages so it's not guaranteed to work every time. *PLEASE* let me know via email or RT bug request if your one-liner was not correctly translated into an App::Rad command. Thanks!>


=head2 exclude I<command_name>

Removes the requested function from your program. Note that this will delete the actual code from your program, so be *extra* careful. It is strongly recommended that you do not use this command and either remove the subroutine yourself or add the function to your excluded list inside I<setup()>.

Note that built-in commands such as 'help' cannot be removed via I<exclude>. They have to be added to your excluded list inside I<setup()>.



=head1 ROLLING YOUR OWN COMMANDS

Creating a new command is as easy as writing any sub inside your program. Some names ("setup", "default", "invalid", "pre_process", "post_process" and "teardown") are reserved for special purposes (see the I<Control Functions> section of this document). App::Rad provides a nice interface for reading command line input and writing formatted output:


=head2 The Controller

Every command (sub) you create receives the controller object "C<< $c >>" (sometimes referred as "C<< $self >>" in other projects) as an argument. The controller is the main interface to App::Rad and has several methods to easen your command manipulation and execution tasks.


=head2 Reading arguments

When someone types in a command, she may pass some arguments to it. Those arguments can be accessed in four different ways, depending on what you want. This way it's up to you to control which and how many arguments (if at all) you want to receive and/or use. They are:

=head3 @ARGV

Perl's @ARGV array has all the arguments passed to your command, without the command name (use C<< $c->cmd >> for this) and without any processing (even if you explicitly use C<< $c->getopt >>, which will change $c->argv instead, see below). Since the command itself won't be in the @ARGV parameters, you can use it in each command as if they were stand-alone programs.

=head3 $c->options

App::Rad lets you automatically retrieve any POSIX syntax command line options (I<getopt-style>) passed to your command via the $c->options method. This method returns a hash reference with keys as given parameters and values as... well... values. The 'options' method automatically supports two simple argument structures:

Extended (long) option. Translates C<< --parameter or --parameter=value >> into C<< $c->options->{parameter} >>. If no value is supplied, it will be set to 1.

Single-letter option. Translates C<< -p >> into C<< $c->options->{p} >>.

Single-letter options can be nested together, so C<-abc> will be parsed into C<< $c->options->{a} >>, C<< $c->options->{b} >> and C<< $c->options{c} >>, while C<--abc> will be parsed into C<< $c->options->{abc} >>. We could, for instance, create a dice-rolling command like this:

    sub roll {
        my $c = shift;

        my $value = 0;
        for ( 1..$c->options->{'times'} ) {
            $value += ( int(rand ($c->options->{'faces'}) + 1));
        }
        return $value;
    }

And now you can call your 'roll' command like:

    [user@host]$ ./myapp.pl roll --faces=6 --times=2

Note that App::Rad does not control which arguments can or cannot be passed: they are all parsed into C<< $c->options >> and it's up to you to use whichever you want. For a more advanced use and control, see the C<< $c->getopt >> method below.

Also note that single-letter options will be set to 1. However, if a user types them more than once, the value will be incremented accordingly. For example, if a user calls your program like so:

   [user@host]$ ./myapp.pl some_command -vvv

or

   [user@host]$ ./myapp.pl some_command -v -v -v

then, in both cases, C<< $c->options->{v} >> will be set to 3. This will let you easily keep track of how many times any given option was chosen, and still let you just check for definedness if you don't care about that. 


=head3 $c->argv

The array reference C<< $c->argv >> contains every argument passed to your command that have B<not> been parsed into C<< $c->options >>. This is usually a list of every provided argument that didn't start with a dash (-), unless you've called C<< $c->getopt >> and used something like 'param=s' (again, see below).

=head3 $c->getopt (Advanced Getopt usage)

App::Rad is also smoothly integrated with Getopt::Long, so you can have even more flexibility and power while parsing your command's arguments, such as aliases and types. Call the C<< $c->getopt() >> method anytime inside your commands (or just once in your "pre_process" function to always have the same interface) passing a simple array with your options, and refer back to $c->options to see them. For instance: 

    sub roll {
        my $c = shift;

        $c->getopt( 'faces|f=i', 'times|t=i' )
            or $c->execute('usage') and return undef;

        # and now you have $c->options->{'faces'} 
        # and $c->options->{'times'} just like above.
    }

This becomes very handy for complex or feature-rich commands. Please refer to the Getopt::Long module for more usage examples.


B<< So, in order to manipulate and use any arguments, remember: >>

=over 6

=item * The given command name does not appear in the argument list;

=item * All given arguments are in C<< @ARGV >>

=item * Automatically processed arguments are in C<< $c->options >>

=item * Non-processed arguments (the ones C<< $c->options >> didn't catch) are in $c->argv

=item * You can use C<< $c->getopt >> to have C<< Getopt::Long >> parse your arguments (it will B<not> change C<< @ARGV >>)

=back


=head2 Sharing Data: C<< $c->stash >>

The "stash" is a universal hash for storing data among your Commands:

    $c->stash->{foo} = 'bar';
    $c->stash->{herculoids} = [ qw(igoo tundro zok gloop gleep) ];
    $c->stash->{application} = { name => 'My Application' };

You can use it for more granularity and control over your program. For instance, you can email the output of a command if (and only if) something happened:

    sub command {
        my $c = shift;
        my $ret = do_something();

        if ( $ret =~ /critical error/ ) {
            $c->stash->{mail} = 1;
        }
        return $ret;
    }

    sub post_process {
        my $c = shift;

        if ( $c->stash->{mail} ) {
            # send email alert...
        }
        else {
            print $c->output . "\n";
        }
    }



=head2 Returning output

Once you're through, return whatever you want to give as output for your command:

    my $ret = "Here's the list: ";
    $ret .= join ', ', 1..5;
    return $ret;
    
    # this prints "Here's the list: 1, 2, 3, 4, 5"

App::Rad lets you post-process the returned value of every command, so refrain from printing to STDOUT directly whenever possible as it will give much more power to your programs. See the I<post_process()> control function further below in this document.


=head1 HELPER METHODS

App::Rad's controller comes with several methods to help you manage your application easily. B<If you can think of any other useful command that is not here, please drop me a line or RT request>.


=head2 $c->execute( I<COMMAND_NAME> )

Runs the given command. If no command is given, runs the one stored in C<< $c->cmd >>. If the command does not exist, the 'default' command is ran instead. Each I<execute()> call also invokes pre_process and post_process, so you can easily manipulate income and outcome of every command.


=head2 $c->cmd

Returns a string containing the name of the command (that is, the first argument of your program), that will be called right after pre_process.


=head3 $c->command

Alias for C<< $c->cmd >>. This longer form is discouraged and may be removed in future versions, as one may confuse it with the C<< $c->commands() >> method, explained below. You have been warned.


=head2 $c->commands()

Returns a list of available commands (I<functions>) inside your program


=head2 $c->is_command ( I<COMMAND_NAME> )

Returns 1 (true) if the given I<COMMAND_NAME> is available, 0 (false) otherwise.


=head2 $c->create_command_name()

Returns a valid name for a command (i.e. a name slot that's not been used by your program). This goes in the form of 'cmd1', 'cmd2', etc., so don't use unless you absolutely have to. App::Rad, for instance, uses this whenever you try to I<include> (see below) a new command but do not supply a name for it.


=head2 $c->load_config( I<< FILE (FILE2, FILE3, ...) >> )

This method lets you easily load into your program one or more configuration files written like this:

    # comments and blank lines are discarded
    key1 value1
    key2:value2
    key3=value3
    key5           # stand-alone attribute (and inline-comment)


=head2 $c->config

Returns a hash reference with any loaded config values (see C<< $c->load_config() >> above).


=head2 $c->register ( I<NAME>, I<CODEREF> [, I<INLINE_HELP> ])

Registers a coderef as a callable command. Note that you don't have to call this in order to register a sub inside your program as a command, run() will already do this for you - and if you don't want some subroutines to be issued as commands you can always use C<< $c->register_commands() >> (note the plural) inside setup(). This is just an interface to dinamically include commands in your programs. The function returns the command name in case of success, undef otherwise.

It is also very useful for creating aliases for your commands:

    sub setup {
        my $c = shift;
        $c->register_commands();

        $c->register('myalias', \&command);
    }

    sub command { return "Hi!" }

and, on the command line:

    [user@host]$ ./myapp.pl command
    Hi!

    [user@host]@ ./myapp.pl myalias
    Hi!

The last parameter is optional and lets you add inline help to your command:

    $c->register('cmd_name', \&cmd_func, 'display secret of life');

=head3 $c->register_command ( I<NAME>, I<CODEREF> [, I<INLINE_HELP> ] )

Longer alias for C<< $c->register() >>. It's use is disencouraged as one may confuse it with C<register_commands> (note the plural) below. Plus you type more :)
As such, this method may be removed in future versions. You have been warned!

=head2 $c->register_commands()

This method, usually called during setup(), tells App::Rad to register subroutines as valid commands. If called without any parameters, it will register B<all> subroutines in your main program as valid commands (note that the default behavior of App::Rad is to ignore subroutines starting with an underscore '_'). You can easily change this behavior using some of the options below:

=head3 Adding single commands

    $c->register_commands( qw/foo bar baz/ );

The code above will register B<only> the subs C<foo>, C<bar> and C<baz> as commands. Other subroutines will B<not> be valid commands, so they can be used as internal subs for your program. You can change this behavior with the bundled options - see 'Adding several commands' and 'Putting it all together' below.

=head3 Adding single commands (with inline help)

    $c->register_commands(
            {
                dos2unix => 'convert text files from DOS to Unix format',
                unix2dos => 'convert text files from Unix to DOS format',
            }
    );

You can pass a hash reference containing commands as keys and a small help string as their values. The code above will register B<only> the subs C<dos2unix> and C<unix2dos>, and the default help for your program will become something like this:

    [user@host]$ ./myapp.pl
    Usage: myapp.pl command [arguments]
    
    Available Commands:
        dos2unix    convert text files from DOS to Unix format
        help        show syntax and available commands
        unix2dos    convert text files from Unix to DOS format


=head3 Adding several commands

You can pass a hash reference as an argument, letting you choose which subroutines to add as commands. The following keys may be used (note the dash preceding each key):

=over 4

=item * C<< -ignore_prefix >>: subroutine names starting with the given string won't be added as commands

=item * C<< -ignore_suffix >>: subroutine names ending with the given string won't be added as commands

=item * C<< -ignore_regexp >>: subroutine names matching the given regular expression (as a string) won't be added as commands

=back

For example:

    use App::Rad;
    App::Rad->run();

    sub setup { 
        my $c = shift; 
        $c->register_commands( { -ignore_prefix => '_' } );
    }

    sub foo  {}  # will become a command
    sub bar  {}  # will become a command
    sub _baz {}  # will *NOT* become a command

This way you can easily segregate between commands and helper functions, making your code even more reusable without jeopardizing the command line interface (As of version 1.04, ignoring commands with underscore '_' prefixes is also the default App::Rad behavior).


=head3 Putting it all together

You can combine some of the options above to have even more flexibility:

    $c->register_commands(
            'foo',
            { -ignore_suffix => 'foo' },
            { bar => 'all your command line are belong to us' },
    );

The code above will register as commands all subs with names B<not> ending in 'foo', but it B<will> register the 'foo' sub as well. It will also give the 'bar' command the help string. This behavior is handy for registering several commands and having a few exceptions, or to add your commands and only have inline help for a few of them (as you see fit).

You don't have to worry about the order of your elements passed, App::Rad will figure them out for you in a DWIM fashion.

    # this does the same as the code above
    $c->register_commands(
            { bar => 'all your command line are belong to us' },
            'foo',
            { -ignore_suffix => 'foo' },
    );

You can even bundle the hash reference to include your C<< cmd => help >> and special keys:

    # this behaves the same way as the code above:
    $c->register_commands(
        'foo',
        { 
            -ignore_suffix => 'foo',
            bar => 'all your command line are belong to us',
        }
    );


=head2 $c->unregister_command ( I<NAME> )

Longer alias for C<< $c->unregister() >>. The use of the shorter form is encouraged, and this alias may be removed in future versions. You have been warned.


=head3 $c->unregister ( I<NAME> )

Unregisters a given command name so it's not available anymore. Note that the subroutine will still be there to be called from inside your program - it just won't be accessible via command line anymore.


=head2 $c->debug( I<MESSAGE> )

Will print the given message on screen only if the debug flag is enabled:

    use App::Rad  qw( debug );

Note that, if debug is enabled, App::Rad itself will print several debug messages stating its current flow, so you can easily find out where everything is happening.


=head2 $c->plugins()

Returns a list of all loaded plugins, in the order in which they were loaded.


=head2 $c->load_plugin( I<PLUGIN NAME> )

This method will dinamically load the given plugin. The plugin needs to be under the C<< App::Rad::Plugin >> namespace, and the name should be relative to this path (i.e. $c->load_plugin('MyPlugin') will try to load 'App::Rad::Plugin::MyPlugin'). If you want to load a plugin by its fully qualified name, you need to prepend a plus sign to the name ('+Fully::Qualified::Plugin::Name'). B<This is an internal method> and you really should refrain from using it. Instead, plugins should be loaded as parameters to the C<< use App::Rad >> statement, as explained above.


=head1 CONTROL FUNCTIONS (to possibly override)

App::Rad implements some control functions which are expected to be overridden by implementing them in your program. They are as follows:

=head2 setup()

This function is responsible for setting up what your program can and cannot do, plus everything you need to set before actually running any command (connecting to a database or host, check and validate things, download a document, whatever). Note that, if you override setup(), you B<< *must* >> call C<< $c->register_commands() >> or at least C<< $c->register() >> so your subs are classified as valid commands (check $c->register_commands() above for more information).

Another interesting thing you can do with setup is to manipulate the command list. For instance, you may want to be able to use the C<include> and C<exclude> commands, but not let them available for all users. So instead of writing:

    use App::Rad qw(include exclude);
    App::Rad->run();

you can write something like this:

    use App::Rad;
    App::Rad->run();

    sub setup {
        my $c = shift;
        $c->register_commands();

        # EUID is 'root'
        if ( $> == 0 ) {
            $c->register('include', \&App::Rad::include);
            $c->register('exclude', \&App::Rad::exclude);
        }
    }

to get something like this:

    [user@host]$ myapp.pl help
    Usage: myapp.pl command [arguments]

    Available Commands:
       help

    [user@host]$ sudo myapp.pl help
    Usage: myapp.pl command [arguments]

    Available Commands:
       exclude
       help
       include



=head2 default()

If no command is given to your application, it will fall in here. Please note that invalid (non-existant) command will fall here too, but you can change this behavior with the invalid() function below (although usually you don't want to).

Default's default (grin) is just an alias for the help command.

    sub default {
        my $c = shift;

        # will fall here if the given
        # command isn't valid.
    }

You are free (and encouraged) to change the default behavior to whatever you want. This is rather useful for when your program will only do one thing, and as such it receives only parameters instead of command names. In those cases, use the "C<< default() >>" sub as your main program's sub and parse the parameters with C<< $c->argv >> and C<< $c->getopt >> as you would in any other command.

=head2 invalid()

This is a special function to provide even more flexibility while creating your command line applications. This is called when the user requests a command that does not exist. The built-in C<< invalid() >> will simply redirect itself to C<< default() >> (see above), so usually you just have to worry about this when you want to differentiate between "no command given" (with or without getopt-like arguments) and "invalid command given" (with or without getopt-like arguments).

=head2 teardown()

If implemented, this function is called automatically after your application runs. It can be used to clean up after your operations, removing temporary files, disconnecting a database connection established in the setup function, logging, sending data over a network, or even storing state information via Storable or whatever.


=head2 pre_process()

If implemented, this function is called automatically right before the actual wanted command is called. This way you have an optional pre-run hook, which permits functionality to be added, such as preventing some commands to be run from a specific uid (e.g. I<root>): 

    sub pre_process {
        my $c = shift;

        if ( $c->cmd eq 'some_command' and $> != 0 ) {
            $c->cmd = 'default'; # or some standard error message
        }
    }
    

=head2 post_process()

If implemented, this function is called automatically right after the requested function returned. It receives the Controller object right after a given command has been executed (and hopefully with some output returned), so you can manipulate it at will. In fact, the default "post_process" function is as goes:

    sub post_process {
        my $c = shift;

        if ( $c->output() ) {
            print $c->output() . "\n";
        }
    }

You can override this function to include a default header/footer for your programs (either a label or perhaps a "Content-type: " string), parse the output in any ways you see fit (CPAN is your friend, as usual), etc.



=head1 IMPORTANT NOTE ON PRINTING INSIDE YOUR COMMANDS

B<The post_process() function above is why your application should *NEVER* print to STDOUT>. Using I<print> (or I<say>, in 5.10) to send output to STDOUT is exclusively the domain of the post_process() function. Breaking this rule is a common source of errors. If you want your functions to be interactive (for instance) and print everything themselves, you should disable post-processing in setup(), or create an empty post_process function or make your functions return I<undef> (so I<post_process()> will only add a blank line to the output).


=head1 DIAGNOSTICS

If you see a '1' printed on the screen after a command is issued, it's probably because that command is returning a "true" value instead of an output string. If you don't want to return the command output for post processing(you'll loose some nice features, though) you can return undef or make post_process() empty.


=head1 CONFIGURATION AND ENVIRONMENT

App::Rad requires no configuration files or environment variables.


=head1 DEPENDENCIES

App::Rad depends only on 5.8 core modules (Carp for errors, Getopt::Long for "$c->getopt", Attribute::Handlers for "help" and O/B::Deparse for the "include" command).

If you have Perl::Tidy installed, the "include" command will tidy up your code before inclusion.

The test suite depends on Test::More, FindBin and File::Temp, also core modules.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to 
C<bug-app-easy at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/garu/ReportBug.html?Queue=App-Rad>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rad

Although this Module comes without any warraties whatsoever (see DISCLAIMER below), I try really hard to provide some quality assurance for the users. This means I not only try to close all reported bugs in the minimum amount of time but I also try to find some on my own.

This version of App::Rad comes with 183 tests and I keep my eye constantly on CPAN Testers L<http://www.cpantesters.org/show/App-Rad.html> to ensure it passes all of them, in all platforms. You can send me your own App::Rad tests if you feel I'm missing something and I'll hapilly add them to the distribution.

Since I take user's feedback very seriously, I really hope you send me any wishlist/TODO you'd like App::Rad to have (please try to send them via RT so other people can give their own suggestions).


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/garu/Bugs.html?Dist=App-Rad>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Rad>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Rad>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Rad>

=back

=head2 IRC

   #app-rad  on irc.perl.org


=head1 TODO

This is a small list of features I plan to add in the near future (in no particular order). Feel free to contribute with your wishlist and comentaries!

=over 4

=item * Shell-like environment

=item * Loadable commands (in an external container file)

=item * Modularized commands (similar to App::Cmd::Commands ?)

=item * app-starter

=item * command inclusion by prefix, suffix and regexp (feature request by fco)

=item * command inclusion and exclusion also by attributes

=item * some extra integration, maybe IPC::Cmd and IO::Prompt

=back


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>


=head1 CONTRIBUTORS

(in alphabetical order)

Ben Hengst

Fernando Correa

Flavio Glock

Thanks to everyone for contributing! Please let me know if I've skipped your name by accident.


=head1 ACKNOWLEDGEMENTS

This module was inspired by Kenichi Ishigaki's presentation I<"Web is not the only one that requires frameworks"> during YAPC::Asia::2008 and the modules it exposed (mainly App::Cmd and App::CLI).

Also, many thanks to CGI::App(now Titanium)'s Mark Stosberg and all the Catalyst developers, as some of App::Rad's functionality was taken from those (web) frameworks.


=head1 LICENSE AND COPYRIGHT

Copyright 2008 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.



=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
