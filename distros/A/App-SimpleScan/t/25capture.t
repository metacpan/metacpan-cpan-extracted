use Test::More tests=>1;
use Test::Differences;
$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `echo "http://fake.video.fr/q=clips+pour+madonna /(Recherche) de vidéos <b>pour/ Y French video matches"| $^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -gen`;
@expected = (map {"$_\n"} (split /\n/,<<EOS));
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://fake.video.fr/q=clips+pour+madonna",
          qr/(Recherche) de vidéos <b>pour/,
          qq(French video matches [http://fake.video.fr/q=clips+pour+madonna] [/(Recherche) de vidéos <b>pour/ should match]);
EOS
push @expected,"\n";
eq_or_diff [@output], [@expected], "got expected output";
