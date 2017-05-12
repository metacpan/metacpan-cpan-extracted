#!perl
# $Id: 11_read_using_Locale-Maketext.pl 347 2009-04-27 18:15:05Z steffenw $

use strict;
use warnings;

our $VERSION = 0;

use Locale::TextDomain qw(table_plural ./LocaleData/);
use Tie::Sub (); # allow to write a subroutine call as fetch hash

if ($ENV{MOD_PERL}) {
    Locale::Messages->select_package('gettext_pp');
}

local $ENV{LANGUAGE} = 'de_DE';

tie my %__x,  'Tie::Sub', sub { return __x(shift, @_) }; ## no critic (Ties)
tie my %__nx, 'Tie::Sub', sub { return __nx(shift, shift, shift, @_) }; ## no critic (Ties)

# write a long text with all the different translatons
print <<"EOT"; ## no critic (CheckedSyscalls)
$__x{'text1 original'}

$__x{"text2 original\n2nd line of text2"}

$__x{['text5 original {text}', text => 'is good']}

$__nx{['text6 original {num} singular', 'text6 original {num} plural', 0, num => 0]}

$__nx{['text6 original {num} singular', 'text6 original {num} plural', 1, num => 1]}

$__nx{['text6 original {num} singular', 'text6 original {num} plural', 1.5, num => 1.5]}

$__nx{['text6 original {num} singular', 'text6 original {num} plural', 2, num => 2]}

$__nx{['text6 original {num} singular', 'text6 original {num} plural', 0, num => 0]}
EOT
;