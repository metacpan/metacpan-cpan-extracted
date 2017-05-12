
use Test::More;
use Test::Deep;
use Test::Lib;
use FindBin qw( $Bin );
use Path::Tiny qw( path );
use Scalar::Util qw( refaddr );

use Beam::Wire;

my @paths = map {; $_, "$_" }
            map { path( $Bin, '..', 'share', $_ ) }
            qw( file.json file.pl file.yml )
            ;

for my $path ( @paths ) {
    subtest "load module from config - $path " . ref($path) => sub {
        my ( $ext ) = $path =~ /[.]([^.]+)$/;
        if ( $ext eq 'json' && !eval { require JSON; 1 } ) {
            pass "Can't load json for config: $@";
            return;
        }

        my $wire = Beam::Wire->new( file => $path );
        my $foo = $wire->get('foo');
        isa_ok $foo, 'My::RefTest';
        is refaddr $wire->get('foo'), refaddr $foo, 'container caches the object';
        isa_ok $wire->get('foo')->got_ref, 'My::ArgsTest', 'container injects My::ArgsTest object';
        is refaddr $wire->get('bar'), refaddr $foo->got_ref, 'container caches Bar object';
        cmp_deeply $wire->get('bar')->got_args, [text => "Hello, World"], 'container gives bar text value';

        my $buzz = $wire->get( 'buzz' );
        isa_ok $buzz, 'My::ArgsTest', 'container gets constructor test object';
        is refaddr $wire->get('buzz'), refaddr $buzz, 'container caches the object';
        cmp_deeply $buzz->got_args, [[qw( one two three )]], 'container gives array of arrayrefs';

        my $fizz = $wire->get( 'fizz' );
        isa_ok $fizz, 'My::ArgsTest', 'container gets Fizz object';
        is refaddr $wire->get('fizz'), refaddr $fizz, 'container caches the object';
        cmp_deeply $fizz->got_args, [{ one => 'two' }], 'container gives hashref';
    };
}

done_testing;
