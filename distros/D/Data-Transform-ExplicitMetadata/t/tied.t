use strict;
use warnings;

use Data::Transform::ExplicitMetadata qw(encode decode);

use Scalar::Util qw(refaddr);
use Test::More tests => 9;
use IO::Handle;

test_tied_scalar();
test_tied_array();
test_tied_hash();
test_tied_handle();

sub test_tied_scalar {
    my $original = 'original data';
    my $tied_value = 'tied scalar';
    tie $original, 'Data::Transform::ExplicitMetadata::TiedScalar', $tied_value;
    my $expected = {
        __reftype => 'SCALAR',
        __refaddr => refaddr(\$original),
        __tied => 'original data',
        __value => {
            __reftype => 'ARRAY',
            __refaddr => refaddr(tied $original),
            __blessed => 'Data::Transform::ExplicitMetadata::TiedScalar',
            __value => [ $tied_value ],
        }
    };
    my $encoded = encode(\$original);
    is_deeply($encoded, $expected, 'encode tied scalar');

    my $decoded = decode($encoded);
    is($$decoded, $tied_value, 'decode tied scalar')
}

sub test_tied_array {
    my @original = ( 'an','array');
    my $tied_value = 'haha';
    tie @original, 'Data::Transform::ExplicitMetadata::TiedArray', $tied_value;
    my $expected = {
        __reftype => 'ARRAY',
        __refaddr => refaddr(\@original),
        __tied => [ 'an', 'array' ],
        __value => {
            __reftype => 'SCALAR',
            __refaddr => refaddr(tied @original),
            __blessed => 'Data::Transform::ExplicitMetadata::TiedArray',
            __value => $tied_value,
        }
    };
    my $encoded = encode(\@original);
    is_deeply($encoded, $expected, 'encode tied array');

    my $decoded = decode($encoded);
    is($decoded->[2], $tied_value, 'decode tied array');
}

sub test_tied_hash {
    my %original = ( one => 1 );
    my $tied_value = 'secret';
    tie %original, 'Data::Transform::ExplicitMetadata::TiedHash', $tied_value;
    my $expected = {
        __reftype => 'HASH',
        __refaddr => refaddr(\%original),
        __tied => { one => 1 },
        __value => {
            __reftype => 'SCALAR',
            __refaddr => refaddr(tied %original),
            __blessed => 'Data::Transform::ExplicitMetadata::TiedHash',
            __value => $tied_value,
        }
    };
    my $encoded = encode(\%original);
    is_deeply($encoded, $expected, 'encode tied hash');

    my $decoded = decode($encoded);
    is($decoded->{foo}, $tied_value, 'decode tied hash');
}

sub test_tied_handle {
    open(my $original, __FILE__);
    my $tied_value = 'secret';
    my $fileno = fileno($original);
    tie *$original, 'Data::Transform::ExplicitMetadata::TiedHandle', $tied_value;
    my $expected = {
        __reftype => 'GLOB',
        __refaddr => refaddr($original),
        __tied => {
            PACKAGE => 'main',
            NAME => '$original',
            SCALAR => {
                __value => undef,
                __reftype => 'SCALAR'
            },
            IO => $fileno,
            IOseek => '0 but true',
            IOmode => '<',
        },
        __value => {
            __reftype => 'SCALAR',
            __refaddr => refaddr(tied *$original),
            __blessed => 'Data::Transform::ExplicitMetadata::TiedHandle',
            __value => $tied_value,
        }
    };
    my $encoded = encode($original);
    ok(delete($encoded->{__tied}->{SCALAR}->{__refaddr}), 'tied original glob scalar has refaddr');

    if ($^O =~ m/MSWin/) {
        # FMode doesn't work on Windows
        delete $_->{__tied}->{IOmode} foreach ($encoded, $expected);
    }
    is_deeply($encoded, $expected, 'encode tied handle');

    my $decoded = decode($encoded);
    is(scalar(<$decoded>), $tied_value, 'decode tied handle');
}

package Data::Transform::ExplicitMetadata::TiedScalar;

sub TIESCALAR {
    my $class = shift;
    my @self = @_;
    return bless \@self, __PACKAGE__;
}

sub FETCH {
    my $self = shift;
    return join(' ', @$self);
}

package Data::Transform::ExplicitMetadata::TiedArray;

sub TIEARRAY {
    my $class = shift;
    my $self = shift;
    return bless \$self, __PACKAGE__;
}

sub FETCH {
    my($self, $idx) = @_;
    return $$self;
}

sub FETCHSIZE {
    return 100;
}

package Data::Transform::ExplicitMetadata::TiedHash;

sub TIEHASH {
    my $class = shift;
    my $self = shift;
    return bless \$self, __PACKAGE__;
}

sub FETCH {
    my($self, $idx) = @_;
    return $$self;
}

package Data::Transform::ExplicitMetadata::TiedHandle;

sub TIEHANDLE {
    my $class = shift;
    my $self = shift;
    return bless \$self, __PACKAGE__;
}

sub READLINE {
    my($self, $idx) = @_;
    return $$self;
}


