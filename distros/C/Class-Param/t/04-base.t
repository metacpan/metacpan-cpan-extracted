#!perl

use strict;
use warnings;

use Test::More;

plan tests => 15;

use_ok( 'Class::Param::Base' );
can_ok( 'Class::Param::Base', 'get'    );
can_ok( 'Class::Param::Base', 'set'    );
can_ok( 'Class::Param::Base', 'add'    );
can_ok( 'Class::Param::Base', 'has'    );
can_ok( 'Class::Param::Base', 'clear'  );
can_ok( 'Class::Param::Base', 'names'  );
can_ok( 'Class::Param::Base', 'new'    );
can_ok( 'Class::Param::Base', 'param'  );
can_ok( 'Class::Param::Base', 'remove' );

my @abstract = qw[ new get set names remove ];

foreach my $abstract ( @abstract ) {
    eval { Class::Param::Base->$abstract };
    like( $@, qr/Abstract method/, qq/Abstract method '$abstract' throws an exception./ );
}
