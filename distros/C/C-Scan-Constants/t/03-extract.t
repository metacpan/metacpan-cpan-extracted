# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should
# work as `perl 03-extract.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Scalar::Util qw( reftype );
use List::MoreUtils qw( any none );
use Test::More tests => 13;
use File::Spec;
BEGIN { use_ok('C::Scan::Constants') };                        # 1

#########################

my @h_files = (  File::Spec->catfile( qw/t include defines.h/ ),
                 File::Spec->catfile( qw/t include enums.h/ ),
                 File::Spec->catfile( qw/t include input.h/ ),
              );

for my $hf (@h_files) {
    print STDERR "File $hf does not exist" unless -f $hf;
}

# Arrange for running directly from this directory
if (!-d File::Spec->catfile(qw/t include/)) {
    @h_files = (  File::Spec->catfile( qw/include defines.h/ ),
                  File::Spec->catfile( qw/include enums.h/ ),
                  File::Spec->catfile( qw/include input.h/ ),
               );
}

my @constants = C::Scan::Constants::extract_constants_from( @h_files );

cmp_ok( scalar @constants, '>',  0,
        "Extraction produced expected non-trivial result" );     # 2

my $any_TEMP = any { $_ =~ /_TEMP_/ } @constants;
ok( $any_TEMP,
    "Extract found constants with names including '_TEMP_'" );   # 3

my $any_enum_blocks = any { $_ =~ /^HASH[(]0x[0-9a-f]+[)]/ } @constants;
ok( $any_enum_blocks,
    "Extract constants from typedef enum blocks" );              # 4

my @rigged_up_hashrefs = grep { ref $_
                                && reftype($_) eq 'HASH' }
                              @constants;

is( scalar( grep { ref $_ &&
                   $_->{name} =~ /omega=24/ } @constants ),
    0,
    "Extracted enum constants don't include specified vals" ); # 5

ok( exists $rigged_up_hashrefs[0]->{name},
    "Rigged-up HASH entries have name elements..." );          # 6

is( $rigged_up_hashrefs[1]->{macro}, 1,
    "...and are marked as macros" );                           # 7

my %enum_names;
for my $enum ( grep { /^HASH[(]0x[0-9a-f]+[)]/ } @constants ) {
    if (exists $enum->{name}) {
        $enum_names{ $enum->{name} } += 1;
    }
    else {
        $enum_names{ $enum->{name} } = 0;
    }
}

my $no_dupes = none { $_ > 1 } values(%enum_names);
ok( $no_dupes,
    "We only saw each enum name once in our scan" );           # 8


my $no_DEFINES_H =none { $_ =~ /_?DEFINES_H_/ } @constants;
ok( $no_DEFINES_H,
    "Header file name was not in the list" );                  # 9

my $any_FOO = any { $_ =~ /FOO_/ } keys(%enum_names);
ok( $any_FOO,
    "Extract found constants with names including 'FOO_'" );   # 10

my $no_donts_expected = none { $_ =~ /dont_/ } keys(%enum_names);
ok( $no_donts_expected,
    "Extract found no constants with names including 'dont_'" );  # 11

my $no_LONGER_STR = none { $_ =~ /LONGER_STR/ } @constants;
ok( $no_LONGER_STR,
    "Extract found no constants with names including 'dont_'" );  # 12

# Thanks to Lee Pumphret for suggesting this test (RT #34986)
my @key_h_exists = map { if ($_ =~ /^KEY_[GHI]$/) { $_ } else { () } } @constants;
is( scalar @key_h_exists, 3,
    "We successfully did not pitch real _H constants" );          # 13
#diag( "expected GHI, found @key_h_exists" )
