use Test::More tests => 10;
BEGIN { use_ok( 'Data::Dump::Streamer', qw(:undump) ); }
use strict;
use warnings;
use Data::Dumper;

#$Id: sortkeys.t 26 2006-04-16 15:18:52Z demerphq $#

# imports same()
(my $helper=$0)=~s/\w+\.\w+$/test_helper.pl/;
require $helper;
# use this one for simple, non evalable tests. (GLOB)
#   same ( $got,$expected,$name,$obj )
#
# use this one for eval checks and dumper checks but NOT for GLOB's
# same ( $name,$obj,$expected,@args )

my $dump;
my $o = Data::Dump::Streamer->new();

isa_ok( $o, 'Data::Dump::Streamer' );

{
    use warnings FATAL=>'all';
    my $hash={(map {$_ => $_, "1$_"=>"1$_" } 0..9,'a'..'j','A'..'J'),map { ( chr(65+$_).$_ => $_, $_.chr(65+$_) => $_) } 0..9};
same( "Sortkeys Mixed Default (smart)", $o , <<'EXPECT',$hash );
$HASH1 = {
           0    => 0,
           "0A" => 0,
           1    => 1,
           "1A" => '1A',
           "1a" => '1a',
           "1B" => 1,
           "1b" => '1b',
           "1C" => '1C',
           "1c" => '1c',
           "1D" => '1D',
           "1d" => '1d',
           "1E" => '1E',
           "1e" => '1e',
           "1F" => '1F',
           "1f" => '1f',
           "1G" => '1G',
           "1g" => '1g',
           "1H" => '1H',
           "1h" => '1h',
           "1I" => '1I',
           "1i" => '1i',
           "1J" => '1J',
           "1j" => '1j',
           2    => 2,
           "2C" => 2,
           3    => 3,
           "3D" => 3,
           4    => 4,
           "4E" => 4,
           5    => 5,
           "5F" => 5,
           6    => 6,
           "6G" => 6,
           7    => 7,
           "7H" => 7,
           8    => 8,
           "8I" => 8,
           9    => 9,
           "9J" => 9,
           10   => 10,
           11   => 11,
           12   => 12,
           13   => 13,
           14   => 14,
           15   => 15,
           16   => 16,
           17   => 17,
           18   => 18,
           19   => 19,
           A    => 'A',
           a    => 'a',
           A0   => 0,
           B    => 'B',
           b    => 'b',
           B1   => 1,
           C    => 'C',
           c    => 'c',
           C2   => 2,
           D    => 'D',
           d    => 'd',
           D3   => 3,
           E    => 'E',
           e    => 'e',
           E4   => 4,
           F    => 'F',
           f    => 'f',
           F5   => 5,
           G    => 'G',
           g    => 'g',
           G6   => 6,
           H    => 'H',
           h    => 'h',
           H7   => 7,
           I    => 'I',
           i    => 'i',
           I8   => 8,
           J    => 'J',
           j    => 'j',
           J9   => 9
         };
EXPECT
same(  "Sortkeys Mixed Lexico", $o->SortKeys('lex'), <<'EXPECT',( $hash ));
$HASH1 = {
           0    => 0,
           "0A" => 0,
           1    => 1,
           10   => 10,
           11   => 11,
           12   => 12,
           13   => 13,
           14   => 14,
           15   => 15,
           16   => 16,
           17   => 17,
           18   => 18,
           19   => 19,
           "1A" => '1A',
           "1B" => 1,
           "1C" => '1C',
           "1D" => '1D',
           "1E" => '1E',
           "1F" => '1F',
           "1G" => '1G',
           "1H" => '1H',
           "1I" => '1I',
           "1J" => '1J',
           "1a" => '1a',
           "1b" => '1b',
           "1c" => '1c',
           "1d" => '1d',
           "1e" => '1e',
           "1f" => '1f',
           "1g" => '1g',
           "1h" => '1h',
           "1i" => '1i',
           "1j" => '1j',
           2    => 2,
           "2C" => 2,
           3    => 3,
           "3D" => 3,
           4    => 4,
           "4E" => 4,
           5    => 5,
           "5F" => 5,
           6    => 6,
           "6G" => 6,
           7    => 7,
           "7H" => 7,
           8    => 8,
           "8I" => 8,
           9    => 9,
           "9J" => 9,
           A    => 'A',
           A0   => 0,
           B    => 'B',
           B1   => 1,
           C    => 'C',
           C2   => 2,
           D    => 'D',
           D3   => 3,
           E    => 'E',
           E4   => 4,
           F    => 'F',
           F5   => 5,
           G    => 'G',
           G6   => 6,
           H    => 'H',
           H7   => 7,
           I    => 'I',
           I8   => 8,
           J    => 'J',
           J9   => 9,
           a    => 'a',
           b    => 'b',
           c    => 'c',
           d    => 'd',
           e    => 'e',
           f    => 'f',
           g    => 'g',
           h    => 'h',
           i    => 'i',
           j    => 'j'
         };
EXPECT
$hash={map { $_ => 1} (1,10,11,2,20,100)};
same( "Sortkeys Numeric Alph==Lex", $o->SortKeys('alph'), <<'EXPECT', ( $hash )  );
$HASH1 = {
           1   => 1,
           10  => 1,
           100 => 1,
           11  => 1,
           2   => 1,
           20  => 1
         };
EXPECT
same( "Sortkeys Numeric", $o->SortKeys('num') , <<'EXPECT', ( $hash ) );
$HASH1 = {
           1   => 1,
           2   => 1,
           10  => 1,
           11  => 1,
           20  => 1,
           100 => 1
         };
EXPECT
same( "Sortkeys Numeric Smart", $o->SortKeys('smart'), <<'EXPECT', ( $hash ) );
$HASH1 = {
           1   => 1,
           2   => 1,
           10  => 1,
           11  => 1,
           20  => 1,
           100 => 1
         };
EXPECT
same( $dump = $o->SortKeys(sub {[ sort grep { /1/ } keys %{shift @_} ]})->Data( $hash )->Out, <<'EXPECT', "Sortkeys Custom Filter", $o );
$HASH1 = {
           1   => 1,
           10  => 1,
           100 => 1,
           11  => 1
         };
EXPECT
$o->SortKeys('smart');
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my $h={'A'...'J'};
    my $h2={'A'..'J'};
    my $foo_bar=bless {foo=>1,bar=>2,baz=>3},'Foo::Bar';
    $o->HashKeys('Foo::Bar'=>[qw(foo bar)],$h=>[qw( C G E )]);
same( $dump = $o->Data($h2,$h,$foo_bar)->Out, <<'EXPECT', "HashKeys - array", $o );
$HASH1 = {
           A => 'B',
           C => 'D',
           E => 'F',
           G => 'H',
           I => 'J'
         };
$HASH2 = {
           C => 'D',
           G => 'H',
           E => 'F'
         };
$Foo_Bar1 = bless( {
              foo => 1,
              bar => 2
            }, 'Foo::Bar' );
EXPECT
    $o->HashKeys($h2=>sub { return ['I'] });
    same( $dump = $o->Data($h2,$h,$foo_bar)->Out, <<'EXPECT', "HashKeys - coderef", $o );
$HASH1 = { I => 'J' };
$HASH2 = {
           C => 'D',
           G => 'H',
           E => 'F'
         };
$Foo_Bar1 = bless( {
              foo => 1,
              bar => 2
            }, 'Foo::Bar' );
EXPECT
    $o->HashKeys();
}
__END__
# with eval testing
{
    same( "", $o, <<'EXPECT', (  ) );

}
# without eval testing
{

}
