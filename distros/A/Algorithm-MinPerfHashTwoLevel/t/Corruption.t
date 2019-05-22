#########################

use strict;
use warnings;

use Test::More qw(no_plan);
use File::Temp;
use Data::Dumper; $Data::Dumper::Sortkeys=1; $Data::Dumper::Useqq=1;

use Tie::Hash::MinPerfHashTwoLevel::OnDisk qw(MAX_VARIANT);

my $class= 'Tie::Hash::MinPerfHashTwoLevel::OnDisk';

my $tmpdir= File::Temp->newdir();

use Tie::Hash::MinPerfHashTwoLevel::OnDisk qw(mph2l_tied_hashref mph2l_make_file);

# trying this with variants before 3 will typically result in failed tests at offsets 8-24,
# that is, we fail to detect that the file has been corrupted. :-(
mph2l_make_file("$tmpdir/test_000.mph2l",source_hash=>{1..10},canonical=>1);
open my $fh,"<", "$tmpdir/test_000.mph2l";
my $data= do { local $/; <$fh> };
close $fh;
$data = "" unless defined $data;
ok($data,sprintf "got data as expected (length: %d)",length($data));
for my $pos (0..length($data)-1) {
    my $chr= substr($data,$pos,1);
    substr( $data, $pos, 1, chr( ord($chr) ^ ( 1 << rand(8) ) ) );
    my $fn= sprintf "$tmpdir/test_%03d.mph2l", $pos+1;
    open my $ofh, ">", $fn or die "failed to open '$fn' for write: $!";
    print $ofh $data;
    close $ofh;
    substr($data,$pos,1,$chr);
}
ok(1,"constructed files ok");
for my $pos (0 .. length($data)) {
    my $fn= sprintf "$tmpdir/test_%03d.mph2l", $pos;
    my $got= eval { mph2l_tied_hashref($fn,validate=>1); 1 };
    my $error= $got ? "" : "Error: $@";
    if ($pos) {
        ok( !$got, sprintf "munging offset %d is noticed", $pos-1 );
        ok( $error=~/Error: Failed to mount/, sprintf "munging offset %d produces an error of sorts", $pos-1 );
    } else {
        ok( $got, "loaded base image ok" );
        ok ( !$error, "No error loading base image");
    }
}
done_testing();
1;
