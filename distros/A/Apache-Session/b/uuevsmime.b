use Benchmark;
use Apache::Session::Serialize::UUEncode;
use Apache::Session::Serialize::Base64;
use Apache::Session::Serialize::Storable;

use vars qw($hash);

$hash = { 
    serialized => undef, 
    data => {
        foo => 'A'x32,
        bar => [1,2,3,4,5,6,7,8,9,0],
        baz => {
            blah => 'A'x32,
            bleh => 'B'x32
        }
    }
};

sub uue {
    my $z = Apache::Session::Serialize::UUEncode::serialize($hash);
    Apache::Session::Serialize::UUEncode::unserialize($hash);
}

sub base64 {
    my $z = Apache::Session::Serialize::Base64::serialize($hash);
    Apache::Session::Serialize::Base64::unserialize($hash);
}

sub storable {
    my $z = Apache::Session::Serialize::Storable::serialize($hash);
    Apache::Session::Serialize::Storable::unserialize($hash);
}

timethese(-3, {
    Base64   => \&base64,
    UUE      => \&uue,
    Storable => \&storable
});

$hash->{data}->{foo} = 'A'x32000;

timethese(-3, {
    'Big Base64'   => \&base64,
    'Big UUE'      => \&uue,
    'Big Storable' => \&storable,
});

print "Length with UUE: ". length(Apache::Session::Serialize::UUEncode::serialize($hash)) ."\n";
print "Length with Base64: ". length(Apache::Session::Serialize::Base64::serialize($hash)) ."\n";
print "Length with Storable: ". length(Apache::Session::Serialize::Storable::serialize($hash)) ."\n";
