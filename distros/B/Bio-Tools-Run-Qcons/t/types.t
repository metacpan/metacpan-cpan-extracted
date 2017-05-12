use strict;
use warnings;

use Test::More qw/no_plan/;
use Test::Exception;

use_ok( 'Bio::Tools::Run::QCons::Types' );

{
    package Test::Executable;
    use Mouse;
    use Bio::Tools::Run::QCons::Types 'Executable';

    has 'exe' => ( is => 'ro', isa => 'Executable' );
}

my $t;

throws_ok { $t = Test::Executable->new( exe => 'foo' ) }
qr/Can't find foo in your PATH/, 'Throws exception when executable not found';

lives_ok { $t = Test::Executable->new( exe => 'perl' ) }
'Lives with a good executable name';
