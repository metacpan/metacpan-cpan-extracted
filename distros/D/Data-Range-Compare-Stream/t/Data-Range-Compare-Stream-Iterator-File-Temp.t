

use strict;
use warnings;
use Test::More qw(no_plan);
use File::Temp qw(tempdir);
use File::Basename;

use_ok('Data::Range::Compare::Stream::Iterator::File::Temp');


{
  package TmpTest;
  use strict;
  use warnings;

  use base qw(Data::Range::Compare::Stream::Iterator::File::Temp);

  sub new {
    my ($class,%args)=@_;
    bless {%args},$class;

  }
  1;
}


{
  
  my $dir= tempdir( CLEANUP => 1 );
  ok(-d $dir,'temp folder should exist!');

  my $s=TmpTest->new(tmpdir=>$dir);

  my $file=$s->get_temp;

  my $foldername=dirname($file->filename);

  cmp_ok($foldername,'eq',$dir,'folder of the temp file should be our folder');

  $file->close;
  unlink $file;
}

