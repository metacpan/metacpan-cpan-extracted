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

=head2 GET /

This route displays a web form where users can upload an image and specify
the desired width and height for the output. The form submits to the POST /blur
route.

=head2 POST /blur

This route accepts an image file upload and optional width and height parameters.
It processes the image and returns an HTML page displaying the blurred image with
a download link and an option to create another image.

=head2 GET /download/:filename

This route serves the processed image file for download. The filename parameter
should match a previously processed image stored in the temporary directory.

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

  # This will return HTML with the results page
  curl -X POST -F "image=@path/to/image.jpg" -F "width=800" -F "height=600" http://localhost:3000/blur
  
  # To download the image directly
  curl -OJ http://localhost:3000/download/image_blur.png

=head1 RESPONSE

The POST /blur response will be an HTML page displaying the blurred image with
download options. The GET /download/:filename response will be the actual image file.

=cut

use v5.40;

package App::BlurFill::Web;
use Dancer2;

our $VERSION = '0.0.4';

use File::Temp qw(tempfile tempdir);
use File::Spec;
use File::Copy;
use App::BlurFill;

# Create a persistent temp directory for storing processed images
my $TEMP_DIR = File::Temp::tempdir(CLEANUP => 1);

sub _get_css {
  return <<'CSS';
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    
    .container {
      background: white;
      border-radius: 16px;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      max-width: 600px;
      width: 100%;
      padding: 40px;
    }
    
    h1 {
      color: #333;
      font-size: 32px;
      font-weight: 700;
      margin-bottom: 12px;
      text-align: center;
    }
    
    .subtitle {
      color: #666;
      font-size: 16px;
      text-align: center;
      margin-bottom: 32px;
      line-height: 1.5;
    }
    
    .form-group {
      margin-bottom: 24px;
    }
    
    label {
      display: block;
      color: #444;
      font-weight: 600;
      margin-bottom: 8px;
      font-size: 14px;
    }
    
    input[type="file"] {
      display: block;
      width: 100%;
      padding: 12px;
      border: 2px dashed #667eea;
      border-radius: 8px;
      background: #f8f9ff;
      cursor: pointer;
      transition: all 0.3s ease;
    }
    
    input[type="file"]:hover {
      border-color: #764ba2;
      background: #f0f1ff;
    }
    
    input[type="number"] {
      width: 100%;
      padding: 12px 16px;
      border: 2px solid #e0e0e0;
      border-radius: 8px;
      font-size: 16px;
      transition: all 0.3s ease;
    }
    
    input[type="number"]:focus {
      outline: none;
      border-color: #667eea;
      box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
    }
    
    .dimensions {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }
    
    button, .button {
      width: 100%;
      padding: 16px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      border-radius: 8px;
      font-size: 18px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
      box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
      text-decoration: none;
      display: inline-block;
      text-align: center;
    }
    
    button:hover, .button:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 16px rgba(102, 126, 234, 0.5);
    }
    
    button:active, .button:active {
      transform: translateY(0);
    }
    
    .info {
      background: #f8f9ff;
      border-left: 4px solid #667eea;
      padding: 16px;
      margin-top: 24px;
      border-radius: 4px;
    }
    
    .info p {
      color: #555;
      font-size: 14px;
      line-height: 1.6;
      margin-bottom: 8px;
    }
    
    .info p:last-child {
      margin-bottom: 0;
    }
    
    .info strong {
      color: #333;
    }

    .result-image {
      margin: 24px 0;
      text-align: center;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .result-image img {
      max-width: 100%;
      height: auto;
      display: block;
    }

    .success-message {
      background: #f0fdf4;
      border-left: 4px solid #10b981;
      padding: 16px;
      margin-bottom: 24px;
      border-radius: 4px;
      color: #065f46;
    }

    .action-buttons {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-top: 24px;
    }

    .button-secondary {
      background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
    }
    
    @media (max-width: 640px) {
      .container {
        padding: 24px;
      }
      
      h1 {
        font-size: 24px;
      }
      
      .dimensions, .action-buttons {
        grid-template-columns: 1fr;
      }
    }
CSS
}

get '/' => sub {
  my $css = _get_css();
  return <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BlurFill - Create Blurred Background Images</title>
  <style>
$css
  </style>
</head>
<body>
  <div class="container">
    <h1>BlurFill</h1>
    <p class="subtitle">Create beautiful blurred background images for your content</p>
    
    <form action="/blur" method="POST" enctype="multipart/form-data">
      <div class="form-group">
        <label for="image">Select Image</label>
        <input type="file" id="image" name="image" accept="image/jpeg,image/jpg,image/png,image/gif" required>
      </div>
      
      <div class="form-group">
        <label>Output Dimensions</label>
        <div class="dimensions">
          <div>
            <label for="width">Width (px)</label>
            <input type="number" id="width" name="width" value="650" min="1" max="4000">
          </div>
          <div>
            <label for="height">Height (px)</label>
            <input type="number" id="height" name="height" value="350" min="1" max="4000">
          </div>
        </div>
      </div>
      
      <button type="submit">Generate Blurred Image</button>
    </form>
    
    <div class="info">
      <p><strong>How it works:</strong></p>
      <p>1. Upload your image (JPEG, PNG, or GIF)</p>
      <p>2. Set your desired output dimensions</p>
      <p>3. Click "Generate" to create a blurred background with your image centered</p>
      <p>4. Your processed image will be displayed with a download link</p>
    </div>
  </div>
</body>
</html>
HTML
};

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
  
  # Copy the processed file to our persistent temp directory
  my $persistent_path = File::Spec->catfile($TEMP_DIR, $out_name);
  File::Copy::copy($outfile, $persistent_path) or die "Copy failed: $!";

  # Display results page with image preview and download link
  my $css = _get_css();
  return <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BlurFill - Result</title>
  <style>
$css
  </style>
</head>
<body>
  <div class="container">
    <h1>BlurFill</h1>
    <p class="subtitle">Your blurred image is ready!</p>
    
    <div class="success-message">
      <strong>✓ Success!</strong> Your image has been processed successfully.
    </div>
    
    <div class="result-image">
      <img src="/download/$out_name" alt="Blurred image preview">
    </div>
    
    <div class="action-buttons">
      <a href="/download/$out_name" class="button" download>Download Image</a>
      <a href="/" class="button button-secondary">Create Another</a>
    </div>
    
    <div class="info">
      <p><strong>What's next?</strong></p>
      <p>• Click "Download Image" to save your blurred background</p>
      <p>• Click "Create Another" to process a new image</p>
    </div>
  </div>
</body>
</html>
HTML
};

get '/download/:filename' => sub {
  my $filename = route_parameters->get('filename');
  
  # Security: only allow filenames without path traversal
  return status 400, { error => 'Invalid filename' }
    if $filename =~ m{[/\\]};
  
  my $filepath = File::Spec->catfile($TEMP_DIR, $filename);
  
  return status 404, { error => 'File not found' }
    unless -f $filepath;
  
  # Determine content type from extension
  my $ext = lc($filename);
  $ext =~ s/.*\.//;
  
  my %mime = (
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    png  => 'image/png',
    gif  => 'image/gif',
  );
  
  my $content_type = $mime{$ext} || 'application/octet-stream';
  
  send_file(
    $filepath,
    system_path => 1,
    content_type => $content_type,
  );
};

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025, Magnum Solutions Ltd. All rights reserved.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
