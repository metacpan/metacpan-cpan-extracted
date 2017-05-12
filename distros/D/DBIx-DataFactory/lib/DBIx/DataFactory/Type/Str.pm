package DBIx::DataFactory::Type::Str;

use strict;
use warnings;
use Carp;

use base qw(DBIx::DataFactory::Type);

use Smart::Args;
use String::Random;

sub type_name { 'Str' }

sub make_value {
    args my $class  => 'ClassName',
         my $size   => {isa => 'Int', optional => 1, default => 20},
         my $regexp => {isa => 'Str', optional => 1};

    $regexp = "[a-zA-Z0-9]{$size}" unless $regexp;
    return String::Random->new->randregex($regexp);
}

1;
