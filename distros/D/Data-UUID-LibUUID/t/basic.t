#!/usr/bin/perl

use strict;

use Test::More tests => 47;

use ok 'Data::UUID::LibUUID' => ":all";

is( length(new_uuid_string()), 36, "new_uuid_string" );

foreach my $version (1, 2, 4) {
    is( length(new_uuid_string($version)), 36, "new_uuid_string($version)" );
}

# doesn't pass on all platforms
#my ( $t1, $t2 ) = map { unpack("N",new_uuid_binary(1)) } 1 .. 2;

#cmp_ok( $t1 - $t2, '<=', 1, "time based UUIDs have close prefix" );

my $bin = new_uuid_binary();
is( length($bin), 16, "binary UUID" );
is( length(uuid_to_string($bin)), 36, "to_string" );

is( uuid_to_binary(uuid_to_string($bin)), $bin, "round trip" );
is( uuid_to_binary($bin), $bin, "to_binary(binary) is a noop" );

my $str = new_uuid_string();
is( uuid_to_string(uuid_to_binary($str)), $str, "round trip to string" );

my $bin2 = new_uuid_binary;
isnt( $bin, $bin2, "uuids differ" );

is( uuid_compare($bin, $bin), 0, "compare same UUID" );
isnt( uuid_compare($bin, $bin2), 0, "compare two diff UUIDs" );
is( uuid_compare($bin, "foo"), undef, "compare two diff UUIDs" );

is( uuid_eq($bin, $bin), 1, "uuid_eq true" );
is( uuid_eq($bin, $bin2), '', "uuid_eq false" );
is( uuid_eq($bin, "foo"), undef, "uuid_eq error" );
ok( uuid_eq($str, $str), "uuid_eq on strings" );
ok( uuid_eq($bin, uuid_to_string($bin)), "uuid_eq on string and bin" );

is( uuid_compare(uuid_to_string($bin), $bin), 0, "compare string and binary" );
{
    package StringObj;;
    use overload q{""} => "stringify";

    sub new {
        my ( $class, $str ) = @_;
        bless { str => $str }, $class;
    }

    sub stringify { $_[0]{str} }
}

my $obj = StringObj->new($str);
ok( ref $obj, "object" );

is( "$obj", $str, "stringifies" );

ok( uuid_eq($str, $obj), "uuid_eq on stringifying object" );

# various error conds:
is( uuid_to_binary("foo"), undef, "to_binary(random_string)" );
is( uuid_to_string("foo"), undef, "to_string(random_string)" );
is( uuid_to_binary(undef), undef, "to_binary(undef)" );
is( uuid_to_binary({}), undef, "to_binary({})" );
is( uuid_to_binary(bless {}, "Blah"), undef, "to_binary(obj)" );
is( uuid_to_binary(*STDOUT), undef, "to_binary(*STDOUT)" );
is( uuid_to_binary(sub { }), undef, "to_binary(sub { })" );
is( uuid_to_binary(42), undef, "to_binary(IV)" );

is( length(new_dce_uuid_string()), 36, 'new_dce_uuid_string ignores its args' );
is( length(new_dce_uuid_string( bless({}, "Foo"), "foo" )), 36, 'new_dce_uuid_string ignores its args' );

{
    ( my $hex = uuid_to_string($bin) ) =~ s/-//g;
    is( uc $hex, uc unpack("H*", $bin), "hex" );
    is( uc $hex, uc uuid_to_hex($bin), "uuid_to_hex" );
    isnt( uc $hex, uc uuid_to_string($bin), "hex != str");
    is( join("-", unpack("A8 A4 A4 A4 A*", uc $hex) ), uc uuid_to_string($bin), "reformat" );
    is( uuid_to_string($hex), uuid_to_string($bin), "uuid_to_string(hex)" );
}

{
    use MIME::Base64;

    my $base64 = MIME::Base64::encode_base64($bin);

    ok( uuid_eq($base64, $bin), "base64 eq bin");

    is( uuid_to_string($base64), uuid_to_string($bin), "uuid_to_string(base64)" );
    is( uuid_to_binary($base64), $bin, "uuid_to_binary(base64)");

    $base64 =~ s/\s*//g;

    is( uuid_to_base64($bin), $base64, "uuid_to_base64");

    ok( uuid_eq($base64, $bin), "base64 eq bin");

    is( uuid_to_string($base64), uuid_to_string($bin), "uuid_to_string(base64)" );
    is( uuid_to_binary($base64), $bin, "uuid_to_binary(base64)");

}

{
    my @idents = map { ascending_ident } 1 .. 200;

    is_deeply(
        [ @idents ],
        [ sort @idents ],
        "identifiers are increasing",
    );

    my %seen;
    my @uniq = grep { !$seen{$_}++ } map { substr($_, 0, 16) } @idents;

    is( scalar(@uniq), scalar(@idents), "strictly increasing, not just monotonically" );
}
