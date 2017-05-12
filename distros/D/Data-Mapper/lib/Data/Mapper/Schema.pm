package Data::Mapper::Schema;
use strict;
use warnings;
use parent qw(Data::Mapper::Class);

sub table        { $_[0]->{table}        }
sub primary_keys { $_[0]->{primary_keys} }
sub columns      { $_[0]->{columns}      }

!!1;
