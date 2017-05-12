package Dancer2::Plugin::EditFile;

use warnings;
use strict;
use Carp;
use File::Copy "cp";
use File::Basename;
use Try::Tiny;

use Dancer2::Core::Types qw(Bool HashRef Str);
use Dancer2::Plugin;

=head1 NAME

Dancer2::Plugin::EditFile - Edit a text file from Dancer2


=head1 VERSION

Version 0.005


=cut

our $VERSION = '0.005';

=head1 SYNOPSIS

  use Dancer2;
  use Dancer2::Plugin::EditFile;


=head1 DESCRIPTION

This plugin will allow you to retrieve a text file using Dancer2 and display it in an html page.  Also, it will save the edited file to it's location on the server.  

It's designed to be flexible and unobtrusive.  It's behavior is customizable through Dancer's config file.  ration file to activate or deactivate files that may be edited.  Just include it in your Dancer2 script, set the configuration and use it.

B<NOTES:>  

=over 4

B<It is your responsibility to set security.  So, be careful!!!>

There is a sample template in the sample folder.

=back

=head1 CONFIGURATION

You may specify the routes and access to files.  The plugin will only read/write files if it has access to them.  The following configuration will generate two routes: '/editfile/display' and '/editfile/save'.  

A sample HTML page with Bootstrap and jQuery is included in the samples directory.  Use it as an example  to build your own page.

  plugins:
    EditFile:
      backup:     1
      backup_dir: '/var/application/backups'
      display:
        method:    'get'
        route:     '/editfile/display'
        template:  'editfile.tt'
        layout:    'nomenu.tt'
      save:
        method:    'get'
        route:     '/editfile/save'
      files:
        id1:      
          heading: 'Edit Config.yml'
          file:    '/var/application/config.yml'
          save:    1
        id2:      
          heading:  'View config script config2'
          file:    '/var/application/config2.txt'
          save:    0
        id3:      
          heading: 'View XML file config3.xml'
          file:    '/var/application/config3.xml'
          save:    0
      
=over 4

B<Note> the  user B<must> have read/write access to the file being edited and the backup directory.  

=back 

=over 4

=item I<backup>

Specify if original file should be saved.  Default = 0 (do not save)

=item I<backup_dir>

Directory where original files should be saved.  Default = /tmp

=item I<display>

Defines display settings.

=over 4

=item I<method>

Default 'get'.

=item I<route>

Route in Dancer to display template and file contents for editing/viewing.  Default '/editfile/display'

=item I<template>

Template cotaining edit/view form.  Default 'editfile.tt'

=item I<layout>

Layout of template.  This is useful when opening a window to edit/view files.

=back

=item I<Save>

=over 4

=item I<method>

Default 'get'.

=item I<route>

=back 

=item I<files>

List of predefined files that may be edited/viewed.

=over 4

=item I<file ids>

A unique identifier for this file.  It's used as part of the route to identify this file.

=item I<heading>

This is a heading to be passed to the template.  Use it as a short description to the file you're editing/viewing.

=item I<file>

The file name on the drive.

=item I<save>

Specifies if file may be saved.  Default = 0 (view only)

=back 

=cut 

#
# Accessors
#
has backup => (
  is          => 'ro',
  isa         => Bool,
  from_config => 1,
  default     => sub { 0 }
);

has backup_dir => (
  is          => 'ro',
  isa         => Str,
  from_config => 1,
  default     => sub { '/tmp' }
);

has display_method => (
  is          => 'ro',
  isa         => Str,
  from_config => 'display.method',
  default     => sub { 'get' }
);

has display_route => (
  is          => 'ro',
  isa         => Str,
  from_config => 'display.route',
  default     => sub { '/editfile/display' },
);

has display_template => (
  is          => 'ro',
  isa         => Str,
  from_config => 'display.template',
  default     => sub { 'editfile.tt' },
);

has display_layout => (
  is          => 'ro',
  isa         => Str,
  from_config => 'display.layout',
  default     => sub { '' },
);

has save_method => (
  is          => 'ro',
  isa         => Str,
  from_config => 'save.method',
  default     => sub { 'get' }
);

has save_route => (
  is          => 'ro',
  isa         => Str,
  from_config => 'save.route',
  default     => sub { '/editfile/save' }
);

has files => (
  is          => 'ro',
  isa         => HashRef,
  from_config => 1,
  default     => sub { {} },    # Empty
);

# Generate routes based on configuration settings
sub BUILD {
  my $plugin = shift;
  my $app    = $plugin->app;

  # Setup route to display a template for the edit/view
  my $disp_method   = $plugin->display_method;
  my $disp_route    = $plugin->display_route;

  $plugin->app->add_route(
    method => $disp_method,
    regexp => qr!$disp_route!,
    code   => \&display_editfile,
  );

  # Setup a route to return json data of the file
  my $save_route  = $plugin->save_route;
  my $save_method = $plugin->save_method;

  # Use regexp to match part of the file, then splat inside code
  $plugin->app->add_route(
    method => $save_method,
    regexp => qr!^$save_route!,
    code   => \&save_editfile,
  );

}    ### BUILD

# Function to display template
sub display_editfile {
  my $app    = shift;
  my $plugin = $app->with_plugin('EditFile');

  my $file_id = $app->request->params->{id};
  my $files   = $plugin->files;

  croak "The specified id: $file_id is not properly defined in your configuration."
    if (    ! $files->{$file_id}->{file} 
         || ! -f $files->{$file_id}->{file} );

  #
  # Expecting reasonably sized text files to edit.  Like configuration files.
  #

  # Slurp file
  local $/;
  open ( my $EDITFILE_IN, "<", $files->{$file_id}->{file} ) ;
  my $editfile = <$EDITFILE_IN>;
  close($EDITFILE_IN);

  $app->template($plugin->display_template, 
                  { id          => $file_id,
                    title       => $files->{$file_id}->{heading},
                    editfile    => $editfile,
                    save_route  => $plugin->save_route,
                    save_method => $plugin->save_method,
                    save        => $files->{$file_id}->{save} },
                  { layout   => $plugin->display_layout }) ;
}              


sub save_editfile {
  my $app    = shift;
  my $plugin = $app->with_plugin('EditFile');

  my $status_message = "";

  my $file_id    = $app->request->params->{id};
  my $editedfile = $app->request->params->{editfile};
  my $files      = $plugin->files;

  if ( ! $files->{$file_id}->{file} ) {
    $status_message = "The specified id: $file_id is not properly defined in your configuration.";
  
  } elsif ( $plugin->{backup} && $plugin->{backup_dir} ) { 
    if ( -d $plugin->{backup_dir} ) {

      my $basename        = basename( $files->{$file_id}->{file} );
      my $backup_filename = $plugin->{backup_dir} 
                          . '/' 
                          . $basename 
                          . '.' 
                          . time;
       
      eval {
        copy($basename, $backup_filename);
      };
      if ( $@ ) {
        $status_message = "Could not save backup";
      } 

    }
  }

  # Write it if there are no errors
  if ( $status_message eq '' ) { 
    eval { 
      open ( my $EDITFILE_OUT, ">", $files->{$file_id}->{file} ) ;
      print $EDITFILE_OUT $editedfile;
      close($EDITFILE_OUT);
    };
    if ( $@ ) {
      $status_message = "Could not write changes to file.";
    }
  }
  
  $app->send_as( JSON => { save_message => $status_message } );
}

=back


=head1 AUTHOR

Hagop "Jack" Bilemjian, C<< <jck000 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-editfile at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-EditFile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::EditFile


You can also look for information at:

=over 4


=item * RT: CPAN's request tracker (report bugs here)

L<https://github.com/jck000/Dancer2-Plugin-EditFile/issues>


=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-EditFile>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-EditFile>


=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-EditFile/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2017 Hagop "Jack" Bilemjian.

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

1; # End of Dancer2::Plugin::EditFile


