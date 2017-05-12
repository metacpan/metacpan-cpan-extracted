#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 73;
use strict;
use warnings;
use lib qw(../lib lib);
use Data::Range::Compare qw(HELPER_CB );
use Data::Dumper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $s='Data::Range::Compare';
my %helper=HELPER_CB;
## Consolidate check
{
  my @raw=map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) }
  (
   [0,1]
   ,[0,4]
   ,[2,3]
   ,[4,5]
  );
  my $consolidated=$s->consolidate_ranges(\%helper,\@raw);
  ok($consolidated->[0] eq '0 - 5','consolidate range check 1');
  ## more complex consolidation check
  @raw=map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) }
  (
   [0,1]
   ,[2,2]
   ,[2,3]
   ,[3,3]
   ,[4,5]
   ,[4,4]
  );
  $consolidated=$s->consolidate_ranges(\%helper,\@raw);
  my $ok=join ', ',@$consolidated;
  ok($ok eq '0 - 1, 2 - 3, 4 - 5','consolidate range check 2');
}
# fill missing
{
  my @raw=map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) }
  (
   [0,1]
   ,[4,5]
  );
  my $list=$s->fill_missing_ranges(\%helper,\@raw);
  my $check=join(" ",@$list);
  ok('0 - 1 2 - 3 4 - 5' eq $check,'fill_missing_ranges');
}

# range_start_end_fill
{
  my @list=(
  [map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [0,1]]
  ,[map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [2,3] ]
  ,[map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [3,7] ]
  );
  my $res=$s->range_start_end_fill(\%helper,\@list);
  ok(join(',',@{$list[0]}) eq '0 - 1,2 - 7','range_start_end_fill 1');
  ok(join(',',@{$list[1]}) eq '0 - 1,2 - 3,4 - 7','range_start_end_fill 2');
  ok(join(',',@{$list[2]}) eq '0 - 2,3 - 7','range_start_end_fill 3');
}
{
  my @list=(
  [map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [0,1]]
  ,[map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [2,3] ]
  ,[map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [3,7] ]
  );
  my $check;
  my ($row,$cols,$next,$missing)=$s->init_compare_row(\%helper,\@list);
  $check=join(', ',@$row);
  ok($check eq '0 - 1, 0 - 1, 0 - 2','init_compare_row');
  ok($next,'next check 1');

  ($row,$cols,$next,$missing)=$s->compare_row(\%helper,\@list,$row,$cols);
  $check=join(', ',@$row);
  ok($check eq '2 - 7, 2 - 3, 0 - 2','compare_row 1');
  ok($next,'next check 2');

  ($row,$cols,$next,$missing)=$s->compare_row(\%helper,\@list,$row,$cols);
  $check=join(', ',@$row);
  ok($check eq '2 - 7, 2 - 3, 3 - 7','compare_row 2');
  ok($next,'next check 3');

  ($row,$cols,$next,$missing)=$s->compare_row(\%helper,\@list,$row,$cols);
  $check=join(', ',@$row);
  ok($check eq '2 - 7, 4 - 7, 3 - 7','compare_row 2');
  ok(!$next,'next check 4');
}
## new set of compare row data
## found this issue when porting the code to php
{
   my $data=[
     # 1
     [
       Data::Range::Compare->new(\%helper,0,1)
     ]

     # 2
     ,[
       Data::Range::Compare->new(\%helper,0,1)
       ,
       Data::Range::Compare->new(\%helper,2,3)
     ]

     # 3
     ,[
       Data::Range::Compare->new(\%helper,5,6)
     ]

     # 4
     ,[
       Data::Range::Compare->new(\%helper,0,6)
     ]

   ];
   my ($row,$cols,$next)=$s->init_compare_row(\%helper,$data);
   ok($next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==0,'checking column 2');
   ok($cols->[2]==-1,'checking column 3');
   ok($cols->[3]==0,'checking coumn 4');
   ok(join(', ',@$row) eq '0 - 1, 0 - 1, 0 - 4, 0 - 6'
     ,'check the sanity of the row');

  ($row,$cols,$next)=$s->compare_row(\%helper,$data,$row,$cols);
   ok($next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==1,'checking column 2');
   ok($cols->[2]==-1,'checking column 3');
   ok($cols->[3]==0,'checking coumn 4');
   ok(join(', ',@$row) eq '2 - 6, 2 - 3, 0 - 4, 0 - 6'
     ,'check the sanity of the row');
  ($row,$cols,$next)=$s->compare_row(\%helper,$data,$row,$cols);
   ok($next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==1,'checking column 2');
   ok($cols->[2]==-1,'checking column 3');
   ok($cols->[3]==0,'checking coumn 4');
   ok(join(', ',@$row) eq '2 - 6, 4 - 6, 0 - 4, 0 - 6'
     ,'check the sanity of the row');
  ($row,$cols,$next)=$s->compare_row(\%helper,$data,$row,$cols);
   ok(!$next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==1,'checking column 2');
   ok($cols->[2]==0,'checking column 3');
   ok($cols->[3]==0,'checking coumn 4');
   ok(join(', ',@$row) eq '2 - 6, 4 - 6, 5 - 6, 0 - 6'
     ,'check the sanity of the row');

}
{
   my $data=[
     # 1
     [
       Data::Range::Compare->new(\%helper,0,1)
     ]

     # 2
     ,[
       Data::Range::Compare->new(\%helper,0,1)
       ,
       Data::Range::Compare->new(\%helper,2,2)
     ]

     # 3
     ,[
       Data::Range::Compare->new(\%helper,5,6)
     ]

     # 4
     ,[
       Data::Range::Compare->new(\%helper,0,6)
     ]

   ];
   my ($row,$cols,$next)=$s->init_compare_row(\%helper,$data);
   ok($next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==0,'checking column 2');
   ok($cols->[2]==-1,'checking column 3');
   ok($cols->[3]==0,'checking coumn 4');
   ok(join(', ',@$row) eq '0 - 1, 0 - 1, 0 - 4, 0 - 6'
     ,'check the sanity of the row');

  ($row,$cols,$next)=$s->compare_row(\%helper,$data,$row,$cols);
   ok($next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==1,'checking column 2');
   ok($cols->[2]==-1,'checking column 3');
   ok($cols->[3]==0,'checking coumn 4');
   ok(join(', ',@$row) eq '2 - 6, 2 - 2, 0 - 4, 0 - 6'
     ,'check the sanity of the row');
  ($row,$cols,$next)=$s->compare_row(\%helper,$data,$row,$cols);
   ok($next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==1,'checking column 2');
   ok($cols->[2]==-1,'checking column 3');
   ok($cols->[3]==0,'checking coumn 4');
   ok(join(', ',@$row) eq '2 - 6, 3 - 6, 0 - 4, 0 - 6'
     ,'check the sanity of the row');
  ($row,$cols,$next)=$s->compare_row(\%helper,$data,$row,$cols);
   ok(!$next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==1,'checking column 2');
   ok($cols->[2]==0,'checking column 3');
   ok($cols->[3]==0,'checking coumn 4');
   ok(join(', ',@$row) eq '2 - 6, 3 - 6, 5 - 6, 0 - 6'
     ,'check the sanity of the row');

}
{
   my $data=[
     # 1
     [
       Data::Range::Compare->new(\%helper,0,1)
       ,Data::Range::Compare->new(\%helper,4,5)
     ]

     # 2
     ,[
       Data::Range::Compare->new(\%helper,0,1)
       ,
       Data::Range::Compare->new(\%helper,4,5)
     ]

     # 3
     ,[
       Data::Range::Compare->new(\%helper,0,1)
       ,
       Data::Range::Compare->new(\%helper,4,5)
     ]

   ];
   my ($row,$cols,$next)=$s->init_compare_row(\%helper,$data);
   ok($next,'should be a next value');
   ok($cols->[0]==0,'checking column 1');
   ok($cols->[1]==0,'checking column 2');
   ok($cols->[2]==0,'checking column 3');
   ok(join(', ',@$row) eq '0 - 1, 0 - 1, 0 - 1'
     ,'check the sanity of the row');

  ($row,$cols,$next)=$s->compare_row(\%helper,$data,$row,$cols);
   ok(!$next,'should be no next value');
   ok($cols->[0]==1,'checking column 1');
   ok($cols->[1]==1,'checking column 2');
   ok($cols->[2]==1,'checking column 3');
   ok(join(', ',@$row) eq '4 - 5, 4 - 5, 4 - 5'
     ,'check the sanity of the row');
}
## wrapper range_compare
{
  my @list=(
  [map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [0,1]]
  ,[map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [2,3] ]
  ,[map { Data::Range::Compare->new(\%helper,$_->[0],$_->[1]) } [3,7] ]
  );
  my $sub=$s->range_compare(\%helper,\@list);
  my $total=0;
  while(my @row=$sub->()) {
    ++$total;
  }
  ok($total==4,'range_compare');

}
#################################
#
### END OF THE UNIT TESTS
1;
__END__
