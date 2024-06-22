#!/usr/bin/env perl

use strict;
use warnings;

use App::Wikidata::Print;

# Arguments.
@ARGV = (
        '-l', 'cs',
        'P2668',
);

# Run.
exit App::Wikidata::Print->new->run;

# Output like:
# Datový typ: wikibase-item
# Štítek: proměnlivost hodnot (cs)
# Popis: pravděpodobnost, že se prohlášení s touto vlastností změní (cs)
# Výroky:
#   P2559: use only instances of Q23611439 as values (en) (normální)
#   P2559: nur Instanzen von Q23611439 als Werte verwenden (de) (normální)
#   P2559: utiliser uniquement les instances de Q23611439 comme valeurs (fr) (normální)
#   P2559: usar solo instancias del elemento Q23611439 (es) (normální)
#   P2559: # ####### ########## ######## ###### ######### ######## Q23611439 (be-tarask) (normální)
#   P2559: bruk kun forekomster av Q23611439 som verdier (nb) (normální)
#   P2559: # # # # # # Q23611439( # # # # # # # # # # ) # # # # #  (zh-hans) (normální)
#   P2559: gebruik alleen items van Q23611439 als waarden (nl) (normální)
#   P2559: usar só instancias do elemento Q23611439 (gl) (normální)
#   P2559: jako hodnoty používejte pouze instance Q23611439 (cs) (normální)
#   P2559: usare solo istanze di Q23611439 come valori (it) (normální)
#   P2559: utilitzeu només les instàncies de Q23611439 com a valors (ca) (normální)
#   P2302: Q21503250 (normální)
#    P2308: Q18616576
#    P2309: Q21503252
#    P2316: Q21502408
#   P2302: Q21510865 (normální)
#    P2308: Q23611439
#    P2309: Q21503252
#   P2302: Q52004125 (normální)
#    P2305: Q29934218
#   P2302: Q53869507 (normální)
#    P5314: Q54828448
#   P2302: Q21503247 (normální)
#    P2306: P2302
#   P2302: Q21510859 (normální)
#    P2305: Q23611288
#    P2305: Q24025284
#    P2305: Q23611840
#    P2305: Q23611587
#    P2305: neznámá hodnota
#   P2271: P569 (normální)
#    P2668: Q23611288
#   P2271: P1082 (normální)
#    P2668: Q23611587
#   P2271: P39 (normální)
#    P2668: Q23611840
#   P2271: P3185 (normální)
#    P2668: Q24025284
#   P2271: P11021 (normální)
#    P2668: neznámá hodnota
#   P1629: Q23611439 (normální)
#   P3254: https://www.wikidata.org/wiki/Wikidata:Property_proposal/Archive/48#P2668 (normální)
#   P31: Q19820110 (normální)
#   P2668: Q24025284 (normální)