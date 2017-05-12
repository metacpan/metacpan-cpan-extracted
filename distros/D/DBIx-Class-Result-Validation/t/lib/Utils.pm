package t::lib::Utils;

use strict;
use warnings;

use base 'Exporter';
use vars '@EXPORT';

@EXPORT = qw/ populate_database /;

sub populate_database
{
  my $schema = shift;


  my @artists = (['object 1','val1','val1','attr1',1], ['object 2','val2','val2','attr2',1]);
  $schema->populate('Object', [
    [qw/name my_enum my_enum_def attribute ref_id/],
    @artists,
    ]);
}

1;
