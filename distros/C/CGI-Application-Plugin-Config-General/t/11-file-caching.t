
use strict;
use warnings;

my $Config_File            = 't/testconf.conf';
my $Containing_Config_File = 't/testconf-container.conf';



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
        $self->mode_param(
            '-path_info' => 2,
        );

        write_original_config();

        # Simple read with caching
        $self->conf('01')->init(
            -ConfigFile       => $Config_File,
        );
        $self->conf('02')->init(
            -ConfigFile       => $Config_File,
        );

        ok($self->conf('01')->obj eq $self->conf('02')->obj, 'Caching ON: objects identical');
        my $config = $self->conf('01')->getall;
        is($config->{'original'}, 1,        '01.original');
        is($config->{'modified'}, 0,        '01.modified');
        is($config->{'fruit'},    'banana', '01.fruit');
        is($config->{'truck'},    'red',    '01.truck');


        # Simple read with caching disabled
        $self->conf('03')->init(
            -ConfigFile       => $Config_File,
            -CacheConfigFiles => 0,
        );
        $self->conf('04')->init(
            -ConfigFile       => $Config_File,
            -CacheConfigFiles => 0,
        );

        ok($self->conf('03')->obj ne $self->conf('04')->obj, 'Caching OFF: objects differ');

        # Delete file in between first and second read (caching ON)
        $self->conf('05')->init(
            -ConfigFile       => $Config_File,
        );

        delete_config();

        eval {
            $self->conf('06')->init(
                -ConfigFile       => $Config_File,
            );
        };
        ok(!$@, 'Delete, Caching ON, no error');
        ok($self->conf('05')->obj eq $self->conf('06')->obj, 'Delete, Caching ON:  objects identical');

        # Delete file in between first and second read (caching OFF)
        write_original_config();
        $self->conf('07')->init(
            -ConfigFile       => $Config_File,
            -CacheConfigFiles => 0,
        );

        delete_config();

        eval {
            $self->conf('08')->init(
                -ConfigFile       => $Config_File,
                -CacheConfigFiles => 0,
            );
        };
        ok($@, 'Delete, Caching OFF, error thrown');



        # Modify before statconfig runs out
        $self->conf('09')->init(
            -ConfigFile       => $Config_File,
        );

        write_modified_config();
        $self->conf('10')->init(
            -ConfigFile       => $Config_File,
        );

        ok($self->conf('09')->obj eq $self->conf('10')->obj, 'Modify before statconfig: Caching ON: objects identical');
        $config = $self->conf('09')->getall;
        is($config->{'original'}, 1,        '09.original');
        is($config->{'modified'}, 0,        '09.modified');
        is($config->{'fruit'},    'banana', '09.fruit');
        is($config->{'truck'},    'red',    '09.truck');


        # Modify before statconfig runs out (short statconfig)
        write_original_config();
        $self->conf('11')->init(
            -ConfigFile       => $Config_File,
            -StatConfig       => 2,
        );

        write_modified_config();
        $self->conf('12')->init(
            -ConfigFile       => $Config_File,
            -StatConfig       => 2,
        );

        ok($self->conf('11')->obj eq $self->conf('12')->obj, 'Modify before (short) statconfig: Caching ON: objects identical');
        $config = $self->conf('11')->getall;
        is($config->{'original'}, 1,        '11.original');
        is($config->{'modified'}, 0,        '11.modified');
        is($config->{'fruit'},    'banana', '11.fruit');
        is($config->{'truck'},    'red',    '11.truck');

        # Modify after statconfig runs out
        write_original_config();
        $self->conf('13')->init(
            -ConfigFile       => $Config_File,
            -StatConfig       => 2,
        );

        sleep 3;
        write_modified_config();

        $self->conf('14')->init(
            -ConfigFile       => $Config_File,
            -StatConfig       => 2,
        );

        ok($self->conf('13')->obj ne $self->conf('14')->obj, 'Modify after statconfig: Caching ON: objects differ');
        $config = $self->conf('13')->getall;
        is($config->{'original'}, 1,        '13.original');
        is($config->{'modified'}, 0,        '13.modified');
        is($config->{'fruit'},    'banana', '13.fruit');
        is($config->{'truck'},    'red',    '13.truck');

        $config = $self->conf('14')->getall;
        is($config->{'original'}, 0,        '14.original');
        is($config->{'modified'}, 1,        '14.modified');
        is($config->{'fruit'},    'plum',   '14.fruit');
        is($config->{'truck'},    'red',    '14.truck');

        sleep 3;

        # Modify after statconfig runs out (modified config is same size)
        write_original_config();
        $self->conf('15')->init(
            -ConfigFile       => $Config_File,
            -StatConfig       => 2,
        );

        sleep 3;
        write_modified_same_size_config();

        $self->conf('16')->init(
            -ConfigFile       => $Config_File,
            -StatConfig       => 2,
        );

        ok($self->conf('15')->obj ne $self->conf('16')->obj, 'Modify after statconfig: Caching ON, modified config same size: objects differ');
        $config = $self->conf('15')->getall;
        is($config->{'original'}, 1,        '15.original');
        is($config->{'modified'}, 0,        '15.modified');
        is($config->{'fruit'},    'banana', '15.fruit');
        is($config->{'truck'},    'red',    '15.truck');

        $config = $self->conf('16')->getall;
        is($config->{'original'}, 0,        '16.original');
        is($config->{'modified'}, 1,        '16.modified');
        is($config->{'fruit'},    'banana', '16.fruit');
        is($config->{'truck'},    'RED',    '16.truck');


        SKIP: {
            skip "Installed Config::General doesn't support 'files'", 11 unless $self->conf('01')->obj->can('files');
            write_original_config();
            write_containing_config();
            $self->conf('50')->init(
                -ConfigFile       => $Containing_Config_File,
                -StatConfig       => 2,
            );

            write_modified_config();
            sleep 3;

            $self->conf('51')->init(
                -ConfigFile       => $Containing_Config_File,
                -StatConfig       => 2,
            );

            ok($self->conf('50')->obj ne $self->conf('51')->obj, 'Include files - Modify after statconfig: Caching ON: objects differ');
            $config = $self->conf('50')->getall;
            is($config->{'container'}, 1,        '50.container');
            is($config->{'original'},  1,        '50.original');
            is($config->{'modified'},  0,        '50.modified');
            is($config->{'fruit'},     'banana', '50.fruit');
            is($config->{'truck'},     'red',    '50.truck');

            $config = $self->conf('51')->getall;
            is($config->{'container'}, 1,        '51.container');
            is($config->{'original'},  0,        '51.original');
            is($config->{'modified'},  1,        '51.modified');
            is($config->{'fruit'},     'plum',   '51.fruit');
            is($config->{'truck'},     'red',    '51.truck');


            delete_containing_config();

        }


        delete_config();




    }

    sub default {
        my $self = shift;
        return "";
    }

    sub write_original_config {
        my $filename = $Config_File;
        my $config = q{
            original = 1
            modified = 0
            fruit    = banana
            truck    = red
        };

        write_config($filename, $config);
    }
    sub write_containing_config {
        my $filename = $Containing_Config_File;
        my $config = qq{
            <<include $Config_File>>
            container = 1
        };

        write_config($filename, $config);
    }

    sub write_modified_config {
        my $filename = $Config_File;
        my $config = q{
            original = 0
            modified = 1
            fruit    = plum
            truck    = red
        };
        write_config($filename, $config);
    }

    sub write_modified_same_size_config {
        my $filename = $Config_File;
        my $config = q{
            original = 0
            modified = 1
            fruit    = banana
            truck    = RED
        };
        write_config($filename, $config);
    }

    sub delete_config {
        unlink $Config_File;
    }
    sub delete_containing_config {
        unlink $Containing_Config_File;
    }

    sub write_config {
        my $filename = shift;
        my $config   = shift;
        open my $fh, '>', $filename or die "Can't clobber temporary config file $filename: $!\n";
        print $fh $config;
        close $fh;
    }


}

my $webapp = WebApp::Foo::Bar::Baz->new;
$webapp->run;



