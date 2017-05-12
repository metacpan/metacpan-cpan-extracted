package Daemon::Simple;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.1';

# Preloaded methods go here.
use Proc::ProcessTable;
use File::Spec;
# Daemon init
sub init
{
	my ($command,$homedir,$pidfile) = @_;
	unless($command)
	{
		print "$0 {start|stop}\n";
		exit;
	}
	unless($homedir)
	{
		$homedir = File::Spec->curdir();
	}
	unless($pidfile)
	{
		$pidfile = $homedir."/$0.pid";
	}
	my $pid = get_pidfile($pidfile);
	my $is_running = is_running($pid); 
	if( $command eq 'start' )
	{
		if( $is_running )
		{
			print "$0 is Already running.\n";
			exit; # stop here
		}
		else
		{
			# run
			print "$0 is Starting.\n";
		}
	}
	elsif( $command eq 'stop' )
	{
		if( $is_running )
		{
			print "Sending stop-signal to $0 (PID:$pid).\n";
			kill_process($pid);
			while( is_running($pid) )
			{
				sleep(1);
			}
			print "$0 (PID:$pid) is stopped.\n";
			destroy_pidfile($pidfile);
		}
		else
		{
			print "$0 (PID:$pid) is Already stopped.\n";
		}
		exit; # stop here
	}
	
        my $cpid = fork();
        if( $cpid ){
            exit;
        }
	chdir($homedir);
        close(STDIN);
        close(STDOUT);
        close(STDERR);
	create_pidfile($pidfile);
}

sub is_running
{
	my $pid = shift;
    my $table = Proc::ProcessTable->new()->table;
	my %processes = map { $_->pid => $_ } @$table;
	return exists $processes{$pid};
}

sub get_pidfile
{
	my $pidfile = shift;
	#get pid from file
	return 0 unless( -e$pidfile );
	open(FILE, "$pidfile");
	my $pid = <FILE>;
        die "Unexpected PID in $pidfile" unless $pid =~ /^(\d+)$/;
        $pid = $1;
        close(FILE);
	return $pid;
}

sub create_pidfile
{
	my $pidfile = shift;
	#write pid to file
	open(FILE,">$pidfile");
	print FILE $$;
	close(FILE);
}

sub kill_process
{
	my $pid = shift;
	#kill process
	kill(9,$pid);
}
sub destroy_pidfile
{
	my $pidfile = shift;
	#delete pid file
	unlink($pidfile);
}

=cut
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Daemon::Simple - Perl extension for making script as daemon with start|stop controlling on unix system

=head1 SYNOPSIS

  use Daemon::Simple;

  Daemon::Simple::init($command);

  or
  
  Daemon::Simple::init($command,"~/");

  or

  my $homedir = `pwd`; chomp($homedir);
  my $pidfile = "/var/run/ffencoder.pid";
  my $command = $ARGV[0];
  Daemon::Simple::init($command,$homedir,$pidfile);

  ## Daemon script ##
  open(FILE,">out.txt");
  select(FILE);


  sleep(10);
  close(FILE);
  __END__

  # in shell
  $ perl foo.pl start
  $ perl foo.pl stop

=head1 DESCRIPTION

This module is good for making a script as a daemon.
A daemon script has start|stop controlling command.
It is simple by adding Daemon::Simple::init() on first line of script.

This module is implemented by wrapping Proc::Daemon.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Proc::Daemon

Proc::ProcessTable

=head1 AUTHOR

HyeonSeung Kim, E<lt>sng2nara@hanmail.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by sng2nara

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
