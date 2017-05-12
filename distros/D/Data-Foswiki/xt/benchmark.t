#!perl -T

use strict;
use warnings;
use Test::More;
use Carp;
use Data::Dumper;
use Data::Foswiki;
#use Data::Foswiki::Test;

eval {
    require Benchmark;
    Benchmark->import(qw( timestr countit timethese cmpthese :hireswallclock));
};

plan skip_all => "Benchmark module needed for this test" if $@;
plan tests => 1;

my @topicList = qw(
  /var/lib/foswiki/data/System/ReleaseNotes01x01.txt
  /var/lib/foswiki/data/System/NewUserTemplate.txt
  /var/lib/foswiki/data/System/WebHome.txt
  /var/lib/foswiki/data/System/WebPreferences.txt
  /var/lib/foswiki/data/System/DefaultPreferences.txt
  /var/lib/foswiki/data/Main/WebPreferences.txt
  /var/lib/foswiki/data/Main/SitePreferences.txt
  /var/lib/foswiki/data/System/FAQDownloadSources.txt
);
my $topicPath = $topicList[0];
plan skip_all => 'need a foswiki install at /var/lib/foswiki'
  unless ( -e $topicPath );

my @topics;
foreach my $file (@topicList) {
    open( my $fh, '<', $topicPath ) or die 'horribly';
    my @topic = <$fh>;
    close($fh);
    push( @topics, \@topic );
}

# ...or in two stages
if (1==2) {
    my $results = timethese(
        -10,
        {
            'Foswiki::deserialise' => sub {
                foreach my $topic (@topics) {
                    my $data = Data::Foswiki::deserialise(@$topic);
                }
            },
    #        'Foswiki::Test::deserialise' =>
    #          sub { 
    #            foreach my $topic (@topics) {
    #                my $data = Data::Foswiki::Test::deserialise(@$topic);
    #            }
    #        },
        },
        'none'
    );

    #print STDERR Dumper($results);
}

my $seconds = 5;
my $t = countit(5, sub {
            foreach my $topic (@topics) {
                my $data = Data::Foswiki::deserialise(@$topic);
            }
            });
my $count = $t->iters;
print STDERR "$count loops of other code took:",timestr($t),"\n";
ok($count > ($seconds*4000), 'too slow (running on my quiet server)');

1;
