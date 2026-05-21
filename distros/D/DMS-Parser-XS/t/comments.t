#!/usr/bin/env perl
# Tier-0 comment-AST tests for the XS DMS parser. Mirrors the pure-Perl
# parser's t/comments.t exactly so the two backends are interchangeable.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../blib/lib";
use lib "$FindBin::Bin/../blib/arch";
use DMS::Parser::XS;

sub parse {
    return DMS::Parser::XS::decode_document($_[0]);
}

sub path_strs {
    my $aref = shift;
    return [ map { ref($_) eq 'DMS::Parser::Index' ? '#' . $_->value : $_ } @$aref ];
}

# 1. Leading
{
    my $doc = parse("# leading\nport: 8080\n");
    is(scalar @{$doc->{comments}}, 1, 'leading: one comment');
    my $ac = $doc->{comments}[0];
    is($ac->{position}, 'leading', 'leading: position');
    is_deeply(path_strs($ac->{path}), ['port'], 'leading: path');
    is($ac->{comment}{kind}, 'line', 'leading: kind=line');
    is($ac->{comment}{content}, '# leading', 'leading: content');
}

# 2. Floating (blank-line gap)
{
    my $doc = parse("# floating\n\nport: 8080\n");
    is(scalar @{$doc->{comments}}, 1, 'floating: one comment');
    my $ac = $doc->{comments}[0];
    is($ac->{position}, 'floating', 'floating: position');
    is_deeply(path_strs($ac->{path}), [], 'floating: empty path');
    is($ac->{comment}{content}, '# floating', 'floating: content');
}

# 3. Trailing
{
    my $doc = parse("port: 8080   # default\n");
    is(scalar @{$doc->{comments}}, 1, 'trailing: one comment');
    my $ac = $doc->{comments}[0];
    is($ac->{position}, 'trailing', 'trailing: position');
    is_deeply(path_strs($ac->{path}), ['port'], 'trailing: path');
    is($ac->{comment}{content}, '# default', 'trailing: content');
}

# 4. End-of-block floating
{
    my $doc = parse("a:\n  x: 1\n  # leftover\n");
    is(scalar @{$doc->{comments}}, 1, 'end-of-block: one comment');
    my $ac = $doc->{comments}[0];
    is($ac->{position}, 'floating', 'end-of-block: position');
    is_deeply(path_strs($ac->{path}), ['a'], 'end-of-block: path');
    is($ac->{comment}{content}, '# leftover', 'end-of-block: content');
}

# 5. Block-form leading
{
    my $doc = parse("###\nNOTE\n###\nport: 8080\n");
    is(scalar @{$doc->{comments}}, 1, 'block-leading: one comment');
    my $ac = $doc->{comments}[0];
    is($ac->{position}, 'leading', 'block-leading: position');
    is_deeply(path_strs($ac->{path}), ['port'], 'block-leading: path');
    is($ac->{comment}{kind}, 'block', 'block-leading: kind=block');
    like($ac->{comment}{content}, qr/^###/, 'block-leading: starts with ###');
    like($ac->{comment}{content}, qr/###$/, 'block-leading: ends with ###');
}

# 6. Front-matter prefix
{
    my $doc = parse("+++\n# meta-leading\nauthor: \"x\"\n+++\nbody: 1\n");
    is(scalar @{$doc->{comments}}, 1, 'fm-prefix: one comment');
    my $ac = $doc->{comments}[0];
    is($ac->{position}, 'leading', 'fm-prefix: position');
    is_deeply(path_strs($ac->{path}), ['__fm__', 'author'], 'fm-prefix: path');
    is($ac->{comment}{content}, '# meta-leading', 'fm-prefix: content');
}

# 7. No comments → empty arrayref
{
    my $doc = parse("a: 1\nb: 2\n");
    is(ref($doc->{comments}), 'ARRAY', 'no-comments: arrayref');
    is(scalar @{$doc->{comments}}, 0, 'no-comments: empty');
}

# 8. List-item leading with DMS::Parser::Index breadcrumb
{
    my $doc = parse("+ 1\n# before-second\n+ 2\n");
    is(scalar @{$doc->{comments}}, 1, 'list-leading: one comment');
    my $ac = $doc->{comments}[0];
    is($ac->{position}, 'leading', 'list-leading: position');
    is(scalar @{$ac->{path}}, 1, 'list-leading: path length 1');
    isa_ok($ac->{path}[0], 'DMS::Parser::Index', 'list-leading: path[0] is DMS::Parser::Index');
    is($ac->{path}[0]->value, 1, 'list-leading: path[0] = index 1');
}

done_testing;
