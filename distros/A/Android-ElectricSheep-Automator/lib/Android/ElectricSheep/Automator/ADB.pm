package Android::ElectricSheep::Automator::ADB;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.005';

use Android::ElectricSheep::Automator::ADB::Device;
use Carp;
use File::Slurp;
use IPC::Open2;
# we already have a run() 'method'
# which clashes with IPC::Run's run() sub
# fingers crossed: don't import IPC::Run::run()
# and use fully qualified name when calling it.
use IPC::Run qw/timeout/;

sub new {
	my ($class, %args) = @_;
	$args{path} //= $ENV{ADB};
	$args{path} //= 'adb';
	$args{verbosity} //= 0;
	$args{args} //= [];
	bless \%args, $class
}

sub run2 {
	my ($self, @args) = @_;
	my ($out, $in);
	my @dev_args = $self->{device_serial} ? ('-s', $self->{device_serial}) : ();
	my $pid = open2 $out, $in, $self->{path}, @{$self->{args}}, @args;
	my $result = read_file $out;
	close $out;
	close $in;
	waitpid $pid, 0 or croak "$!";
	$result;
}

# returns an arrayref of
#   [statuscode, stdout, stderr]
# on success statuscode is 0 and stdout/stderr may or may not have something
# on failure statuscode is 1 and stdout/stderr may or may not have something
# the '$result' returned by original run2() is now the stdout,
# the 2nd item in the returned arrayref
sub run {
	my ($self, @args) = @_;
	my ($out, $in, $err);
	my @dev_args = $self->{device_serial} ? ('-s', $self->{device_serial}) : ();
	my @cmd = ($self->{path}, @{$self->{args}}, @args);
	if( $self->{verbosity} > 0 ){ print STDOUT __PACKAGE__.'::run()'." : executing command : ".join(' ', @cmd)."\n" }
	# check if undef is passed in @cmd, IPC does not like that
	for (@cmd){
		if( ! defined $_ ){
			my $errstr = __PACKAGE__.'::run()'." : error, command contains undef values (Perl's undef) which is not allowed, most likely a cockup with creating the command array: @cmd";
			carp $errstr;
			return [1, "", $errstr]
		}
	}
	my $res = eval {
	  IPC::Run::run(
		\@cmd,
		\$in, \$out, \$err,
		# AHP: on timeout it throws an exception matching
		#   /^IPC::Run: .*timed out/
		# or specify your own exception name (see doc)
		# I can't find what unit the timeout interval is!
		IPC::Run::timeout(1000)
	  )
	};
	# WARNING: adb on error sometimes returns non-zero exit code
	# but sometimes it exits normally with zero but there is
	# an error which you can find in the STDOUT/STDERR.
	# Unfortunately this is not a consistent message.
	# For example:
	#   adb shell xyz
	# will set $? to 127
	# but, e.g. this:
	#   adb shell input keycombination 1 2
	# will exit with $?=0 and print some error message!
	# Searching for 'Error:' in STDERR is ok?
	# TODO: this needs to be dealt with here.
	my $exit_code = $? >> 8;
	#if( (! $res) || $@ || ($err=~/\bError\: /) ){
	if( ($exit_code > 0) || $@ || ($err=~/\bError\: /) ){
		carp "STDERR:\n${err}\nOTHER INFO: $@\n\n"
			.(($@=~/IPC::Run: .*timed out/)
			  ?"\nWARNING: it looks like a timeout has occured.\n\n"
			  :""
			 )
			.__PACKAGE__.'::run()'." : error, failed to execute command (see above for stderr), exit code was '${exit_code}': ".join(' ', @cmd)
		; # end carp
		return [1, $out, $err, $exit_code];
	}
	return [0, $out, $err, $exit_code];
}

sub start_server { shift->run('start-server') }
sub kill_server  { shift->run('kill-server') }

sub connect      { shift->run('connect', @_) }
sub disconnect   { shift->run('disconnect', @_) }

sub devices      {
	my $ret = shift->run('devices', '-l');
	if( $ret->[0] != 0 ){
		print STDERR __PACKAGE__.'::devices()'." : error, failed to enquire devices:\n".$ret->[1]."\n".$ret->[2];
		return undef
	}
	my @devices = grep { ! /^List of devices/ }
		      grep { / / }
		      split '\n', $ret->[1]; # stdout contains the devices one in each line
	my @result;
	for (@devices) {
		next if /^List of devices/;
		next unless / /;
		push @result, Android::ElectricSheep::Automator::ADB::Device->new(split)
	}
	@result
}

sub set_device {
	my ($self, $device) = @_;
	$self->{device_serial} = $device->serial;
}

sub wait_for_device   { shift->run('wait-for-device') }
sub get_state         { shift->run('get-state') }
sub get_serialno      { shift->run('get-serialno') }
sub get_devpath       { shift->run('get-devpath') }
sub remount           { shift->run('remount') }
sub reboot            { shift->run('reboot', @_) }
sub reboot_bootloader { shift->run('reboot-bootloader') }
sub root              { shift->run('root') }
sub usb               { shift->run('usb') }
sub tcpip             { shift->run('tcpip', @_) }

sub push {
	my ($self, $local, $remote) = @_;
	$self->run(push => $local, $remote)
}

sub pull {
	my ($self, $remote, $local) = @_;
	$self->run(pull => $remote, $local)
}

sub pull_archive {
	my ($self, $remote, $local) = @_;
	$self->run(pull => '-a', $remote, $local)
}

sub shell { shift->run(shell => @_) }

1;
__END__

=encoding utf-8

=head1 NAME

Android::ElectricSheep::Automator::ADB - thin wrapper over the 'adb' command

=head1 SYNOPSIS

  use Android::ElectricSheep::Automator::ADB;;
  my $adb = Android::ElectricSheep::Automator::ADB->new(path => '/opt/android/platform-tools/adb');
  my @devices = $adb->devices;
  $adb->set_device($devices[0]);
  $adb->push('file.txt', '/sdcard/');
  sleep 10;
  $adb->reboot('recovery');

  # Version 0.002
  # run() is now using IPC::Run::run() to spawn commands
  # a lot of other methods depend on it, e.g. shell(), pull(), push(), devices(), etc.
  # they all return what it returns.
  # the changes make it easy to find out if there was an error
  # in executing external commands and getting the stderr from that.
  # $ret is [ $statuscode, $stdout, $stderr]
  # for success, $statuscode must be 0 ($stdout, $stderr may be blank in any case)
  my $ret = $adb->run("adb devices");
  if( $ret->[0] != 0 ){ croak "command has failed: ".$ret->[2] }

  my $ret = $adb->shell("getevent");
  if( $ret->[0] != 0 ){ croak "command has failed: ".$ret->[2] }

  my $ret = $adb->push('file.txt', '/sdcard/');
  if( $ret->[0] != 0 ){ croak "command has failed: ".$ret->[2] }

=head1 DESCRIPTION

This module is a minimal wrapper over the Android Debug Bridge
(C<adb>) command for manipulating Android devices.

Methods die on non-zero exit code and return the text printed by the
C<adb> command. The available methods are:

=over

=item Android::ElectricSheep::Automator::ADB->B<new>([I<args>])

Create a new Android::ElectricSheep::Automator::ADB object. The available arguments are C<path>,
the path to the C<adb> executable (defaults to the value of the
environment variable C<ADB> or the string C<adb>),
C<verbosity> which can be 0 for a silent run or
a positive integer denoting increased verbosity (default is 0),
and C<args>, an
arrayref of arguments passed to every adb command (defaults to []).

=item $adb->B<devices>

Returns a list of L<Android::ElectricSheep::Automator::ADB::Device> objects representing
connected devices. In case of failure running the query, it
will return an empty array.

=item $adb->B<set_device>(I<$device>)

Takes an L<Android::ElectricSheep::Automator::ADB::Device> and directs all further commands to
that device by passing C<-s serialno> to every command.

=item $adb->B<run>(I<$command>, [I<@args>])

Run an arbitrary ADB command and return its output (among other things).
Its return is an ARRAYref as C<[$statuscode, $stdout, $stderr]>.
C<$statuscode> is zero on success or 1 on failure.
C<$stdout> is the C<stdout> from running the command (it can be empty)
and C<$stderr> is the C<stderr>.

=item $adb->B<start_server>

=item $adb->B<kill_server>

=item $adb->B<connect>(I<$host_and_port>)

=item $adb->B<disconnect>([I<$host_and_port>])

=item $adb->B<wait_for_device>

=item $adb->B<get_state>

=item $adb->B<get_serialno>

=item $adb->B<get_devpath>

=item $adb->B<remount>

=item $adb->B<reboot>([I<$where>])

=item $adb->B<reboot_bootloader>

=item $adb->B<root>

=item $adb->B<usb>

=item $adb->B<tcpip>(I<$port>)

=item $adb->B<push>(I<$local>, I<$remote>)

=item $adb->B<pull>(I<$remote>, I<$local>)

=item $adb->B<shell>(I<@args>)

Analogues of the respective adb commands.

=item $adb->B<pull_archive>(I<$remote>, I<$local>)

Same as C<adb pull -a $remote $local>.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

Changes in Version 0.002 by Andreas Hadjiprocopis E<lt>bliako@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
