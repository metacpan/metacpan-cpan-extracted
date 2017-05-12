package App::AutoCRUD::View::Download;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::View';

use Cwd;
use HTTP::Date;
use Plack::MIME;

use namespace::clean -except => 'meta';


sub render {
  my ($self, $file, $context) = @_;

  open my $fh, "<:raw", $file or die $!;
  my ($size, $mtime) = (stat $fh)[7, 9];

  # code mostly borrowed from App::File
  my $content_type = Plack::MIME->mime_type($file) || 'text/plain';
  Plack::Util::set_io_path($fh, Cwd::realpath($file));

 # TODO : SUPPORT CONDITIONAL GET

  return [
    200,
    [
      'Content-Type'   => $content_type,
      'Content-Length' => $size,
      'Last-Modified'  => HTTP::Date::time2str($mtime),
     ],
    $fh,
   ];

}

1;


__END__



