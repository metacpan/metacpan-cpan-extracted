#
# $Id
# 
use warnings;
use strict;
use Test::More tests => 7;

BEGIN { use_ok( 'Attribute::Method' ); }

eval {
    package Class::Easy;
    use strict;
    use warnings;
    use Attribute::Method qw/$prop/;
    sub new : Method { 
	bless { @_ }, $self 
    }
    sub set : Method( $prop ){
	$self->{prop} = $prop;
    }
    sub get : Method {
	$self->{prop};
    }
};

ok !$@, "Class::Easy";
use B::Deparse;
my $ce = Class::Easy->new(prop => 1);
isa_ok $ce, 'Class::Easy';
is $ce->get, 1;
is $ce->set(2), 2;
is $ce->get, 2;

eval q{
    package Class::Wrong;
    use strict;
    use warnings;
    use Attribute::Method qw/$propeller/;
    sub new : Method { 
	bless { @_ }, $self 
    }
    sub set : Method( $prop ){
	$self->{prop} = $prop;
    }
    sub get : Method {
	$self->{prop};
    }
};
ok $@, "Class::Wrong";
# like $@, qr/strict/;
