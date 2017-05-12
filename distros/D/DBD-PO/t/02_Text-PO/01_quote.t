#!perl -T

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Test::DBD::PO::Defaults qw($FILE_TEXT_PO $DROP_TABLE);
use Test::More tests => 7 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('IO::File');
    require_ok('DBD::PO::Text::PO');
}

my $test_string = join "\n", (
    (
        map {
            join q{}, map { chr $_ } 8 * $_ .. 8 * $_ + 7;
        } 0 .. 15
    ),
    (
        map {
            join q{}, map { "\\" . chr $_ } 8 * $_ .. 8 * $_ + 7;
        } 0 .. 15
    ),
);

sub quote {
    my $string = shift;
    my $eol    = shift;

    my %named = (
        #qq{\a} => qq{\\a}, # BEL
        #qq{\b} => qq{\\b}, # BS
        #qq{\t} => qq{\\t}, # TAB
        qq{\n} => qq{\\n}, # LF
        #qq{\f} => qq{\\f}, # FF
        #qq{\r} => qq{\\r}, # CR
        qq{"}  => qq{\\"},
        qq{\\} => qq{\\\\},
    );
    $string =~ s{
        ( [^ !#$%&'()*+,\-.\/0-9:;<=>?@A-Z\[\]\^_`a-z{|}~] )
    }{
        ord $1 < 0x80
        ? (
            exists $named{$1}
            ? $named{$1}
            : sprintf '\x%02x', ord $1
        )
        : $1;
    }xmsge;
    $string = qq{"$string"};
    # multiline
    if ($string =~ s{\A ( " .*? \\n )}{""\n$1}xms) {
        $string =~ s{\\n}{\\n"$eol"}xmsg;
    }

    return $string;
}

my $po_string = quote($test_string, "\n");

# write po file
{
    my $file_handle = IO::File->new();
    isa_ok($file_handle, 'IO::File');

    ok(
        $file_handle->open(
            $FILE_TEXT_PO,
            '> :encoding(utf-8)',
        ),
        'open file',
    );

    my $text_po = DBD::PO::Text::PO->new({
        eol     => "\n",
        charset => 'utf-8',
    });
    isa_ok($text_po, 'DBD::PO::Text::PO', 'new');

    # header
    $text_po->write_entry(
        $FILE_TEXT_PO,
        $file_handle,
        [
            q{},
            'Content-Type: text/plain; charset=utf-8',
        ],
    );

    # line
    $text_po->write_entry(
        $FILE_TEXT_PO,
        $file_handle,
        [
            'id',
            $test_string,
        ],
    );
}

# check_table_file
{
    my $po = <<"EOT";
msgid ""
msgstr "Content-Type: text/plain; charset=utf-8"

msgid "id"
msgstr $po_string

EOT
    local $INPUT_RECORD_SEPARATOR = ();
    open my $file1,
         '< :encoding(utf-8)',
         $FILE_TEXT_PO or croak $OS_ERROR;
    my $content1 = <$file1>;
    open my $file2, '< :encoding(utf-8)', \($po) or croak $OS_ERROR;
    my $content2 = <$file2>;
    eq_or_diff($content1, $content2, 'check po file');
}

# drop table
SKIP: {
    skip('delete file', 1)
        if ! $DROP_TABLE;

    unlink $FILE_TEXT_PO;
    ok(! -e $FILE_TEXT_PO, 'table file deleted');
}
