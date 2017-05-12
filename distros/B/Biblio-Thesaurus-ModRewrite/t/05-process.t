#!perl

use Test::More tests => 7;
use Test::Output;

use Biblio::Thesaurus;
use Biblio::Thesaurus::ModRewrite;

sub proc {
	my $code = shift;
	my $obj = thesaurusLoad('examples/geo.iso');
	my $t = Biblio::Thesaurus::ModRewrite->new($obj);
	$t->process($code);
}

# 1 -- term relation term
output_is { proc(<<'CODE') } <<'OUTPUT','','term relation term';
Braga 'CITY-OF' Portugal => sub { print "found\n"; }.
CODE
found
OUTPUT

# 2 -- $t relation term
output_is { proc(<<'CODE') } <<'OUTPUT','','$t relation term';
$city 'CITY-OF' Portugal => sub { print $city . "\n"; }.
CODE
Braga
Guimaraes
Lisboa
Porto
OUTPUT

# 3 -- term relation $t
output_is { proc(<<'CODE') } <<'OUTPUT','','term relation $t';
Guimaraes 'CITY-OF' $country => sub { print $country . "\n"; }.
CODE
Portugal
OUTPUT

# 4 -- term $r term
output_is { proc(<<'CODE') } <<'OUTPUT','','term $r term';
Braga $relation Portugal => sub { print "$relation\n"; }.
CODE
CITY-OF
OUTPUT

# 5 -- $t relation $t
output_is { proc(<<'CODE') } <<'OUTPUT','','$t relation $t';
$a 'CITY-OF' $b => sub { print "$a @ $b\n"; }.
CODE
Braga @ Braga
Braga @ Portugal
Bruxelas @ Belgica
Guimaraes @ Portugal
Lisboa @ Portugal
Londres @ Inglaterra
Madrid @ Espanha
Paris @ Franca
Porto @ Portugal
Vigo @ Espanha
OUTPUT

# 6 -- $t relation $t
output_is { proc(<<'CODE') } '', <<'OUTPUT','$t relation $t';
$a 'CITY-OF' $a => sub { warn "CITY-OF reflexiva para $a\n"; }.
CODE
CITY-OF reflexiva para Braga
OUTPUT

# 7 -- $t relation term -- empty $t
output_is { proc(<<'CODE') } '','','$t relation term -- empty $t';
$city 'CITY-OF' Russia => sub { print $city; }.
CODE
