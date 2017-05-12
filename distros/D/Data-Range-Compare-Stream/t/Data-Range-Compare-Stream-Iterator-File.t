# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

use strict;
use warnings;
use IO::File;
use Test::More tests => 46 + 7;

BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::File') };

#########################

# most tests require this file to exist!
my $exists;
my $filename;

my $custom_file=-r 'custom_file.src' ? 'custom_file.src' : 't/custom_file.src' ? 't/custom_file.src' : undef;
# guess file locations
foreach my $location (qw(file_test.src t/file_test.src)) {
  $exists=-r $location;
  $filename=$location;
  last if $exists;
}


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#
# Basic Constructor tests

{
  my $bad_args=Data::Range::Compare::Stream::Iterator::File->new;
  ok($bad_args->in_error,'no file should show an error state') or diag(Dumper($bad_args));
}

SKIP: {
  skip 'Cannot read from file_test.src',12 unless $exists;
  
  my $s=new Data::Range::Compare::Stream::Iterator::File(filename=>$filename);
  ok($s,'instance should exist!');
  ok(!$s->in_error,'Instance should not be in error!');
  
  ok($s->has_next,'instance should have next');

  cmp_ok($s->get_next.'','eq',''.'1 - 2','first row should be: 1 - 2');
  ok($s->has_next,'instance should have row 2');
  cmp_ok($s->get_next.'','eq',''.'3 - 4','first row should be: 3 - 4');

  ok($s->has_next,'instance should have row 3');
  cmp_ok($s->get_next.'','eq',''.'5 - 6','first row should be: 7 - 8');

  ok($s->has_next,'instance should have row 3');
  cmp_ok($s->get_next.'','eq',''.'7 - 8','first row should be: 1 - 2');

  ok(!$s->has_next,'instance should have no more rows!');
  undef $s;
}

SKIP: {
  skip 'Cannot read from file_test.src',16 unless $exists;
  my $fh=IO::File->new($filename);
  skip 'Cannot read from file_test.src',16 unless $fh;

  my $s=new Data::Range::Compare::Stream::Iterator::File(fh=>$fh);

  ok(!$s->in_error,'Instance should not be in error!');
  
  ok($s->has_next,'instance should have next');
  cmp_ok($s->get_pos,'==',0,'current position check');

  cmp_ok($s->get_next.'','eq',''.'1 - 2','first row should be: 1 - 2');
  cmp_ok($s->get_pos,'==',1,'current position check');
  cmp_ok($s->get_size,'==',4,'get_size check');

  ok($s->has_next,'instance should have row 2');
  cmp_ok($s->get_next.'','eq',''.'3 - 4','first row should be: 3 - 4');
  cmp_ok($s->get_pos,'==',2,'current position check');

  ok($s->has_next,'instance should have row 3');
  cmp_ok($s->get_next.'','eq',''.'5 - 6','first row should be: 7 - 8');
  cmp_ok($s->get_pos,'==',3,'current position check');

  ok($s->has_next,'instance should have row 3');
  cmp_ok($s->get_next.'','eq',''.'7 - 8','first row should be: 1 - 2');
  cmp_ok($s->get_pos,'==',4,'current position check');

  ok(!$s->has_next,'instance should have no more rows!');

}

SKIP: {
  skip 'cannot read from custom file',17 unless $custom_file;

  {
    package MyTestPkg;
    use strict;

    use base qw(Data::Range::Compare::Stream);
    use constant NEW_FROM_CLASS=>'MyTestPkg';

    1;
  }
  my $parse_line=sub {
    my ($line)=@_;
    my @data=split /\s+/,$line;
    return [@data[1,2],$line];
  };
  my $result_to_line=sub {
    my ($result)=@_;
    return $result->data;
  };
  my $s=new Data::Range::Compare::Stream::Iterator::File(NEW_FROM=>'MyTestPkg',result_to_line=>$result_to_line,parse_line=>$parse_line,filename=>$custom_file);
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
}


SKIP: {
  skip 'Cannot read from file_test.src',7 unless $custom_file;
  my $check=0;
  {
    package MyFilePkg;
    use base qw(Data::Range::Compare::Stream::Iterator::File);
    sub DESTROY {
      my ($self)=@_;
      ++$check if defined($self->{fh});
      $self->SUPER::DESTROY;
      ++$check unless defined($self->{fh});
      
    }

    1;
  }
  cmp_ok($check,'==',0,'check status');
  {
    my $s=new MyFilePkg(filename=>$custom_file);
    ok(defined($s->get_fh),'should fetch the file handle without error');
    ok($s->created_fh,'get created file handle state');
    undef $s;
  }
  cmp_ok($check,'==',2,'check status');
  $check=0;
  {
    my $fh=IO::File->new($custom_file,'r');
    my $s=new MyFilePkg(fh=>$fh);
    ok(!$s->created_fh,'get created file handle state');
    ok(defined($s->get_fh),'should fetch the file handle without error');
    undef $s;
  }
  cmp_ok($check,'==',1,'check status');




}
