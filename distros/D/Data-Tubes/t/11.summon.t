use strict;
use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;

my $files = __PACKAGE__->can('sequence');
ok !$files, 'sub "sequence" does not exist initially';

summon('Plumbing::sequence');
$files = __PACKAGE__->can('sequence');
ok $files, 'sub "sequence" summoned';

my $tube = __PACKAGE__->can('traverse');
ok !$tube, 'sub "traverse" does not exist initially';

summon('+Data::Tubes::Util::traverse');
$tube = __PACKAGE__->can('traverse');
ok $tube, 'sub "traverse" summoned';

summon([qw< Reader read_by_line read_by_paragraph read_by_separator >]);
ok __PACKAGE__->can('read_by_line'),      'summoned by_line';
ok __PACKAGE__->can('read_by_paragraph'), 'summoned by_paragraph';
ok __PACKAGE__->can('read_by_separator'), 'summoned by_separator';

summon([qw< Source open_file iterate_files iterate_array >]);
ok __PACKAGE__->can('open_file'),      'summoned open_file';
ok __PACKAGE__->can('iterate_files'), 'summoned iterate_files';
ok __PACKAGE__->can('iterate_array'), 'summoned iterate_array';

# older interface (up to 0.734 included)
{
   local $Data::Tubes::API_VERSION = '0.734';

   my $tube = __PACKAGE__->can('read_file_maybe');
   ok !$tube, 'sub "read_file_maybe" does not exist initially';
   summon('Data::Tubes::Util::read_file_maybe');
   ok __PACKAGE__->can('read_by_line'), 'summoned read_file_maybe';

   my $files = __PACKAGE__->can('pipeline');
   ok !$files, 'sub "pipeline" does not exist initially';
   summon('Plumbing::pipeline');
   ok __PACKAGE__->can('pipeline'), 'sub "pipeline" summoned';

   my $files = __PACKAGE__->can('logger');
   ok !$files, 'sub "logger" does not exist initially';
   summon('+Plumbing::logger');
   ok __PACKAGE__->can('logger'), 'sub "logger" summoned';

   my $files = __PACKAGE__->can('fallback');
   ok !$files, 'sub "fallback" does not exist initially';
   summon('!Data::Tubes::Plugin::Plumbing::fallback');
   ok __PACKAGE__->can('fallback'), 'sub "fallback" summoned';
}

done_testing();
