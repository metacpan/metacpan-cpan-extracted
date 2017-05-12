
# I'm only doing these tests in Config::General format.
# multi-format file caching tests can be found in the
# Config::Context test suite

use strict;
use warnings;

my $Config_File            = 't/testconf.conf';
my $Containing_Config_File = 't/testconf-container.conf';
my $Included_File          = 'testconf.conf';

my $Files_Method_Supported = 1;

use Test::More;
eval { require Config::General; };

if ($@) {
    plan 'skip_all' => "Config::General not installed"
}
else {
    my $test_config = q{
        some  = 1
        data  = 0
        to    = 1
        make  = 0
        the   = 1
        file  = 0
        gods  = 1
        happy = ?
    };
    if (WebApp::Foo::Bar::Baz::write_config($Config_File, $test_config)) {
        plan 'no_plan';
    }
    else {
        plan 'skip_all' => "Cannot set timestamp on files created in current directory";
    }
    unlink $Config_File;
}


eval { require Config::General };

if ($Config::General::VERSION < 2.28) {
    $Included_File          = 't/testconf.conf';
    $Files_Method_Supported = 0;
}




{
    package WebApp::Foo::Bar::Baz;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Context;

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
            file              => $Config_File,
        );
        $self->conf('02')->init(
            file              => $Config_File,
        );

        ok($self->conf('01')->raw eq $self->conf('02')->raw, 'Caching ON: underlying config identical');
        my $config = $self->conf('01')->context;
        is($config->{'original'}, 1,        '01.original');
        is($config->{'modified'}, 0,        '01.modified');
        is($config->{'fruit'},    'banana', '01.fruit');
        is($config->{'truck'},    'red',    '01.truck');


        # Simple read with caching disabled
        $self->conf('03')->init(
            file               => $Config_File,
            cache_config_files => 0,
        );
        $self->conf('04')->init(
            file               => $Config_File,
            cache_config_files => 0,
        );

        ok($self->conf('03')->raw ne $self->conf('04')->raw, 'Caching OFF: underlying config differ');

        # Delete file in between first and second read (caching ON)
        $self->conf('05')->init(
            file              => $Config_File,
        );

        delete_config();

        # This is necessary to prevent Cwd::abs_path failing on some platforms
        # when the file does not exist
        # abs_path of the file is used as the key in the cache
        touch_config($Config_File);

        eval {
            $self->conf('06')->init(
                file              => $Config_File,
            );
        };
        ok(!$@, 'Delete, Caching ON, no error') or die "$@";
        ok($self->conf('05')->raw eq $self->conf('06')->raw, 'Delete, Caching ON:  underlying config identical');

        # Delete file in between first and second read (caching OFF)
        write_original_config();
        $self->conf('07')->init(
            file               => $Config_File,
            cache_config_files => 0,
        );

        delete_config();

        eval {
            $self->conf('08')->init(
                file               => $Config_File,
                cache_config_files => 0,
            );
        };
        ok($@, 'Delete, Caching OFF, error thrown');


        write_original_config();


        # Modify before statconfig runs out
        $self->conf('09')->init(
            file              => $Config_File,
        );

        write_modified_config();
        $self->conf('10')->init(
            file              => $Config_File,
        );

        ok($self->conf('09')->raw eq $self->conf('10')->raw, 'Modify before statconfig: Caching ON: underlying config identical');
        $config = $self->conf('09')->context;
        is($config->{'original'}, 1,        '09.original');
        is($config->{'modified'}, 0,        '09.modified');
        is($config->{'fruit'},    'banana', '09.fruit');
        is($config->{'truck'},    'red',    '09.truck');


        # Modify before statconfig runs out (short statconfig)
        write_original_config();
        $self->conf('11')->init(
            file              => $Config_File,
            stat_config       => 1,
        );

        write_modified_config();
        $self->conf('12')->init(
            file              => $Config_File,
            stat_config       => 1,
        );

        ok($self->conf('11')->raw eq $self->conf('12')->raw, 'Modify before (short) statconfig: Caching ON: underlying config identical');
        $config = $self->conf('11')->context;
        is($config->{'original'}, 1,        '11.original');
        is($config->{'modified'}, 0,        '11.modified');
        is($config->{'fruit'},    'banana', '11.fruit');
        is($config->{'truck'},    'red',    '11.truck');

        # Modify after statconfig runs out
        write_original_config();
        $self->conf('13')->init(
            file              => $Config_File,
            stat_config       => 1,
        );

        sleep 2;
        write_modified_config();

        $self->conf('14')->init(
            file              => $Config_File,
            stat_config       => 1,
        );

        ok($self->conf('13')->raw ne $self->conf('14')->raw, 'Modify after statconfig: Caching ON: underlying config differ');
        $config = $self->conf('13')->context;
        is($config->{'original'}, 1,        '13.original');
        is($config->{'modified'}, 0,        '13.modified');
        is($config->{'fruit'},    'banana', '13.fruit');
        is($config->{'truck'},    'red',    '13.truck');

        $config = $self->conf('14')->context;
        is($config->{'original'}, 0,        '14.original');
        is($config->{'modified'}, 1,        '14.modified');
        is($config->{'fruit'},    'plum',   '14.fruit');
        is($config->{'truck'},    'red',    '14.truck');

        sleep 2;

        # Modify after statconfig runs out (modified config is same size)
        write_original_config();
        $self->conf('15')->init(
            file              => $Config_File,
            stat_config       => 1,
        );

        sleep 2;
        write_modified_same_size_config();

        $self->conf('16')->init(
            file              => $Config_File,
            stat_config       => 1,
        );

        ok($self->conf('15')->raw ne $self->conf('16')->raw, 'Modify after statconfig: Caching ON, modified config same size: underlying config differ');
        $config = $self->conf('15')->context;
        is($config->{'original'}, 1,        '15.original');
        is($config->{'modified'}, 0,        '15.modified');
        is($config->{'fruit'},    'banana', '15.fruit');
        is($config->{'truck'},    'red',    '15.truck');

        $config = $self->conf('16')->context;
        is($config->{'original'}, 0,        '16.original');
        is($config->{'modified'}, 1,        '16.modified');
        is($config->{'fruit'},    'banana', '16.fruit');
        is($config->{'truck'},    'RED',    '16.truck');

        SKIP: {
            unless ($Files_Method_Supported) {
                skip "Installed version of Config::Context doesn't support 'files'", 11
            }

            write_original_config();
            write_containing_config();

            $self->conf('50')->init(
                file              => $Containing_Config_File,
                stat_config       => 1,
            );

            write_modified_config();
            sleep 2;

            $self->conf('51')->init(
                file              => $Containing_Config_File,
                stat_config       => 1,
            );

            ok($self->conf('50')->raw ne $self->conf('51')->raw, 'Include files - Modify after statconfig: Caching ON: objects differ');
            $config = $self->conf('50')->context;
            is($config->{'container'}, 1,        '50.container');
            is($config->{'original'},  1,        '50.original');
            is($config->{'modified'},  0,        '50.modified');
            is($config->{'fruit'},     'banana', '50.fruit');
            is($config->{'truck'},     'red',    '50.truck');

            $config = $self->conf('51')->context;
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

        write_config($filename, $config) or diag "failed to set timestamps on file: $Config_File\n";
    }
    sub write_containing_config {
        my $filename = $Containing_Config_File;
        my $config = qq{
            <<include $Included_File>>
            container = 1
        };

        write_config($filename, $config) or diag "failed to set timestamps on file: $Config_File\n";
    }

    sub write_modified_config {
        my $filename = $Config_File;
        my $config = q{
            original = 0
            modified = 1
            fruit    = plum
            truck    = red
        };
        write_config($filename, $config) or diag "failed to set timestamps on file: $Config_File\n";
    }

    sub write_modified_same_size_config {
        my $filename = $Config_File;
        my $config = q{
            original = 0
            modified = 1
            fruit    = banana
            truck    = RED
        };
        write_config($filename, $config) or diag "failed to set timestamps on file: $Config_File\n";
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
        print $fh $config or die "Can't write to temporary config file $filename: $!\n";
        close $fh;

        # Attempt to update the timestamp on the file to the current time
        my $time = time;
        utime $time, $time, $filename;

        my ($mtime) = (stat $filename)[9];

        my $diff = $mtime - $time;
        if ($diff) {
            my $abs_path               = Cwd::abs_path($filename);
            my $age_compared_to_script = -M $filename;
            diag "timestamps details: file: $abs_path; time: $time; mtime: $mtime: diff: $diff; -M: $age_compared_to_script\n";
        }
        return if $diff;
        return 1;

    }

    sub touch_config {
        my $filename = shift;
        open my $fh, '>', $filename or die "Can't clobber temporary config file $filename: $!\n";
        close $fh;
    }
}

my $webapp = WebApp::Foo::Bar::Baz->new;
$webapp->run;


