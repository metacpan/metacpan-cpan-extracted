package Dancer::Plugin::Tail;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Dancer ':syntax';
use Dancer::Exception ':all';
use Dancer::Plugin;
use Dancer::Session;
use String::Random;


my $STRRand = String::Random->new;


=head1 NAME

Dancer::Plugin::Tail - Tail a file from Dancer

=head1 VERSION

Version 0.0003

=cut

our $VERSION = '0.0003';

=head1 SYNOPSIS

  use Dancer;
  use Dancer::Plugin::Tail;


=head1 DESCRIPTION

This plugin will allow you to tail a file from within Dancer.  It's designed to be unobtrusive.  So, it is functional just by calling it from your scripts.  Add or remove entries from the configuration file to activate or deactivate files that may be viewed.  The plugin will dynamically generate a route in your application based on parameters from the configuration file.


=head1 CONFIGURATION

  plugins:
    tail:
      interval: 3000
      tmpdir:   '/tmp'
      files:
        id1:    '/var/logs/access_log'
        id2:    '/var/logs/error_log'

You may specify the route and access to files.  The plugin will only read files so it must have read access to them.  The above configuration will generate '/showittome' as a route.  

A sample HTML page is included in the samples directory.  Use it as an example to build your own page.


=cut

# Generate a route based on configuration settings

my $conf  = plugin_setting;

get '/tail/:id/:curr_pos' => sub {

  my $id       = params->{id};            # Id of file
  my $curr_pos = params->{curr_pos} || 0; # Start reading from here

  my $log_file = '';

  if ( defined $conf->{files}->{$id} ) {  # is it predefined?
    $log_file = $conf->{files}->{$id};
  } elsif ( session->{'tail_' . $id} ) {  # is it a temp file?
    $log_file = session->{'tail_' . $id};
  } else {
    send_error('404');
  }

  # Only do it if the file is defined
  if ( $log_file ne '' ) {

    debug "Tail file:$log_file";

    my ($output, $whence);

    open(my $IN, '<', $log_file);         # Open file for reading

    # Add header if it's 1st request
    if ( $curr_pos < 1 ) {
      $output = "$log_file\n";
    }

    # Determine where to start reading
    if ( $curr_pos < 0 ) {
      $whence = 2;                        # Relative to current position
    } else {
      $whence = 1;                        # Absolute current position
    }

    seek( $IN, $curr_pos, $whence );      # Seek the place where we were last
    while ( my $line = <$IN> ) {          # Continue until end
      $output .= $line ;
    }

    my $file_end = tell($IN);             # Figure out the end of the file
    debug "File End: $file_end";
    close($IN);

    # Return JSON
    to_json( { new_curr_pos => $file_end, 
               interval     => $conf->{interval},
               output       => $output } );
  }
};

=head1 C<temp_file_to_tail>

=cut

register temp_file_to_tail => sub {
  my $file_id  = $STRRand->randregex( '[A-Za-z]{16}' ) . time;

  my $log_file = $conf->{tmpdir} . '/' . $file_id ;
  session 'tail_' . $file_id => $log_file;

  return $file_id;
};

register_plugin;

=head1 AUTHOR

Hagop "Jack" Bilemjian, C<< <jck000 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-tail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Tail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Tail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Tail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Tail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Tail>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Tail/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Hagop "Jack" Bilemjian.

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


=head1 SEE ALSO
 
L<Dancer>
 
L<Dancer::Plugin>
 
=cut

1; # End of Dancer::Plugin::Tail





