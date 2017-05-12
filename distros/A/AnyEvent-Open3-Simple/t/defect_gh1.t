use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More tests => 2;

use AnyEvent::Open3::Simple;

my $called_on_start = 0;

AnyEvent::Open3::Simple->new({
  on_start => sub { $called_on_start = 1 },
})->run($^X, '-e', '42');

is $called_on_start, 1, 'called_on_start = 1 (hashref)';

$called_on_start = 0;

AnyEvent::Open3::Simple->new(
  on_start => sub { $called_on_start = 1 },
)->run($^X, '-e', '42');

is $called_on_start, 1, 'called_on_start = 1 (list)';
