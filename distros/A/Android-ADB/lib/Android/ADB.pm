package Android::ADB;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.001';

use Android::ADB::Device;
use Carp;
use File::Slurp;
use IPC::Open2;

sub new {
	my ($class, %args) = @_;
	$args{path} //= $ENV{ADB};
	$args{path} //= 'adb';
	$args{args} //= [];
	bless \%args, $class
}

sub run {
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

sub start_server { shift->run('start-server') }
sub kill_server  { shift->run('kill-server') }

sub connect      { shift->run('connect', @_) }
sub disconnect   { shift->run('disconnect', @_) }

sub devices      {
	my @devices = split '\n', shift->run('devices', '-l');
	my @result;
	for (@devices) {
		next if /^List of devices/;
		next unless / /;
		push @result, Android::ADB::Device->new(split)
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
	$self->run(push => $remote, $local)
}

sub pull_archive {
	my ($self, $remote, $local) = @_;
	$self->run(push => '-a', $remote, $local)
}

sub shell { shift->run(shell => @_) }

1;
__END__

=encoding utf-8

=head1 NAME

Android::ADB - thin wrapper over the 'adb' command

=head1 SYNOPSIS

  use Android::ADB;;
  my $adb = Android::ADB->new(path => '/opt/android/platform-tools/adb');
  my @devices = $adb->devices;
  $adb->set_device($devices[0]);
  $adb->push('file.txt', '/sdcard/');
  sleep 10;
  $adb->reboot('recovery');

=head1 DESCRIPTION

This module is a minimal wrapper over the Android Debug Bridge
(C<adb>) command for manipulating Android devices.

Methods die on non-zero exit code and return the text printed by the
C<adb> command. The available methods are:

=over

=item Android::ADB->B<new>([I<args>])

Create a new Android::ADB object. The available arguments are C<path>,
the path to the C<adb> executable (defaults to the value of the
environment variable C<ADB> or the string C<adb>) and C<args>, an
arrayref of arguments passed to every adb command (defaults to []).

=item $adb->B<devices>

Returns a list of L<Android::ADB::Device> objects representing
connected devices.

=item $adb->B<set_device>(I<$device>)

Takes an L<Android::ADB::Device> and directs all further commands to
that device by passing C<-s serialno> to every command.

=item $adb->B<run>(I<$command>, [I<@args>])

Run an arbitrary ADB command and return its output.

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

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
