
use Test::More;
use Imager;
foreach my $format (qw/jpeg png/){
    unless ( defined $Imager::formats{$format} ) {
        plan skip_all => "Missing $format support";
        last;
    }
}
plan tests => 34;
use_ok( 'App::StaticImageGallery' );
use_ok( 'App::StaticImageGallery::Dir' );

# ./maint/style_to_package.pl styles/Test > t/lib/App/StaticImageGallery/Style/Test.pm
use lib 't/lib';
my $work_dir = 't/images/';
my $data_dir = 't/images/.StaticImageGallery/';
my @images = sort ('JPEG.jpg','PNG.png');
my @default_ARGV = (
    # '--no-recursive',
    '--style' => 'Test',
    # '-vvvvv',
);
{
    local @ARGV;
    push @ARGV, @default_ARGV;
    push @ARGV, 'build';
    push @ARGV, $work_dir;
    my $app = App::StaticImageGallery->new_with_options();
    $app->run();

    isa_ok($app, 'App::StaticImageGallery');

    ok( -f $work_dir . '/index.html', 'Check index.html');
    ok( -f $work_dir . '/sub_folder/index.html', 'Check sub_folder/index.html');
    foreach my $image ( @images ){
        foreach my $size ('small','medium','large'){
            my $html = sprintf("%s.%s.html",$image,$size);
            my $image = sprintf("%s.%s.jpg",$image,$size);
            ok ( -f $data_dir . '/' . $html, "Check " . $html );
            ok ( -f $data_dir . '/' . $image, "Check " . $image );
        }
    }
}

{
    local @ARGV;
    push @ARGV, @default_ARGV;
    push @ARGV, '--no-recursive';
    push @ARGV, 'clean';
    push @ARGV, $work_dir;
    my $app = App::StaticImageGallery->new_with_options();
    $app->run();

    isa_ok($app, 'App::StaticImageGallery');

    ok( ! -f $work_dir . '/index.html', 'Check index.html');
    ok( -f $work_dir . '/sub_folder/index.html', 'Check sub_folder/index.html');
    foreach my $image ( @images ){
        foreach my $size ('small','medium','large'){
            my $html = sprintf("%s.%s.html",$image,$size);
            my $image = sprintf("%s.%s.jpg",$image,$size);
            ok ( ! -f $data_dir . '/' . $html, "Check " . $html );
            ok ( ! -f $data_dir . '/' . $image, "Check " . $image );
        }
    }
}

{
    local @ARGV;
    push @ARGV, @default_ARGV;
    push @ARGV, 'clean';
    push @ARGV, $work_dir;
    my $app = App::StaticImageGallery->new_with_options();
    $app->run();

    isa_ok($app, 'App::StaticImageGallery');

    ok( ! -f $work_dir . '/sub_folder/index.html', 'Check sub_folder/index.html');
}

# Check rebuild
# {
#     # Build
#     local @ARGV;
#     push @ARGV, 'build';
#     push @ARGV, $work_dir;
#     my $app = App::StaticImageGallery->new_with_options();
#     $app->run();
#     isa_ok($app, 'App::StaticImageGallery');
# 
# 
# 
# }


