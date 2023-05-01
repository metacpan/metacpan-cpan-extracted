#!/usr/bin/env perl

use strict;
use warnings;

use App::Wikidata::Print;

# Arguments.
@ARGV = (
        '-l cs',
        'P2668',
);

# Run.
exit App::Wikidata::Print->new->run;

# Output like:
# Data type: wikibase-item
# Label: proměnlivost hodnot (cs)
# Description: pravděpodobnost, že se prohlášení s touto vlastností změní (cs)
# Statements:
#   P2302: Q21503250 (normal)
#    P2308: Q18616576
#    P2309: Q21503252
#    P2316: Q21502408
#   P2302: Q21510865 (normal)
#    P2308: Q23611439
#    P2309: Q21503252
#   P2302: Q52004125 (normal)
#    P2305: Q29934218
#   P2302: Q53869507 (normal)
#    P5314: Q54828448
#   P2302: Q21503247 (normal)
#    P2306: P2302
#   P2302: Q21510859 (normal)
#    P2305: Q23611288
#    P2305: Q24025284
#    P2305: Q23611840
#    P2305: Q23611587
#    P2305: unknown value
#   P2668: Q24025284 (normal)
#   P3254: https://www.wikidata.org/wiki/Wikidata:Property_proposal/Archive/48#P2668 (normal)
#   P31: Q19820110 (normal)
#   P2271: P569 (normal)
#    P2668: Q23611288
#   P2271: P1082 (normal)
#    P2668: Q23611587
#   P2271: P39 (normal)
#    P2668: Q23611840
#   P2271: P3185 (normal)
#    P2668: Q24025284
#   P2271: P11021 (normal)
#    P2668: unknown value
#   P1629: Q23611439 (normal)
#   P2559: use only instances of Q23611439 as values (en) (normal)
#   P2559: nur Instanzen von Q23611439 als Werte verwenden (de) (normal)
#   P2559: utiliser uniquement les instances de Q23611439 comme valeurs (fr) (normal)
#   P2559: usar solo instancias del elemento Q23611439 (es) (normal)
#   P2559: у якасьці значэньняў ужывайце толькі сутнасьці элемэнту Q23611439 (be-tarask) (normal)
#   P2559: bruk kun forekomster av Q23611439 som verdier (nb) (normal)
#   P2559: 请只将性质为Q23611439（维基数据属性更改频率）的项作为值 (zh-hans) (normal)
#   P2559: gebruik alleen items van Q23611439 als waarden (nl) (normal)
#   P2559: usar só instancias do elemento Q23611439 (gl) (normal)
#   P2559: jako hodnoty používejte pouze instance Q23611439 (cs) (normal)
#   P2559: usare solo istanze di Q23611439 come valori (it) (normal)
#   P2559: utilitzeu només les instàncies de Q23611439 com a valors (ca) (normal)