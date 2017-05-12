#!/usr/bin/perl -w

use Test::More tests => 8;
use Activator::Exception;
use Exception::Class::TryCatch;
use Data::Dumper;

my $err;
try eval {
    Activator::Exception->throw( 'MyObj', 'MyCode' );
};
catch $err;
ok( $err, "Can catch $err");

$err = undef;

try eval {
    1;
};
ok( !$err, "Catch nothing when no error thrown");

try eval {
    Activator::Exception->throw( 'MyObj', 'MyCode', 'MyExtra' );
};
catch $err;
ok( $err eq 'MyObj MyCode MyExtra', 'all fields in err string' );

try eval {
    Activator::Exception::DB->throw( 'DbObj', 'DbCode', 'DbExtra' );
};
catch $err;
ok( $err, "Can catch subclass exception");
ok( $err eq 'DbObj DbCode DbExtra', 'subclass exception inherits fields' );

try eval {
    die "text failure";
};
catch $err;
ok( $err, "Can catch random die");
my $str = $err;
chomp $str;
ok( $err =~ /^text failure/, "random die caught");
ok( $err->isa('Exception::Class::Base'), 'random die is a blessed Exception obj');
