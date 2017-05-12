#!/usr/bin/perl -w

use strict;

my $Has_PH = $] < 5.009;

$SIG{__WARN__} = sub { return if $_[0] =~ /^Pseudo-hashes are deprecated/ };


use Test::More tests => 5;

BEGIN { use_ok 'Class::Fields::Inherit' }


package Yar;

use public  qw( Pub Pants );
use private qw( _Priv _Pantaloons );
use protected   qw( _Prot Armoured );

BEGIN {
    use Class::Fields::Inherit;
    inherit_fields('Pants', 'Yar');
}

::is_deeply([sort keys %Pants::FIELDS], 
            [sort qw(Pub Pants _Prot Armoured)],
            'inherit_fields()'
);

# Can't use compile time (my Pants) because then eval won't catch
# the error (it won't be run time)
use fields;
my $trousers = fields::new('Pants');

eval {
    $trousers->{Pub}        = "Whatver";
    $trousers->{Pants}      = "This too";
    $trousers->{_Prot}      = "Hey oh";
    $trousers->{Armoured}   = 4;
};
::ok($@ eq '' or $@ !~ /no such field/i) or diag $@;

my $error = $Has_PH ? 'no such( [\w-]+)? field'
                    : q[Attempt to access disallowed key];

eval {
    $trousers->{_Priv} = "Yarrow";
};
::like($@, "/^$error/i");

eval {
    $trousers->{_Pantaloons} = "Yarrow";
};
::like($@, "/^$error/i");
