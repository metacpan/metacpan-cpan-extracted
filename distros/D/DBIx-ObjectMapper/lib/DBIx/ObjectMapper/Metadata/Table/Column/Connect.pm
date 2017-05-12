package DBIx::ObjectMapper::Metadata::Table::Column::Connect;
use strict;
use warnings;
use Scalar::Util qw(blessed);

use overload
    '""' => sub {
        _format($_[0]->{col1}) . ' || ' . _format($_[0]->{col2})
    },
    fallback => 1,
;

sub _format {
    my $col = shift;
    if(  blessed $col ) {
        return $col;
    }
    else {
        return "'" . $col . "'";
    }
}

sub new {
    my ( $class, $col1, $col2 ) = @_;
    bless { col1 => $col1, col2 => $col2 }, $class;
}

1;
