#!perl
# t/007-nameset.t: test Data::Hopen::Util::NameSet
use rlib 'lib';
use HopenTest;

use Test::Fatal;

use Data::Hopen::Util::NameSet;

my $s;

# Run the tests twice: once without add() and once with add().
for ( my $iter = 0 ; $iter < 2 ; ++$iter ) {

    # Set up this iter's test object
    if ( $iter == 0 ) {
        $s = Data::Hopen::Util::NameSet->new();
        isa_ok( $s, 'Data::Hopen::Util::NameSet' );
        ok( !$s->contains('x'), "Empty nameset rejects 'x'" );
        $s->add(
            'foo', 'bar', qr/bat/,
            [ qr/qu+x/i, 'array', ['inner array'] ],
            { key => 'value' },
            'русский', 'язык'
        );

    }
    elsif ( $iter == 1 ) {
        $s = Data::Hopen::Util::NameSet->new(
            'foo', 'bar', qr/bat/,
            [ qr/qu+x/i, 'array', ['inner array'] ],
            { key => 'value' },
            'русский', 'язык'
        );
        isa_ok( $s, 'Data::Hopen::Util::NameSet' );
    }

    # Accessors
    is( ref( $s->strings ), 'ARRAY', 'strings is an arrayref' );
    is( ref( $s->regexps ), 'ARRAY', 'regexps is an arrayref' );

    # Contains tests
    ok( !$s->contains('x'), "Nameset rejects 'x'" );
    ok( $s->contains($_),   "Nameset accepts literal $_" )
      foreach ( qw(foo bar array key), 'inner array' );
    ok( $s->contains($_), "Nameset accepts $_" ) foreach qw(bat qux QUX QuUuUx);

    # UTF-8 words
    ok $s->contains($_), "Nameset accepts UTF8 $_" foreach qw(русский язык);

    # Some kanji and hiragana
    ok !$s->contains($_), "Nameset rejects UTF8 $_" foreach qw(日本語 ひらがな);

    # Partial words shouldn't succeed
    ok( !$s->contains($_), "Nameset rejects $_" )
      foreach qw(foobar fooqux fooQUX other_inner_array foofoo batqux batarray);

}    #foreach test

# Complex, new()
$s = Data::Hopen::Util::NameSet->new( qw(foo bar), qr/./ );
ok( $s->complex, 'set with regexps is complex' );
$s = Data::Hopen::Util::NameSet->new(qw(foo bar));
ok( !$s->complex, 'set without regexps is not complex' );

# Complex, add()
$s = Data::Hopen::Util::NameSet->new;
$s->add( qw(foo bar), qr/./ );
ok( $s->complex, 'set with regexps is complex' );
$s = Data::Hopen::Util::NameSet->new;
$s->add(qw(foo bar));
ok( !$s->complex, 'set without regexps is not complex' );

# More add()
ok( !defined exception { $s->add() }, 'add() without parms succeeds' );
ok( !defined exception { $s->add( { key1 => 42, key2 => undef } ) },
    'add(hashref) succeeds' );
ok( $s->contains($_), "add(hashref) added $_" ) foreach qw(key1 key2);

# More _build()
$s = Data::Hopen::Util::NameSet->new(qr/foo/);
ok( $s->contains('foo'),  'nameset without strings accepts foo from regex' );
ok( !$s->contains('bar'), 'nameset without strings rejects bar' );

# Error cases
like( exception { Data::Hopen::Util::NameSet::new() },
    qr/Call as/, 'new() throws when called directly' );

like(
    exception { Data::Hopen::Util::NameSet::add() },
    qr/Need an instance/,
    'add() throws when called directly'
);

like(
    exception { Data::Hopen::Util::NameSet::contains() },
    qr/Need an instance/,
    'contains() throws when called directly'
);

like(
    exception { Data::Hopen::Util::NameSet::_build() },
    qr/Need an instance/,
    '_build() throws when called directly'
);

like(
    exception {
        Data::Hopen::Util::NameSet->new( sub { } )
    },
    qr/I don't know how to handle this/,
    'new(CODEREF) throws'
);

done_testing();

# vi: set fenc=utf8:
