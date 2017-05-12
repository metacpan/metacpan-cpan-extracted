use strict;
use warnings;
use Test::More;
use AnnoCPAN::XMLCGI;

#plan 'no_plan';
plan tests => 6;

open STDIN, '<', 't/note.xml' or die;

my $cgi = AnnoCPAN::XMLCGI->new;

isa_ok ( $cgi,  'AnnoCPAN::XMLCGI' );
is ( $cgi->param('section'),    123,                'param(section)' );
is ( $cgi->param('mode'),       'show',             'param(mode)' );
is ( $cgi->param('note_text'),  'This is a note',   'param(note_text)' );
is ( $cgi->param('id'),         5,                  'param(id)' );

is ( $cgi->header,  "Content-type: text/html; charset=UTF-8\n\n",  'header' );

