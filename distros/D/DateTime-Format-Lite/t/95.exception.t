# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/95.exception.t
## Tests for DateTime::Format::Lite::Exception: construction, stringification,
## accessors, throw(), and the NullObject chaining behaviour.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More qw( no_plan );

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );
use_ok( 'DateTime::Format::Lite::Exception' );

# NOTE: Basic construction with message
subtest 'new with message string' => sub
{
    my $e = DateTime::Format::Lite::Exception->new( 'something went wrong' );
    ok( defined( $e ), 'exception created' );
    isa_ok( $e, 'DateTime::Format::Lite::Exception' );
    is( $e->message, 'something went wrong', 'message accessor' );
};

# NOTE: Construction with hashref
subtest 'new with hashref' => sub
{
    my $e = DateTime::Format::Lite::Exception->new({
        message => 'test error',
        file    => 'Foo.pm',
        line    => 42,
    });
    is( $e->message, 'test error', 'message' );
    is( $e->file,    'Foo.pm',     'file'    );
    is( $e->line,    42,           'line'    );
};

# NOTE: Auto-population of file and line
subtest 'auto-populated file and line' => sub
{
    my $e = DateTime::Format::Lite::Exception->new( 'auto location' );
    ok( defined( $e->file ) && length( $e->file ), 'file auto-populated' );
    ok( defined( $e->line ) && $e->line > 0,       'line auto-populated' );
};

# NOTE: Stringification includes file and line
subtest 'stringification includes location' => sub
{
    my $e = DateTime::Format::Lite::Exception->new({
        message => 'bad input',
        file    => 'Parser.pm',
        line    => 99,
    });
    my $str = "$e";
    like( $str, qr/bad input/,   'string includes message' );
    like( $str, qr/Parser\.pm/,  'string includes file'    );
    like( $str, qr/99/,          'string includes line'    );
};

# NOTE: bool overload is always true
subtest 'bool overload always true' => sub
{
    my $e = DateTime::Format::Lite::Exception->new( 'error' );
    ok( $e, 'exception is true in boolean context' );
};

# NOTE: throw() dies with exception
subtest 'throw() dies' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    local $@;
    eval
    {
        DateTime::Format::Lite::Exception->throw( 'thrown error' );
    };
    ok( $@, 'throw() caused die' );
    isa_ok( $@, 'DateTime::Format::Lite::Exception' );
    like( $@->message, qr/thrown error/, 'thrown exception has message' );
};

# NOTE: error() sets $ERROR class variable
subtest 'error() sets class variable' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y',
        on_error => 'undef',
    );
    $fmt->parse_datetime( 'bad' );
    my $class_err = DateTime::Format::Lite->error;
    ok( defined( $class_err ), 'class error variable set' );
    isa_ok( $class_err, 'DateTime::Format::Lite::Exception' );
};

# NOTE: error() sets instance error
subtest 'error() sets instance error' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y',
        on_error => 'undef',
    );
    $fmt->parse_datetime( 'bad' );
    my $inst_err = $fmt->error;
    ok( defined( $inst_err ), 'instance error set' );
    isa_ok( $inst_err, 'DateTime::Format::Lite::Exception' );
};

# NOTE: Two instances have independent errors
subtest 'two instances have independent errors' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $fmt1 = DateTime::Format::Lite->new( pattern => '%Y', on_error => 'undef' );
    my $fmt2 = DateTime::Format::Lite->new( pattern => '%Y', on_error => 'undef' );

    $fmt1->parse_datetime( 'bad1' );
    my $msg1 = $fmt1->error->message;

    $fmt2->parse_datetime( 'bad2' );
    my $msg2 = $fmt2->error->message;

    # Both should have errors set independently
    ok( defined( $msg1 ), 'fmt1 has error' );
    ok( defined( $msg2 ), 'fmt2 has error' );
};

# NOTE: NullObject - chaining on error does not die
subtest 'NullObject chaining does not die' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d',
        on_error => 'undef',
    );
    local $@;
    # This should not die even though parse_datetime returns a NullObject
    # in object context; the chain should silently return undef/empty
    my $result = eval
    {
        $fmt->parse_datetime( 'bad-input' )->iso8601;
    };
    ok( !$@, 'chaining on error does not die' );
    ok( !$result, 'chained call returns false value' );
};

# NOTE: pass_error propagates existing error
subtest 'pass_error propagates existing error' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y',
        on_error => 'undef',
    );
    # Manually set an error then pass it
    $fmt->error( 'original error' );
    my $result = $fmt->pass_error;
    ok( !defined( $result ), 'pass_error returns undef' );
    # The error should still be accessible
    ok( defined( $fmt->error ), 'error still accessible after pass_error' );
};

done_testing;

__END__
