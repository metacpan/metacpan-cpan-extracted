use Test::More tests => 19;
use File::Spec;

require_ok( 'Crypt::YAPassGen' );

my ($passgen, $passwd);
my $freq = File::Spec->catfile(qw(blib lib Crypt YAPassGen 
    american-english.dat));

eval { $passgen = Crypt::YAPassGen->new( freq => $freq ) };

ok(!$@, "Not dead creating object");
isa_ok($passgen, 'Crypt::YAPassGen');

$passwd = $passgen->generate();

is(length($passwd), 8, 'Right length');
like($passwd, qr/^[a-z]+$/, 'We should have just 7 bit lowercase ASCII');

#OK, now for different settings

undef $passgen; undef $passwd;

eval { $passgen = Crypt::YAPassGen->new(
    freq        =>  $freq,
    length      =>  10,
    post_sub    =>  'caps',
    algorithm   =>  'linear',
) };

ok(!$@, "Not dead creating object");
isa_ok($passgen, 'Crypt::YAPassGen');

$passwd = $passgen->generate();

is(length($passwd), 10, 'Right length');
like($passwd, qr/^[A-Za-z]+$/, 'We should have just 7 bit ASCII');


#now try single methods

my $ret = $passgen->algorithm('log');

$passwd = $passgen->generate();

is(ref($ret), 'CODE', 'Change algorithm to "log"');
is(length($passwd), 10, 'Right length');
like($passwd, qr/^[A-Za-z]+$/, 'We should have just 7 bit ASCII');


$ret = $passgen->length();
is($ret, 10, 'Fetch length');
$ret = $passgen->length(11);
is($ret, 11, 'Set length');

$passwd = $passgen->generate();
is(length($passwd), 11, 'Right length');

$passgen->reset_post_subs();
$passwd = $passgen->generate();
like($passwd, qr/^[a-z]+$/, 'We should have just 7 bit lowercase ASCII');

$passgen->add_post_sub( sub { tr/a-z/A-Z/ } );
$passwd = $passgen->generate();
like($passwd, qr/^[A-Z]+$/, 'We should have just 7 bit uppercase ASCII');


$passgen->reset_post_subs();

SKIP: {
    #comment out next line and set $dict and $output     
    #if you want to test producing a frequency file
    skip "Not testing producing a frequency file", 2;
    my $dict = '/usr/share/dict/words';
    my $output = '';
    $passgen->freq('');
    $passgen->ascii(1);
    print STDERR "\nCreating a frequency file, this can take a while...\n";
    $passgen->make_freq($dict, $output || ());
    $passwd = $passgen->generate();
    is(length($passwd), 11, 'Right length');
    like($passwd, qr/^[a-z]+$/, 'We should have just 7 bit lowercase ASCII');
}

