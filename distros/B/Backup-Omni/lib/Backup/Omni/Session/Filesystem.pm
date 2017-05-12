package Backup::Omni::Session::Filesystem;

our $VERSION = '0.01';

use Params::Validate ':all';

use Backup::Omni::Class
  version   => $VERSION,
  base      => 'Backup::Omni::Base',
  utils     => 'db2dt omni2dt trim',
  constants => 'OMNIDB',
  constant => {
      COMMAND => '%s -filesystem %s:%s "%s" -detail -since %s -until %s 2>&1',
  },
  vars => {
      PARAMS => {
          -host  => 1,
          -date  => { regex => qr/\d{4}-\d\d-\d\d/ },
          -path  => { optional => 1, default => '/archive' },
          -label => { optional => 1, default => '/archive' },
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

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $date = $self->date . ' 00:00:00';
    my $since = db2dt($date);
    my $until = $since->clone->add(days => 1);

    my $command = sprintf(COMMAND, OMNIDB, $self->host, $self->path, $self->label, $since->ymd('-'), $until->ymd('-'));
    my @result = `$command`;
    my $rc = $?;

    unless (grep(/SessionID/, @result)) {

        $self->throw_msg(
            'backup.omni.session.filesystem',
            'nosession',
            $self->host, $self->date
        );

    }

    foreach my $line (@result) {

        chomp($line);
        next if ($line eq '');

        $line =~ m/^(.*): (.*)/;

        my $key = $1;
        my $value = $2;

        $key = trim($key);
        $key =~ s/ /_/g;
        $key = lc($key);

        $value = trim($value);
        $value = omni2dt($value) if ($value =~ /\w\w\w \d\d \w\w\w \d\d\d\d/);
        
        # order is important here. Don't change

        $self->class->accessors($key);    # may cause redefination errors
        $self->{$key} = $value;

    }

    return $self;

}

1;

__END__

=head1 NAME

Backup::Omni::Session::Filesystem - Return a session object for a given backup

=head1 SYNOPSIS

 use Backup::Omni::Session::Filesystem;

 my $session = Backup::Omni::Session::Filesystem->new(
     -host => 'esd189-aix-01',
     -date => '2013-01-10' 
 );

 printf("session id = %s\n", $session->sessionid);

=head1 DESCRIPTION

This module will return the session object for a given filesystem backup on a 
particular date. It runs the omnidb command with the appropiate options.
If any errors are encounterd, an exception is thrown.

=head1 METHODS

=head2 new

This method will initialze the object. It takes four parameters.

=over 4

=item B<-host>

The name of the host the backup was preformed against.

=item B<-date>

The date the backup was ran. It must be in YYYY-MM-DD format.

=item B<-path>

The path the backup was for. Defaults to '/archive'.

=item B<-label>

The label of the backup. Defaults to '/archive'.

=back

=head2 Session Object

If the session is found an object is returned. That object has the following
methods defined.

=over 4

=item B<sessionid>

This method returns the session id.

=item B<started>

The datetime when the backup started.

=item B<finished>

The datetime when the backup finished.

=item B<object_status>

The status of objec.

=item B<object_size>

The size of the object.

=item B<backup_type>

The type of backup.

=item B<protection>

The protection level of the backup.

=item B<catalog_retention>

The retention period of the backup. It may be the same as the protection.

=item B<version_type>

The version type of the backup.

=item B<access>

The access type of the backup.

=item B<number_of_warnings>

The number of warning generated during this backup.

=item B<number_of_errors>

The number of errors that were generated during this backup.

=item B<device_name>

The name of the device that backup was performed on.

=item B<backup_id>

The id of this backup.

=item B<copy_id>

The copy id of this backup.

=item B<encrypted>

Wither this backup was encrupted.

=back

=head1 SEE ALSO

 Backup::Omni::Base
 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Constants
 Backup::Omni::Exception
 Backup::Omni::Restore::Filesystem::Single
 Backup::Omni::Session::Messages
 Backup::Omni::Session::Monitor
 Backup::Omni::Session::Results

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
