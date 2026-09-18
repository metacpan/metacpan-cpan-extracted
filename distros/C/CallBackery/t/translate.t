use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::Base -strict;

use Test::More;
use Mojo::JSON qw(encode_json decode_json);

use CallBackery::Translate qw(trm trmJoin);

# The wire shape is a contract with the qooxdoo frontend: an ARRAY means
# "this wants translating", anything else is data. xtr() in
# callbackery/locale/MTranslation.js is the other half of it.
#
# This used to collapse the no-argument case to a bare string, which put the
# most common kind of translatable text -- a plain sentence with nothing
# substituted into it -- beyond the frontend's reach. Everything that was not
# a form label then stayed in English however the catalogue was filled.

subtest 'a plain string crosses the wire as a one element array' => sub {
    my $wire = decode_json(encode_json({ v => trm('Not assigned') }))->{v};
    is(ref $wire, 'ARRAY', 'an array, not a bare string');
    is_deeply($wire, ['Not assigned'], 'holding just the msgid');
};

subtest 'arguments ride along untouched, unsubstituted' => sub {
    my $wire = decode_json(encode_json({ v => trm('Status: %1', 'migrated') }))->{v};
    is_deeply($wire, ['Status: %1', 'migrated'],
        'the placeholder survives so the frontend can fill it in ITS language');
};

subtest 'arguments are stringified before they leave' => sub {
    my $wire = decode_json(encode_json({ v => trm('%1 pending', 7) }))->{v};
    is_deeply($wire, ['%1 pending', '7'], 'a number becomes a string');
};

# A message with an optional part in it -- a cert warning, a verification
# code, the result of a change nobody may have made -- cannot be one msgid
# without writing out a msgid per combination. So an argument may be a
# trm() of its own, and each piece is translated in its own right.
subtest 'an argument may be a message of its own' => sub {
    my $base = trm('Registration Updated Successfully');
    my $warn = trm('Certificate does not name %1','agw.example.com');
    my $msg  = trm('%1'."\n\n".'Verification Code: %2', $base, '482913');
    $msg     = trm('%1'."\n\n".'%2', $msg, $warn);

    my $wire = decode_json(encode_json({ v => $msg }))->{v};
    is_deeply($wire, [
        "%1\n\n%2",
        [ "%1\n\nVerification Code: %2", ['Registration Updated Successfully'], '482913' ],
        [ 'Certificate does not name %1', 'agw.example.com' ],
    ], 'the pieces arrive as pieces, none of them flattened into its parent');
};

# A list whose length is only known at run time -- warnings on a dashboard,
# flags on a table row -- cannot have a msgid of its own, and join()ing it
# stringifies every part. The generated msgid holds no words at all.
subtest 'a list of messages joins without losing any of them' => sub {
    my $wire = decode_json(encode_json({
        v => trmJoin("\n", trm('Disk %1 is full','sda'), trm('No contract'))
    }))->{v};
    is_deeply($wire, ["%1\n%2", ['Disk %1 is full','sda'], ['No contract']],
        'each part keeps its own msgid, the separator carries no words');

    is_deeply(decode_json(encode_json({ v => trmJoin("\n", trm('alone')) }))->{v},
        ['alone'], 'a single part is not wrapped in a pointless %1');

    is_deeply(decode_json(encode_json({ v => trmJoin("\n") }))->{v},
        [''], 'and nothing at all is the empty message');

    is_deeply(decode_json(encode_json({
        v => trmJoin(', ', trm('x'), '', undef, trm('y'))
    }))->{v}, ['%1, %2', ['x'], ['y']],
        'undef and empty parts drop out rather than leaving gaps');
};

# The overload is the backend-side escape hatch: log lines, mail bodies and
# anything else that never reaches the frontend. It substitutes but does NOT
# translate, which is exactly why a trm() that gets concatenated into another
# string can no longer be translated at all.
subtest 'stringification substitutes without translating' => sub {
    is("".trm('Status: %1','migrated'), 'Status: migrated',
        'the placeholder is filled in');
    ok(trm('abc') eq 'abc', 'and eq compares against the rendered text');
};

# A nested message runs the same overload, and its s/// used to reset $1
# while the outer substitution was still walking its string. The tail of the
# outer message then kept its literal "%2".
subtest 'a nested message stringifies all the way down' => sub {
    my $inner = trm('Verification Code: %1','482913');
    my $outer = trm('%1'."\n".'%2', $inner, trm('Done'));
    is("$outer", "Verification Code: 482913\nDone",
        'both placeholders are filled in, the nested one included');
};

done_testing;
