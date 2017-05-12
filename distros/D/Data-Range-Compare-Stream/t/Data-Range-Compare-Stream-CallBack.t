use strict;
use warnings;
use Test::More tests=>95;
use Data::Dumper;

# full feature unit test for:
# Data::Range::Compare::Stream::CallBack
#
# Using a common instance seems to solve the %HELPER Concept
# used in the original DRC class.  Although DRC and DRCS will
# always differ in thier result sets, this is a big step in
# bridging the compatibility gap.
#
use_ok('Data::Range::Compare::Stream::CallBack');
use Data::Range::Compare::Stream::CallBack qw(%HELPER);
use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream::Iterator::File::MergeSortAsc;
use Data::Range::Compare::Stream::Iterator::File;
use Data::Range::Compare::Stream::Iterator::Validate;
use Data::Range::Compare::Stream::Iterator::Consolidate;
use Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc;
use Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;
use Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn;

# factory overload testing
eval {

  my $count=0;

  my $helper={
    sub_one=>sub { ++$count;$_[0] -1 },
    add_one=>sub { ++$count;$_[0] + 1 },
    cmp_values=>sub { ++$count;$_[0] <=> $_[1] }
  };
  my $obj=new Data::Range::Compare::Stream::CallBack($helper,0,0);
  isa_ok($obj,'Data::Range::Compare::Stream::CallBack');

  cmp_ok($obj->add_one(1),'==',2,'add_one check');
  cmp_ok($obj->sub_one(1),'==',0,'sub_one check');
  cmp_ok($obj->cmp_values(0,0),'==',0,'cmp_values check same');
  cmp_ok($obj->cmp_values(1,0),'==',1,'cmp_values check left is more');
  cmp_ok($obj->cmp_values(0,1),'==',-1,'cmp_values check right is more');
  cmp_ok($count,'==',5,'make sure the call backs were actually used');
  ok($obj,'instance should return true');

  cmp_ok($obj->to_string,'eq','0 - 0','to string check');

  my $child=$obj->factory(0,1);

  isa_ok($child,'Data::Range::Compare::Stream::CallBack');
  cmp_ok($child->add_one(1),'==',2,'add_one check');
  cmp_ok($child->sub_one(1),'==',0,'sub_one check');
  cmp_ok($child->cmp_values(0,0),'==',0,'cmp_values check same');
  cmp_ok($child->cmp_values(1,0),'==',1,'cmp_values check left is more');
  cmp_ok($child->cmp_values(0,1),'==',-1,'cmp_values check right is more');
  cmp_ok($count,'==',11,'make sure the call backs were actually used');
  cmp_ok($child->to_string,'eq','0 - 1','to string check');

  my $bad=$obj->factory(1,0);
  isa_ok($bad,'Data::Range::Compare::Stream::CallBack');
  ok(!$bad,'instance should be false!');
};

# Iterator::Array testing
eval {
  my $factory_instance=new Data::Range::Compare::Stream::CallBack(\%HELPER);
  isa_ok($factory_instance,'Data::Range::Compare::Stream::CallBack');

  my $it=new Data::Range::Compare::Stream::Iterator::Array(
    factory_instance=>$factory_instance,
  );
  $it->create_range(0,1);
  $it->create_range(0,0);
  $it->create_range(1,1);
  $it->prepare_for_consolidate_asc;
  my $list=[];
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','0 - 1');
  }
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','0 - 0');
  }
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','1 - 1');
  }
};

# Iterator::File testing
eval {
  my $factory_instance=new Data::Range::Compare::Stream::CallBack(\%HELPER);
  isa_ok($factory_instance,'Data::Range::Compare::Stream::CallBack');

  my $fit=new Data::Range::Compare::Stream::Iterator::File(
    filename=>'t/file_test.src',
    factory_instance=>$factory_instance
  );
  isa_ok($fit,'Data::Range::Compare::Stream::Iterator::File');
  my $bad;
  my $it=new Data::Range::Compare::Stream::Iterator::Validate($fit,on_bad_range=>sub { ++$bad });


  
  while($it->has_next) {
    my $next=$it->get_next;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');
  }
  ok(!$bad,'should not have any bad ranges');
  

};

# MergeSortAsc testing
eval {
  my $factory_instance=new Data::Range::Compare::Stream::CallBack(\%HELPER);
  my $it=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(
    file_list=>[qw(t/file_test.src t/merg_sort_test.src)],
    bucket_size=>1,
    factory_instance=>$factory_instance,
  );

  while($it->has_next) {
    my $next=$it->get_next;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');
  }

};
diag $@ if $@;

# Consolidation test
eval {
  my $factory_instance=new Data::Range::Compare::Stream::CallBack(\%HELPER);
  my $fit=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(
    file_list=>[qw(t/file_test.src t/merg_sort_test.src)],
    factory_instance=>$factory_instance,
  );
  my $it=new Data::Range::Compare::Stream::Iterator::Consolidate($fit,factory_instance=>$factory_instance);
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','0 - 4','consolidation validation');

  }
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','5 - 6','consolidation validation');

  }

  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','7 - 8','consolidation validation');

  }
  ok(!$it->has_next);
};

eval {
  my $factory_instance=new Data::Range::Compare::Stream::CallBack(\%HELPER);
  my $fit=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(
    file_list=>[qw(t/file_test.src t/merg_sort_test.src)],
    factory_instance=>$factory_instance,
  );
  my $ito=new Data::Range::Compare::Stream::Iterator::Consolidate($fit,factory_instance=>$factory_instance);
  my $it=new Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc($ito,factory_instance=>$factory_instance);
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','0 - 8','consolidation validation');

  }

  ok(!$it->has_next);
};
# testing of Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing;
eval {
  my $factory_instance=new Data::Range::Compare::Stream::CallBack(\%HELPER);
  isa_ok($factory_instance,'Data::Range::Compare::Stream::CallBack');

  my $ita=new Data::Range::Compare::Stream::Iterator::Array(
    factory_instance=>$factory_instance,
  );
  $ita->create_range(0,1);
  $ita->create_range(4,5);
  $ita->create_range(7,8);
  $ita->prepare_for_consolidate_asc;
  my $itc=new Data::Range::Compare::Stream::Iterator::Consolidate($ita,factory_instance=>$factory_instance);
  my $it=new Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing($itc,factory_instance=>$factory_instance);
  my $list=[];
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','0 - 1');
  }
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','2 - 3');
  }
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','4 - 5');
  }
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','6 - 6');
  }
  {
    ok($it->has_next,'should have next');
    my $next=$it->get_next->get_common;
    isa_ok($next,'Data::Range::Compare::Stream::CallBack');

    my $string=$next->to_string;
    cmp_ok($string,'eq','7 - 8');
  }

  ok(!$it->has_next,'should be empty now');
};

# Data::Range::Compare::Stream::Iterator::Compare::Asc
eval {
  my $factory_instance=new Data::Range::Compare::Stream::CallBack(\%HELPER);
  my $sets=[
    [ qw( 
      0 0 
      1 4 
      9 11 
      16 42 )]
    ,[qw(
      3 7
      9 21
    )]
  ];
  my $con=new Data::Range::Compare::Stream::Iterator::Compare::Asc(
    factory_instance=>$factory_instance,
  );
  foreach my $set (@$sets) {
    my $ita=new Data::Range::Compare::Stream::Iterator::Array(
      factory_instance=>$factory_instance,
    );
    while(my ($start,$end)=splice @$set,0,2) {
      $ita->create_range($start,$end);
    }
    $ita->prepare_for_consolidate_asc;
    my $itc=new Data::Range::Compare::Stream::Iterator::Consolidate($ita,factory_instance=>$factory_instance);
    $con->add_consolidator($itc);
  }
  while($con->has_next) {
    my $next=$con->get_next;
    my $common=$next->get_common;
    isa_ok($common,'Data::Range::Compare::Stream::CallBack');
  }
};


eval {
  my $factory_instance=new Data::Range::Compare::Stream::CallBack(\%HELPER);
  my $sets=[
    [ qw( 
      0 2 
      0 0 
      1 4 
      9 11 
      10 10
      16 42 )]
    ,[qw(
      3 7
      9 21
    )]
  ];
  my $con=new Data::Range::Compare::Stream::Iterator::Compare::Asc(
    factory_instance=>$factory_instance,
  );
  foreach my $set (@$sets) {
    my $ita=new Data::Range::Compare::Stream::Iterator::Array(
      factory_instance=>$factory_instance,
    );
    while(my ($start,$end)=splice @$set,0,2) {
      $ita->create_range($start,$end);
    }
    $ita->prepare_for_consolidate_asc;
    my $itc=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn(
      $ita,
      $con,
      factory_instance=>$factory_instance
    );
    $con->add_consolidator($itc);
  }
  while($con->has_next) {
    my $next=$con->get_next;
    my $common=$next->get_common;
    isa_ok($common,'Data::Range::Compare::Stream::CallBack');
  }
};



# End of the unit tests!
#done_testing();
