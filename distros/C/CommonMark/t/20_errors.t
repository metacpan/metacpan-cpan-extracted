use strict;
use warnings;

use Symbol;
use Test::More tests => 11;

BEGIN {
    use_ok('CommonMark');
}

{
    package MyHandle;
    sub TIEHANDLE { return bless({}, shift); }
}

my $handle = Symbol::gensym;
tie *$handle, 'MyHandle';
eval {
    CommonMark->parse_file(*$handle);
};
like($@, qr/parse_file: file is not a file handle/,
     'parse_file with tied handle dies');

{
    package MyClass;
    sub new { return bless({}, shift); }
}

my $obj = MyClass->new;
eval {
    CommonMark::Node::get_type($obj);
};
like($@, qr/get_type: node is not of type CommonMark::Node/,
     'get_type on wrong class dies');

my $doc       = CommonMark->parse_document('*text*');
my $paragraph = $doc->first_child;
my $emph      = $paragraph->first_child;
my $text      = $emph->first_child;

eval {
    $text->insert_after($emph);
};
like($@, qr/insert_after: invalid operation/, 'insert_after dies');

eval {
    $emph->set_list_tight(1);
};
like($@, qr/set_list_tight: invalid operation/, 'set_list_tight dies');

eval {
    $paragraph->set_url('/url');
};
like($@, qr/set_url: invalid operation/, 'set_url dies');

eval {
    $doc->render();
};
like($@, qr/must provide format/, 'render without format');

eval {
    $doc->render(format => 'non_existent');
};
like($@, qr/invalid format/, 'render with invalid format');

eval {
    my $paragraph = CommonMark->create_paragraph(
        children => [
            CommonMark->create_text(literal => 'text'),
        ],
        text => 'text',
    );
};
like($@, qr/can't set both children and text/,
     'create_text with children and text');

eval {
    my $doc = CommonMark->parse(smart => 1);
};
like($@, qr/must provide either string or file/, 'parse without input');

eval {
    my $doc = CommonMark->parse(string => 'md', file => \*STDIN);
};
like($@, qr/can't provide both string and file/, 'parse with string and file');

