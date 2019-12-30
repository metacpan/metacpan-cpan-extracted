package test_03_depends_catch;

use strict;
use Test::More;

use parent 'Exporter';
use CHI::Cascade::Value;

our @EXPORT = qw(test_cascade);

my $test_mask = '';

sub test_cascade {
    my $cascade = shift;

    plan tests => 7;

    $cascade->rule(
        target          => 'throw_exception',
        code            => sub {
            $test_mask .= 'a';
            die CHI::Cascade::Value->new->value( { exception => 1 } );
        }
    );

    $cascade->rule(
        target          => 'test_exception',
        depends         => 'throw_exception',
        depends_catch   => sub {
            isa_ok( $_[0], 'CHI::Cascade::Rule'  );
            isa_ok( $_[1], 'CHI::Cascade::Value' );
            isa_ok( $_[2], 'CHI::Cascade::Rule'  );
            ok(     $_[3] eq 'throw_exception'   );
            $test_mask .= 'b';
        },
        code            => sub {
            # should not be executed
            $test_mask .= 'c';
        }
    );

    my $ret = $cascade->run('test_exception');

    ok( ref $ret eq 'HASH' );
    ok( exists $ret->{exception} && $ret->{exception} == 1 );
    ok( $test_mask eq 'ab' ) or diag( "\$test_mask is $test_mask" );
}

1;
