
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp::Foo::Bar::Baz;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::General;

    sub setup {
        my $self = shift;

        $self->header_type('none');
        $self->run_modes(
            'start' => 'default',
        );

        $ENV{'SCRIPT_NAME'} = '/apps/red/users';
        $ENV{'PATH_INFO'}   = '/some/long/path/one';

        $ENV{'SITE_NAME'}   = 'fred';

        $self->conf('one')->init(
            -ConfigFile       => 't/conf/05-site.conf',
            -CacheConfigFiles => 0,
        );

        $ENV{'SITE_NAME'}   = 'unseen';

        $self->conf('two')->init(
            -ConfigFile       => 't/conf/05-site.conf',
            -CacheConfigFiles => 0,
        );

        $ENV{'TORQUEMADA'}  = 'hat';

        $self->conf('three')->init(
            -ConfigFile       => 't/conf/05-site.conf',
            -SiteVar          => 'TORQUEMADA',
            -SiteSectionName  => 'Porkpie',
            -CacheConfigFiles => 0,
        );

        $ENV{'SITE_NAME'}  = 'hat';

        $self->conf('four')->init(
            -ConfigFile       => 't/conf/05-site.conf',
            -SiteSectionName  => 'Porkpie',
            -CacheConfigFiles => 0,
        );
    }

    sub default {
        my $self = shift;

        my $config;

        # no match
        $config = $self->conf('one')->getall;
        is($config->{'caveat_emptor'}, 0, '1.caveat_emptor');
        is($config->{'the_lid_man'},   0, '1.the_lid_man');

        is($config->{'Porkpie'}{'hat'}{'the_lid_man'},   1, '1.subsection Porkpie');

        # site unseen
        $config = $self->conf('two')->getall;
        is($config->{'caveat_emptor'}, 1, '2.caveat_emptor');
        is($config->{'the_lid_man'},   0, '2.the_lid_man');

        # Porkpie hat
        $config = $self->conf('three')->getall;
        is($config->{'caveat_emptor'}, 0, '3.caveat_emptor');
        is($config->{'the_lid_man'},   1, '3.the_lid_man');

        # Porkpie hat
        $config = $self->conf('four')->getall;
        is($config->{'caveat_emptor'}, 0, '4.caveat_emptor');
        is($config->{'the_lid_man'},   1, '4.the_lid_man');


        return "";
    }
}

my $webapp = WebApp::Foo::Bar::Baz->new;
$webapp->run;


