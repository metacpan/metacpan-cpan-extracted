package Backup::Omni::Session::Monitor;

our $VERSION = '0.01';

use Params::Validate ':all';

use Backup::Omni::Class
  version   => $VERSION,
  base      => 'Backup::Omni::Base',
  utils     => 'omni2dt trim',
  constants => 'OMNISTAT',
  constant => {
      RUNNING => '%s -session %s -status_only 2> /dev/null',
      COMMAND => '%s -session %s -detail 2> /dev/null',
  },
  vars => {
      PARAMS => {
          -session => 1,
      }
  }
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        Backup::Omni::Base::validation_exception($params, $class);
    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub running {
    my $self = shift;

    my $stat = 0;
    my $command = sprintf(RUNNING, OMNISTAT, $self->session);

    my @result = `$command`;
    my $rc = $?;

    if ((grep(/SessionID/, @result)) && ($rc == 0)) {

        $stat = 1;

    }

    return $stat;

}

sub object {
    my $self = shift;

    my $started = 0;
    my $obj = undef;
    my $command = sprintf(COMMAND, OMNISTAT, $self->session);

    my @result = `$command`;
    my $rc = $?;
    
    if ((grep(/Object name/, @result)) && ($rc == 0)) {

        $obj = Backup::Omni::Session::Monitor::Object->new();

        foreach my $line (@result) {

            chomp($line);
            next if ($line eq '');

            if ($line =~ /Object name/) {

                $started = 1;
                $self->_parse_line($obj, $line);

            } else {

                if ($started) {

                    if ($line =~ /Device name/) {

                        $started = 0;
                        last;

                    }

                    $self->_parse_line($obj, $line);

                }

            }

        }

    }

    return $obj;

}

sub device {
    my $self = shift;

    my $started = 0;
    my $obj = undef;
    my $command = sprintf(COMMAND, OMNISTAT, $self->session);

    my @result = `$command`;
    my $rc = $?;

    if ((grep(/Object name/, @result)) && ($rc == 0)) {

        $obj = Backup::Omni::Session::Monitor::Device->new();

        foreach my $line (@result) {

            chomp($line);
            next if ($line eq '');

            if ($line =~ /Device name/) {

                $started = 1;
                $self->_parse_line($obj, $line);

            } else {

                if ($started) {

                    if ($line =~ /Object name/) {

                        $started = 0;
                        last;

                    }

                    $self->_parse_line($obj, $line);

                }

            }

        }

    }

    return $obj;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _parse_line {
    my $self = shift;
    my $obj  = shift;
    my $line = shift;

    $line =~ m/^(.*): (.*)/;

    my $key = $1;
    my $value = $2;

    $key = trim($key);
    $key =~ s/ /_/g;
    $key = lc($key);

    $value = trim($value);
    $value = omni2dt($value) if ($value =~ /\w\w\w \d\d \w\w\w \d\d\d\d/);

    # order is important here. Don't change

    $obj->class->accessors($key);    # may cause redefination errors
    $obj->{$key} = $value;

}

# the following are stubs, they are filled out above in _parse_line().

package Backup::Omni::Session::Monitor::Device;

use Backup::Omni::Class
  version => '0.01',
  base    => 'Backup::Omni::Base',
;

package Backup::Omni::Session::Monitor::Object;

use Backup::Omni::Class
  version => '0.01',
  base    => 'Backup::Omni::Base',
;

1;

__END__

=head1 NAME

Backup::Omni::Session::Monitor - Monitor a running session

=head1 SYNOPSIS

 use Backup::Omni::Session::Monitor;

 my $monitor = Backup::Omni::Session::Monitor->new(
     -session => '2013/01/25-40'
 );

 while ($monitor->running) {

     $device = monitor->device;
     printf("saveset position: %s", $device->done);

     sleep(10);

 }

 printf("session done\n");

=head1 DESCRIPTION

This module will monitor and return information from a running session. 
It runs the omnistat command with the appropiate options. If any errors are 
encounterd, an exception is thrown.

=head1 METHODS

=head2 new

This method will initialze the object. It takes one parameter.

=over 4

=item B<-session>

The session id to monitor.

=back

=head2 running

This method returns true if the session is "running".

=head2 device

The method returns a Backup::Omni::Session::Monitor::Device object. If the
session has finished "running" it will return undef. See L<Backup::Omni::Session::Result>
to see how to get the results. This object has the following methods:

=over 4

=item B<device_name>

The device this session is running on.

=item B<host>

The host the session is running on.

=item B<started>

The session started using the device.

=item B<finished>

The time the session finished using the device or a '-'.

=item B<done>

The number of bytes read from the device.

=item B<physical_device>

The actual physical device that is being used.

=item B<status>

The status of the device.

=back

=head2 object

The method returns a Backup::Omni::Session::Monitor::Object object. If the
session has finished "running" it will return undef. See L<Backup::Omni::Session::Result>
to see how to get the results. This object has the following methods:

=over 4

=item B<object_name>

The name of the session object.

=item B<object_type>

The object type.

=item B<sessionid>

The original session id for this object.

=item B<restore_started>

The datetime the restore started.

=item B<backup_started>

The datetime the backup started.

=item B<level>

The objects level.

=item B<warnings>

The number of warnings for this object.

=item B<errors>

The number of errors for this object.

=item B<processed_size>

The processed size of this object.

=item B<device>

The device this object is using.

=item B<status>

The status of the object.

=back

=head1 SEE ALSO

 Backup::Omni::Base
 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Constants
 Backup::Omni::Exception
 Backup::Omni::Restore::Filesystem::Single
 Backup::Omni::Session::Filesystem
 Backup::Omni::Session::Messages
 Backup::Omni::Session::Results

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
