use strict;
use warnings;

use Test::More;
use Config::Any::Log4perl;

plan tests => 4;

{
    my $config = Config::Any::Log4perl->load('t/data/Sample.log4perl');
    ok($config);
    is($config->{'log4perl.logger'}, 'TRACE, SCREEN');
}

{
    my $config = Config::Any::Log4perl->load('t/data/Sample.log4perl', { config_name => 'logger' });
    ok(exists $config->{logger});
    is_deeply $config
            , {
                  'logger' => {
                      'log4perl.appender.SCREEN.layout' => 'Log::Log4perl::Layout::PatternLayout'
                  ,   'log4perl.appender.SCREEN.layout.ConversionPattern' => '%d %-5p [%5P] %m%n'
                  ,   'log4perl.appender.SCREEN.stderr' => '1'
                  ,   'log4perl.appender.SCREEN' => 'Log::Log4perl::Appender::Screen'
                  ,   'log4perl.logger' => 'TRACE, SCREEN'
                  }
              }
            , 'load';
}
