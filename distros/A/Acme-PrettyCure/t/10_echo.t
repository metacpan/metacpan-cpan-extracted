use strict;
use warnings;
use utf8;
use t::Utils;

use Acme::PrettyCure::Girl::CureEcho;

my $ayumi = Acme::PrettyCure::Girl::CureEcho->new;

is_output sub { $ayumi->transform; }, <<EOS, '変身時の台詞';
想いよ届け! キュアエコー!
EOS

done_testing;

