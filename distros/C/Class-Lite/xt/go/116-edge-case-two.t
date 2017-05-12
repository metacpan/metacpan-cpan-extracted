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

$check          = 'redefine import';
#
BEGIN {
    package Module::Empty;
    sub import {
        ### @_
        shift;
        my $caller      = caller;
        my $imsym       = 'IMPORTS';
        no strict 'refs';
        push @{"${caller}::$imsym"}, @_;
        ### @_
        ### @Module::Empty::Cub::IMPORTS
    };
}
BEGIN {
    package Module::Empty::Cub;
    use Module::Empty qw| foo bar baz |;
    our @ISA;
    ### @ISA
}
pass( $check );

$check          = 'redefine import show imports';
$have           = \@Module::Empty::Cub::IMPORTS;
$want           = [qw| foo bar baz |];
is_deeply( $have, $want, $check );

note('The next check emits an error intentionally; this is ok.');

eval {
    my $self        = Module::Empty::Cub->new;
};
$eval_err       = $@;
$want           = qr/Can't locate object method "new"/;
$check          = 'did not inherit';
like( $eval_err, $want, $check );
note($eval_err);




END {
    done_testing();
};
exit 0;

