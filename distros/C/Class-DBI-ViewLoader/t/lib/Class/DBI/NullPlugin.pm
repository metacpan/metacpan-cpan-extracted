package Class::DBI::NullPlugin;


use strict;
use warnings;

use base qw( Exporter );

our @EXPORT = qw( null );

sub null {
    return "null";
}

1;

__END__
