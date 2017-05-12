#!/usr/bin/perl -w

use Test::More tests => 11;
use Test::Exception;
use Activator::Registry;
use Activator::Log;

BEGIN{ 
    $ENV{ACT_REG_YAML_FILE} ||= "$ENV{PWD}/t/data/Registry-advanced.yml";
}

#Activator::Log->level('DEBUG');

my $test_yaml_file = "$ENV{PWD}/t/data/Registry-test.yml";

# object instantiation
my $reg = Activator::Registry->new();
ok( defined ( $reg ), 'instantiate' );

my $replacements = { VAR1 => 'one',
		     VAR2 => 'two',
		     VAR3 => 'three',
		     VAR4 => 'four',
		     VAR5 => 'five',
		   };
lives_ok {
    $reg->replace_in_realm( 'default', $replacements );
} "replace_in_realm doesn't die";


ok( $reg->get( 'top_level' ) eq $replacements->{VAR2}, 'replacement works at top level' );

# deep structs maintained
my $deep = $reg->get( 'deep_hash' );
ok( $deep->{level_1}->{level_2}->{level_3} eq $replacements->{VAR1}, 'deep value match' );

my $list = $reg->get( 'list' );
ok( @$list[0] eq 'foo', 'item1 maintained' );
ok( @$list[1] eq 'bar', 'item2 maintained' );
ok( @$list[2] eq $replacements->{VAR3}, 'item3 replaced' );
ok( @$list[3] eq $replacements->{VAR4}, 'item4 replaced' );
ok( @$list[4] eq $replacements->{VAR5}, 'item5 replaced' );

# multiple keys in the same line get replaced
my $multi = $reg->get('multi');
ok( $multi eq 'one plus two equals four - one' , 'complex replacements work');

# recursive key definitions work
my $recursive = $reg->get('recursive');
ok( $recursive eq 'one plus two equals four - one equals three' , 'recursive replacements work');
