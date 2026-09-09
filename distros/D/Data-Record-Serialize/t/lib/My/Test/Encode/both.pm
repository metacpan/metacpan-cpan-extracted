package My::Test::Encode::both;

use Moo::Role;

sub print  { }    ## no critic (ProhibitBuiltinHomonyms)
sub say    { }    ## no critic (ProhibitBuiltinHomonyms)
sub encode { }
sub close  { }    ## no critic (ProhibitBuiltinHomonyms, ProhibitAmbiguousNames)

with 'Data::Record::Serialize::Role::Encode';
with 'Data::Record::Serialize::Role::Sink';

1;
