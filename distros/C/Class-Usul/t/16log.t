use t::boilerplate;

use Test::More;
use File::DataClass::IO;

use_ok 'Class::Usul::Log';

my $file = io [ 't', 'test.log' ]; $file->exists and $file->unlink;
my $log  = Class::Usul::Log->new( encoding => 'UTF-8', logfile => $file );

$log->debug( 'test' );
unlike $file->all, qr{ \Q[DEBUG] Test\E }msx, 'Does not log debug level';

$log->info ( 'test' );
like $file->all, qr{ \Q[INFO] Test\E }msx, 'Log info level';

$log->warn ( 'test' );
like $file->all, qr{ \Q[WARNING] Test\E }msx, 'Log warning level';

$log->error( 'test' );
like $file->all, qr{ \Q[ERROR] Test\E }msx, 'Log error level';

$log->alert( 'test' );
like $file->all, qr{ \Q[ALERT] Test\E }msx, 'Log alert level';

$log->fatal( 'test' );
like $file->all, qr{ \Q[FATAL] Test\E }msx, 'Log fatal level';

$log = Class::Usul::Log->new
   ( debug => 1, encoding => 'UTF-8', logfile => $file );

$log->debug( 'test' );
like $file->all, qr{ \Q[DEBUG] Test\E }msx, 'Log debug level';

use Class::Usul::Log qw( default );

my $r = log 'Function';

like $file->all, qr{ \Q[INFO] Function\E }msx, 'Imports function default level';
is $r, 1, 'Log function returns true';

log 'warn', 'Watchit';
like $file->all, qr{ \Q[WARNING] Watchit\E }msx, 'Level and message';

log 'error', 'Failed', { leader => 'Lead', tag => 'ID' };
like $file->all, qr{ \Q[ERROR] Lead[ID] Failed\E }msx,
   'Level message and options';

log { level => 'fatal', message => 'Brown Bread' };
like $file->all, qr{ \Q[FATAL] Brown Bread\E }msx, 'From hash reference';

log level => 'alert', message => 'Wake Up';
like $file->all, qr{ \Q[ALERT] Wake Up\E }msx, 'From list of keys and values';

my $size = $file->stat->{size}; $r = log;

is $file->stat->{size}, $size, 'Logs nothing with no args';
is $r, 0, 'Returns false when not logging';

log 'nochance', 'testing';
is $r, 0, 'Non existant level returns false';

$file->exists and $file->unlink;
done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
