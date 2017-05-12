use Test::More tests => 76;
use lib 'lib';
use DPKG::Log;
use DPKG::Log::Entry;

can_ok('DPKG::Log::Entry', 'line');
can_ok('DPKG::Log::Entry', 'lineno');
can_ok('DPKG::Log::Entry', 'timestamp');
can_ok('DPKG::Log::Entry', 'type');
can_ok('DPKG::Log::Entry', 'associated_package');
can_ok('DPKG::Log::Entry', 'action');
can_ok('DPKG::Log::Entry', 'status');
can_ok('DPKG::Log::Entry', 'subject');
can_ok('DPKG::Log::Entry', 'installed_version');
can_ok('DPKG::Log::Entry', 'available_version');
can_ok('DPKG::Log::Entry', 'conffile');
can_ok('DPKG::Log::Entry', 'decision');

my $dpkg_log_entry;
ok($dpkg_log_entry = DPKG::Log::Entry->new(
                        line => '2011-02-02 11:15:33 startup archives unpack',
                        lineno => 1,
                        type => 'startup',
                        subject => 'archives',
                        action => 'unpack'
                     ),
                     "initialize DPKG::Log::Entry object");
isa_ok($dpkg_log_entry, "DPKG::Log::Entry", "entry");

my $type;
is($dpkg_log_entry->type, "startup", "entry has correct type");
my $subject;
is($dpkg_log_entry->subject, "archives", "entry has correct subject");
my $action;
is($dpkg_log_entry->action, "unpack", "entry has correct action");

my $dpkg_log = DPKG::Log->new('filename' => 'test_data/install.log');
$dpkg_log->parse;
my $entry = $dpkg_log->next_entry;
my $entry_no;
my $line;

ok($line = $entry->line, "line is stored in entry");
ok($entry_no = $entry->lineno, "lineno is stored in entry");
ok($entry->timestamp, "entry $entry_no has timestamp");
isa_ok($entry->timestamp, "DateTime", "timestamp attribute");
is($entry->action, "configure", "entry $entry_no has correct action");
is($entry->type, "startup", "entry $entry_no has correct type");
is($entry->subject, "packages", "entry $entry_no has correct subject");

$entry = $dpkg_log->next_entry;
$old_line = $line;
ok($line = $entry->line, "line is stored in entry");
ok($entry_no = $entry->lineno, "lineno is stored in entry");
ok($entry->timestamp, "entry $entry_no has timestamp");
isa_ok($entry->timestamp, "DateTime", "timestamp attribute");
is($entry->action, "install", "entry $entry_no has correct action");
is($entry->type, "action", "entry $entry_no has correct type");
is($entry->subject, "package", "entry $entry_no has correct subject");
is($entry->associated_package, "libdatetime-format-strptime-perl", "entry $entry_no has correct package");

$entry = $dpkg_log->next_entry;
$old_line = $line;
ok($line = $entry->line, "line is stored in entry");
ok($entry_no = $entry->lineno, "lineno is stored in entry");
ok($entry->timestamp, "entry $entry_no has timestamp");
isa_ok($entry->timestamp, "DateTime", "timestamp attribute");
is($entry->action, "configure", "entry $entry_no has correct action");
is($entry->type, "action", "entry $entry_no has correct type");
is($entry->subject, "package", "entry $entry_no has correct subject");
is($entry->associated_package, "libdatetime-format-strptime-perl", "entry $entry_no has correct package");
is($entry->installed_version, "1.5000-1", "entry $entry_no has correct installed_version");
is($entry->available_version, "1.5000-1", "entry $entry_no has correct available_version");

$entry = $dpkg_log->next_entry;
$old_line = $line;
ok($line = $entry->line, "line is stored in entry");
isnt($line, $old_line, "line is different from previous line");
ok($entry_no = $entry->lineno, "lineno is stored in entry");
ok($entry->timestamp, "entry $entry_no has timestamp");
isa_ok($entry->timestamp, "DateTime", "timestamp attribute");
is($entry->status, "unpacked", "entry $entry_no has correct status");
is($entry->action, undef, "entry $entry_no has correct action");
is($entry->type, "status", "entry $entry_no has correct type");
is($entry->subject, "package", "entry $entry_no has correct subject");
is($entry->associated_package, "libdatetime-format-strptime-perl", "entry $entry_no has correct package");
is($entry->installed_version, "1.5000-1", "entry $entry_no has correct installed_version");

$entry = $dpkg_log->next_entry;
$old_line = $line;
ok($line = $entry->line, "line is stored in entry");
isnt($line, $old_line, "line is different from previous line");
ok($entry_no = $entry->lineno, "lineno is stored in entry");
ok($entry->timestamp, "entry $entry_no has timestamp");
isa_ok($entry->timestamp, "DateTime", "timestamp attribute");
is($entry->status, "half-configured", "entry $entry_no has correct status");
is($entry->action, undef, "entry $entry_no has correct action");
is($entry->type, "status", "entry $entry_no has correct type");
is($entry->subject, "package", "entry $entry_no has correct subject");
is($entry->associated_package, "libdatetime-format-strptime-perl", "entry $entry_no has correct package");
is($entry->installed_version, "1.5000-1", "entry $entry_no has correct installed_version");

$entry = $dpkg_log->next_entry;
$old_line = $line;
ok($line = $entry->line, "line is stored in entry");
isnt($line, $old_line, "line is different from previous line");
ok($entry_no = $entry->lineno, "lineno is stored in entry");
ok($entry->timestamp, "entry $entry_no has timestamp");
isa_ok($entry->timestamp, "DateTime", "timestamp attribute");
is($entry->status, "installed", "entry $entry_no has correct status");
is($entry->action, undef, "entry $entry_no has correct action");
is($entry->type, "status", "entry $entry_no has correct type");
is($entry->subject, "package", "entry $entry_no has correct subject");
is($entry->associated_package, "libdatetime-format-strptime-perl", "entry $entry_no has correct package");
is($entry->installed_version, "1.5000-1", "entry $entry_no has correct installed_version");
ok($entry->new(line => "2011-02-02 11:15:33 startup archives unpack", lineno => 1), "init DPKG::Log::Entry from existing ref");
