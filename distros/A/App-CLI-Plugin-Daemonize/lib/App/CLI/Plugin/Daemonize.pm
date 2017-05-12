package App::CLI::Plugin::Daemonize;

=head1 NAME

App::CLI::Plugin::Daemonize - for App::CLI::Plugin::Extension daemonize plugin module

=head1 VERSION

1.0

=head1 SYNOPSIS

  # MyApp.pm
  package MyApp;
  
  use strict;
  use base qw(App::CLI::Extension);
  
  # extension method
  __PACKAGE__->load_plugins(qw(Daemonize));
  
  # extension method
  __PACKAGE__->config( deemonize => 1 );
  
  1;
  
  # MyApp/Daemonize.pm
  package MyApp::Daemonize;
  
  use strict;
  use base qw(App::CLI::Command);
  
  sub options { return ("daemonize" => "daemonize") };
  
  sub run {
          
      my($self, @argv) = @_;
      # anything to do...
  }
  
  1;
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # daemon execute
  [kurt@localhost ~] ./myapp daemonize

=head1 DESCRIPTION

App::CLI::Plugin::Daemonize - daemonize plugin module

daemonize method setting

  # enable daemonize
  __PACKAGE__->config( daemonize => 1 );

or if --daemonize option is defined. it applies.

  # in MyApp/**.pm
  sub options {
      return ( "daemonize" => "daemonize" ) ;
  }
  
  # execute
  [kurt@localhost ~] ./myapp daemonize --daemonize

=head1 METHOD

=head2 daemonize

Enable daemonize. It usually runs in the setup method, no explicit attempt to

=cut

use strict;
use warnings;
use File::Spec;
use POSIX qw(setsid);

our $VERSION = '1.0';

sub setup {

	my($self, @argv) = @_;

	my $daemonize = (exists $self->config->{daemonize}) ? $self->config->{daemonize} : 0;
	if (exists $self->{daemonize}) {
		$daemonize = $self->{daemonize};
	}

	if ($daemonize) {
		$self->daemonize;
	}

	$self->maybe::next::method(@argv);
}

sub daemonize {

	my $self = shift;

	my $devnull = File::Spec->devnull;

	# detach parent process
	$SIG{CHLD} = 'IGNORE';
	defined(my $pid = fork) or $self->throw("can not fork. $!");
	if ($pid < 0) {
		$self->throw("cat not fork. pid:$pid");
	}
	if ($pid) {
		exit;
	}

	# change umask
	umask 0;

	# pgrp and session leader
	my $sid = POSIX::setsid;
	if($sid < 0) {
		$self->throw("can not setsid. sid:$sid");
	}

	# chdir /
	chdir "/" or $self->throw("can not chdir /. $!");

	open STDIN, "<", $devnull  or $self->throw("can not open STDIN");
	open STDOUT, ">", $devnull or $self->throw("can not open STDOUT");
	open STDERR, ">&STDOUT"    or $self->throw("can not open STDERR");
}

1;

__END__

=head1 AUTHOR

Akira Horimoto

=head1 SEE ALSO

L<App::CLI::Extension>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (C) 2010 Akira Horimoto

=cut
