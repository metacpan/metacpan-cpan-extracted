use strict;
use warnings;
use Test::Fatal;
use Test::More 0.88;
use lib 't/lib';
use Test::Class::Load 'load_first_existing_class';

is(
    load_first_existing_class(
        'Class::Load::Nonexistent', 'Class::Load::OK'
    ),
    'Class::Load::OK',
    'load_first_existing_class ignore nonexistent class'
);

is(
    load_first_existing_class(
        'Class::Load::Nonexistent', 'Class::Load::OK'
    ),
    'Class::Load::OK',
    'load_first_existing_class ignore nonexistent class - works when good class is already loaded'
);

like(
    exception {
        load_first_existing_class( 'Foo', 'bad name' );
    },
    qr/^\Q`bad name' is not a module name/,
    'load_first_existing_class balks on bad class name'
);

like(
    exception {
        load_first_existing_class( 'Class::Load::Nonexistent', 'Class::Load::Nonexistent2' );
    },
    qr/^\QCan't locate Class::Load::Nonexistent or Class::Load::Nonexistent2 in \E\@INC/,
    'load_first_existing_class throws an error when no classes can be loaded'
);

like(
    exception {
        load_first_existing_class(
            'Class::Load::Nonexistent',
            'Class::Load::Nonexistent2',
            'Class::Load::Nonexistent3'
        );
    },
    qr/^\QCan't locate Class::Load::Nonexistent, Class::Load::Nonexistent2, or Class::Load::Nonexistent3 in \E\@INC/,
    'load_first_existing_class throws an error when no classes can be loaded'
);

like(
    exception {
        load_first_existing_class( 'Class::Load::Nonexistent' );
    },
    qr/^\QCan't locate Class::Load::Nonexistent in \E\@INC/,
    'load_first_existing_class throws an error when given one class which it cannot load'
);

like(
    exception {
        load_first_existing_class(
            'Class::Load::VersionCheck',  { -version => 43 },
            'Class::Load::VersionCheck2', { -version => 43 },
        );
    },
    qr/^\QCan't locate Class::Load::VersionCheck (version >= 43) or Class::Load::VersionCheck2 (version >= 43) in \E\@INC/,
    'load_first_existing_class throws an error when given multiple classes which it cannot load because of version checks'
);

like(
    exception {
        load_first_existing_class(
            'Class::Load::VersionCheck',  { -version => 43 },
            'Class::Load::VersionCheck2', { -version => 43 },
            'Class::Load::Nonexistent'
        );
    },
    qr/^\QCan't locate Class::Load::VersionCheck (version >= 43), Class::Load::VersionCheck2 (version >= 43), or Class::Load::Nonexistent in \E\@INC/,
    'load_first_existing_class throws an error when given multiple classes which it cannot load, some because of version checks'
);

like(
    exception {
        load_first_existing_class( 'Class::Load::VersionCheck', {-version => 43} );
    },
    qr/^\QCan't locate Class::Load::VersionCheck (version >= 43) in \E\@INC/,
    'load_first_existing_class throws an error when given one class which it cannot load because of version checks'
);

like(
    exception {
        load_first_existing_class(
            'Class::Load::VersionCheck2', { -version => 43 },
            'Class::Load::SyntaxError', { -version => 43 },
            'Class::Load::Nonexistent'
        );
    },
    qr/^\QCouldn't load class (Class::Load::SyntaxError) because: Missing right curly or square bracket/,
    'load_first_existing_class throws an error when a class fails to load because of a syntax error'
);

is(
    load_first_existing_class(
        'Class::Load::VersionCheck',  { -version => 43 },
        'Class::Load::VersionCheck2', { -version => 43 },
        'Class::Load::OK'
    ),
    'Class::Load::OK',
    'load_first_existing_class returns loadable class when two classes fail version checks'
);

is(
    load_first_existing_class(
        'Class::Load::VersionCheck',  { -version => 43 },
        'Class::Load::VersionCheck2', { -version => 41 },
        'Class::Load::OK'
    ),
    'Class::Load::VersionCheck2',
    'load_first_existing_class returns loadable class when a class passes the version check'
);

done_testing;
