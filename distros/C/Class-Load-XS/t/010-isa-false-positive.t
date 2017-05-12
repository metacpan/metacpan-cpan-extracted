use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

use lib 't/lib';
use Test::Class::Load 'load_optional_class';

isnt(
    exception {
        load_optional_class('Class::Load::Error::DieAfterIsa');
    },
    undef,
    'Class which calls die is reported as an error'
);

{
    local $TODO
        = q{I'm not sure this is fixable as it's really an interpreter issue.};

    isnt(
        exception {
            load_optional_class('Class::Load::Error::DieAfterIsa');
        },
        undef,
        'Class which calls die is reported as an error (second attempt)'
    );
}

isnt(
    exception {
        load_optional_class('Class::Load::Error::DieAfterBeginIsa');
    },
    undef,
    'Class populates @ISA in BEGIN then dies - error on load'
);

{
    local $TODO
        = q{I'm not sure this is fixable as it's really an interpreter issue.};

    isnt(
        exception {
            load_optional_class('Class::Load::Error::DieAfterBeginIsa');
        },
        undef,
        'Class populates @ISA in BEGIN then dies - error on load (second attempt)'
    );
}

isnt(
    exception {
        load_optional_class('Class::Load::Error::SyntaxErrorAfterIsa');
    },
    undef,
    'Class with a syntax error causes an error'
);

isnt(
    exception {
        load_optional_class('Class::Load::Error::SyntaxErrorAfterIsa');
    },
    undef,
    'Class with a syntax error causes an error (second attempt)'
);

done_testing;
