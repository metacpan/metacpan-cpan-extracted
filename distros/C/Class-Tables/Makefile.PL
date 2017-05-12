use strict;
use ExtUtils::MakeMaker;
use DBI;
use Data::Dumper;

unless (grep { /^(mysql|SQLite|Pg)$/ } DBI->available_drivers) {
    die "Class::Tables requires DBD::mysql, DBD::SQLite, or DBD::Pg at this time";
}

use lib 'testconfig';
my $Config;
eval q[
    use Class::Tables::TestConfig;
    $Config = Class::Tables::TestConfig->Config;
];

if (defined $Config->{dsn} and not $ARGV[0] =~ /^-s(etup)?$/) {

    print qq[
        For the test suite, we use the database connection info specified
        during the previous run. If you want to change the values, run
        perl Makefile.PL -s.
    \n];

} else {

    print qq[
        I need to connect to a database to run the test suite. Please
        supply the connection information for a MySQL or SQLite database
        that I can use for testing.

        WARNING: All existing tables in this database will be deleted!
        
        Enter "NONE" (without the quotes) to indicate an empty string
        for a config value.

        Enter "SKIP" (without the quotes) to skip the test suite
        completely during the build/install process.
    \n];

    $Config->{dsn} = 'dbi:mysql:test'
        unless defined $Config->{dsn};

    for (qw/dsn user password/) {
        $Config->{$_} = prompt "The $_ for tests:", $Config->{$_};
        $Config->{$_} = "" if $Config->{$_} eq "NONE";

        if ($Config->{dsn} =~ /^skip$/i) {
            print "\nOK - The test suite will be SKIPPED!\n";
	    last;
        }
    }
}


print qq[        
        Current values:
            dsn      = '$Config->{dsn}'
            user     = '$Config->{user}'
            password = '$Config->{password}'
\n] unless $Config->{dsn} =~ /^skip$/i;


use File::Path;
mkpath "testconfig/Class/Tables", 0, 0700;

open OUT, '>testconfig/Class/Tables/TestConfig.pm'
    or die "Error writing the TestConfig\n";

print OUT
    "package Class::Tables::TestConfig;\n",
    "sub Config {\n",
        Dumper($Config),
    "};\n1;\n";

close OUT;

WriteMakefile(
    NAME          => 'Class::Tables',
    VERSION_FROM  => 'lib/Class/Tables.pm',
    PREREQ_PM     => { DBI => 0,
                       Carp => 0,
                       overload => 0,
                       Storable => 0,
                       "Lingua::EN::Inflect" => 0 },
    clean         => { FILES => "testconfig" },
    ABSTRACT_FROM => 'lib/Class/Tables.pm',
    AUTHOR        => 'Mike Rosulek <mike@mikero.com>',
);
