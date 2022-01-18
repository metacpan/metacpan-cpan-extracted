use strict;
use warnings;

use lib 'lib';

use Test::More;
use Test::Deep;
use Audit::Log;
use List::Util qw{uniq};

my $parser = Audit::Log->new('t/audit.log','name','type','nametype','line','timestamp');
my $rows = $parser->search( type => qr/path/i, nametype => qr/create|delete/i, name => qr/^backups\/[^\.]/, key => qr/backupwatch/, older => 1642448670, newer => 1642441403 );

my $expected = [
  {
    'line' => 3,
    'timestamp' => '1642441406.575',
    'type' => 'PATH',
    'nametype' => 'CREATE',
    'name' => 'backups/test.txt'
  },
  {
    'type' => 'PATH',
    'timestamp' => '1642441412.975',
    'line' => 8,
    'name' => 'backups/testme.txt',
    'nametype' => 'DELETE'
  }
];

is_deeply($rows,$expected,"Parser works as expected");
done_testing();
