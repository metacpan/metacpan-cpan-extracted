package App::CLI::Extension;

=pod

=head1 NAME

App::CLI::Extension - for App::CLI extension module

=head1 VERSION

1.421

=head1 SYNOPSIS

  # MyApp.pm
  package MyApp;
  
  use strict;
  use base qw(App::CLI::Extension);
  
  # extension method
  # load App::CLI::Plugin::Foo,  MyApp::Plugin::Bar
  __PACKAGE__->load_plugins(qw(Foo +MyApp::Plugin::Bar));
  
  # extension method
  __PACKAGE__->config( name => "kurt" );
  
  1;
  
  # MyApp/Hello.pm
  package MyApp::Hello;
  
  use strict;
  use base qw(App::CLI::Command);
  use constant options => ("age=i" => "age");
  
  sub run {
  
      my($self, @args) = @_;
      # config - App::CLI::Extension extension method(App::CLI::Extension::Component::Config)
      print "Hello! my name is " . $self->config->{name} . "\n";
      print "age is " . "$self->{age}\n";
  }
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # execute
  [kurt@localhost ~] myapp hello --age=27
  Hello! my name is kurt
  age is 27

=head1 DESCRIPTION

The expansion module which added plug in, initial setting mechanism to App::CLI

App::CLI::Extension::Component::* modules is automatic, and it is done require

(It is now Config and Stash is automatic, and it is done require)

=head2 RUN PHASE

  +----------------------+
  |   ** run_method **   |
  |  +----------------+  |
  |  |  setup  phase  |  | 
  |  +----------------+  |
  |          ||          |
  |  +----------------+  |
  |  |  prerun phase  |  | 
  |  +----------------+  |
  |          ||          |  
  |  +----------------+  |   if anything error...   +----------------+
  |  |    run phase   |  |  ======================> |   fail  phase  |
  |  +----------------+  |                          +----------------+
  |          ||          |                       set exit_value(default: 255)
  |  +----------------+  |                                   |
  |  |  postrun phase |  |                                   |
  |  +----------------+  |                                   |
  +----------------------+                                   |
              |                                              |
              |                                              |
     +----------------+                                      |
     |  finish phase  |  <================================== +
     +----------------+  
              |
             exit

=head2 SETUP

If you define initialization and initialization of each plug-in

=head2 PRERUN

If you want the process to run before you run something in the main processing

=head2 RUN

Process to define the main(require). however, $self->finished non-zero if not executed

=head2 POSTRUN

After the run method to execute. however, $self->finished non-zero if not executed

=head2 FINISH

At the end of all processing

=head2 FAIL

setup/prerun/run/postrun/finish processing to be executed if an exception occurs somewhere in the phase error

$self->e is the App::CLI::Extension::Exception or Error::Simple instance is set

=cut

use strict;
use warnings;
use base qw(App::CLI Class::Accessor::Grouped);
use 5.008000;
use UNIVERSAL::require;

our $VERSION    = '1.421';
our @COMPONENTS = qw(
					Config
					ErrorHandler
					InstallCallback
					OriginalArgv
					Stash
					RunCommand
                  );

__PACKAGE__->mk_group_accessors(inherited => "_config", "_components", "_orig_argv", "_plugins");
__PACKAGE__->_config({});
__PACKAGE__->_plugins([]);

=pod

=head1 METHOD

=cut

sub import {

	my $class = shift;
	my @loaded_components;
	foreach my $component (@COMPONENTS) {
		$component = sprintf "%s::Component::%s", __PACKAGE__, $component;
		$component->require or die "load component error: $UNIVERSAL::require::ERROR";
		$component->import;
		push @loaded_components, $component;
    }
	$class->_components(\@loaded_components);
}

sub dispatch {

	my $class = shift;
	# save original argv
	my @argv = @ARGV;
	$class->_orig_argv(\@argv);
	my $cmd = $class->prepare(@_);
	$cmd->subcommand;
	{
		no strict "refs"; ## no critic
		no warnings "uninitialized"; ## adhoc
		my $pkg = ref($cmd);
		# component and plugin set value
		unshift @{"$pkg\::ISA"}, @{$class->_components};
		if (scalar(@{$class->_plugins}) != 0) {
			unshift @{"$pkg\::ISA"}, @{$class->_plugins};
		}
		$cmd->config($class->_config);
		$cmd->orig_argv($class->_orig_argv);
	}
	$cmd->run_command(@ARGV);
}


=pod

=head2 load_plugins

auto load and require plugin modules

Example

  # MyApp.pm
  # MyApp::Plugin::GoodMorning and App::CLI::Plugin::Config::YAML::Syck require
  __PACKAGE__->load_plugins(qw(+MyApp::Plugin::GoodMorning Config::YAML::Syck));
  
  # MyApp/Plugin/GoodMorning.pm
  package MyApp::Plugin::GoodMorning;
  
  use strict;
   
  sub good_morning {
  
      my $self = shift;
      print "Good monring!\n";
  }
  
  # MyApp/Hello.pm
  package MyApp::Hello;
  
  use strict;
  use base qw(App::CLI::Command);
  
  sub run {
  
      my($self, @args) = @_;
      $self->good_morning;
  }
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # execute
  [kurt@localhost ~] myapp hello
  Good morning!

=cut

sub load_plugins {

	my($class, @load_plugins) = @_;

	my @loaded_plugins = @{$class->_plugins};
	foreach my $plugin(@load_plugins){

		if ($plugin =~ /^\+/) {
			$plugin =~ s/^\+//;
		} else {
			$plugin = "App::CLI::Plugin::$plugin";
		}
		$plugin->require or die "plugin load error: $UNIVERSAL::require::ERROR";
		$plugin->import;
		push @loaded_plugins, $plugin;
	}

	$class->_plugins(\@loaded_plugins);
}

=pod

=head2 config

configuration method

Example

  # MyApp.pm
  __PACKAGE__->config(
                 name           => "kurt",
                 favorite_group => "nirvana",
                 favorite_song  => ["Lounge Act", "Negative Creep", "Radio Friendly Unit Shifter", "You Know You're Right"]
              );
  
  # MyApp/Hello.pm
  package MyApp::Hello;
  
  use strict;
  use base qw(App::CLI::Command);
  
  sub run {
  
      my($self, @args) = @_;
      print "My name is " . $self->config->{name} . "\n";
      print "My favorite group is " . $self->config->{favorite_group} . "\n";
      print "My favorite song is " . join(",", @{$self->config->{favorite_song}});
      print " and Smells Like Teen Spirit\n"
  }
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # execute
  [kurt@localhost ~] myapp hello
  My name is kurt
  My favorite group is nirvana
  My favorite song is Lounge Act,Negative Creep,Radio Friendly Unit Shifter,You Know You're Right and Smells Like Teen Spirit

=cut

sub config {

	my($class, %config) = @_;
	$class->_config(\%config);
	return $class->_config;
}

=head1 COMPONENT METHOD

=head2 argv0

my script name

Example:

  # MyApp/Hello.pm
  package MyApp::Hello;
  use strict;
  use feature ":5.10.0";
  use base qw(App::CLI::Command);
     
  sub run {
  
      my($self, @args) = @_;
      say "my script name is " . $self->argv0;
  }
  
  1;

  # execute
  [kurt@localhost ~] myapp hello
  my script name is myapp

=head2 full_argv0

my script fullname

Example:

  # MyApp/Hello.pm
  package MyApp::Hello;
  use strict;
  use feature ":5.10.0";
  use base qw(App::CLI::Command);
  
  sub run {
  
      my($self, @args) = @_;
      say "my script full name is " . $self->full_argv0;
  }
  
  1;
  
  # execute
  [kurt@localhost ~] myapp hello
  my script name is /home/kurt/myapp

=head2 cmdline

my execute cmdline string

Example:

  # MyApp/Hello.pm
  package MyApp::Hello;
  use strict;
  use feature ":5.10.0";
  use base qw(App::CLI::Command);
  
  sub run {
  
      my($self, @args) = @_;
      say "my script cmdline is [" . $self->cmdline . "]";
  }
  
  1;
  
  # execute
  [kurt@localhost ~] myapp hello --verbose --num=10
  my script cmdline is [/home/kurt/myapp hello --verbose --num=10]

=head2 orig_argv

my execute script original argv

Example:

  # MyApp/Hello.pm
  package MyApp::Hello;
  use strict;
  use feature ":5.10.0";
  use base qw(App::CLI::Command);
  
  sub run {
  
      my($self, @args) = @_;
      say "my script original argv is [" join(", ", @{$self->orig_argv}) . "]";
  }
  
  1;
  
  # execute
  [kurt@localhost ~] myapp hello --verbose --num=10
  my script original argv is [hello,--verbose, --num=10]

=head2 stash

like global variable in Command package

Example:
  
  # MyApp/Hello.pm
  package MyApp::Hello;
  use strict;
  use feature ":5.10.0";
  use base qw(App::CLI::Command);
   
  sub run {
  
      my($self, @args) = @_;
      $self->stash->{name} = "kurt";
      say "stash value: " . $self->stash->{name};
  }
  
  1;

=head2 new_callback

install new callback phase

Example:

  $self->new_callback("some_phase");
  # registered callback argument pattern
  $self->new_callback("some_phase", sub { $self = shift; "anything to do..." });

=head2 add_callback

install callback

Example:

  $self->add_callback("some_phase", sub { my $self = shift; say "some_phase method No.1" });
  $self->add_callback("some_phase", sub { my $self = shift; say "some_phase method No.1" });
  $self->add_callback("any_phase", sub {
                                     my($self, @args) = @_;
                                     say "any_phase args: @args";
                                  });

=cut

=head2 exec_callback

execute callback

Example:

  $self->execute_callback("some_phase");
  # some_phase method method No.1
  # some_phase method method No.2
  
  $self->execute_callback("any_phase", qw(one two three));
  # any_phase args: one two three 

=head2 exists_callback

exists callback check

Example:

  if ($self->exists_callback("some_phase")) {
      $self->exec_callback("some_phase");
  } else {
      die "some_phase is not exists callback phase";
  }

=head2 exit_value

set exit value

Example:

  # program exit value is 1(ex. echo $?)
  $self->exit_value(1);

=head2 finished 

setup or prepare phase and 1 set, run and postrun phase will not run. default 0

Example:

  # MyApp/Hello.pm
  package MyApp::Hello;
  
  use strict;
  use base qw(App::CLI::Command);
  
  sub prerun {
   
      my($self, @args) = @_;
      $self->finished(1);
  }
  
  # non execute 
  sub run {
  
      my($self, @args) = @_;
      print "hello\n";
  }

=head2 throw

raises an exception, fail phase transitions

Example:

  # MyApp/Hello.pm
  package MyApp::Hello;
  
  use strict;
  use base qw(App::CLI::Command);
  
  sub run {
  
      my($self, @args) = @_;
      my $file = "/path/to/file";
      open my $fh, "< $file" or $self->throw("can not open file:$file");
      while ( my $line = <$fh> ) {
          chomp $line;
          print "$line\n";
      }
      close $fh;
  }
  
  # transitions fail phase method
  sub fail {
  
      my($self, @args) = @_;
      # e is App:CLI::Extension::Exception instance
      printf "ERROR: %s", $self->e;
      printf "STACKTRACE: %s", $self->e->stacktrace;
  }
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # execute
  [kurt@localhost ~] myapp hello
  ERROR: can not open file:/path/to/file at lib/MyApp/Throw.pm line 10.
  STACKTRACE: can not open file:/path/to/file at lib/MyApp/Throw.pm line 10
          MyApp::Throw::run('MyApp::Throw=HASH(0x81bd6b4)') called at /usr/lib/perl5/site_perl/5.8.8/App/CLI/Extension/Component/RunCommand.pm line 36
          App::CLI::Extension::Component::RunCommand::run_command('MyApp::Throw=HASH(0x81bd6b4)') called at /usr/lib/perl5/site_perl/5.8.8/App/CLI/Extension.pm line 177
          App::CLI::Extension::dispatch('MyApp') called at ./myapp line 7

when you run throw method, App::CLI::Extension::Exception instance that $self->e is set to.

App::CLI::Extension::Exception is the Error::Simple is inherited. refer to the to documentation of C<Error>

throw method without running CORE::die if you run the $self->e is the Error::Simple instance will be set

=head2 e

App::CLI::Extension::Exception or Error::Simple instance. There is a ready to use, fail phase only

=head1 RUN PHASE METHOD

=head2 setup

=head2 prerun

=head2 postrun

=head2 finish

program last phase. By default, the exit will be executed automatically, exit if you do not want the APPCLI_NON_EXIT environ valiable how do I set the (value is whatever)

=head2 fail

error phase. default exit value is 255. if you want to change exit_value, see exit_value manual

=cut

1;

__END__

=head1 SEE ALSO

L<App::CLI> L<Class::Accessor::Grouped> L<UNIVERSAL::require>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Copyright (C) 2009 Akira Horimoto

=cut

