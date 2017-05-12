use Test::More no_plan;
use Config::YAML;
use Getopt::Long;

@ARGV = qw( --noclobber );

my $c = Config::YAML->new(config => 't/test.yaml');
ok($c->{clobber} == 1, "This should always work if the previous tests did");
GetOptions( $c,
            'clobber|c!'
          );
ok($c->{clobber} == 0, "Param update via Getopt worked");
