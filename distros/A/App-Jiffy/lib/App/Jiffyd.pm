package App::Jiffyd;

use strict;
use warnings;

use Dancer;
use App::Jiffy::TimeEntry;
use YAML::Any qw( LoadFile );

my $cfg = LoadFile( $ENV{HOME} . '/.jiffy.yml' ) || {};

post '/timeentry' => sub {

  # Create and save Entry
  App::Jiffy::TimeEntry->new(
    title => param 'title',
    cfg   => $cfg,
  )->save;
};

1;
