# $Id: 10_constructors.t 22 2012-07-05 21:36:33Z jim $

# Build an array of contructor names and params here so we can calculate
# the number of tests and loop thru them.

BEGIN {
@constructors = (
  {
    name => 'from_r454year',
    params => {
      r454year => 2000
    }
  },
  {
    name => 'new',
    params => {
      year => 2000
    }
  },
  {
    name => 'from_epoch',
    params => {
      epoch => time()
    }
  },
  {
    name => 'now',
    params => { }
  },
  {
    name => 'today',
    params => { }
  },
  {
    name => 'last_day_of_month',
    params => {
      year => 2006,
      month => 1
    }
  },
  {
    name => 'from_day_of_year',
    params => {
      year => 2006,
      day_of_year => 31
    }
  }
);

my $loops = scalar(@constructors);
$loops *= 7;
$totaltests = $loops + 1;
};

use Test::More tests => $totaltests;

BEGIN { use_ok('DateTime::Fiscal::Retail454') };

#########################

for ( @constructors ) {
# First, test thru the normal package
  my $cname = $_->{name};
  my $r454 = DateTime::Fiscal::Retail454->$cname( %{$_->{params}} );
  isa_ok($r454, 'DateTime::Fiscal::Retail454');
  isa_ok($r454, 'DateTime');
  ok(exists($r454->{_R454_year}) && 1,"_R454_year defined in constructor $cname");
# Now run the same tests as an empty sub-class
  my $r454_2 = Empty::Retail454->$cname( %{$_->{params}} );
  isa_ok($r454_2, 'Empty::Retail454');
  isa_ok($r454_2, 'DateTime::Fiscal::Retail454');
  isa_ok($r454_2, 'DateTime');
  ok(exists($r454_2->{_R454_year}) && 1,"_R454_year defined in Empty $cname");
}

exit;

# package for empty package tests
package Empty::Retail454;
use base qw(DateTime::Fiscal::Retail454);

__END__

