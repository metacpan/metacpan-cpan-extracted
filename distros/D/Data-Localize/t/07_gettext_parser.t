use strict;
use Cwd ();
BEGIN {
    unshift @INC, Cwd::abs_path()
}
use utf8;
use t::Data::Localize::Test qw(write_po);
use Test::More tests => 7;
use Data::Localize::Gettext::Parser;

{
    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "Bonjour, étranger!"
EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'Hello, stranger!' => 'Bonjour, étranger!' },
        'parsing a simple po file'
    );
}

{
    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "Bonjour, étranger!"

msgid "I am empty"
msgstr ""
EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'Hello, stranger!' => 'Bonjour, étranger!' },
        'parsing a po file with an empty string for one id'
    );

    $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 1,
    );

    $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon, {
            'Hello, stranger!' => 'Bonjour, étranger!',
            'I am empty'       => q{},
        },
        'parsing a po file with an empty string for one id - keep_empty is true'
    );
}

{
    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "Bonjour, étranger!"

#, fuzzy
msgid "I don't know"
msgstr "Je ne sais pas"
EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'Hello, stranger!' => 'Bonjour, étranger!' },
        'parsing a po file with a fuzzy translation'
    );

    $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 1,
        keep_empty => 0,
    );

    $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon, {
            'Hello, stranger!' => 'Bonjour, étranger!',
            q{I don't know}    => 'Je ne sais pas',
        },
        'parsing a po file with a fuzzy translation - use_fuzzy is true'
    );
}

{
    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "Bonjour, étranger!"

msgid "One\n"
"Two \\ Three\n"
"Four"
msgstr "Un\n"
"Deux \\ Trois\n"
"Quatre"
EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'Hello, stranger!' => 'Bonjour, étranger!',
          "One\nTwo \\ Three\nFour" => "Un\nDeux \\ Trois\nQuatre",
        },
        'parsing a po file with a multi-line id and translation'
    );
}


{
    my $file = write_po( <<'EOM' );
msgid "This is \"quote\"."
msgstr "C'est \"citation\"."

EOM

    my $parser = Data::Localize::Gettext::Parser->new(
        encoding   => 'utf-8',
        use_fuzzy  => 0,
        keep_empty => 0,
    );

    my $lexicon = $parser->parse_file($file);

    is_deeply(
        $lexicon,
        { 'This is "quote".' => q{C'est "citation".} },
        'parsing a po file with a dobule-quotation marks contained data'
    );
}
