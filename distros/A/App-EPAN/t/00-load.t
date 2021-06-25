use Test::More;

use App::EPAN;

ok defined($App::EPAN::VERSION), 'version is defined';
diag("Testing App::EPAN $App::EPAN::VERSION");

my $instance = App::EPAN->new;
isa_ok $instance, 'App::EPAN';

can_ok $instance, qw<
   action_add
   action_create
   action_index
   action_inject
   action_install
   action_list_actions
   action_list_obsoletes
   action_purge_obsoletes
   action_update
>;

done_testing();
