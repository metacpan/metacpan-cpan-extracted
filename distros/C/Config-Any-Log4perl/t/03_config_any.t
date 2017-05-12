use strict;
use warnings;

use Test::More;
use Config::Any;

plan tests => 1;

{
    my $config = Config::Any->load_files({
          files => [ 't/data/Sample.log4perl' ]
        , use_ext => 1
        , driver_args => { Log4perl => { config_name => 'logger' }}
    });

    is_deeply $config
            , [{ 't/data/Sample.log4perl' =>
                    {
                        'logger' => {
                            'log4perl.appender.SCREEN.layout' => 'Log::Log4perl::Layout::PatternLayout'
                        ,   'log4perl.appender.SCREEN.layout.ConversionPattern' => '%d %-5p [%5P] %m%n'
                        ,   'log4perl.appender.SCREEN.stderr' => '1'
                        ,   'log4perl.appender.SCREEN' => 'Log::Log4perl::Appender::Screen'
                        ,   'log4perl.logger' => 'TRACE, SCREEN'
                        }
                    }
              }]
            , 'load_files';
}
