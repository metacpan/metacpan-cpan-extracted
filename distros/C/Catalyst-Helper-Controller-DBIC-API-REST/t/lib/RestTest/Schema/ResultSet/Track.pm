package    # hide from PAUSE
    RestTest::Schema::ResultSet::Track;

use strict;
use warnings;

use parent 'RestTest::Schema::ResultSet';

sub search {
    my $self = shift;
    my ( $clause, $params ) = @_;

    # test custom attrs
    if ( ref $clause eq 'HASH' ) {
        if ( my $pretend = delete $clause->{pretend} ) {
            $clause->{'cd.year'} = $pretend;
        }
    }
    my $rs = $self->SUPER::search(@_);
}

1;
