use strict;
use warnings;
use Test::More;
use lib qw( t/TestApp/lib );

BEGIN {
  eval "require IO::Capture::Stderr";
  if ( $@ ) {
    plan skip_all => 'requires IO::Capture::Stderr';
  }
}

plan tests => 4;

local $ENV{CM_JDBI_MEMORY} = 1;

use TestApp::Model::JDBI;

my $model   = TestApp::Model::JDBI->new;
my $capture = IO::Capture::Stderr->new;

clear();

$model->setup_database;

ok !capture(), 'no log by default';

$model->trace(1);

ok capture(), 'logged';

$model->trace(0);

ok !capture(), 'log disabled';

$model->trace(sub { print STDERR 'logged' });

ok capture() eq 'logged', 'logger is replaced';

END { clear() }

sub clear {
  my $database = $model->database;
  if ( $database && -f $database && -s $database ) {
    $model->disconnect;
    unlink $database;
  }
}

sub capture {
  $capture->start;
  my $author = $model->record('Author');
     $author->load(1);
  $capture->stop;

  return $capture->read;
}
