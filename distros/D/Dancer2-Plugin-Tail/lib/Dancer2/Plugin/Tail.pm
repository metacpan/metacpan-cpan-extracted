package Dancer2::Plugin::Tail;

use Dancer2::Core::Types qw(Bool HashRef Str);
use Dancer2::Plugin;

use Carp;
use Session::Token;

=head1 NAME

Dancer2::Plugin::Tail - Tail a file from Dancer2


=head1 VERSION

Version 0.016

=cut

our $VERSION = '0.016';


=head1 SYNOPSIS

  use Dancer2;
  use Dancer2::Plugin::Tail;


=head1 DESCRIPTION

This plugin will allow you to tail a file from within Dancer2.  It's designed to be unobtrusive.  So, it is functional just by calling it from your scripts.  Edit entries in the Dancer configuration to setup routes and activate files that may be tailed.  Additionally, you may define or restrict definition of tailed files.


=head1 CONFIGURATION

You may specify the route to files.  The plugin will only read files so Dancer2 must have read access to them.  The following configuration will generate two routes: '/tail/display' and '/tail/read'.  

A sample HTML page with Bootstrap and jQuery is included in the samples directory.  Use it as an example to build your own page.

  plugins:
    Tail:
      update_interval: 3000
      stop_on_empty_cnt: 5
      tmpdir:          '/tmp'
      display:
        method:    'get'
        url:       '/tail/display'
        template:  'tail.tt'
        layout:    'nomenu.tt'
      data:
        method:    'get'
        url:       '/tail/read'
      files:
        id1:    
          heading: 'Server Access Log'
          file:    '/var/logs/access_log'
        id2:    
          heading: 'Server Error Log'
          file:    '/var/logs/error_log'

=over 

=item I<update_interval>

Specify an update interval.  Default is 3 seconds (3000).  This value is passed to your web page or window.  See example that's included.


=item I<stop_on_empty_cnt>

Specify the number of empty responses before stopping.  Default is 10.  This value is passed to your web page or window.  See example that's included.


=item I<tmpdir>

location of user generted files to tail.  Default is '/tmp'.


=item I<display>

Defines display settings.

=over 4

=item I<method>

Default 'get'.


=item I<url>

Route in Dancer2 to display template for tailing.  
Default = '/tail/display'


=item I<template>

Template of tail screen. 
Default = 'tail.tt'


=item I<layout>

Layout of template.  This is useful when opening a window to tail files.

=back

=item I<data>

Defines file tail settings.

=over 4

=item I<method>

Default 'get'.


=item I<url>

Route in Dancer2 to tail files.  
Default = '/tail/read'

=back

=item I<files>

List of predefined files that can be tailed.

=over 4

=item I<ID>

Define a unique ID for this file

=over 4

=item I<heading>

This is a heading or title of the html page to be passed to the template.  Use it as a short description to the file you're taiing.


=item I<file>

Full path and file name to tail.

=back 

B<Note> that you B<must> have a session provider configured to dynamically tail files using this plugin.  This plugin requires sessions in order to track information about user defined tailed files for the logged in user.
Please see L<Dancer2::Core::Session> for information on how to configure session management within your application.

=back

=back

=head1 display_tail 

This function displays the specified template with the data from the configuration file.


=head1 define_file_to_tail

A function called to dynamically define a file to tail.  This is useful for launching long running applications and having their out put tailed.  In general, this will generate a 32 character string that you should use to direct the output of your process.  Then, Dancer2::Plugin::Tail will tail the content of this file.


=head1 _tail_the_file

This private function does the actual job of tailing the file.



=head1 _new_file_id
  
An internal functio that returns a 32 character string when called from define_file_to_tail.


=cut 

#
# Accessors
#
has update_interval => (
  is          => 'ro',
  isa         => Str,
  from_config => 1,
  default     => sub { '3000' },    # 3 second interval
);

has stop_on_empty_cnt => (
  is          => 'ro',
  isa         => Str,
  from_config => 1,
  default     => sub { '10' },    # 10 Empty or 30 secs i
                                  #  (update_interval * stop_on_empty_cnt) = 30
);

has data_method => (
  is          => 'ro',
  isa         => Str,
  from_config => 'data.method',
  default     => sub { 'get' }
);

has data_url => (
  is          => 'ro',
  isa         => Str,
  from_config => 'data.url',
  default     => sub { '/tail/read' }
);

has display_method => (
  is          => 'ro',
  isa         => Str,
  from_config => 'display.method',
  default     => sub { 'get' }
);

has display_url => (
  is          => 'ro',
  isa         => Str,
  from_config => 'display.url',
  default     => sub { '/tail/display' },
);

has display_template => (
  is          => 'ro',
  isa         => Str,
  from_config => 'display.template',
  default     => sub { 'tail.tt' },
);

has display_layout => (
  is          => 'ro',
  isa         => Str,
  from_config => 'display.layout',
  default     => sub { '' },
);

has tmpdir => (
  is          => 'ro',
  isa         => Str,
  from_config => 1,
  default     => sub { '/tmp' },    # write to /tmp
);

has files => (
  is          => 'ro',
  isa         => HashRef,
  from_config => 1,
  default     => sub { {} },    # Empty
);

sub _new_file_id {
  Session::Token->new( length => 32 )->get;
}

# Generate routes based on configuration settings
sub BUILD {
  my $plugin = shift;
  my $app    = $plugin->app;

  # Setup route to display a template for the tail
  my $disp_method   = $plugin->display_method;
  my $disp_url      = $plugin->display_url;

  $plugin->app->log( debug => "Adding Route ");
  $plugin->app->log( debug => "      Method " . $disp_method);
  $plugin->app->log( debug => "      Regexp " . $disp_url);
  $plugin->app->add_route(
    method => $disp_method,
    regexp => qr!$disp_url!,
    code   => \&display_tail,
  );

  # Setup a route to return json data of the file
  my $data_url    = $plugin->data_url;
  my $data_method = $plugin->data_method;

  $plugin->app->log( debug => "Adding Route ");
  $plugin->app->log( debug => "      Method " . $data_method);
  $plugin->app->log( debug => "      Regexp " . $data_url);

  # Use regexp to match part of the file, then splat inside code
  $plugin->app->add_route(
    method => $data_method,
    regexp => qr!^$data_url!,
    code   => \&_tail_the_file,
  );

}    ### BUILD


# Function to display template
sub display_tail {
  my $app     = shift;
  my $plugin  = $app->with_plugin('Tail');

  my $error   = undef;
  my $params  = $app->request->params;

  $plugin->app->log( debug => "Params:");
  $plugin->app->log( debug => $params );

  my $tail_file_id = $params->{'tail_file_id'};        ### ID in config
  my $curr_pos     = $params->{'curr_pos'} || 0;    ### Current position to read from

  my $tail_id      = 'tail-' . $tail_file_id;  ### ID from session

  my $file         = undef;
  my $tail_file    = undef;
  my $tail_heading = undef;
  my $files        = $plugin->files;

  $plugin->app->log( debug => "Files:" );
  $plugin->app->log( debug => $files );
  $plugin->app->log( debug => "File id:" . $tail_file_id );
  $plugin->app->log( debug => "tail id:" . $tail_id );
  $plugin->app->log( debug => "if "      . $files->{$tail_file_id} );
  $plugin->app->log( debug => "file:"    . $files->{$tail_file_id}->{file} );
  $plugin->app->log( debug => "heading"  . $files->{$tail_file_id}->{heading} );

  # Predefined
  if ( $files->{$tail_file_id} ) {
    $plugin->app->log( debug => "Predefined file_id=" . $tail_file_id );
    $tail_file    = $files->{$tail_file_id}->{file} ;
    $tail_heading = $files->{$tail_file_id}->{heading};

  # User defined
  } else {
    $plugin->app->log( debug => "User defined tail_id=" . $tail_id );
    my $file      = $plugin->app->session->read($tail_id); 
    $tail_file    = $file->{file};
    $tail_heading = $file->{heading};
  }

  if (    ! defined $tail_file 
       || $tail_file eq '' ) {
    $plugin->app->log( debug => "file id " . $file_id . " is not defined." );
    $error = 'The file-id you specified does not exist.' ;
  } 

  $app->template($plugin->display_template, 
                  { tail_file_id      => $tail_file_id,
                    curr_pos          => $curr_pos,
                    heading           => $tail_heading,
                    data_method       => $plugin->data_method,    
                    data_url          => $plugin->data_url,
                    update_interval   => $plugin->update_interval,
                    stop_on_empty_cnt => $plugin->stop_on_empty_cnt,
                    error             => $error },
                  { layout            => $plugin->display_layout }) ;
}              

# Function for a user to dynamically define a file 
sub define_file_to_tail {
  my ( $plugin, $tail ) = @_;

  my $file_id = _new_file_id();  # Create a new file id

  $tail->{heading} = ' '  if ( ! defined $tail->{heading} );
  if ( ! defined $tail->{file} ) { 
    $tail->{file} = $plugin->tmpdir . '/' . $file_id ;
  } else {
    if ( ! -e $tail->{file} ) {
      open( my $touchfile, ">>", $tail->{file} ) ;
      print $touchfile " ";
      close($touchfile);
    }
  }

  my $tail_id = 'tail-' . $file_id ;

  # Store the file name into session
  $plugin->app->session->write( $tail_id => $tail );

  return $file_id;
}

# Function to tail a file
sub _tail_the_file {
  my $app      = shift;
  my $plugin   = $app->with_plugin('Tail');

  $plugin->app->log( debug => "In _tail_the_file " );

  my $params  = $app->request->params;

  my $tail_file_id = $params->{'tail_file_id'};
  my $curr_pos     = $params->{'curr_pos'};

  my $tail_id      = 'tail-' . $tail_file_id ;

  my $files        = $plugin->files;
  my $file         = undef;
  my $tail_file    = undef;
  my $tail_heading = undef;

  $plugin->app->log( debug => "files " );
  $plugin->app->log( debug => $files );

  # Predefined
  if ( $files->{$tail_file_id} ) {
    $plugin->app->log( debug => "Predefined " . $tail_file_id );
    $tail_file    = $files->{$tail_file_id}->{file} ;
    $tail_heading = $files->{$tail_file_id}->{heading};

  # User defined
  } else {
    $plugin->app->log( debug => "User defined " . $tail_id );
    my $file      = $plugin->app->session->read($tail_id); 
    $tail_file    = $file->{file};
    $tail_heading = $file->{heading};
  }

  $plugin->app->log( debug => "File to tail is " . $tail_file );
  if (    $tail_file  
       && -e $tail_file ) {

    my ($output, $whence);

    open(my $IN, '<', $tail_file);  # Open file for reading

    # Add header if it's 1st request
    if ( $curr_pos < 1 ) {
      $output = "$tail_file\n";
    }

    # Determine where to start reading
    if ( $curr_pos < 0 ) {
      $whence = 2; # Relative to current position
    } else {
      $whence = 1; # Absolute current position
    }

    seek( $IN, $curr_pos, $whence ); # Seek the place 
                                                          # where we were last
    while ( my $line = <$IN> ) {     # Continue until end
      $output .= $line ;
    }

    my $file_end = tell($IN);   # Figure out the end of the file
    close($IN);
    $plugin->app->log( debug => "Returning JSON:" );
    $plugin->app->log( debug => "new_curr_pos " . $file_end);
    $plugin->app->log( debug => "interval     " . $plugin->update_interval);
    $plugin->app->log( debug => "output       " . $output );


    # Return JSON
    $app->send_as( JSON => { new_curr_pos => $file_end, 
                             interval     => $plugin->update_interval,
                             output       => $output } );

  } else {  ### if -e
    $plugin->app->log( debug => "No file to tail or file does not exist " . $tail_file );

  }
}    

# setup keywords
plugin_keywords qw( define_file_to_tail );

=head1 AUTHOR

Hagop "Jack" Bilemjian, C<< <jck000 at gmail.com> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Tail


You can also look for information at:

=over 

=item * Report bugs on github

L<https://github.com/jck000/Dancer2-Plugin-Tail/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-Tail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-Tail>

=item * Search metaCPAN

L<https://metacpan.org/pod/Dancer2::Plugin::Tail/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Hagop "Jack" Bilemjian.

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
 
L<Dancer2>
 
L<Dancer2::Plugin>
 
=cut

1; # End of Dancer2::Plugin::Tail

