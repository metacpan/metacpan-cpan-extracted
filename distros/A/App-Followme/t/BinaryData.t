#!/usr/bin/env perl
use strict;

use Test::More tests => 5;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

$lib = catdir(@path, 't');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::BinaryData;

my $test_dir = catdir(@path, 'test');
rmtree($test_dir, 0, 1) if -e $test_dir;

mkdir($test_dir) unless -e $test_dir;
 
chdir($test_dir) or die $!;

#----------------------------------------------------------------------
# Create object

my %configuration = (top_directory => $test_dir,
                     base_directory => $test_dir,
                     extension => 'txt',
                    );

my $obj = App::Followme::BinaryData->new(%configuration);

isa_ok($obj, "App::Followme::BinaryData"); # test 1
can_ok($obj, qw(new build)); # test 2

#----------------------------------------------------------------------
# Test file variables

do {
    my @count = qw(one two three);
    my $code = <<'EOQ';
File number %%
EOQ

    for (my $i=0 ; $i < 3; ++ $i) {
        my $output = $code;
        my $kount = ucfirst($count[$i]);
        $output =~ s/%%/$kount/g;

        my $filename = catfile($test_dir, "$count[$i].txt");
        fio_write_page($filename, $output);
    }

    my $filename = catfile($test_dir, 'one.txt');
    my %data = $obj->fetch_data('title', $filename);

    is($data{title}, 'One', 'get title from filename'); # test 3

    my $data = \%data;
    my $sorted_order = 1;
    $obj->{sort_field} = 'title';
    my $sorted_data = $obj->format($sorted_order, $data);
    
    is($sorted_data->{title}, 'one', 'format sortable title'); # test 4

    my $url = $obj->get_url($filename);
    is($url, 'one.txt', 'get url from filename'); # test 5
};
