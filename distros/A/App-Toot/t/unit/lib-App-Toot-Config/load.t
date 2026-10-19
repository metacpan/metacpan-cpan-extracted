#!/usr/bin/env perl

use FindBin ();
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";
use App::Toot::Test;

use File::Temp ();

my $class = 'App::Toot::Config';
use_ok( $class );

use constant {
    EXPECTED_DEFAULT => {
        instance      => 'masto.don.test',
        username      => 'default',
        client_id     => '12345',
        client_secret => '67890',
        access_token  => 'abcde',
    },
    EXPECTED_BOOK => {
        instance      => 'masto.don.test',
        username      => 'book',
        client_id     => '12345',
        client_secret => '67890',
        access_token  => 'abcde',
    },
};

my $default_section = <<'INI';
[default]
instance = masto.don.test
username = default
client_id = 12345
client_secret = 67890
access_token = abcde
INI

my $empty_default_with_book = <<'INI';
[default]
[book]
instance = masto.don.test
username = book
client_id = 12345
client_secret = 67890
access_token = abcde
INI

my $book_only = <<'INI';
[book]
instance = masto.don.test
username = book
client_id = 12345
client_secret = 67890
access_token = abcde
INI

my $book_with_unused_stub = <<'INI';
[book]
instance = masto.don.test
username = book
client_id = 12345
client_secret = 67890
access_token = abcde

[stub]
instance = masto.don.test
INI

my $book_missing_access_token = <<'INI';
[book]
instance = masto.don.test
username = book
client_id = 12345
client_secret = 67890
INI

my $malformed = <<'INI';
[default]
this line is not a property
INI

my $config_dir;

App::Toot::Test::override(
    package => 'App::Toot::Config',
    name    => '_get_conf_dir',
    subref  => sub { return $config_dir },
);

sub write_config {
    my $content = shift;

    $config_dir = File::Temp::tempdir( CLEANUP => 1 );

    my $file = "$config_dir/config.ini";
    open( my $fh, '>', $file ) or die "unable to write $file: $!";
    print {$fh} $content;
    close($fh);

    return;
}

HAPPY_PATH: {
    note('happy path');

    write_config($default_section);

    my $config = $class->load('default');
    is_deeply( $config, EXPECTED_DEFAULT(), 'config from the default section is returned' );
}

EMPTY_DEFAULT: {
    note('empty default section alongside the requested section');

    write_config($empty_default_with_book);

    my $config = $class->load('book');
    is_deeply( $config, EXPECTED_BOOK(), 'config from the book section is returned' );
}

NO_DEFAULT: {
    note('no default section');

    write_config($book_only);

    my $config = $class->load('book');
    is_deeply( $config, EXPECTED_BOOK(), 'config from the book section is returned' );
}

UNUSED_INCOMPLETE_SECTION: {
    note('incomplete section that was not requested');

    write_config($book_with_unused_stub);

    my $config = $class->load('book');
    is_deeply( $config, EXPECTED_BOOK(), 'config from the book section is returned' );
}

UNKNOWN_SECTION: {
    note('requested section is not defined');

    write_config($book_only);

    dies_ok { $class->load('development') } 'dies if the requested section is not defined';
    like $@, qr/development section was not found in the config/,
        'exception indicates the requested section was not found';
}

EMPTY_DEFAULT_REQUESTED: {
    note('requested section is empty');

    write_config($empty_default_with_book);

    dies_ok { $class->load('default') } 'dies if the requested section has no keys';
    like $@, qr/instance key for default section in .*config\.ini is not defined/,
        'exception indicates the missing key';
}

MISSING_KEY: {
    note('requested section is missing a key');

    write_config($book_missing_access_token);

    dies_ok { $class->load('book') } 'dies if the requested section is missing a key';
    like $@, qr/access_token key for book section in .*config\.ini is not defined/,
        'exception indicates the missing key';
}

MALFORMED_CONFIG: {
    note('config cannot be parsed');

    write_config($malformed);

    dies_ok { $class->load('default') } 'dies if the config cannot be parsed';
    like $@, qr/config\.ini/, 'exception names the config file';
    like $@, qr/Syntax error/, 'exception indicates the config could not be parsed';
    unlike $@, qr/is not defined/, 'exception does not claim a section or key is missing';
}

done_testing();