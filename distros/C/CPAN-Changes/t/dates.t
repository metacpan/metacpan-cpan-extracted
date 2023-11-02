use strict;
use warnings;
use Test::More;

use CPAN::Changes::Parser;

my $parser = CPAN::Changes::Parser->new;

my $changes = $parser->parse_file('corpus/test/date_formats.changes');

for my $release ($changes->releases) {
    my $date = $release->date;
    my $note = $release->note;
    my ($want) = $note =~ /WANT:(.*)/;
    $want = undef
      if $want eq 'undef';

    is $date, $want, 'correct date for ' . $release->version;
}

done_testing;
