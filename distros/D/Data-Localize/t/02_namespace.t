use strict;
use Cwd ();
BEGIN {
    unshift @INC, Cwd::abs_path()
}
use utf8;
use Test::More tests => 6;
use t::Data::Localize::Test;

use_ok "Data::Localize";
use_ok "Data::Localize::Namespace";

{
    my $loc = Data::Localize::Namespace->new(
        namespaces => [ 't::Data::Localize::Test::Namespace' ]
    );
    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Hello, stranger!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔さん、こんにちは!', "localization for ja");
}

{
    # hack
    no warnings 'once';
    local $Data::Localize::Test::Namespace::ja::Lexicon{'Hello, [_1]!'} = '[_1]さん、こんにちは!';
    my $loc = Data::Localize::Namespace->new(
        style => 'maketext',
        namespaces => [ 't::Data::Localize::Test::Namespace' ]
    );
    my $out = $loc->localize_for(
        lang => 'ja',
        id   => 'Hello, stranger!',
        args => [ '牧大輔' ],
    );
    is($out, '牧大輔さん、こんにちは!', "localization with additional lexicon");
}

{
    my $loc = Data::Localize->new(languages => [ 'ja' ]);
    $loc->add_localizer(
        class => 'Namespace',
        namespaces => [ 't::Data::Localize::Test::Namespace' ]
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!', "localization for ja");

    $loc->localizers->[0]->add_namespaces(
        't::Data::Localize::Test::AltNamespace'
    );

    $out = $loc->localize('Good night, stranger!', '牧大輔');
    is($out, '牧大輔さん、おやすみなさい!', "localization after adding extra");

}
