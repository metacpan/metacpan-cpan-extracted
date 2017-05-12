use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $a = CPAN::Changes->new();
my $b = CPAN::Changes->new();

my $params = { version => '1.0'};

$a->add_release( $params );
$b->add_release( $params );

my ( @changes ) = ( 'hello' );

$a->release( '1.0' )->add_changes( @changes );

is_deeply( $a->release( '1.0' )->changes, { '' => [ 'hello' ] }, 'changes on "A"' );
is_deeply( $b->release( '1.0' )->changes, { }, 'no changes on "B"' );

done_testing;
