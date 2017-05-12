use Test::More;
use lib 't/lib';
use DBI;
use Carp::Assert;
use CGI::Uploader::Test; # provides setup() and read_file()
use strict;

use CGI::Uploader;
use File::Path;

my $found_module = 0;
eval { require Image::Magick; };
$found_module = !$@;
if ($found_module) {
    plan (qw/no_plan/)
}
else {
    eval { require Graphics::Magick; };
    $found_module = !$@;
    if ($found_module) {
        plan (qw/no_plan/)
    }
    else {
        plan skip_all => "No graphics module found for image resizing. Install Graphics::Magick or Image::Magick: $@ ";
    }
}

use CGI::Uploader::Transform::ImageMagick;

 # This should work, even if we don't preload either one
 delete $INC{'Image/Magick.pm'};
 delete $INC{'Graphics/Magick.pm'};

 my ($tmp_filename, $img)  = CGI::Uploader::Transform::ImageMagick->gen_thumb( 't/20x16.png', [ w => 5 ]);

 my ($w,$h) = $img->Get('width','height');

 is($w,5,'as class method - correct height only width is supplied');
 is($h,4,'as class method - correct height only width is supplied');


####

my ($DBH,$drv) = setup();

     my %imgs = (
        'img_1' => {
            gen_files => {
                # old API
                img_1_thumb => {
                    transform_method => \&gen_thumb,
                    params => [{ w => 10 }],
                },
                # new API
                new_api_thumb => gen_thumb({ w => 10}),
            },
        },
     );

     use CGI;
     my $u =    CGI::Uploader->new(
        updir_path=>'t/uploads',
        updir_url=>'http://localhost/test',
        dbh  => $DBH,
        spec => \%imgs,
        query => CGI->new(),
     );
     ok($u, 'Uploader object creation');

{
     my ($tmp_filename,$img)  = CGI::Uploader::Transform::ImageMagick->gen_thumb({
             filename => 't/20x16.png',
             w => 10,
     });
     my ($w,$h) = $img->Get('width','height');
     is($h,8,'correct height only width is supplied (also testing new API)');
}

{
     my ($tmp_filename,$img)  = CGI::Uploader::Transform::ImageMagick->gen_thumb({
             filename => 't/20x16.png',
             h => 8,
         });
     my ($w,$h) = $img->Get('width','height');
     is($w,10,'correct width only width is supplied (also testing new API');
}


     eval {
         my %entity_upload_extra = $u->store_upload(
             file_field  => 'img_1',
             src_file    => 't/20x16.png',
             uploaded_mt => 'image/png',
             file_name   => '20x16.png',
             );
         };
    is($@,'', 'store_upload() survives');

    my $db_height =$DBH->selectrow_array(
        "SELECT height
            FROM uploads
            WHERE upload_id = 2");
    is($db_height, 8, "correct height calculation when thumb height omitted from spec ");

{
    my $db_height =$DBH->selectrow_array(
        "SELECT height
            FROM uploads
            WHERE upload_id = 3");
    is($db_height, 8, "correct height calculation when thumb height omitted from spec (using new API) ");
}




