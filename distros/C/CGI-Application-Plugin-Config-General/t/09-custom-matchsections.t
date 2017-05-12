
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp::Pear;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::General;

    sub setup {
        my $self = shift;

        $self->header_type('none');
        $self->run_modes(
            'start' => 'default',
        );
        $self->mode_param(
            '-path_info' => 2,
        );

        $ENV{'SITE_NAME'} = 'rhonda';
        $ENV{'SCRIPT_NAME'} = '/foo/bar.cgi';
        $self->conf->init(
            -ConfigFile => 't/conf/09-custom-matchsections.conf',
            -Options => {
                -LowerCaseNames => 1,
                -MatchSections => [
                    {
                        -Name        => 'Fruit',
                        -SectionType => 'module',
                        -MatchType   => 'substring',
                    }
                ],

            },
        );

    }

    sub default {
        my $self = shift;

        my $config = $self->conf->getall;
        is($config->{'apple'},   0,    'apple');
        is($config->{'pear'},    1,    'pear');
        is($config->{'rhonda'},  0,    'rhonda');
        is($config->{'foo'},     0,    'foo');

        return "";
    }
}

my $webapp = WebApp::Pear->new;
$webapp->run;

