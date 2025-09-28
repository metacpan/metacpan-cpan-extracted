#!/usr/bin/env perl

use strict;
use warnings;

use App::Wikidata::Template::CS::CitaceMonografie;

# Arguments.
@ARGV = (
        '-l cs',
        '-p',
        'Q79324593',
);

# Run.
exit App::Wikidata::Template::CS::CitaceMonografie->new->run;

# Output like:
# {{Citace monografie
#  | autor = Mistr Eckhart
#  | isbn = 978-80-901884-8-8
#  | místo = Brno
#  | počet stran = 333
#  | překladatelé = Martin Mrskoš, Petr Snášil, Vilém Konečný
#  | rok = 2019
#  | titul = Kázání
#  | vydavatel = Horus
# }}