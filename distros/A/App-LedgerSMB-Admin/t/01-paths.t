use Test::More tests => 6;
use App::LedgerSMB::Admin;

ok(App::LedgerSMB::Admin->add_paths(
      mock1 => 't/data/mock1',
      mock2 => 't/data/mock2'
  ), 'Added paths');

ok(my %paths = App::LedgerSMB::Admin->add_paths(), 'got baths');
is(keys(%paths ), 2, 'Correct number of paths');

is(App::LedgerSMB::Admin->path_for('undef'), undef, 
    'unknown pth returns undef');

is(App::LedgerSMB::Admin->path_for('mock1'), 't/data/mock1', 
   'correct path for mock1');

is(App::LedgerSMB::Admin->path_for('mock2'), 't/data/mock2', 
   'correct path for mock2');


