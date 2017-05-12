#!/usr/bin/perl -w

# This is a Module::Build script for BioPerl-DB installation.
# See http://search.cpan.org/~kwilliams/Module-Build/lib/Module/Build.pm

use strict;
use warnings;
use Module::Build;
use File::Spec;
use File::Basename;

# add any supported drivers here
my @supported = qw(mysql Pg Oracle);

my $build = Module::Build->new(
    module_name         => 'Bio::DB::BioDB',
    dist_name           => 'BioPerl-DB',
    dist_version        => '1.006900',
    dist_author         => 'BioPerl Team <bioperl-l@bioperl.org>',
    dist_abstract       => 'BioPerl-DB - package for biological databases',
    license             => 'perl',
    requires            => {
                        'perl'               => '5.6.1',
                        'Bio::Root::Version' => '1.006900',
                        'DBI'                => 0
        },
    recommends          => {
                        'Graph::Directed'   => 0
        },
    auto_features => {
        Pg_support          => {
                          description => "Postgres databases",
                          requires    => { 'DBD::Pg' => 0},
                         },
        mysql_support       => {
                          description => "MySQL databases",
                          requires    => { 'DBD::mysql' => 0},
                         },
        Oracle_support      => {
                          description => "Oracle databases",
                          requires    => { 'DBD::Oracle' => 0},
                         },
    },
    dynamic_config      => 1,
    create_makefile_pl  => 'passthrough'
);

my $accept = $build->args->{accept};

# Ask questions for db configuration (Harness file)
biosql_conf();

# Optionally have script files installed.
if ($accept ? 0 : $build->y_n("Install scripts? y/n", 'n')) {
    my $files = $build->_find_file_by_type('pl', 'scripts');
    
    my $script_build = File::Spec->catdir($build->blib, 'script');
    
    my @tobp;
    while (my ($file, $dest) = each %$files) {
        $dest = 'bp_'.File::Basename::basename($dest);
        $dest = File::Spec->catfile($script_build, $dest);
        $build->copy_if_modified(from => $file, to => $dest);
        push @tobp, $dest;
    }
    
    $build->script_files(\@tobp);
}

# Create the build script and exit
$build->create_build_script;

exit;

# setup t/DBHarness.biosql.conf
sub biosql_conf {
    my $continue = $accept ||
        $build->y_n("Have you already installed BioSQL? y/n", 'y');
    $continue ||
        die "\nBioSQL must be installed prior to installation of bioperl-db; ".
        "see the INSTALL file\n";
    
    my @drivers = grep {$build->features($_.'_support')}
         qw(mysql Pg Oracle);
    
    die "You must install a supported database driver\n" unless @drivers;
    
    my $config_file = File::Spec->catfile('t', 'DBHarness.biosql.conf');
    if (-e $config_file) {
        ($accept || $build->y_n(
            "Do you want to use the existing '$config_file' config file? y/n",
            'y')) && return;
        unlink($config_file);
    }
    
    open(my $out, ">", $config_file)
        or die "Error: could not write to config file '$config_file'\n";
    
    my %config = (driver     => $drivers[0],
                  host       => '127.0.0.1',
                  user       => 'root',
                  port       => 3306,
                  password   => '',
                  dbname     => 'bioseqdb',
                  database   => 'biosql',
                  schema_sql => '../biosql-schema/sql/biosqldb-mysql.sql');
    
    $config{driver} = $build->prompt("DBD driver to use (mandatory)?",
                                     $config{driver});
    $config{host} = $build->prompt("Machine to connect to (mandatory)?",
                                   $config{host});
    $config{user} = $build->prompt("User to connect to server as (mandatory)?",
                                   $config{user});
    
    $config{port} = $build->prompt("Port the server is running on (optional, ".
                                   "'' for undef/none)?", $config{port});
    $config{port} = undef if $config{port} eq "''";
    
    $config{password} = $build->prompt("Password (optional)?",
                                       $config{password} || 'undef');
    $config{password} = '' if $config{password} eq 'undef';
    
    $build->log_info(<<COMMENT);
# The next answer will be used to identify the database name in
# the connect string, e.g., using database=, dbname=, or sid=,
# depending on the driver.
#
# If this is not set the test scripts will build a temporary
# database from scratch at the beginning and destroy it at the
# end. Conversely, if you do set it then the database must exist,
# or else the tests will fail.
#
# Generally, it is preferred to pre-build the database, simply for
# efficiency reasons, and it will also enable debugging your
# schema content if some test acts up.\n
COMMENT
    $config{dbname} = $build->prompt("Name of your existing Biosql database, ".
                                     "as it is known to your RDBMS ".
                                     "(optional, '' for none)?",
                                     $config{dbname});
    $config{dbname} = '' if $config{dbname} eq "''";
    
    unless ($config{dbname}) {
        $config{schema_sql} = $build->prompt("Set schema_sql to use the ".
                                             "version appropriate for your ".
                                             "RDBMS (mandatory)",
                                             $config{schema_sql});
    }
    # don't know why it is stored as an array ref, is this correct?
    $config{schema_sql} = "['$config{schema_sql}']"; 
    
    $build->log_info(<<COMMENT);
# The next answer does not refer to the schema or RDBMS; it only
# identifies which of the databases supported in bioperl-db you
# want to be using. Since at present bioperl-db only supports biosql,
# this must be biosql.
COMMENT
    $config{database} = $build->prompt("The name of the database within ".
                                       "bioperl-db?", $config{database});
    
    print $out "{\n"; 
    while (my ($key, $val) = each %config) {
        # no empty strings, undefined conf setting should be undef (w/o quotes)
        $val = "'$val'" unless $key eq 'schema_sql' || !defined($val);
        if (!defined($val)) {
            $val = 'undef';
        }
        print $out "\t'$key' => $val,\n";
    }
    print $out "}\n";
    close($out);
    
    # maybe add the capability of using a temporary (test) database, and
    # load the SQL on the fly?  A little trickier (SQL is in a different
    # repo and is driver-dependent)

    # probably should add a database ping here and die gracefully otherwise.
        
    # we deliberately don't add the config file to cleanup, but it shouldn't
    # cause problems because it is in MANIFEST.SKIP
}

