use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Copy;

if ($^O =~ /MSWin/){
    print "this distribution is not meant to run on MS Windows\n";
    exit;
}

my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

if (! grep { -x "$_/sqlite3" } split /:/, $ENV{PATH}) {
    die "sqlite3 must be installed to continue\n";
}

# copy initial db and conf file

if (! -e 'db/envui.db'){
    print "copying default db...\n";
    copy 'src/envui-dist.db', 'db/envui.db' or die $!;
}
if (! -e 'config/envui.json'){
    print "copying default config...\n";
    copy 'src/envui-dist.json', 'config/envui.json' or die $1;
}

sub MY::postamble {
return <<EOF;

install:: all local

local:
	cp ~/envui/config/envui.json ~

	rm -rf ~/envui
	mkdir ~/envui

	mkdir ~/envui/bin
	cp bin/* ~/envui/bin

	mkdir ~/envui/config
	cp src/envui-dist.json ~/envui/config/envui.json

	mkdir ~/envui/db
	cp src/envui-dist.db ~/envui/db/envui.db

	cp -R lib ~/envui

	mkdir ~/envui/public
	mkdir ~/envui/public/js
	mkdir ~/envui/public/css
	cp public/js/* ~/envui/public/js
	cp public/css/* ~/envui/public/css

	mkdir ~/envui/src
	cp src/* ~/envui/src

	mkdir ~/envui/views
	cp views/* ~/envui/views

	cp config.yml ~/envui
EOF
}

WriteMakefile(
    NAME                => 'App::RPi::EnvUI',
    AUTHOR              => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM        => 'lib/App/RPi/EnvUI.pm',
    ABSTRACT_FROM            => 'lib/App/RPi/EnvUI.pm',
    ($eumm_version >= 6.3001
        ? ('LICENSE'=> 'perl')
        : ()),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/app-rpi-envui/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/app-rpi-envui.git',
                web => 'https://github.com/stevieb9/app-rpi-envui',
            },
        },
    },
    PL_FILES            => {},
    PREREQ_PM => {
        'Async::Event::Interval' => 0.04,
        'Crypt::SaltedHash' => 0,
        'Dancer2'     => 0.203001,
        'Dancer2::Plugin::Auth::Extensible' => 0,
        'Dancer2::Plugin::Auth::Extensible::Provider::Base' => 0,
        'Dancer2::Session::JSON' => 0,
        'DateTime'  => 0,
        'DBI' => 0,
        'DBD::SQLite' => 0,
        'Digest::SHA1' => 0,
        'JSON::XS' => 0,
        'Logging::Simple' => '1.01',
        'Mock::Sub' => '1.07',
        'Plack::Test' => 0,
        'RPi::DHT11' => '1.01',
        'RPi::Const' => '1.02',
        'Test::More' => 0,
        'WiringPi::API' => '1.04',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'wui-*' },
);
