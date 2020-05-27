package TypeTester;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Data::AnyXfer::Elastic::Types qw/ IndexName IndexType IndexId/;

has index_name => ( is => 'rw', isa => IndexName, );
has index_type => ( is => 'rw', isa => IndexType, );
has index_id   => ( is => 'rw', isa => IndexId );

1;

package main;

use Data::AnyXfer::Test::Kit;

my $tester = TypeTester->new();

for (qw/index_name index_type index_id/) {

    foreach my $test ( tests() ) {

        if ( $test->{dies} ) {
            dies_ok { $tester->$_( $test->{input} ) } $test->{name};
        } else {
            lives_ok { $tester->$_( $test->{input} ) } $test->{name};
        }
    }
}

sub tests {
    return (
        {   name  => 'letters/numbers',    # VALID
            input => 'interiors2014'
        },
        {   name  => 'with - _ characters',    # VALID
            input => 'in-ter_iors'
        },
        {   name  => 'with white space',
            dies  => 1,
            input => 'quick fox'
        },
        {   name  => 'with capitalised letters',
            dies  => 1,
            input => 'INTERIORS'
        },
        {   name  => 'with punctuation',
            dies  => 1,
            input => 'interiors!,^'
        },
    );
}

done_testing;

1;
