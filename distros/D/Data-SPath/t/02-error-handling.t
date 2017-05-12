#!perl
use strict;
use Test::More tests => 21;

BEGIN {
    use_ok(
        "Data::SPath",
        spath => {
            method_miss => \&t1_method_miss,
            key_miss => \&t1_key_miss,
            index_miss => \&t1_index_miss,
            key_on_non_hash => \&t1_key_on_non_hash,
            args_on_non_method => \&t1_args_on_non_method
        }
    )
}

my $data = {
    string => "bar",
    array => [ qw/foo bar baz/ ],
    hash => { foo => 1, bar => 2 },
    regexp => qr/regex/,
    object => TObj->new( "foo", "bar" ),
};

ok( !eval { spath $data, "/nonexistent_key" }, "croak on missing hash key" );
is( $@, "t1_key_miss\n", "default key_miss error handler" );
ok( !eval { spath $data, "/nonexistent_key", { key_miss => \&t2_key_miss } }, "inline key_miss error handler croaks" );
is( $@, "t2_key_miss\n", "inline key_miss error handler" );

ok( !eval { spath $data, "/string/bar" }, "croak on key on non-hash" );
is( $@, "t1_key_on_non_hash\n", "default key_on_non_hash error handler" );
ok( !eval { spath $data, "/string/bar", { key_on_non_hash => \&t2_key_on_non_hash } }, "inline key_on_non_hash error handler croaks" );
is( $@, "t2_key_on_non_hash\n", "inline key_on_non_hash error handler" );

ok( !eval { spath $data, "/object/bar" }, "croak method_miss" );
is( $@, "t1_method_miss\n", "default method_miss error handler" );
ok( !eval { spath $data, "/object/bar", { method_miss => \&t2_method_miss } }, "inline method_miss error handler croaks" );
is( $@, "t2_method_miss\n", "inline method_miss error handler" );

ok( !eval { spath $data, "/string('bar', 'baz')" }, "croak args_on_non_method" );
is( $@, "t1_args_on_non_method\n", "default args_on_non_method error handler" );
ok( !eval { spath $data, "/string('bar', 'baz', 'bat')", { args_on_non_method => \&t2_args_on_non_method } }, "inline args_on_non_method error handler croaks" );
is( $@, "t2_args_on_non_method\n", "inline args_on_non_method error handler" );

ok( !eval { spath $data, "/array/3" }, "croak index_miss" );
is( $@, "t1_index_miss\n", "default index_miss error handler" );
ok( !eval { spath $data, "/array/3", { index_miss => \&t2_index_miss } }, "inline index_miss error handler croaks" );
is( $@, "t2_index_miss\n", "inline index_miss error handler" );

sub t1_method_miss { die "t1_method_miss\n" }
sub t1_key_miss { die "t1_key_miss\n" }
sub t1_index_miss { die "t1_index_miss\n" }
sub t1_key_on_non_hash { die "t1_key_on_non_hash\n" }
sub t1_args_on_non_method { die "t1_args_on_non_method\n" }

sub t2_method_miss { die "t2_method_miss\n" }
sub t2_key_miss { die "t2_key_miss\n" }
sub t2_index_miss { die "t2_index_miss\n" }
sub t2_key_on_non_hash { die "t2_key_on_non_hash\n" }
sub t2_args_on_non_method { die "t2_args_on_non_method\n" }

BEGIN {
    package TObj;

    sub new { my $class = shift; bless { a => shift, b => shift }, $class }
    sub a { $_[0]->{a} = $_[1] if @_; $_[0]->{a} }
    sub b { $_[0]->{b} = $_[1] if @_; $_[0]->{b} }
}

