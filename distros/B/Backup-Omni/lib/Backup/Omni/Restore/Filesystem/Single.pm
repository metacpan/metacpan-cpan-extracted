package Backup::Omni::Restore::Filesystem::Single;

our $VERSION = '0.01';

use Params::Validate ':all';

use Backup::Omni::Class
  version   => $VERSION,
  base      => 'Backup::Omni::Base',
  utils     => 'trim',
  constants => 'OMNIR',
  constant => {
      COMMAND => '%s -filesystem %s:%s "%s" -session %s -tree %s -full -as %s -target %s -no_monitor',
  },
  vars => {
      PARAMS => {
          -host    => 1,
          -session => 1,
          -target  => 1,
          -from    => 1,
          -to      => 1,
          -label   => { optional => 1, default => '/archive' },
          -path    => { optional => 1, default => '/archive' },
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

sub submit {
    my $self = shift;

    my $session = '';
    my $command = sprintf(COMMAND, OMNIR, $self->host, $self->path, $self->label, $self->session, $self->from, $self->to, $self->target);
    my @results = `$command`;
    my $rc = $?;

    unless (grep(/Restore successfully/, @results)) {

        $self->throw_msg(
            'backup.omni.restore.filesystem.single.submit',
            'nosubmit',
            $self->session
        );

    }

    foreach my $line (@results) {

        chomp($line);
        next if ($line eq '');

        if ($line =~ /(R-.*)/) {

            $session = $1;
            last;

        }

    }

    return trim($session);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Backup::Omni::Restore::Filesystem::Single - Restore a single file using a "filesystem object"

=head1 SYNOPSIS

 use Backup::Omni::Session::Result;
 use Backup::Omni::Session::Monitor;
 use Backup::Omni::Utils 'convert_id';
 use Backup::Omni::Session::Filesystem;
 use Backup::Omni::Restore::Filesystem::Single;

 my $session = Backup::Omni::Session::Filesystem->new(
     -host => 'esd189-aix-01',
     -date => '2013-01-10'
 );

 my $restore = Backup::Omni::Restore::Filesystem::Single->new(
     -host    => 'esd189-aix-01',
     -from    => '/archive/pwsipc/pwsipcs.130110_002319.db',
     -to      => '/import01/pwsipc/pwsipcs.130110_002319.db',
     -target  => 'wem-lmgt-02',
     -session => $session->sessionid
 );

 my $temp = $restore->submit;
 my $jobid = convert_id($temp);
 my $monitor = Backup::Omni::Session::Monitor->new(-session => $jobid);

 while ($monitor->running) {

     $device = $monitor->device;
     printf("saveset positon: %s", $device->done);

     sleep(10);

 }

 my $result = Backup::Omni::Session::Result->new(-session => $jobid);
 printf("the restore finished with a status of: %s\n", $result->status);

=head1 DESCRIPTION

This module will restore a single file from a HP DataProtector 
"Filesystem object" using the cli command omnir with the appropiate options. 
The above is a complete script to restore a single file without any error 
checking.

=head1 METHODS

=head2 new

This method will initialize the object. It takes four parameters.
  
=over 4

=item B<-host>

The name of the host that the backup was performed on.

=item B<-session>

The session id of the backup.

=item B<-target>

The target system to restore the file too.

=item B<-from>

The name of the file to restore.

=item B<-to>

The name of the restored file.

=item B<-path> 

The path on the host that was backed up. Defaults to "/archive".

=item B<-label>

The label that was defined for this backup. Defaults to "/archive".

=back

=head2 submit

Submit the restore job to DataProtector. If successful, it will return a
temporary session id, otherwise an exception is thrown.

=head1 SEE ALSO

 Backup::Omni::Base
 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Constants
 Backup::Omni::Exception
 Backup::Omni::Session::Filesystem
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
