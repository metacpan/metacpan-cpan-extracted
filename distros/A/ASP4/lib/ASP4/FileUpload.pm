
package ASP4::FileUpload;

use strict;
use warnings 'all';
use Carp 'confess';


sub new
{
  my ($class, %args) = @_;
  
  foreach(qw( ContentType FileHandle FileName ))
  {
    confess "Required param '$_' was not provided"
      unless $args{$_};
  }# end foreach()
  
  $args{UploadedFileName} = $args{FileName};
  ($args{FileName})       = $args{FileName} =~ m{[/\\]?([^/\\]+)$};
  ($args{FileExtension})  = $args{FileName} =~ m/([^\.]+)$/;
  $args{FileSize}         = (stat($args{FileHandle}))[7];
  
  return bless \%args, $class;
}# end new()


# Public readonly properties:
sub ContentType       { shift->{ContentType} }
sub FileName          { shift->{FileName} }
sub UploadedFileName  { shift->{UploadedFileName} }
sub FileExtension     { shift->{FileExtension} }
sub FileSize          { shift->{FileSize} }

sub FileContents
{
  my $s = shift;
  local $/;
  my $ifh = $s->FileHandle;
  return scalar(<$ifh>);
}# end FileContents()

sub FileHandle
{
  my $s = shift;
  my $ifh = $s->{FileHandle}; 
  seek($ifh,0,0)
    or confess "Cannot seek to the beginning of filehandle '$ifh': $!";
  return $ifh;
}# end FileHandle()


# Public methods:
sub SaveAs
{
  my ($s, $path) = @_;
  
  # Create the file path if it doesn't yet exist:
  my $folder = "";
  my @parts = grep { $_ } split /\//, $path;
  pop(@parts);
  for( @parts )
  {
    $folder .= "/$_";
    unless( -d $folder )
    {
      mkdir( $folder, 0777 );
    }# end unless()
  }# end for()
  
  open my $ofh, '>', $path
    or confess "Cannot open '$path' for writing: $!";
  my $ifh = $s->FileHandle;
  while( my $line = <$ifh> )
  {
    print $ofh $line;
  }# end while()
  close($ofh);
  
  return 1;
}# end SaveAs()


sub DESTROY
{
  my $s = shift;
  my $ifh = $s->FileHandle;
  close($ifh);
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::FileUpload - Simple interface for handling File Uploads

=head1 SYNOPSIS

  # In your handler:
  sub run {
    my ($s, $context) = @_;
    
    if( my $file = $Request->FileUpload('fieldname') ) {
    
      # Save the file:
      $file->SaveAs('/var/media/uploads/budget.csv');
      
      # Some info about it:
      warn $file->UploadedFileName; # C:\Users\billg\budget.csv
      warn $file->FileName;         # budget.csv
      warn $file->FileExtension;    # csv
      warn $file->FileSize;         # 273478 (Calculated via (stat(FH))[7] )
      warn $file->ContentType;      # text/csv
      warn $file->FileContents;     # (The contents of the file)
      my $ifh = $file->FileHandle;  # A normal, plain old filehandle
    }
  }

=head1 DESCRIPTION

This class provides a simple interface to uploaded files in ASP4.

=head1 PUBLIC PROPERTIES

=head2 UploadedFileName

The name of the file - as uploaded by the user.  For example, if the user was on 
Windows, it might look like C<C:\Users\billg\Desktop\file.txt>

=head2 Filename

The name of the file itself - eg: C<file.txt>

=head2 FileExtension

If the filename is C<file.txt>, C<FileExtension> would return C<txt>.

=head2 FileSize

The size of the uploaded file in bytes.

=head2 FileHandle

Returns a filehandle (open for reading) pointing to the uploaded file.

=head2 ContentType

The C<content-type> header supplied by the browser for the uploaded file.

=head2 FileContents

The contents of the uploaded file.

=head1 PUBLIC METHODS

=head2 SaveAs( $path )

Writes the contents of the uploaded file to C<$path>.  Will throw an exception if
something goes wrong.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

