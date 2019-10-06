use strict;
use Cwd ();
BEGIN {
    unshift @INC, Cwd::abs_path()
}
use utf8;
use Test::More tests => 12;
use File::Spec;
use Scalar::Util qw(blessed);
use t::Data::Localize::Test qw(write_po);

use_ok "Data::Localize";
use_ok "Data::Localize::Gettext";

{
    my $loc = Data::Localize::Gettext->new(
        path => 't/04_gettext/*.po',
    );

    is_deeply(
        $loc->paths,
        [ 't/04_gettext/*.po' ],
        'paths contains single glob value in t/04_gettext/ - BUILDARGS handles path argument correctly'
    );

    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Hello, stranger!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!"});
}

{
    my $loc = Data::Localize->new(auto => 0, languages => [ 'ja' ]);
    $loc->add_localizer(
        class => 'Gettext',
        path => 't/04_gettext/*.po'
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!"});

    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "%1さん、おじゃまんぼう！"
EOM

    $loc->localizers->[0]->add_path($file);

    is_deeply(
        $loc->localizers->[0]->paths,
        [ 't/04_gettext/*.po', $file ],
        'paths contains newly added path'
    );

    $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、おじゃまんぼう！', q{translation for "Hello, stranger!" from new file});

}

{
    require Data::Localize::Format::Gettext;
    @Data::Localize::Format::Gettext::TestWithCustomMethod::ISA =
        qw( Data::Localize::Format::Gettext )
    ;
    sub Data::Localize::Format::Gettext::TestWithCustomMethod::test {
        my ($self, $lang, $args) = @_;
        return join(':', $lang, map { blessed $_ ? ref $_ : $_ } @$args);
    }

    my $loc = Data::Localize::Gettext->new(
        path => 't/04_gettext/*.po',
        formatter => Data::Localize::Format::Gettext::TestWithCustomMethod->new(
            functions => {
                foo => sub {
                    my ($lang, $args) = @_;
                    return join(':', $lang, map { blessed $_ ? ref $_ : $_ } @$args);
                }
            }
        )
    );

    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Dynamically Create Me!',
    );
    is($out, 'ja:a:b:cを動的に作成したぜ!', 'dynamic translation');

    $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Embedded Dynamic',
        args => [ 42, 84 ],
    );
    is($out, 'ja:42:84を動的に作成したぜ!', 'dynamic translation');

    my $object = bless {}, 'Foo';
    $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Embedded Dynamic',
        args => [ 42, $object ],
    );
    is($out, 'ja:42:Fooを動的に作成したぜ!', 'dynamic translation with object as argument, object is not stringified');
    
    $out = $loc->localize_for(
        lang => 'ja',
        id   => "Embedded Dynamic (function)",
        args => [ 42, $object ],
    );
    ok $out, "got something";
    is $out, "ja:42:Fooを動的に作成したぜ!";
}

