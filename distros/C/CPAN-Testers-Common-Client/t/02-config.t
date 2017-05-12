use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use_ok( 'CPAN::Testers::Common::Client::Config' );

# ---- parser checks
my $parser = \&CPAN::Testers::Common::Client::Config::_parse_transport_args;
is_deeply(
    $parser->('uri'),
    ['uri'],
    'simplest transport arg parsing'
);
is_deeply(
    $parser->('"foo bar"'),
    ['foo bar'],
    'simplest transport arg parsing with double quotes'
);

is_deeply(
    $parser->('uri https://foo id_file bar'),
    [qw(uri https://foo id_file bar)],
    'complete transport args parsing'
);
is_deeply(
    $parser->('uri https://foo id_file "foo bar"'),
    ['uri', 'https://foo', 'id_file', 'foo bar'],
    'complete transport args parsing with double quotes'
);

is_deeply(
    $parser->(q(uri https://foo id_file 'foo bar')),
    ['uri', 'https://foo', 'id_file', 'foo bar'],
    'complete transport args parsing with single quotes'
);

my $bs = "\x5c"; # <-- backslash character! "\"
is_deeply(
    $parser->(qq("a b" c 'd e' f "g 'h" 'i " j' k 'a${bs}"' "l${bs}"m" 'x${bs}${bs}y' 'a${bs}${bs}${bs}'b' )),
    [ 'a b', 'c', 'd e', 'f', "g 'h", 'i " j', 'k', 'a"', q(l"m), qq(x${bs}y), qq(a${bs}'b)],
    'complete transport args parsing with multiple quotes and escapes'
);

my $td = tempdir(File::Spec->catdir('t', 'cf XXXX'), CLEANUP => 1);
to_file(File::Spec->catfile($td, 'config.ini'), <<'EOF');
edit_report=default:ask/no pass/na:no
email_from=Some User (SOMEUSER) <bogus@cpan.org>
send_report=default:ask/yes pass/na:yes
transport=Metabase uri https://metabase.cpantesters.org/api/v1/ id_file metabase_id.json
EOF
my $id_file = File::Spec->catfile($td, 'metabase_id.json');
to_file($id_file, '[]');
$ENV{PERL_CPAN_REPORTER_DIR} = $td;

sub to_file {
    my ($file, $text) = @_;
    open my $fh, '>', $file or die "$file: $!";
    print $fh $text;
    close $fh;
}

my $config = CPAN::Testers::Common::Client::Config->new(
    prompt => sub { ok(1, 'prompt called') },
    warn   => sub { ok(1, 'warn called')   },
    print  => sub { ok(1, 'print called')  },
);

ok $config, 'config client spawns';

isa_ok $config,
       'CPAN::Testers::Common::Client::Config',
       'config client has the proper class';

can_ok $config,
       qw( get_config_dir get_config_filename myprompt mywarn myprint
           setup read email_from edit_report send_report send_duplicates
           transport transport_name transport_args
       );

for my $method (qw(myprompt mywarn myprint read)) {
    eval { $config->$method };
    is $@, '', $method;
}

is(
    $config->email_from,
    'Some User (SOMEUSER) <bogus@cpan.org>',
    'got the right email_from'
);

is $config->transport_name, 'Metabase', 'found right transport name';

my %args = @{ $config->transport_args };
is_deeply \%args, {
        'uri',
        'https://metabase.cpantesters.org/api/v1/',
        'id_file',
        $id_file,
}, 'transport_args content';

my $args = $config->transport_args;
is ref $args, 'ARRAY', 'transport_args is an array ref';

# ---- extra normalizer checks
my $normalized = $config->_normalize_id_file('~/some/file');
unlike $normalized, qr(~), 'relative "~" paths are resolved';
$normalized = $config->_normalize_id_file('"/some path/file"');
is $normalized, '/some path/file', 'quoted paths have quotes removed';

done_testing;
