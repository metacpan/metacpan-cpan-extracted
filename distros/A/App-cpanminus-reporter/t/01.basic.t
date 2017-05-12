use strict;
use warnings;
use Test::More;
use App::cpanminus::reporter;

can_ok 'App::cpanminus::reporter',
	qw( new config verbose quiet only exclude build_dir build_logfile
        run get_author make_report get_meta_for);

ok my $reporter = App::cpanminus::reporter->new, 'created a new reporter object';
isa_ok $reporter, 'App::cpanminus::reporter';

like $reporter->build_dir, qr/\.cpanm$/, 'build_dir properly set';
like $reporter->build_logfile, qr/build\.log$/, 'build_logfile properly set';

my $ret;
is $reporter->quiet, undef,    'quiet() is not set by default';
ok $ret = $reporter->quiet(1), 'setting quiet() to true';
is $reporter->quiet, 1,        'quiet() now set to true';
is $ret, $reporter->quiet,     'quiet() was properly returned when set';

is $reporter->verbose, undef,    'verbose() is not set by default';
ok $ret = $reporter->verbose(1), 'setting verbose() to true';
is $reporter->verbose, 1,        'verbose() now set to true';
is $ret, $reporter->verbose,     'verbose() was properly returned when set';

is $reporter->force, undef,    'force() is not set by default';
ok $ret = $reporter->force(1), 'setting force() to true';
is $reporter->force, 1,        'force() now set to true';
is $ret, $reporter->force,     'force() was properly returned when set';

is $reporter->exclude, undef, 'exclude() is not set by default';
ok $ret = $reporter->exclude('Foo, Bar::Baz,Meep-Moop'), 'setting exclude()';
is_deeply(
  [ sort keys %{ $reporter->exclude } ],
  [ qw(Bar-Baz Foo Meep-Moop) ],
  'exclude() now set to the proper dists'
);
is_deeply $ret, $reporter->exclude, 'exclude() was properly returned when set';

is $reporter->only, undef, 'only() is not set by default';
ok $ret = $reporter->only('Meep::Moop,Bar-Baz , Foo'), 'setting only()';
is_deeply(
  [ sort keys %{ $reporter->only } ],
  [ qw(Bar-Baz Foo Meep-Moop) ],
  'only() now set to the proper dists'
);
is_deeply $ret, $reporter->only, 'only() was properly returned when set';

ok my $config = $reporter->config, 'object has config()';
isa_ok $config, 'CPAN::Testers::Common::Client::Config';

done_testing;
