use strict; use warnings;
package DJSON;
our $VERSION = '0.0.8';

use Pegex;

use base 'Exporter';
our @EXPORT = qw(decode_djson);

sub decode_djson {
    pegex(
        djson_grammar(),
        'DJSON::Receiver',
    )->parse($_[0]);
}

use constant djson_grammar => <<'...';
%grammar djson
%version 0.0.1

djson: map | seq | list

node: map | seq | scalar

map:
    /- LCURLY -/
    pair*
    /- RCURLY -/

pair: string /- COLON? -/ node /- COMMA? -/

seq:
    /- LSQUARE -/
    node* %% /- COMMA? -/
    /- RSQUARE -/

list: node* %% /- COMMA? -/

scalar: double | single | bare

string: scalar

double: /
    DOUBLE
    ([^ DOUBLE ]*)
    DOUBLE
/

single: /
    SINGLE
    ([^ SINGLE ]*)
    SINGLE
/

bare: /(
    [^
        WS
        LCURLY RCURLY
        LSQUARE RSQUARE
        SINGLE DOUBLE
        COMMA
    ]+
)/

ws: /(: WS | comment )/

comment: / HASH SPACE ANY* BREAK /
...

###############################################################################
# The receiver class can reshape the data at any given rule match.
###############################################################################
package DJSON::Receiver;
use base 'Pegex::Tree';
use boolean;

sub got_string {"$_[1]"}
sub got_map { +{ map {($_->[0], $_->[1])} @{$_[1]->[0]} } }
sub got_seq { $_[1]->[0] }
sub got_bare {
    $_ = pop;
    /true/ ? true :
    /false/ ? false :
    /null/ ? undef :
    /^(
        -?
        (?: 0 | [1-9] [0-9]* )
        (?: \. [0-9]* )?
        (?: [eE] [\-\+]? [0-9]+ )?
    )$/x ? ($_ + 0) :
    "$_"
}

1;
