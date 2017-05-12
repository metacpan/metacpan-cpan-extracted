use strict;
use warnings;
use Test::More;

#~ use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

my $eval_err    ;
my $have        ;
my $want        ;
my $check       ;

# Construction
eval {
    BEGIN {
        package Module::Empty;
        use Class::Lite qw| attr1 attr2 attr3 |;
    }
};
$eval_err       = $@;

$check          = $eval_err ? $eval_err : 'use ok';
ok( ! $eval_err, $check );

$check          = 'redefine fore_import';
#
BEGIN {
    package Module::Empty;
    sub fore_import {
        my $class       = shift;
        my $args        = shift;
        my $hoge        =    $args->{hoge}      // 'default'     ;
        my @accessors   = @{ $args->{accessors} // []           };
        # _do_hoge{$hoge};
        return @accessors;
    };
}
BEGIN {
    package Module::Empty::Cub;
    use Module::Empty {
        hoge        => 'piyo',
        accessors   => [qw| chim chum choo |],
    };
}
pass( $check );

my $self        = Module::Empty::Cub->new;

# Access
$check          = 'put_chum';
$self->put_chum('meeple');
$have           = $self->{chum};
$want           = 'meeple';
is( $have, $want, $check );
$check          = 'get_chum';
$have           = $self->get_chum;
is( $have, $want, $check );



END {
    done_testing();
};
exit 0;

