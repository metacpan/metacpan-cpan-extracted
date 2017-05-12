
package Apache2::ASP::MediaManager;

use strict;
use base 'Apache2::ASP::UploadHandler';
use MIME::Types;
use IO::File;

my $mimetypes = MIME::Types->new();


#==============================================================================
sub run
{
  my ($s, $context) = @_;
  
  shift(@_);
	
	my $mode = $context->request->Form->{mode};
	
	return unless ( ! $mode ) || ( $mode !~ m/^(create|edit)$/ );
	
  my $filename = $s->compose_download_file_path( $context );
  my $file = $s->compose_download_file_name( $context );
  
  # Find its MIME type and set our 'ContentType' value:
  my $ext;
  unless( $mode )
  {
    # Find its MIME type and set our 'ContentType' value:
    ($ext) = $file =~ m/.*?\.([^\.]+)$/;
    my $type = $ext ? $mimetypes->mimeTypeOf( $ext ) || 'application/octet-stream' : 'application/octet-stream';
    $context->response->ContentType( $type );
  }# end unless()
  
  # Call our extension hooks:
  if( $mode )
  {
    if( $mode eq 'delete' )
    {
      $s->before_delete( $context, $filename )
        or return;
      $s->delete_file( $context, $filename );
      return $s->after_delete( $context, $filename );
    }
    elsif( defined(my $handler = $s->modes( $mode )) )
    {
      return $handler->( $s, $context );
    }# end if()
  }# end if()
  
  # Get the readable filehandle:
  unless( -f $filename )
  {
    $context->response->Status( 404 );
    return;
  }# end unless()
  
  # Call our before- hook:
  $s->before_download( $context, $filename )
    or return;
  
  # Wait until "before_download" has cleared before we open a filehandle:
  my $ifh = $s->open_file_for_reading( $context, $filename );
  
  # Send any HTTP headers:
  $s->send_http_headers($context, $filename, $file, $ext);
  
  # Print the file out:
  if( (stat($ifh))[7] < 1024 ** 2 )
  {
    # File is < 1M, so just slurp and print:
    local $/;
    $context->response->Write( scalar(<$ifh>) );
  }
  else
  {
    while( my $line = <$ifh> )
    {
      $context->response->Write( $line );
    }# end while()
  }# end while()
  $context->response->Flush;
  
  # Done!
  $ifh->close;
  
  # Call our after- hook:
  $s->after_download( $context, $filename );
}# end run()


#==============================================================================
sub send_http_headers
{
  my ($s, $context, $filename, $file, $ext) = @_;
  
  # Send the 'content-length' header:
  $context->r->err_headers_out->{'Content-Length'} = (stat($filename))[7];
  
  # PDF files should force the "Save file as..." dialog:
  my $disposition = (lc($ext) eq 'pdf') ? 'attachment' : 'inline';
  $file =~ s/\s/_/g;
  
  $context->r->err_headers_out->{'content-disposition'} = "$disposition;filename=" . $file . ';yay=yay';
}# end send_http_headers()


#==============================================================================
sub delete_file
{
  my ($s, $context, $filename) = @_;
  
  die "'$filename' is a directory, not a file" if -d $filename;
  return unless -f $filename;
  unlink( $filename )
    or die "Cannot delete file '$filename' from disk: $!";
}# end delete_file()


#==============================================================================
sub open_file_for_writing
{
  my ($s, $context, $filename) = @_;
  
  # Try to open the file for writing:
  my $ofh = IO::File->new();
  $ofh->open($filename, '>' )
    or die "Cannot open file '$filename' for writing: $!";
  $ofh->binmode;
  $ofh->autoflush(1);
  
  return $ofh;
}# end open_file_for_writing()


#==============================================================================
sub open_file_for_reading
{
  my ($s, $context, $filename) = @_;
  
  # Try to open the file for reading:
  my $ifh = IO::File->new();
  $ifh->open($filename, '<' )
    or die "Cannot open file '$filename' for reading: $!";
  $ifh->binmode;
  
  return $ifh;
}# end open_file_for_reading()


#==============================================================================
sub open_file_for_appending
{
  my ($s, $context, $filename) = @_;
  
  # Try to open the file for appending:
  my $ofh = IO::File->new();
  $ofh->open($filename, '>>' )
    or die "Cannot open file '$filename' for appending: $!";
  $ofh->binmode;
  $ofh->autoflush(1);
  
  return $ofh;
}# end open_file_for_appending()


#==============================================================================
sub compose_download_file_path
{
  my ($s, $context) = @_;
  
  # Compose the local filename:
  my $file = $context->request->Form->{file};
  my $filename = $context->config->web->media_manager_upload_root . '/' . $file;
  
  return $filename;
}# end compose_file_path()


#==============================================================================
sub compose_download_file_name
{
  my ($s, $context) = @_;
  
  # Compose the local filename:
  my $file = $context->request->Form->{file};
  
  return $file;
}# end compose_file_name()


#==============================================================================
sub compose_upload_file_name
{
  my ($s, $context, $Upload) = @_;
  
#  my $filename = $Upload;
  my ($filename) = $Upload->{upload}->{upload_filename} =~ m/.*[\\\/]([^\/\\]+)$/;
  if( ! $filename )
  {
    $filename = $Upload->{upload}->{upload_filename};
  }# end if()
  
  return $filename;
}# end compose_upload_file_name()


#==============================================================================
sub compose_upload_file_path
{
  my ($s, $context, $Upload, $filename) = @_;
  
  unless( defined($filename) && length($filename) )
  {
    die "\$filename not provided";
  }# end unless()
  
  return $context->config->web->media_manager_upload_root . "/$filename";
}# end compose_upload_file_path()


#==============================================================================
sub upload_start
{
  my ($s, $context, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_start( $context, $Upload );

  my $filename = $s->compose_upload_file_name( @_ );
  
  # Make sure we can open the file for writing:
  my $target_file = $s->compose_upload_file_path( $context, $Upload, $filename);
  
  # Open the file for writing:
  my $ofh = $s->open_file_for_writing($context, $target_file);
  print $ofh delete($Upload->{data});
  
  # Done with the filehandle:
  $ofh->close;
  
  # Store some information for later:
  $ENV{filename} ||= $target_file;
  $ENV{download_file} ||= $filename;
  
  # Depending on the 'mode' parameter, we do different things:
  local $_ = $s->_args('mode');
  if( /^create$/ )
  {
    $s->before_create($context, $Upload);
  }
  elsif( /^edit$/ )
  {
    $s->before_update($context, $Upload);
  }
  else
  {
    die "Unknown mode: '$_'";
  }# end if()
}# end upload_start()


#==============================================================================
sub upload_hook
{
  my ($s, $context, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_hook( @_ );
  
  my $filename = eval {
    my $name = $ENV{filename}; # $context->r->pnotes( 'filename' );
    $name;
  } or return;
  
  my $ofh = $s->open_file_for_appending($context, $filename);
  no warnings 'uninitialized';
  print $ofh delete($Upload->{data});
  $ofh->close;
}# end upload_hook()


#==============================================================================
sub upload_end
{
  my ($s, $context, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_end( @_ );
  
  # Return information about what we just did:
  my $info = {
    new_file      => $ENV{filename},
    filename_only => $ENV{download_file},
    link_to_file  => "/media/" . $ENV{download_file},
  };
  $Upload->{$_} = $info->{$_} foreach keys(%$info);
  
  # Depending on the 'mode' parameter, we do different things:
#  local $_ = $context->request->Form->{mode};
  my $form = $context->request->Form;
  $form = $context->request->Form;
  if( $form->{mode} =~ /^create$/ )
  {
    $s->after_create($context, $Upload);
  }
  elsif(  $form->{mode} =~ /^edit$/ )
  {
    $s->after_update($context, $Upload);
  }
  else
  {
    die "Unknown mode: '$_'";
  }# end if()
}# end upload_end()


#==============================================================================
sub before_download
{
  my ($s, $context) = @_;
  
}# end before_download()


#==============================================================================
sub after_download
{
  my ($s, $context) = @_;
  
}# end after_download()


#==============================================================================
sub before_create
{
  my ($s, $context, $Upload) = @_;
  1;
}# end before_create()


#==============================================================================
sub before_update
{
  my ($s, $context, $Upload) = @_;
  1;
}# end before_update()


#==============================================================================
sub after_create
{
  my ($s, $context, $Upload) = @_;
  
}# end after_create()


#==============================================================================
sub after_update
{
  my ($s, $context, $Upload) = @_;
  
}# end after_update()


#==============================================================================
sub before_delete
{
  my ($s, $context, $filename) = @_;
  
}# end before_delete()


#==============================================================================
sub after_delete
{
  my ($s, $context, $filename) = @_;
  
}# end after_delete()

1;# return true:


=pod

=head1 NAME

Apache2::ASP::MediaManager - Instant file management for Apache2::ASP applications

=head1 SYNOPSIS

Create a file in your C</handlers> folder named C<MM.pm> and add the following:

  package MM;
  
  use strict;
  use warnings 'all';
  use base 'Apache2::ASP::MediaManager';
  use vars __PACKAGE__->VARS;
  
  sub before_download {
    my ($s, $context, $filename) = @_;
    
    warn "About to download '$filename'";
    return 1;
  }
  
  sub after_download {
    my ($s, $context, $filename) = @_;
    
    warn "Finished download of '$filename'";
    return 1;
  }
  
  sub before_create {
    my ($s, $context, $Upload) = @_;
    
    warn "About to create '$Upload->{filename_only}'";
    return 1;
  }
  
  sub after_create {
    my ($s, $context, $Upload) = @_;
    
    warn "Just created '$Upload->{filename_only}'";
    return $Response->Redirect( $ENV{HTTP_REFERER} );
  }
  
  sub before_update {
    my ($s, $context, $Upload) = @_;
    
    warn "About to update '$Upload->{filename_only}'";
    return 1;
  }
  
  sub after_update {
    my ($s, $context, $Upload) = @_;
    
    warn "Just updated '$Upload->{filename_only}'";
    return $Response->Redirect( $ENV{HTTP_REFERER} );
  }
  
  sub after_delete {
    my ($s, $context, $filename) = @_;
    
    warn "Just deleted '$filename'";
    return $Response->Redirect( $ENV{HTTP_REFERER} );
  }
  
  1;# return true:

Then create a file in your C</htdocs> folder named C<mm-test.asp>:

  <html>
    <body>
      <h1>File Upload Test</h1>
      <form
          method="post"
          enctype="multipart/form-data"
          action="/handlers/MM?mode=create&uploadID=2kj4hkj234h">
        <input type="file" name="filename" >
        <input type="submit" value="Upload File Now">
      </form>
      
      <h2>Existing Files (if any)</h2>
      <p>
  <%
    opendir my $dir, $Config->web->media_manager_upload_root;
    while( my $file = readdir($dir) )
    {
      next unless -f $Config->web->media_manager_upload_root . '/' . $file;
  %>
        <a href="/handlers/MM?file=<%= $file %>"><%= $file %></a><br>
  <%
    }# end while()
  %>
      </o>
    </body>
  </html>

B<REALLY IMPORTANT!>: Notice the C<?mode=create&uploadID=2kj4hkj234h> in the C<action>
attribute of the C<form> tag.  The C<mode> tells the MediaManager that we are B<creating>
a file, and the C<uploadID> will allow us to track the progress of the upload.

B<IMPORTANT>: Check your configuration, where you see:

  <config>
    ...
    <web>
      ...
      <media_manager_upload_root>@ServerRoot@/MEDIA</media_manager_upload_root>
      ...
    </web>
    ...
  </config>

Make B<*sure*> that your webserver has ownership or read/write access to that folder
and all of its contents.

When you access http://yoursite.com/mm-test.asp in your browser and submit the form,
C<Apache2::ASP::MediaManager> will save it under your C<media_manager_upload_root>
folder for you.

=head1 DESCRIPTION

Handling file uploads can be a real pain.  Restricting file uploads and downloads
to a select group of users is also problematic.

B<And Then...>

And then there was C<Apache2::ASP::MediaManager>.  Now you can have fully-functional
file uploads in seconds.  

=head1 UPLOAD PROGRESS INDICATORS

C<Apache2::ASP::MediaManager> makes it easy to provide upload progress indicators.

Remember that C<uploadID> parameter in the C<action> attribute of your form? While 
the upload is taking place, the C<$Session> object is getting updated with the
status of the upload.  If you were to make another handler - C</handlers/UploadProgress.pm> -
and insert the following code:

  package UploadProgress;

  use strict;
  use base 'Apache2::ASP::FormHandler';
  use vars __PACKAGE__->VARS;

  sub run {
    my ($s, $context) = @_;
    
    my $uploadID = $Form->{uploadID};
    
    $Session->{"upload$uploadID" . "percent_complete"} ||= 0;
    
    $Response->Expires( -30 );
    $Response->Write( $Session->{"upload$uploadID" . "percent_complete"} );
  }# end run()

  1;# return true:

And add call out to it via AJAX - you can get real-time upload progress information
about the current upload.

Example:

  window.setInterval(function() {
    httpOb.open("GET", "/handlers/UploadProgress?uploadID=2kj4hkj234h", true);
    httpOb.onreadystatechange = function() {
      if( httpOb.readyState == 4 ) {
        document.getElementById("percent_complete").innerHTML = httpOb.responseText + '%';
      }// end if()
    };
  }, 1000);

You should also add an element with an id of "percent_complete" to he form:

  <div id="percent_complete">0%</div>

=head1 PUBLIC PROPERTIES

None.

=head1 PUBLIC METHODS

Nothing you need to worry about.

=head1 EVENTS

B<About the C<$Upload> argument>:

The C<$Upload> argument is an instance of L<Apache2::ASP::UploadHookArgs>.

=head2 before_download( $self, $context )

Called before allowing a file to be downloaded from the server.

B<NOTE>: This method must return true, or the file will not be downloaded.

=head2 after_download( $self, $context )

Called after allowing a file to be downloaded from the server.

=head2 before_create( $self, $context, $Upload )

Called before allowing a new file to be uploaded to the server.

B<NOTE>: This method must return true, or the file will not be created.

=head2 after_create( $self, $context, $Upload )

Called after allowing a new file to be uploaded to the server.

=head2 before_update( $self, $context, $Upload )

Called before allowing a new file to be uploaded to replace an existing file.

B<NOTE>: This method must return true, or the file will not be updated.

=head2 after_update( $self, $context, $Upload )

Called after a new file has been uploaded to replace an existing file.

=head2 before_delete( $self, $context, $filename )

Called before deleting a file.

B<NOTE>: This method must return true, or the file will not be deleted.

=head2 after_delete( $self, $context, $filename )

Called after deleting a file.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

