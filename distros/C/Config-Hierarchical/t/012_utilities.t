# utilities test

use strict ;
use warnings ;
use Test::Exception ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Test::NoWarnings ;
use Test::Warn ;

use Config::Hierarchical ; 

{
local $Plan = {'Dump and information' => 3} ;

my $file_regex = __FILE__ ; $file_regex = qr/$file_regex/ ;

my $config = new Config::Hierarchical
				(
				NAME => 'this config',
				
				INITIAL_VALUES  =>
					[
					{NAME => 'CC', VALUE => 1},
					{NAME => 'CC', VALUE => 2},
					{NAME => 'AS', VALUE => 4},
					] ,
				) ;

my $dump = $config->GetDump() ;
isnt($dump, '', 'dump not empty') ;

my ($name, $location) = $config->GetInformation() ;
is($name, 'this config') ;
like($location, $file_regex, 'information reports right file') ;

}


{
local $Plan = {'Dump shows category in priority order not alphanumeric' => 1} ;

my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES    => ['Z', 'A'],
				DEFAULT_CATEGORY => 'A',
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'Z', NAME => 'Z', VALUE => 1},
					{CATEGORY => 'A', NAME => 'A', VALUE => 2},
					] ,
				) ;

my $dump = $config->GetDump(DISPLAY_ADDRESS => 0, GLYPHS => ['', '', '', '']) ;
like($dump, qr/CATEGORIES \nZ \nZ/, 'dump category in priority order') ;
}


{
#~ use Data::TreeDumper ;

local $Plan = {'verbose' => 55} ;

my $file_regex = __FILE__ ; $file_regex = qr/$file_regex/ ;
my @messages ;
my $info = sub {push @messages, @_} ;
	
my $config = new Config::Hierarchical
				(
				NAME            => 'verbose test',
				VERBOSE         => 1,
				INITIAL_VALUES  => [{NAME => 'CC', VALUE => 1}],
				INTERACTION     => {INFO => $info},
				) ;

is(@messages, 2, "Create and Set messages") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Creating Config::Hierarchical/, 'creation message') ;
like($messages[1], $file_regex, 'verbose reports right file') ;
like($messages[1], qr/Setting 'CURRENT::CC' to '1'/, 'Set message') ;
#~ diag DumpTree(\@messages) ;


@messages = () ;
my $cc = $config->Get(NAME => 'CC') ;
is(@messages, 2, "Get message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Getting 'CC'/, 'Get message') ;
like($messages[1], qr/found in category 'CURRENT'/, 'Get message') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->GetDump() ;
is(@messages, 0, "Dump generates no message") ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
my $hash_ref = $config->GetHashRef() ;
is(@messages, 3, "GetHashRef generates a message per variable") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/GetHashRef/, 'GetHashRef message') ;
like($messages[1], qr/Getting 'CC'/, 'Get message') ;
like($messages[2], qr/found in category 'CURRENT'/, 'Get message') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->GetHistory(NAME => 'CC') ;
is(@messages, 0, "GetHistory generates no message") ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->Set(NAME => 'LD', VALUE => 2) ;
is(@messages, 1, "set message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Set/, 'Set message') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->SetMultiple([NAME => 'M1', VALUE => 1], [NAME => 'M2', VALUE => 1]) ;
is(@messages, 2, "SetMultiple messages") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Set/, 'Set message') ;
like($messages[1], $file_regex, 'verbose reports right file') ;
like($messages[1], qr/Set/, 'Set message') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
my @multiple = $config->GetMultiple('M1', 'M2') ;
is(@messages, 4, "GetMultiple messages") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Getting 'M1'/, 'Get message') ;
like($messages[1], qr/found in category 'CURRENT'/, 'Get message') ;
like($messages[2], $file_regex, 'verbose reports right file') ;
like($messages[2], qr/Getting 'M2'/, 'Get message') ;
like($messages[3], qr/found in category 'CURRENT'/, 'Get message') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->IsLocked(NAME => 'CC') ;
is(@messages, 1, "IsLocked message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Check/, 'checking message') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->Lock(NAME => 'CC') ;
is(@messages, 1, "Lock message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/locking/i, 'locking message') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->Unlock(NAME => 'CC') ;
is(@messages, 1, "Unlock message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/unlocking/i, 'unlocking message') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->SetDisableSilentOptions(1) ;
is(@messages, 1, "SetDisableSilentOptions message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/DISABLE_SILENT_OPTIONS/, 'DISABLE_SILENT_OPTIONS') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->SetDisableSilentOptions(0) ;
is(@messages, 1, "SetDisableSilentOptions message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/DISABLE_SILENT_OPTIONS/, 'DISABLE_SILENT_OPTIONS') ;
#~ diag DumpTree(\@messages) ;

@messages = () ;
$config->Exists(VERBOSE => 1, NAME => 'CC') ;
is(@messages, 1, "Exists message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Checking Existance/, 'Checking Existance') ;
#~ diag DumpTree(\@messages) ;


@messages = () ;
my @tuples = $config->GetKeyValueTuples(VERBOSE => 1) ;
is(@messages, 10, "Exists message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/'GetKeyValueTuples' at/, 'GetKeyValueTuples') ;
#~ diag DumpTree(\@messages) ;
#~ diag DumpTree($config) ;


@messages = () ;
my @keys = $config->GetKeys() ;
is(@messages, 1, "GetKey message") ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/GetKeys/, 'GetKeys') ;
}

{
#~ use Data::TreeDumper ;

local $Plan = {'verbose' => 4} ;

my $file_regex = __FILE__ ; $file_regex = qr/$file_regex/ ;
my @messages ;
my $info = sub {push @messages, @_} ;
	
my $config = new Config::Hierarchical
				(
				NAME            => 'config',
				VERBOSE         => 1,
				INITIAL_VALUES  => [{NAME => 'CC', VALUE => 1}],
				INTERACTION     => {INFO => $info},
				) ;

@messages = () ;
my $config2 = new Config::Hierarchical
				(
				NAME            => 'config 2',
				VERBOSE         => 1,
				CATEGORY_NAMES    => ['A', 'B'],
				DEFAULT_CATEGORY => 'A',
				INTERACTION     => {INFO => $info},
				INITIAL_VALUES  => [{CATEGORY => 'A', ALIAS_CATEGORY => $config}],
				) ;

is(@messages, 7, "SetAlias message") or diag DumpTree(\@messages) ;
like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Creating Config::Hierarchical/, 'creation message') ;
like($messages[1], qr/SetCategoryAlias/, 'SetCategoryAlias') ;

use Data::TreeDumper ;
}




