use strict;
use Test::More;

use JSON::PP 'encode_json';
use Acme::DreamyImage;

my $output_file = "dreamy_" . int(rand(12345678)) . ".jpg";
my $seed = $output_file . time . $$;

my $img = Acme::DreamyImage->new(seed => $seed, width => 800, height => 450);
$img->write(file => $output_file);
ok -f $output_file, "The output is produced";
ok( (stat($output_file))[7] > 0, "The output size is non-zero." );

if ($ENV{TRAVIS}) {
    my $output_url = `curl --silent -F name=${output_file} -F 'file=\@${output_file}' 'https://www.uguu.se/api.php?d=upload-tool'`;
    diag $output_url;
}

done_testing;

