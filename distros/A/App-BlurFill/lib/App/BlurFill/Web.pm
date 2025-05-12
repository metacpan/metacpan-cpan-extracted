=head1 NAME

App::BlurFill::Web - The web interface to App::BlurFill

=head1 SYNOPSIS

  # In a PSGI environment
  use App::BlurFill::Web;

  App::BlurFill::Web->to_app;

=head1 DESCRIPTION

App::BlurFill::Web is a web interface for the App::BlurFill module. It allows users
to upload an image file, specify the desired width and height, and receive a blurred
image file in response.

=head1 ROUTES

=head2 POST /blur

This route accepts an image file upload and optional width and height parameters.
It processes the image and returns a blurred version of the image.
The blurred image is returned as a downloadable file.

=head1 PARAMETERS

=head2 image

The image file to be processed. This parameter is required.
It should be a valid image file format (e.g., JPEG, PNG, GIF).

=head2 width

The desired width of the output image. Default is 650 pixels.

=head2 height

The desired height of the output image. Default is 350 pixels.

=head1 EXAMPLE

  POST /blur
  Content-Type: multipart/form-data

  image: <binary image data>
  width: 800
  height: 600

=head2 Using C<curl>

  curl -OJ -X POST -F "image=@path/to/image.jpg" -F "width=800" -F "height=600" http://localhost:3000/blur

=head1 RESPONSE

The response will be a blurred image file with the specified width and height.

=cut

use v5.40;

package App::BlurFill::Web;
use Dancer2;

our $VERSION = '0.0.3';

use File::Temp qw(tempfile tempdir);
use App::BlurFill;

post '/blur' => sub {
  my $upload = upload('image')
    or return status 400, { error => 'Missing image file' };

  my $orig_name = $upload->filename;
  my ($name, $path, $ext) =
    File::Basename::fileparse($orig_name, qr/\.[^.]*$/);

  return status 400, { error => 'Uploaded file must have a file extension' }
    unless $ext;

  my $format = lc $ext;
  $format =~ s/^\.//;

  my %mime = (
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    png  => 'image/png',
    gif  => 'image/gif',
  );

  return status 400, { error => "Unsupported file format: .$format" }
    unless exists $mime{$format};

  my $content_type = $mime{$format};

  my $width  = query_parameters->get('width')  || 650;
  my $height = query_parameters->get('height') || 350;

  my $in_dir = File::Temp::tempdir;
  my $in_path = "$in_dir/$name$ext";
  $upload->copy_to($in_path);

  my $outfile;
  eval {
    my $blur = App::BlurFill->new(
      file   => $in_path,
      width  => $width,
      height => $height,
    );
    $outfile = $blur->process;
  } or return status 500, { error => "Processing failed: $@" };

  my ($out_name) = File::Basename::fileparse($outfile);

  response_header 'Content-Disposition' => qq{attachment; filename="$out_name"};
  send_file(
    $outfile,
    system_path => 1,
    content_type => $content_type,
    content_disposition => "attachment; filename=\"$out_name\"",
  );
};

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025, Magnum Solutions Ltd. All rights reserved.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
