use strict;
use warnings;

use Data::Transform::ExplicitMetadata qw(encode decode);

use Scalar::Util;
use File::Temp;
use Test::More tests => 8;

subtest test_scalar => sub {
    plan tests => 8;

    my $tester = sub {
        my($original, $desc) = @_;
        my $encoded = encode($original);
        is($encoded, $original, "encode $desc");
        my $decoded = decode($encoded);
        is($decoded, $original, "decode $desc");
    };

    $tester->(1, 'number');
    $tester->('a string', 'string');
    $tester->('', 'empty string');
    $tester->(undef, 'undef');
};

subtest test_simple_references => sub {
    plan tests => 6;

    my %tests = (
        scalar => \'a scalar',
        array  => [ 1,2,3 ],
        hash   => { one => 1, two => 2, string => 'a string' }
    );
    foreach my $test ( keys %tests ) {
        my $original = $tests{$test};
        my $encoded = encode($original);

        my $expected = {
            __value => ref($original) eq 'SCALAR' ? $$original : $original,
            __reftype => Scalar::Util::reftype($original),
            __refaddr => Scalar::Util::refaddr($original),
        };
        $expected->{__blesstype} = Scalar::Util::blessed($original) if Scalar::Util::blessed($original);

        is_deeply($encoded, $expected, "encode $test");

        my $decoded = decode($encoded);
        is_deeply($decoded, $original, "decode $test");
    }
};

subtest test_filehandle => sub {
    plan skip_all => q(Filehandle open mode tests don't work on Windows)
        if ($^O =~ m/MSWin/);
    plan tests => 5;

    encode_filehandle_test_open_mode();
};

sub encode_filehandle_test_open_mode {
    my $temp_fh = File::Temp->new();
    $temp_fh->close();
    my $filename = $temp_fh->filename;

    foreach my $mode (qw( < > >> +>> +<)) {
        open(my $filehandle, $mode, $filename) || die "Can't open temp file in mode $mode: $!";
        my $encoded = encode($filehandle);
        is ($encoded->{__value}->{IOmode}, $mode, "IOMode for mode $mode");
    }
}

subtest test_filehandle_with_fmode => sub {
    if (eval { require FileHandle::Fmode }) {
        plan tests => 5;
    } else {
        plan skip_all => 'FileHandle::Fmode is not installed';
    }

    no warnings 'redefine';
    # make the fcntl function return false so it'll fall back to Fmode
    local *Data::Transform::ExplicitMetadata::_get_open_mode_fcntl = sub { '' };

    encode_filehandle_test_open_mode();
};


subtest test_coderef => sub {
    plan tests => 2;

    my $original = sub { 1 };

    my $encoded = encode($original);

    my $expected = {
        __value => "$original",
        __reftype => 'CODE',
        __refaddr => Scalar::Util::refaddr($original),
    };

    is_deeply($encoded, $expected, 'encode coderef');

    my $decoded = decode($encoded);
    is(ref($decoded), 'CODE', 'decoded to a coderef');
};

subtest test_refref => sub {
    plan tests => 2;

    my $hash = { };
    my $original = \$hash;

    my $expected = {
        __reftype => 'REF',
        __refaddr => Scalar::Util::refaddr($original),
        __value => {
            __reftype => 'HASH',
            __refaddr => Scalar::Util::refaddr($hash),
            __value => { }
        }
    };
    my $encoded = encode($original);
    is_deeply($encoded, $expected, 'encode ref reference');

    my $decoded = decode($encoded);
    is_deeply($decoded, $original, 'decode ref reference');
};

subtest test_regex => sub {
    plan tests => 3;

    my $original = qr(a regex \w)m;

    my $expected = {
        __reftype => 'REGEXP',
        __refaddr => Scalar::Util::refaddr($original),
        __value => [ 'a regex \w', 'm' ],
    };
    my $encoded = encode($original);
    is_deeply($encoded, $expected, 'encode regex');

    my $decoded = decode($encoded);
    is("$decoded", "$original", 'decode regex');
    isa_ok($decoded, 'Regexp');
};

subtest test_vstring => sub {
    plan tests => 6;

    my $original = v1.2.3.4;

    my $expected = {
        __reftype => 'VSTRING',
        __value => [ 1, 2, 3, 4 ],
    };
    my $encoded = encode($original);
    is_deeply($encoded, $expected, 'encode vstring');

    my $decoded = decode($encoded);
    is($decoded, $original, 'decode vstring');
    is(ref(\$decoded),
        $^V ge v5.10.0 ? 'VSTRING' : 'SCALAR',
        'ref to decoded');


    my $vstring = v1.2.3.4;
    $original = \$vstring;
    $expected->{__refaddr} = Scalar::Util::refaddr($original);
    $encoded = encode($original);
    is_deeply($encoded, $expected, 'encode vstring ref');

    $decoded = decode($encoded);
    is($$decoded, $$original, 'decode vstring ref');
    is(ref($decoded),
        $^V ge v5.10.0 ? 'VSTRING' : 'SCALAR',
        'decoded ref');
};
