# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }
use strict;
use warnings;
use utf8;
use lib '../lib';
use open ':std', ':encoding(UTF-8)';
use Test::More ; #tests => 122;
use Test::Exception;
use File::Spec;
use File::Path;
use File::Copy;
use File::Temp qw(tempdir);
use File::Slurp qw( read_file write_file);
use Data::Printer;
my $naughty_file = "./blns.txt"; # source: https://github.com/minimaxir/big-list-of-naughty-strings, please read LICENSE in file blns.license.txt
sub prepare_baginfo_key {
    my $key = shift;
    my $tmp;
    $tmp->{input} =  join(":", $key, "value");
    $tmp->{expected}->[0]->{$key} = "value";
    return $tmp;
}

sub prepare_baginfo_value {
    my $value = shift;
    my $tmp;
    $tmp->{input} =  join(":", "key", $value);
    $tmp->{expected}->[0]->{"key"} = $value;
    return $tmp;
}

## tests
my $Class = 'Archive::BagIt';
use_ok($Class);
my @ROOT = grep {length} 'src';
my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
## tests
my $bag = $Class->new({bag_path=>$SRC_BAG});
open my $fh, "<encoding(UTF-8)", $naughty_file or die "open of file '$naughty_file' failed: $!";
my $lineno = 0;
while(<$fh>) {
    chop; # we use chop to avoid wrong chomping if last char is a CR or similar
    $lineno++;
    next if ! defined $_;
    next if $_=~ m/^#/; # comment
    next if $_=~ m/^$/; # empty
    next if $_=~ m/^\s/; # no key nor label should start with space
    my $tmp_value = prepare_baginfo_value( $_ );
    my $got_value = $bag->_parse_bag_info( $tmp_value->{input} );
    #use Data::Printer; p($got_value);
    is_deeply($got_value, $tmp_value->{expected}, "_parse_bag_info(), test if naugthy string value fails, lineno=$lineno");
    next if $_=~ m/:/; # ignore a line with colon, because we test with keys
    next if $_=~ m/\s/; # ignore a line with whitespace, because  could not be part of key
    my $tmp_key = prepare_baginfo_key( $_ );
    my $got_key = $bag->_parse_bag_info( $tmp_key->{input} );
    is_deeply($got_key, $tmp_key->{expected}, "_parse_bag_info(), test if naugthy string key fails, lineno=$lineno");
}
close $fh;
done_testing();
1;

