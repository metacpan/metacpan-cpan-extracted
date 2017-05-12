use strict;
use lib qw( ../lib ./test );
use DBI;
use Cwd;
use Test::More;
use Test::Exception;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Tests require DBD::SQLite') : (tests => 54);
    use_ok('Class::DBI::Factory');
    use_ok('Class::DBI::Factory::Config');
    use_ok('Class::DBI::Factory::Handler');
    use_ok('Class::DBI::Factory::List');
    use_ok('Class::DBI::Factory::Ghost');
    use_ok('Class::DBI::Factory::Mailer');
    use_ok('Class::DBI::Factory::Exception', qw(:try));
}

my $here = cwd;
my $now = scalar time;
my $configfile = "$here/test/cdf.conf";

my $dumb_factory = Class::DBI::Factory->new;
isa_ok( $dumb_factory, 'Class::DBI::Factory', 'empty factory'); 

$dumb_factory->use_classes(qw(Thing));
my $classes = $dumb_factory->classes;
is( $$classes[0], 'thing', 'use_classes'); 

undef $dumb_factory;

$ENV{_SITE_TITLE} = '_test';
$ENV{_CDF_CONFIG} = $configfile;

my $factory = Class::DBI::Factory->instance;

ok( $factory, 'full factory constructed' );

print "\nCONFIG\n\n";

isa_ok($factory->config, 'Class::DBI::Factory::Config', 'full factory config');
isa_ok($factory->config->ac, 'AppConfig', 'config->ac');
is($factory->config->get('refresh_interval'), '3600', 'config values');
is($factory->config->get('template_root'), '<undef>', 'config non-values');

print "\nFACTORY\n\n";

my $dsn = "dbi:SQLite:dbname=cdftest.db";
my $config = set_up_database($dsn);
$factory->set_db($config);

ok( $factory->dbh && $factory->dbh->ping, 'connected to ' . $config->{db_type});

my $thing = $factory->create(thing => {
	title => 'Wellington boot remover',
	description => 'Inclined metal foot rest with a notch at the far end ready to receive the heel of a wellington boot and hold it in position while the foot is removed from it.',
	date => $now,
});

is( $thing->title, 'Wellington boot remover', 'factory->create' );

is( $thing->_factory, $factory, 'managed class namespace properly interfered with');

$factory->create(thing => {
	title => 'Ironing Board',
	description => 'Cloth-covered surface of adjustable height shaped so as to provide a suitable surface for the application of hot iron to wrinkled clothing.',
	date => $now,
});

$factory->create(thing => {
	title => 'Spice rack',
	description => 'Small, two-tier construction of warped pine shelves above which wonky dowels attempt to prevent the toppling of each row of tall, thin spice jars designed to contain as little pulverised spice as possible while still appearing large and full.',
	date => $now,
});

$factory->create(thing => {
	title => 'Bread board',
	description => 'Flat, usually wooden surface which collects crumbs and accepts gouges during the slicing of bread.',
	date => $now,
});

my $id = $thing->id;
my $rething = $factory->retrieve('thing', $id);

is( $thing, $rething, 'factory->retrieve' );

$thing->title('Wellyoff');
$thing->update;

is( $thing->title, 'Wellyoff', 'object->update' );

$thing->title('Wellington boot remover');
$thing->update;

my $iterator = $factory->search_like('thing', title => '%board');

is( $iterator->count, 2, 'factory->search_like');

my $count = $factory->count('thing');

is( $count, 4, 'factory->count');

my $dbh = $factory->dbh;
isa_ok( $dbh, "DBIx::ContextualFetch::db", 'factory->dbh' );

throws_ok { $factory->load_class('No::Chance::Boyo'); } 'Exception::SERVER_ERROR', 'SERVER_ERROR exception thrown by bad load_class call';
throws_ok { $factory->fugeddaboutit('thing', 1); } 'Exception::SERVER_ERROR', 'SERVER_ERROR exception thrown by AUTOLOAD with disallowed method name';

SKIP: {
    eval "require Template;";
    skip "Template not installed", 3 if $@;
    
    my $tt = $factory->tt;
    isa_ok( $tt, "Template", 'factory->template' );
    
    my $html;
    my $template = '[% test %]';
    $factory->process(\$template, { test => 'pass' } , \$html);
    is( $html, 'pass', 'factory->parse');

    $template = "[% factory.retrieve('thing', " . $thing->id . ").title %]";
    $html = '';
    $factory->process(\$template, { factory => $factory } , \$html);
    is( $html, $thing->title, 'template calls to factory methods');

    $template = "[% IF 1 %][% factory.retrieve('thing', " . $thing->id . ").title %]";
    $html = '';
    throws_ok { $factory->process(\$template, { factory => $factory } , \$html); } 'Exception::SERVER_ERROR', 'SERVER_ERROR exception thrown by broken template';
}

print "\nHANDLER\n\n";

print "Proper handler tests would require Apache::Test and a great load of configuration. It seems like overkill here. Do get in touch if you disagree (or would like to write some :)\n\n";

my $handler = Class::DBI::Factory::Handler->new();
isa_ok ($handler, 'Class::DBI::Factory::Handler', "handler object");

print "\nLIST\n\n";

my $list = $factory->list('thing', date => $now, sortby => 'title');

ok( $list, 'list construction');

my $total = $list->total;

is( $total, 4, 'list size');

my @contents = $list->contents;

is( $contents[0]->title, 'Bread board', 'list ordering');

my $other_list = $factory->list_from($iterator);
my $count = $other_list->total;

is( $count, 2, 'list from iterator');

throws_ok { $factory->list('anything'); } 'Exception::NOT_FOUND', 'NOT_FOUND exception thrown by list call with non-moniker';

print "\nGHOST\n\n";

my $ghost = $factory->ghost_object('thing', {
    title => 'testy',
    description => 'wooooo',
});

ok ($ghost, 'ghost object created');
is ($ghost->is_ghost, '1', 'ghost knows it\'s a ghost');
is ($ghost->type, 'thing', 'ghost linked to correct data class');
ok ($ghost->find_column('title'), 'ghost finds correct columns');
is ($ghost->title, 'testy', 'ghost holds column values');
isa_ok ($ghost->make, 'Thing', 'ghost make() object');

my $otherghost = $factory->ghost_from($thing);

ok ($otherghost, 'ghost object created from real object');
is ($otherghost->title, 'Wellington boot remover', 'title transcribed ok');
is ($otherghost->moniker, 'thing', 'ghost moniker ok');
is ($otherghost->class, 'Thing', 'ghost class ok');

print "\nMAILER\n\n";

my $mailer = $factory->mailer;
isa_ok ($mailer, 'Class::DBI::Factory::Mailer', 'mailer object');

$factory->mailer->mta('IO');
is ($mailer->mta, 'IO', 'mailer transport set');

my $mailfile = 'mailtest.txt';
$mailer->mta_parameters($mailfile);
is ($mailer->mta_parameters, $mailfile, 'mailer parameter set');

SKIP: {
    eval "require File::Slurp; require Email::Send::IO;";
    skip "File::Slurp and/or Email::Send::IO not installed.", 1 if $@;
    unless ($@) {
        $factory->send_message({
            from => 'testy',
            to => 'testy',
            subject => 'testy',
            message => 'hello dere',
        });
    
        my $target = qq|To: testy
From: testy
Subject: testy
Content-Type: text/plain

hello dere|;

        my $message = File::Slurp::read_file( $mailfile ) if -e $mailfile;
        is($message, $target, "Email message 'delivered' to local filesystem");
        unlink $mailfile;
    }
}

print "\nEXCEPTIONS\n\n";

# Handler tests mostly relate to exceptions

throws_ok { test_404(); } 'Exception::NOT_FOUND', 'NOT_FOUND exception thrown';

try {
    test_404();
}
catch Exception::NOT_FOUND with {
    my $ex = shift;
    is ($ex->view, 'notfound', 'exception returns correct view');
    is ($ex->text, 'Just testing', 'exception returns correct text');
    is ($ex->stringify, 'Just testing', 'exception stringifies politely');
}
otherwise {
    print "bad! Exception not caught.";
};

print "\nCONFIGURATION SELF-UPDATE\n\n";

warn "...Time passes...\n\n";
sleep(1);

my ($testparam, $testvalue);
my @c = ('A'..'Z', 'a'..'z', 0..9);
$testparam .= $c[ int(rand $#c) ] for (1..8);
$testvalue .= $c[ int(rand $#c) ] for (1..8);

open CFG, ">>$configfile"; 
print CFG "$testparam = $testvalue\n";
close CFG;

my $ts = $factory->config->timestamp;
$factory->config->refresh;

isnt( $factory->config->timestamp, $ts, 'config detects file update' );
is ( $factory->config->get($testparam), $testvalue, "config contains new parameter");


# that's all, folks.










sub test_404 {
    throw Exception::NOT_FOUND(
        -text => "Just testing", 
        -view =>'404',
    );
}

END {
    undef $factory;
    print "\nTests complete: database deleted.\n\n" if $config->{db_type} eq 'SQLite' && unlink "${here}/cdftest.db";
}

sub set_up_database {
    my $dsn = shift;
	my $dbh;
	eval { $dbh = DBI->connect($dsn,"",""); };
    die "connecting to (and creating) SQLite database './cdftest.db' failed: $!" if $@;
    $dbh->do('create table things (id integer primary key, title varchar(255), description text, date int);');
    return {
        db_type => 'SQLite',
        db_name => 'cdftest.db',
        db_username => '',
        db_password => '',
        db_host => '',
        db_port => '',
    };
} 


