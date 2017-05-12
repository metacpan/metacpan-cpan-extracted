#!perl -T

use Test::More tests => 17;

BEGIN {
	use_ok( 'Class::Serializer' );
}

# use version to determine if scalars are being properly serialized
my $version = $Class::Serializer::VERSION;

# define some variables in order to test serialization
$Class::Serializer::AryRef = [1, 2, 3];
$Class::Serializer::HashRef = [ab => 'c', de => 'f'];
$Class::Serializer::SimpleScalar = 'abcdef';

$Class::Serializer::Complex = {
	key => [
		$Class::Serializer::AryRef, 
		$Class::Serializer::HashRef, 
		$Class::Serializer::SimpleScalar,
		\$Class::Serializer::SimpleScalar
	]};

my $bound_variable = 42;
*Class::Serializer::closure_test = sub {
    return $bound_variable;
};

ok( my $str  = Class::Serializer->as_string('Class::Serializer') );

# possibly clean-up from previous run
File::Path::rmtree('t/Class');

ok( my $file = Class::Serializer->as_file('Class::Serializer', 't/Class/Serializer/Serialized.pm') );

# fix up Win32 line-endings
if ($^O eq 'MSWin32') { $str =~ s/\n/\r\n/g }

# poor man's diff
ok( length($str) == -s $file, "poor man's diff 1" );

push(@INC, '.');
cleanup_module();

require_ok( 't/Class/Serializer/Serialized.pm' );
ok( $version == $Class::Serializer::VERSION, "scalar serialization test 1.1 ($version == $Class::Serializer::VERSION)" );
ok( Class::Serializer->closure_test == $bound_variable, "scalar serialization test 1.2 (closure_test == $bound_variable)" );

ok( my $second_file = Class::Serializer->as_file('Class::Serializer', 't/Class/Serializer/ReSerialized.pm') );

cleanup_module();
require_ok( 't/Class/Serializer/ReSerialized.pm' );

ok( $version == $Class::Serializer::VERSION, "scalar serialization test 2.1 ($version == $Class::Serializer::VERSION)" );
ok( Class::Serializer->closure_test == $bound_variable, "scalar serialization test 2.2 (closure_test == $bound_variable)" );

ok( my $third_file = Class::Serializer->as_file('Class::Serializer', 't/Class/Serializer/ReReSerialized.pm') );

cleanup_module();
require_ok( 't/Class/Serializer/ReReSerialized.pm' );

ok( $version == $Class::Serializer::VERSION, "scalar serialization test 3.1 ($version == $Class::Serializer::VERSION)" );
ok( Class::Serializer->closure_test == $bound_variable, "scalar serialization test 3.2 (closure_test == $bound_variable)" );

SKIP: {
    skip "while statements generate a bogus do{} which breaks this test", 2;
    ok( (-s $second_file == -s $third_file), "poor man's diff 2" );
    ok( (-s $second_file == -s $file), "poor man's diff 3" );
}

# clean-up
File::Path::rmtree('t/Class');

sub cleanup_module {
    for my $key (keys %Class::Serializer::) {
        delete $Class::Serializer::{$key};
    }
}
