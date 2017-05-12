use strict;
use warnings;
use Test::More tests => 10;
use Test::Reporter;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';

ok my $reporter = App::cpanminus::reporter->new(
  force          => 1, # ignore mtime check on build.log
  build_logfile  => $dir . '/build.dist_subdir.log',
  quiet          => 1,
  'skip-history' => 1,
  'ignore-versions' => 1,
), 'created new reporter object';

sub test_reporter_new {
    my $self = shift;
    my %params = @_;

    my @params = qw( comments distfile distribution from grade
                     transport transport_args via);

    is_deeply [ sort keys %params ], \@params,
              'arguments properly passed to Test::Reporter';

    is $params{distfile}, 'ILYAZ/modules/Term-ReadLine-Perl-1.0303.tar.gz'
       => 'distfile is properly set';

    is $params{distribution}, 'Term-ReadLine-Perl-1.0303'
       => 'distribution is properly set';

    is $params{from}, undef, 'from is properly set';

    is $params{grade}, 'pass', 'grade is properly set';

    is $params{transport}, undef, 'transport is properly set';
    is $params{transport_args}, undef, 'transport is properly set';

    like $params{via}, qr/^App::cpanminus::reporter/, 'via is properly set';

    return bless {}, 'Test::Reporter';
}
sub test_reporter_send {
    my $self = shift;
    pass 'Test::Reporter::send called';
    return 1;
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *Test::Reporter::new = \&test_reporter_new;
  local *Test::Reporter::send = \&test_reporter_send;
  $reporter->run;
};

