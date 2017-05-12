package Dancer::Logger::Hourlyfile;

use strict;
use warnings;

use Carp;
use base 'Dancer::Logger::Abstract';
use Dancer::FileUtils qw(open_file);
use Dancer::Config 'setting';
use IO::File;
use File::Path qw(make_path);
use POSIX qw/strftime/;

our $VERSION = '0.07';

sub init {
  my $self = shift;
  $self->SUPER::init(@_);

# Grab Settings
  $self->{log_path}   = setting('log_path') . '/';
  $self->{log_fname}  = setting('log_file') . '.log' || setting('environment') . '.log';
  $self->{log_file}   = $self->{log_fname};
  $self->{log_hourly} = setting('log_hourly') || "filename";

  my $log_time = setting('log_time');
  if ( $log_time eq 'gmtime' ) {
    $self->{log_time} = 'gmtime';
  } else {
    $self->{log_time} = 'localtime';
  }

}


sub _log {
  my ( $self, $level, $message ) = @_;

  # Check or set fh
  $self->_setfh;

  my $fh  = $self->{fh};

  $fh->print( $self->format_message( $level => $message ) )
    or carp "writing logs to file $self->{logfile} failed: $!";
}


sub _setfh {
  my $self = shift;
 
  my $test_fh      = $self->{fh};
  my $current_time = undef;
  my $path_time    = undef;
  my $file_time    = undef;


  if ( $self->{log_time} eq 'gmt' ) {
    $current_time = POSIX::strftime( "%Y-%m-%d-%H", gmtime    ) ;
    $path_time    = POSIX::strftime( "%Y/%m/%d/",   gmtime    ) ;
    $file_time    = POSIX::strftime( "%Y%m%d%H_",   gmtime    ) ;
  } else {
    $current_time = POSIX::strftime( "%Y-%m-%d-%H", localtime ) ;
    $path_time    = POSIX::strftime( "%Y/%m/%d/",   localtime ) ;
    $file_time    = POSIX::strftime( "%Y%m%d%H_",   localtime ) ;
  }

  # Return if fh is good
  if ( ref $test_fh && $test_fh->opened ) {  # fh exists and is open
    return ;
  }

  # Date hasn't changed
  if ( exists $self->{log_current} && $self->{log_current} eq $current_time ) {
    return ;
  }

  # if here, then fh is no good.  Clean it up
  close($test_fh) if ( ref $test_fh );;

  $self->{log_current} = $current_time;    # reset tracking of time change
  $self->{log_file}    = $self->{log_path} ;

  # YYYY/MM/DD to path if extended
  if ( $self->{log_hourly} eq 'extended' ) {
    $self->{log_path} .= $path_time ;
  }

  # Make sure path exists
  make_path( $self->{log_path} );

  # finish building filename
  $self->{log_file}   = $self->{log_path} . $file_time . $self->{log_fname};

  # get a new fh
  open( my $fh, '>>', $self->{log_file} )
    || croak "Unable to open $self->{log_file}: $!";

  $fh->autoflush(1);

  # store fh for later use
  $self->{fh} = $fh;

}

1;
__END__

=pod

=head1 NAME

Dancer::Logger::Hourlyfile - Rotate writing to log files on an hourly basis


=head1 DESCRIPTION

This module will write log entries to a separate file every hour.  Like an automated logrotate.  It will append YYYYMMDDHH to each hourly logfile name.  Specify local time or GMT time.  Finally, use the "extended" filename setting to further breakdown by writing into subdirectories YYYY/MM/DD/

  filename:

      log/2014052019_filename.log
      ^^^ ^^^^^^^^^^ ^^^^^^^^
      |   YYYYMMDDHH Filename 
      Path

              
  extended:

      log/2014/05/20/2014052019_filename.log
      |              ^^^^^^^^^^ ^^^^^^^^
      Path           YYYYMMDDHH Filename 


=head1 CONFIGURATION SETTINGS

In your Dancer's environment file set the following:

  logger:     "hourlyfile"   # tell Dancer to use this module
  log_path:   "/var/log"     # full path
  log_hourly: "filename"     # defaults to "filename" if not specified.
                             # The only other option is "extended"
  log_file:   "outputfile"   # file name
  log_time:   "local"        # defaults to "local" if not specified.  
                               The only other option is "gmt" 


=head1 SAMPLE CONFIGURATION

=over 4

=head2 filename(default)


    logger:     "hourlyfile"
    log:        "core"
    log_path:   "/var/mydancerapp/logs"
    log_file:   "myserver"
    log_time:   "gmt"
    log_hourly: "filename"

  This configuration will produce the following files where the times are GMT:

    /var/mydancerapp/logs/2014052000_myserver.log
    /var/mydancerapp/logs/2014052001_myserver.log
    ...
    ...
    ...
    /var/mydancerapp/logs/2014052023_myserver.log


=head2 Extended 


    logger:     "hourlyfile"
    log:        "core"
    log_path:   "/var/mydancerapp/logs"
    log_file:   "myserver"
    log_time:   "gmt"
    log_hourly: "extended"

  This configuration will produce the following files where the times are GMT:

    /var/mydancerapp/logs/2014/05/20/2014052000_myserver.log
    /var/mydancerapp/logs/2014/05/20/2014052001_myserver.log
    ...
    ...
    ...
    /var/mydancerapp/logs/2014/05/20/2014052023_myserver.log



=head1 AUTHOR

Hagop "Jack" Bilemjian, C<< <jck000 at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-logger-rotatehourly at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Logger-Hourlyfile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Logger::Hourlyfile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Logger-Hourlyfile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Logger-Hourlyfile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Logger-Hourlyfile>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Logger-Hourlyfile/>




=head1 ACKNOWLEDGEMENTS

Dancer!  


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Hagop "Jack" Bilemjian.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Dancer::Logger:::Hourlyfile
