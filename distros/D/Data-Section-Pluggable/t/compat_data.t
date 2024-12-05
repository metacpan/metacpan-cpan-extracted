use strict;
use warnings;
use lib "corpus/lib";
use DataInCode;
use Test::More;
use Data::Section::Pluggable;

my $d = Data::Section::Pluggable->new('DataInCode');
my $x = $d->get_data_section;

is $x->{foo}, "bar\n\n";

done_testing;



