use blib;
use Test2::V0;
use Acme::Image::Stb      qw[:all];
use File::Spec::Functions qw[updir];
#
my ($file) = grep { -e $_ } qw[demo.png t/demo.png];
$file // skip_all 'I have no idea where the demo image is so... goodbye.', 1;
diag "Demo image is at $file";
ok load_and_resize( $file, 'output.png', .25 ), 'load_and_resize(...)';
#
ok -e 'output.png', 'output file was created';

# This is good enough
ok -s 'output.png' < -s $file, 'output file is smaller on disk than the original';
#
done_testing;
