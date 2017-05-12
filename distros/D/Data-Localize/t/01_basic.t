use strict;
use Test::More;
use t::Data::Localize::Test;

use_ok "Data::Localize";

subtest 'sanity' => sub {
    my $loc = Data::Localize->new(
        auto => 0,
        fallback_languages => [ 'en' ],
    );
    $loc->add_localizer(
        class => 'Namespace',
        namespaces => [ 't::Data::Localize::Test::Namespace' ]
    );

    is($loc->localize("Hello, stranger!", "John Doe"), "Hello, John Doe!");
};

subtest 'add instance' => sub {
    my $loc = Data::Localize->new();
    $loc->add_localizer(
        Data::Localize::Namespace->new(
            namespaces => [ 't::Data::Localize::Test::Namespace' ]
        )
    );
    is($loc->localize("Hello, stranger!", "John Doe"), "Hello, John Doe!");
};

done_testing;