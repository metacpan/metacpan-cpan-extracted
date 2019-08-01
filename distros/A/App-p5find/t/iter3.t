# perl
use v5.18;
use File::Spec::Functions qw< catfile >;
use File::Basename qw< basename >;
use FindBin qw< $Bin $Script >;
use Test2::V0;

use App::p5find qw(p5_doc_iterator);

my $iter = p5_doc_iterator( $Bin, catfile($Bin, "..", "lib") );
my $found = 0;
my %seen;
while(my $doc = $iter->()) {
    my $f = basename( $doc->filename );
    $seen{$f} = 1;
}
ok $seen{"p5find.pm"}, "found p5find.pm";
ok $seen{$Script}, "found $Script";

done_testing;
