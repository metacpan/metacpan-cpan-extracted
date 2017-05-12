# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);
use strict;
use utf8;

use Convert::CEGH::Gematria 'enumerate';

is ( 1, 1, "loaded." );


is ( enumerate ( "አዳም" ), 45, "Ge'ez  Gematria"  );
is ( enumerate ( "ΑΔΑΜ" ), 46, "Greek  Gematria" );
is ( enumerate ( "מדא" ), 45, "Hebrew Gematria"  );
