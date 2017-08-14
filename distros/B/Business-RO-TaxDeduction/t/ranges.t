use strict;
use warnings;
use Test::Most;
use Scalar::Util qw(blessed);

use Business::RO::TaxDeduction::Ranges;

my $years = {
    2005 => 2005,
    2006 => 2005,
    2015 => 2005,
    2016 => 2016,
    2017 => 2016,
};
my $vbl_min = {
    2005 => 1000,
    2016 => 1500,
};
my $vbl_max = {
    2005 => 3000,
    2016 => 3000,
};
my $f_min = {
    2005 => 1000,
    2016 => 1500,
};
my $f_max = {
    2005 => 2000,
    2016 => 1500,
};

foreach my $year ( sort keys %{$years} ) {
    ok my $tdr = Business::RO::TaxDeduction::Ranges->new(
        year => $year,
    ), 'new instance';
    is $tdr->year, $year, "year $year";
    is $tdr->base_year, $years->{$year}, "base year " . $years->{$year};
    is $tdr->vbl_min, $vbl_min->{ $years->{$year} }, 'vbl_min';
    is $tdr->vbl_max, $vbl_max->{ $years->{$year} }, 'vbl_max';
    is $tdr->f_min, $f_min->{ $years->{$year} }, 'f_min';
    is $tdr->f_max, $f_max->{ $years->{$year} }, 'f_max';

}

done_testing;
