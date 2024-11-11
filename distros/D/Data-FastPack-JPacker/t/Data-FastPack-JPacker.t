use strict;
use warnings;

use Data::FastPack qw<encode_fastpack decode_fastpack>;
use Data::FastPack::Meta;
use File::Path qw<remove_tree>;

use Test::More;

BEGIN { use_ok('Data::FastPack::JPacker') };

my $count=5;
my $encoded="";
encode_fastpack($encoded,[[0,1,$_]]) for(1..$count);

my $encoded_copy=$encoded;
my @decoded;

decode_fastpack($encoded_copy, \@decoded);

ok (@decoded == $count);

#use Data::Dumper;
#use feature ":all";
#say STDERR Dumper @decoded;


use File::Temp qw<mktemp>;
# Write to file
my $input=mktemp("fastpackXXXXXXXX");;
{
  open my $fh, ">", $input;
  print $fh $encoded;
}

my $html_container="test";

my $jpacker=Data::FastPack::JPacker->new(html_continer=>$html_container, message_limit=>2);

my $prefix="some_group";
$jpacker->pack_files($input, $prefix);

# Clean up
#
unlink $input;
remove_tree $prefix;

done_testing();


