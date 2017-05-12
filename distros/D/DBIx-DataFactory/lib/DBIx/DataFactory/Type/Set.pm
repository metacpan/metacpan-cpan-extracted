package DBIx::DataFactory::Type::Set;

use strict;
use warnings;
use Carp;

use base qw(DBIx::DataFactory::Type);

use Smart::Args;

sub type_name { 'Set' }

sub make_value {
    args my $class => 'ClassName',
         my $set   => 'ArrayRef';
    return $set->[int rand(scalar @$set)];
}

1;
