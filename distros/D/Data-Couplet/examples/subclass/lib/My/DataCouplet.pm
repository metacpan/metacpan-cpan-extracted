package My::DataCouplet;

# ABSTRACT: An Example use of Data::Couplet::Extension

use Data::Couplet::Extension -with => [qw( My::Plugin )];
use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

1;

