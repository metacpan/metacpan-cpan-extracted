use strict;
use warnings;
use Data::Dumper;

use Test::More tests=>8291;

use File::Temp qw(tempdir);
use File::Basename;
my $dir= tempdir( CLEANUP => 1 );


use Data::Range::Compare::Stream::Iterator::File;
use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream::Sort;

BEGIN {
  use_ok('Data::Range::Compare::Stream::Iterator::File::MergeSortAsc');
};

my $custom_file=-r 'custom_file.src' ? 'custom_file.src' : 't/custom_file.src' ? 't/custom_file.src' : undef;

my $file;
foreach my $check (qw(merg_sort_test.src t/merg_sort_test.src)) {
  if(-r $check) {
    $file=$check;
    last;
  }
}
my $big_file;
foreach my $check (qw(merg_sort_size_test.src t/merg_sort_size_test.src)) {
  if(-r $check) {
    $big_file=$check;
    last;
  }
}

SKIP: {
  skip 'cannot open test file',60 unless $file;
{
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(file_list=>[$file]);
  ok($obj,'object should exist as true!');
  ok($obj->has_next,'object should have next');
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 3','result cmp');
  }
  {
    ok($obj->has_next);
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result cmp');
  }
  {
    ok($obj->has_next);
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','result cmp');
  }
}
{
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(filename=>$file);
  ok($obj,'object should exist as true!');
  ok($obj->has_next,'object should have next');
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 3','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','result cmp');
  }
}
{
  my $base_it=new Data::Range::Compare::Stream::Iterator::File(filename=>$file);
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(iterator_list=>[$base_it]);
  ok($obj,'object should exist as true!');
  ok($obj->has_next,'object should have next');
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 3','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','result cmp');
  }
}
{
  my $base_it=new Data::Range::Compare::Stream::Iterator::File(filename=>$file);
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(auto_prepare=>1,file_list=>[$file],iterator_list=>[$base_it]);

  ok($obj,'object should exist as true!');
  ok($obj->has_next,'object should have next') or diag($obj->get_result_file);
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 3','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 3','result cmp');
  }

  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result cmp');
  }

  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','result cmp');
  }
}
{
  my $base_it=new Data::Range::Compare::Stream::Iterator::File(filename=>$file);
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(filename=>$file,file_list=>[$file],iterator_list=>[$base_it]);
  ok($obj,'object should exist as true!');
  ok($obj->has_next,'object should have next');
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 3','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 3','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 3','result cmp');
  }

  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result cmp');
  }

  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','result cmp');
  }
  {
    my $result=$obj->get_next;
    ok(defined($result),'result object should be defined');
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','result cmp');
  }
} 

}

{
  my $array=new Data::Range::Compare::Stream::Iterator::Array(sorted=>1);
  $array->insert_range(Data::Range::Compare::Stream->new(1,1));
  $array->insert_range(Data::Range::Compare::Stream->new(2,2));
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(iterator_list=>[$array]);
  ok($obj,'object should exists');
  {
    ok($obj->has_next,'should have next');
    my $result=$obj->get_next;
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 1','result check');
  }
  {
    ok($obj->has_next,'should have next');
    my $result=$obj->get_next;
    my $string=$result->to_string;
    cmp_ok($string,'eq','2 - 2','result check');
  }
  ok(!$obj->has_next,'should not have next');
}

if(1) {
SKIP: {
  skip 'cannot open test file',8194 unless $big_file;
  
  # Make sure our bucket size makes good use of temp files!
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(bucket_size=>100,filename=>$big_file);

  ok($obj,'object should exists');
  my $total=0;
  my $last_range=new Data::Range::Compare::Stream(0,4266);
  while($obj->has_next) {
    ++$total;
    my $result=$obj->get_next;
    cmp_ok(sort_in_consolidate_order_asc($last_range,$result),'!=',1,'range sort check') or diag("$last_range $result");
    $last_range=$result;
  }
  cmp_ok($total,'==',8192,'result count total');
}
}

{
  my $array=new Data::Range::Compare::Stream::Iterator::Array(sorted=>1);
  $array->insert_range(Data::Range::Compare::Stream->new(0,0));
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(iterator_list=>[$array]);
  ok($obj,'object should exists');
  {
    ok($obj->has_next,'should have next');
    my $result=$obj->get_next;
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 0','result check');
  }
  ok(!$obj->has_next,'should not have next');
  my $result_file=$obj->get_result_file;
  ok(-e $result_file,'result file should exist');
  undef $obj;
  ok(!-e $result_file,'result file should no longer exist');
}
{
  my $array=new Data::Range::Compare::Stream::Iterator::Array(sorted=>1);
  $array->insert_range(Data::Range::Compare::Stream->new(0,0));
  my $obj=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(unlink_result_file=>0,iterator_list=>[$array]);
  ok($obj,'object should exists');
  {
    ok($obj->has_next,'should have next');
    my $result=$obj->get_next;
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 0','result check');
  }
  ok(!$obj->has_next,'should not have next');
  my $result_file=$obj->get_result_file;
  ok(-e $result_file,'result file should exist');
  undef $obj;
  ok(-e $result_file,'result file should exist');
  unlink $result_file;
}

SKIP: {
  skip 'cannot read from custom file',17 unless $custom_file;

  {
    package MyTestPkg;
    use strict;
    use warnings;

    use base qw(Data::Range::Compare::Stream);
    use constant NEW_FROM_CLASS=>'MyTestPkg';

    1;
  }
  my $parse_line=sub {
    my ($line)=@_;
    my @data=split /\s+/,$line;
    my $ref=[@data[1,2],$line];

    $ref;
  };
  my $result_to_line=sub {
    my ($result)=@_;
    my $line=$result->data;
    $line;
  };

  my $s=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(
      parse_line=>$parse_line,
      NEW_FROM=>'MyTestPkg',
      result_to_line=>$result_to_line,
      filename=>$custom_file,
      tmpdir=>$dir
  );
  ok($s,'object should exist');
  {
    ok($s->has_next,'has_next check');
    my $result=$s->get_next;
    isa_ok($result,'MyTestPkg','NEW_FROM test');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 2','result check');
    $string=$result->data;
    cmp_ok($string,'eq',"COL_1 0 2\n",'raw data check');
    $string=$s->result_to_line($result);
    cmp_ok($string,'eq',"COL_1 0 2\n",'raw data check');
  }
  {
    ok($s->has_next,'has_next check');
    my $result=$s->get_next;
    isa_ok($result,'MyTestPkg','NEW_FROM test');
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 1','result check');
    $string=$result->data;
    cmp_ok($string,'eq',"COL_2 0 1\n",'raw data check');
    $string=$s->result_to_line($result);
    cmp_ok($string,'eq',"COL_2 0 1\n",'raw data check');
  }
  {
    ok($s->has_next,'has_next check');
    my $result=$s->get_next;
    isa_ok($result,'MyTestPkg','NEW_FROM test');
    my $string=$result->to_string;
    cmp_ok($string,'eq','3 - 4','result check');
    $string=$result->data;
    cmp_ok($string,'eq',"COL_3 3 4\n",'raw data check');
    $string=$s->result_to_line($result);
    cmp_ok($string,'eq',"COL_3 3 4\n",'raw data check');
  }
  ok(!$s->has_next,'has_next check');
  cmp_ok(dirname($s->get_result_file),'eq',$dir,'temp file check');


}

