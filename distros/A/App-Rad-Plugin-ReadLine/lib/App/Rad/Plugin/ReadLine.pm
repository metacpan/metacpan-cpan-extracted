package App::Rad::Plugin::ReadLine;
BEGIN {
  $App::Rad::Plugin::ReadLine::VERSION = '0.002';
}

# ABSTRACT: App::Rad::Plugin::ReadLine a Term::UI ->shell for Rad Apps


use warnings; 
use strict;

our $GreetWithCommand = 'help';  # when the shell starts, run this command
our $GreetWithSub             ;  # you can pass in a sub too,  both GreetWith's are run
our $DefaultCommand   = ''    ; 
our $ShellPrompt      = "[" . $0 . "]";

# we keep prompting until this is false
# (we register "exit" as a command to set it to 0 upon entering shell)
our $still_going = 1;


use Term::UI;
use Term::ReadLine;


our $term;
sub _terminal { 
    $term ||= Term::ReadLine->new($ENV{TERM} || 'critter');
}

sub _shell_prompt   {
    # add a space to the end
    $ShellPrompt =~ / $/?  $ShellPrompt : "$ShellPrompt " 
}
sub _shell_help     { "run $0 in interactive mode" };
sub _shell_command  { 'shell' } 


sub shell_options { 
    my $c = shift;

    if (@_==0) {
        $c->register( _shell_command() => \&shell, _shell_help() );
        return;
    }

    my ($opts, $name, $help);
    my $no_register;

    if ('HASH' eq ref $_[0]) {
        ($opts, $name, $help) = @_;
        $GreetWithCommand = $opts->{GreetWithCommand}
                             if exists $opts->{GreetWithCommand};
        $GreetWithSub = $opts->{GreetWithSub}
                             if exists $opts->{GreetWithSub};
        $DefaultCommand = $opts->{DefaultCommand}
                             if exists $opts->{DefaultCommand};
        $ShellPrompt = $opts->{ShellPrompt}
                             if exists $opts->{ShellPrompt};

        $c->debug(sprintf'shell_options '
                    . '$GreetWithCommand   = %s, '
                    . '$GreetWithSub       = %s, '
                    . '$ShellPrompt        = %s, '
                    . '$DefaultCommand     = %s. also '
                    . '$name = %s, $help = %s',
                    map defined $_ ? $_ : '(not defined)',
                        $GreetWithCommand,
                        $GreetWithSub,
                        $ShellPrompt,
                        $DefaultCommand,
                        $name, $help
        );

        $no_register = 1
            if @_ >= 2 and not defined $name;
    }
    else {
        ($name, $help) = @_;
        $no_register = 1
            if @_ >= 1 and not defined $name;
    }

    if ($no_register) { 
        $c->debug("not registering shell as a command since \$name was passed as undef");
    }
    else {
        $name = _shell_command() if not defined $name;
        $help = _shell_help()    if not defined $help;
        

        $c->debug("registering shell as '$name' => '$help'");
        $c->register( $name => \&shell, $help );
    }
}


# this is printed when your shell first starts, it will optionally run a command,
# then optionally run a sub
# again, you can do both, but that's likely to be unhelpful
sub _welcome {
    my $c = shift;
    # $c->critters();
    $c->stash->{shelllvl} ++;

    do {
        local $c->{'cmd'} = $GreetWithCommand; 
        $c->execute();
    } if defined $GreetWithCommand; 

    $c->$GreetWithSub() if defined $GreetWithSub;

} 

sub shell {
    my $c = shift;
    # $c->critters();
    $c->stash->{shelllvl} ++;
    {no warnings qw[ redefine ];
    *App::Rad::Help::usage = sub { 
        "Your app as a shell. Type commands with arguments"
    };}

    
    # sub-shells
    local $GreetWithCommand  = $GreetWithCommand ;
    local $GreetWithSub      = $GreetWithSub     ;
    local $DefaultCommand    = $DefaultCommand   ;

    local $ShellPrompt       = $ShellPrompt      ;
    local $still_going       = $still_going      ;

    $c->shell_options(@_) if @_;

    $c->register( 'exit', sub { 
        $App::Rad::Plugin::ReadLine::still_going = 0;
    }, "exit the $0 shell" );

    $c->unregister_command('shell');# Xhibit forbidden

    my $welcome = \&_welcome;
    $c->$welcome();

    while($still_going) {
        (my $cmd, local @ARGV) = split  ' ',
        _terminal->get_reply(
              prompt => _shell_prompt(),
              default => $DefaultCommand,
        );
        if (defined $cmd and $cmd ne '') { 
            @{$c->argv} = @ARGV;
            $c->{'cmd'} = $cmd;

            $c->debug('received command: ' . $c->{'cmd'});
            $c->debug('received parameters: ' . join (' ', @{$c->argv} ));
        }
        $c->_tinygetopt();
        # run the specified command
        #       setup/pre_process are run for us... 
        $c->execute();
        # teardown is run after this (again, magically)
    }
}


"Say my name"

__END__
=pod

=head1 NAME

App::Rad::Plugin::ReadLine - App::Rad::Plugin::ReadLine a Term::UI ->shell for Rad Apps

=head1 VERSION

version 0.002

=head1 SYNOPSIS

To run your app as a shell, you can either...

=head2 call  C<< ->shell >> from an action ...

start shell mode straight away from a sub-command 

#see ./example/01-myapp

  #! /usr/bin/perl
  #...
  use App::Rad qw[ ReadLine ];
  App::Rad->run();
  sub turtles :Help('do it in the shell'){
      my $c = shift;
      $c->shell({
          GreetWithCommand => '',  # use what App::Rad decides is the default
          ShellPrompt => 'c/,,\\'  # ascii turtle for the prompt
      });
  }

#end of listing

#running ./example/01-myapp demo turtles exit

  Usage: ./example/01-myapp command [arguments]
  
  Available Commands:
      help   	show syntax and available commands
      turtles	do it in the shell
  

#.

C<< ->shell >> takes the same options as C<< ->shell_options >>

arguments to C<&shell> are all optional,
in the hope I can play nice with other plugins 
that implement a C<&shell> method

=head2 ... or call C<< ->shell_options >> in setup and (optionally) specify a sub-command name

#see ./example/02-registered

  #! /usr/bin/perl
  #...
  use App::Rad qw[ ReadLine ];
  App::Rad->run();
  sub setup {
      my $c = shift;
      $c->register_commands(
          'serious', 'business'
          #...other commands here 
      );
      $c->shell_options( 'interactive' );    # all args optional, with sensible defaults
  }
  
  sub serious  :Help('Important functionality - not to be joked about') {};
  sub business :Help('You gotta do what you gotta do.') {};
  #...

#end of listing

#running ./example/02-registered demo interactive

  Your app as a shell. Type commands with arguments
  
  Available Commands:
      business   	You gotta do what you gotta do.
      demo       	
      exit       	exit the ./example/02-registered shell
      help       	show syntax and available commands
      interactive	run ./example/02-registered in interactive mode
      serious    	Important functionality - not to be joked about
  
  [./example/02-registered] exit

#.

If you call C<< ->shell_options >> you will get an extra sub-command that starts a shell for you.

=head2 You can do both...

... allowing you to have a shell for App-wide commands, and another (sub) shell with different commands:

#see ./example/03-subshell-app

  #! /usr/bin/perl
  #...
  use App::Rad qw[ ReadLine ];
  App::Rad->run();
  sub setup {
      my $c = shift;
      $c->register_commands( qw[ demo critter_shell ] );
      $c->register( something => sub {
              #...
          }, 'helpful things'
      );
      $c->register( status => sub {
              #...
          }, 'show current status'
      );
      $c->shell_options;
  }
  sub critter_shell : Help('a sub-shell'){
      my $c=shift;
      # set up commands to be visible in critter_shell, they will
      # not be available from the command line
  
      $c->unregister_command( $_ ) for qw[ something status demo critter_shell ];
      $c->register( critterfy     => sub {
              "A critter has been configured for the current user\n" # boring;
          }, 'setup critter instance for user with given id');
      $c->register( decritterfy   => sub {}, 'remove a critter, for the user with given id' );
  
      $c->shell({ ShellPrompt => 'critters> ' });
  }

#end of listing

#running ./example/03-subshell-app demo shell something status critter_shell critterfy exit

  Your app as a shell. Type commands with arguments
  
  Available Commands:
      critter_shell	a sub-shell
      demo         	
      exit         	exit the ./example/03-subshell-app shell
      help         	show syntax and available commands
      something    	helpful things
      status       	show current status
  
  [./example/03-subshell-app] something
  Helpful things going on: ... done
  
  [./example/03-subshell-app] status
  Deadlines: met
  Financial: under budget
  Customers: happy
  Pigs     : saddled up and ready for flight
  
  [./example/03-subshell-app] critter_shell
  Your app as a shell. Type commands with arguments
  
  Available Commands:
      critterfy  	setup critter instance for user with given id
      decritterfy	remove a critter, for the user with given id
      exit       	exit the ./example/03-subshell-app shell
      help       	show syntax and available commands
  
  critters> critterfy
  A critter has been configured for the current user
  
  critters> exit
  [./example/03-subshell-app] exit

#.

=head2 Commands with arguments 

The arguments to your your commands are done in an I< I could be the shell for all you know > way ...

 [./yourapp] sub_name

works just fine, you can see it going on in the subs above.

 [./yourapp] subname --switch ordinal options 

seems to result in the correct things in 
C<$c->options>, 
C<$c->argv>  and 
C<@ARGV> 

You can import C<< App::Rad::Plugin::ReadLine::Demo qw[ getopt ] >> into your app as an action, and run it a couple of times to see the arguments being interpreted

=head2 shell_options( [ \%options ], [ $command_name, [ $command_help ]])

All arguments are optional:

 ->shell_options( "name", "help" )
 ->shell_options( { GreetWithCommand => 'help' } )
 ->shell_options( { DefaultCommand   => 'exit' }, 'subshell' )
 ->shell_options;

=head3 C<\%options>'s keys are:

C<GreetWithCommand> => run this App::Rad command when the shell starts

C<GreetWithSub>     => run this sub-ref (as a method on $c) when the shell starts

C<DefaultCommand>   => if the user doesn't enter a command, they entered this.
'' will use App::Rad's default command.

C<ShellPrompt>      => what to prompt the user with, defautl is "$0 "

=head3 C<[$command_name, [ $command_help ]]>:

C<$command_name> is the name of the sub-comamnd name

C< $command_help> is the help to pass

... both are passed to C<< $c->register >>, along with C<\&shell>

=head1 BUGS

If you found a bug feel free to report it via L<http://rt.cpan.org/>
(you could use L<App::rtpaste> if you wanted to)

It's fairly likely that C<App::Rad> apps expect more (or less) interfeering with than 
this module provides ... it's sad but true.

If you're complaining about how poor a job I've done please include as may of the following as you can:

=over 4 

=item * What you expected it to do 

=item * What it did 

=item * How you made it do that 

(a test case, or your app would be idea)

=item * How you made it stop doing that 

(ie a patch to fix it, or a work around...)

=back

=head1 BUGS

Please report any bugs or feature requests to bug-app-rad-plugin-readline@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=App-Rad-Plugin-ReadLine

=head1 AUTHOR

FOOLISH <FOOLISH@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by FOOLISH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

