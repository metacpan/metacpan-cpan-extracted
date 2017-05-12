use strict;
use warnings;

use Test::More 0.88;

use Courriel::HeaderAttribute;

{
    my $attr = Courriel::HeaderAttribute->new(
        name  => 'foo',
        value => 'simple',
    );

    is(
        $attr->as_string,
        'foo=simple',
        'simple attribute as string'
    );
}

{
    my $attr = Courriel::HeaderAttribute->new(
        name  => 'foo',
        value => 'a' x 150,
    );

    my $expect = 'foo*0=' . ( 'a' x 78 );
    $expect .= q{ } . 'foo*1=' . ( 'a' x ( 150 - 78 ) );

    is(
        $attr->as_string,
        $expect,
        'simple attribute with continuation as string'
    );
}

{
    my $attr = Courriel::HeaderAttribute->new(
        name  => 'foo',
        value => 'has space',
    );

    is(
        $attr->as_string,
        q{foo="has space"},
        'quoted attribute as string'
    );
}

{
    my $attr = Courriel::HeaderAttribute->new(
        name  => 'foo',
        value => q{has space and double quote (")},
    );

    is(
        $attr->as_string,
        q{foo="has space and double quote (\\")"},
        'quoted attribute as string with escaped quote'
    );
}

{
    my $attr = Courriel::HeaderAttribute->new(
        name  => 'foo',
        value => 'a ' x 70,
    );

    my $expect = q{foo*0="} . ( 'a ' x 39 ) . q{"};
    $expect .= q{ } . q{foo*1="} . ( 'a ' x 31 ) . q{"};

    is(
        $attr->as_string,
        $expect,
        'simple attribute with continuation as string'
    );
}

{
    my $attr = Courriel::HeaderAttribute->new(
        name     => 'foo',
        value    => 'not really chinese',
        language => 'zh',
    );

    is(
        $attr->as_string,
        q{foo*=UTF-8'zh'not%20really%20chinese},
        'attribute with a language is always encoded'
    );
}

{
    my $attr = Courriel::HeaderAttribute->new(
        name     => 'foo',
        value    => "\x{4E00}\x{4E00}\x{4E00}",
        language => 'zh',
    );

    is(
        $attr->as_string,
        q{foo*=UTF-8'zh'%E4%B8%80%E4%B8%80%E4%B8%80},
        'attribute with utf-8 data'
    );
}

{
    my $attr = Courriel::HeaderAttribute->new(
        name  => 'foo',
        value => "\x{4E00}\x{4E00}\x{4E00}",
    );

    is(
        $attr->charset, 'UTF-8',
        'any non ASCII data automatically sets the charset to UTF-8'
    );

    is(
        $attr->as_string,
        q{foo*=UTF-8''%E4%B8%80%E4%B8%80%E4%B8%80},
        'attribute with utf-8 data and no language'
    );
}

{
    my $attr = Courriel::HeaderAttribute->new(
        name  => 'foo',
        value => "\x{4E00}" x 30,
    );

    my $expect = join q{ },
        q{foo*0*=UTF-8''%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8},
        'foo*1*=%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4',
        'foo*2*=%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80',
        'foo*3*=%E4%B8%80%E4%B8%80%E4%B8%80%E4%B8%80';

    is(
        $attr->as_string,
        $expect,
        'attribute with utf-8 data and continuations'
    );
}

done_testing();
