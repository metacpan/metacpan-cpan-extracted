
use strict;
use warnings;
use Config::Context;
use Cwd;
use Test::More 'tests' => 39;
my $Per_Driver_Tests = 13;
my $PerlIO_Available;

my $Config_File            = 't/testconf.conf';
my $Containing_Config_File = 't/testconf-container.conf';
my $Included_File          = 'testconf.conf';

sub write_config {
    my $filename = shift;
    my $config   = shift;
    open my $fh, '>', $filename or die "Can't clobber temporary config file $filename: $!\n";
    print $fh $config or die "Can't write to temporary config file $filename: $!\n";
    close $fh;
}

# Version 2.27 and earlier of Config::General
# specified included files relative to the current directory,
# not to the included file.

eval { require Config::General; };

my $Files_Method_Supported = 1;
my $CG_Included_File;

if (($Config::General::VERSION || 0) >= 2.28) {
    $CG_Included_File = $Included_File;
}
else {
    $Files_Method_Supported = 0;
    $CG_Included_File = $Config_File;
}

my (%Inner_Conf, %Containing_Conf);

$Inner_Conf{'ConfigGeneral'} = <<EOF;
        <section quux>
           quux = inner
           <nested worble>
               worble       = inner
               inner_worble = true
           </nested>
        </section>
        <section bar>
           bar = inner
           inner_bar = true
           <nested bam>
               inner_bam = true
           </nested>
        </section>
EOF

$Containing_Conf{'ConfigGeneral'} = <<EOF;
        <section foo>
           foo = outer
           <nested boom>
               boom       = outer
               outer_boom = true
           </nested>
        </section>
        <section bar>
           bar = outer
           outer_bar = true
           <nested bam>
               bam = outer
               outer_bam = true
           </nested>
        </section>
        <<include $CG_Included_File>>

EOF

$Inner_Conf{'ConfigScoped'} = <<EOF;
   section quux {
        quux = inner
        nested = {
            worble = {
                 worble       = inner
                 inner_worble = true
            }
        }
   }
   section bar {
       bar = inner
       inner_bar = true
       nested = {
           bam = {
               inner_bam = true
           }
       }
   }
EOF


$Containing_Conf{'ConfigScoped'} = <<EOF;
   section foo {
       foo = outer
       nested = {
           boom = {
               boom       = outer
               outer_boom = true
           }
       }
   }
   section bar {
       bar = outer
       outer_bar = true
       nested = {
           bam = {
               bam       = outer
               outer_bam = true
           }
       }
   }
   %include $Included_File

EOF


$Inner_Conf{'XMLSimple'} = <<EOF;
<opt>
        <section name="quux">
           <quux>inner</quux>
           <nested name="worble">
               <worble>inner</worble>
               <inner_worble>true</inner_worble>
           </nested>
        </section>
        <section name="bar">
           <bar>inner</bar>
           <inner_bar>true</inner_bar>
           <nested name="bam">
               <inner_bam>true</inner_bam>
           </nested>
        </section>
        </opt>
EOF
$Containing_Conf{'XMLSimple'} = <<EOF;
<opt>
       <xi:include href="$Included_File" xmlns:xi="http://www.w3.org/2001/XInclude" />
        <section name="foo">
           <foo>outer</foo>
           <nested name="boom">
               <boom>outer</boom>
               <outer_boom>true</outer_boom>
           </nested>
        </section>
        <section name="bar">
           <bar>outer</bar>
           <outer_bar>true</outer_bar>
           <nested name="bam">
               <bam>outer</bam>
               <outer_bam>true</outer_bam>
           </nested>
        </section>
       </opt>

EOF





sub runtests {
    my $driver = shift;

    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    my @config_modules = $driver_module->config_modules;
    eval "require $_;" for @config_modules;

    if ($@) {
        skip "prereqs of $driver (".(join ', ', @config_modules).") not installed", 36;
    }

    write_config($Containing_Config_File, $Containing_Conf{$driver});
    write_config($Config_File,            $Inner_Conf{$driver});

    Config::Context->clear_file_cache();

    my $conf = Config::Context->new(
        driver             => $driver,
        file               => $Containing_Config_File,
        match_sections     => [
            {
                name         => 'section',
            },
            {
                name         => 'nested',
            },

        ],
        driver_options => {
            ConfigScoped => {
                warnings => {
                    permissions => 'off',
                },
            },
        },
    );

    my %config = $conf->raw;

    is($config{'section'}{'quux'}{'quux'},                             'inner',  "$driver: quux/quux");
    is($config{'section'}{'quux'}{'nested'}{'worble'}{'worble'},       'inner',  "$driver: quux/nested/worble/worble");



    is($config{'section'}{'foo'}{'foo'},                               'outer',  "$driver: foo/foo");
    is($config{'section'}{'foo'}{'nested'}{'boom'}{'boom'},            'outer',  "$driver: foo/nested/boom/boom");
    is($config{'section'}{'foo'}{'nested'}{'boom'}{'outer_boom'},      'true',   "$driver: foo/nested/boom/outer_boom");


    is($config{'section'}{'bar'}{'bar'},                               'inner',  "$driver: bar/bar");


    is($config{'section'}{'bar'}{'nested'}{'bam'}{'inner_bam'},        'true',   "$driver: bar/nested/bam/inner_bam");
    is($config{'section'}{'quux'}{'nested'}{'worble'}{'inner_worble'}, 'true',   "$driver: quux/quux/worble/inner_worble");
    is($config{'section'}{'bar'}{'inner_bar'},                         'true',   "$driver: bar/inner_bar");

    my @files = sort @{ $conf->files };

    my @expected_files = sort(
        Cwd::abs_path($Containing_Config_File),
        Cwd::abs_path($Config_File),
    );

    SKIP: {
        if ($driver eq 'ConfigGeneral' and !$Files_Method_Supported) {
            skip "Installed version of Config::General doesn't support 'files'", 1;
        }

        # use lower-case comparisons to be compatible with case-insensitive filesystems
        my @lc_files          = map { lc } @files;
        my @lc_expected_files = map { lc } @expected_files;

        ok(eq_array(\@lc_files, \@lc_expected_files), 'files')
           or diag( "got files: \n" . (join "\t\n", @lc_files)
                  . "\n"
                  . "expected: \n" . (join "\t\n", @lc_expected_files)
                  . "\n"
              );
    }
    SKIP: {
        if ($driver eq 'ConfigScoped') {
            skip "hashes do not merge with ConfigScoped", 3;
        }
        else {
            is($config{'section'}{'bar'}{'outer_bar'},                         'true',   "$driver: bar/outer_bar");
            is($config{'section'}{'bar'}{'nested'}{'bam'}{'bam'},              'outer',  "$driver: bar/nested/bam/bam");
            is($config{'section'}{'bar'}{'nested'}{'bam'}{'outer_bam'},        'true',   "$driver: bar/nested/bam/outer_bam");
        }
    }

}

SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        runtests('ConfigGeneral');
    }
    else {
        skip "Config::General not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        runtests('ConfigScoped');
    }
    else {
        skip "Config::Scoped not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        runtests('XMLSimple');
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", $Per_Driver_Tests;
    }
}

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}



unlink $Containing_Config_File;
unlink $Config_File;


