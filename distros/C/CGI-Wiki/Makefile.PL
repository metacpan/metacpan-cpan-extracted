use ExtUtils::MakeMaker;
use DBI;
use Data::Dumper;
use strict;

# Large chunks of this were inspired by the Makefile.PL supplied with
# DBIx::FullTextSearch -- thanks!

# See if we already have some config variables set.
use lib "lib";
eval "use CGI::Wiki::TestConfig";

# Even if we do have a previous configuration saved, we can over-ride and
# be asked all the questions again by specifying the -s flag or setting
# the appropriate environment variable.
if ($CGI::Wiki::TestConfig::configured
    and not (@ARGV and $ARGV[0] eq '-s')
    and not $ENV{CGI_WIKI_RERUN_CONFIG}
   ) {
    print "\nFor the test suite, we use the database and user info\n"
        . "specified during the previous run.  If you want to change\n"
        . "some or all of the values, run 'perl Makefile.PL -s'.\n\n"
        . "**** REMEMBER THAT THESE TESTS ARE DESTRUCTIVE.  ****\n"
        . "**** DO NOT RUN THEM ON A DATABASE THAT CONTAINS ****\n"
        . "****       OR EVER WILL CONTAIN LIVE DATA.       ****\n"
        . "****                                             ****\n"
        . "**** THE DATABASE VALUES YOU GAVE PREVIOUSLY ARE ****\n"
        . "**** STORED IN CGI::Wiki::TestConfig AND WILL BE ****\n"
        . "****    USED FOR FUTURE INSTALLS OF THIS AND     ****\n"
        . "****             RELATED MODULES.                ****\n\n";
} else {
    print "\nYou should supply at least one set of options for testing,\n"
        . "preferably relevant to the backend(s) you intend to use live.\n"
        . "Running the tests under every possible backend combination is\n"
	. "recommended.  To enter an undefined value, accept the empty\n"
        . "string or explicitly enter 'undef'.\n\n"
        . "****        THESE TESTS ARE DESTRUCTIVE.         ****\n"
        . "**** DO NOT RUN THEM ON A DATABASE THAT CONTAINS ****\n"
        . "****       OR EVER WILL CONTAIN LIVE DATA.       ****\n"
        . "****                                             ****\n"
        . "****  THE DATABASE VALUES YOU GIVE HERE WILL BE  ****\n"
        . "**** STORED IN CGI::Wiki::TestConfig AND WILL BE ****\n"
        . "****    USED FOR FUTURE INSTALLS OF THIS AND     ****\n"
        . "****             RELATED MODULES.                ****\n\n";

    my %config;

    # Grab information from previous runs.
    if ($CGI::Wiki::TestConfig::configured) {
        %config = %CGI::Wiki::TestConfig::config;
    }

    # Grab information from environment variables.
    foreach my $store (qw(MySQL Pg)) {
        my $dbname = $ENV{"CGI_WIKI_".uc($store)."_DBNAME"};
	if ($dbname and $dbname ne "undef") {
	    $config{$store}{dbname} = $dbname;
            foreach my $var (qw(dbuser dbpass dbhost)) {
                my $value = $ENV{"CGI_WIKI_".uc($store)."_".uc($var)};
		if ($value and $value ne "undef") {  	            $config{$store}{$var} = $value;
		} elsif ($value eq "undef") {
		    $config{$store}{$var} = undef;
		}
	    }
	} elsif ($dbname eq "undef") {
	    $config{$store}{dbname} = undef;
	}
    }

    my $dbixfts = $ENV{CGI_WIKI_DBIXFTS_MYSQL};
    if ($dbixfts and $dbixfts ne "undef") {
        $config{dbixfts} = 1;
    } elsif ($dbixfts eq "undef") {
        $config{dbixfts} = 0;
    }

    # Finally ask questions; then check the settings work.
    my %dsn_prefix = ( MySQL => "dbi:mysql:",
		       Pg    => "dbi:Pg:dbname=" );
    my %driver = ( MySQL => "DBD::mysql",
	           Pg    => "DBD::Pg" );
    foreach my $store_type (qw(MySQL Pg)) {
        # See whether we have the driver installed.
        eval "require " . $driver{$store_type};
        if ($@) {
            print "\n$driver{$store_type} not installed... skipping...\n";
	    $config{$store_type}{dbname} = undef;
	    next;
	}

        # Prompt for the options.
        my ($dbname, $dbuser, $dbpass, $dbhost);
        my $pad = ' ' x (7-length $store_type);
        $dbname = prompt "\n${pad}Database name for $store_type: ",
	                 $config{$store_type}{dbname};
        undef $dbname unless ($dbname and $dbname ne "undef");
        if ($dbname and $dbname ne "undef") {
	    $dbuser = prompt "            Database user: ",
	                     $config{$store_type}{dbuser};
            undef $dbuser unless ($dbuser and $dbuser ne "undef");
	    $dbpass = prompt "        Database password: ",
	                     $config{$store_type}{dbpass};
            undef $dbpass unless ($dbpass and $dbpass ne "undef");
	    $dbhost = prompt "Database host (if needed): ",
	                     $config{$store_type}{dbhost};
            undef $dbhost unless ($dbhost and $dbhost ne "undef");

            # Check that these connection parameters actually work.
            my $dsn = $dsn_prefix{$store_type}.$dbname;
            $dsn .= ";host=$dbhost" if $dbhost;
            my $dbh = eval { DBI->connect($dsn,
 				          $dbuser, $dbpass, {PrintError => 1})
			         or die DBI->errstr;
			   };
            die "\nCan't connect to $store_type with those parameters:"
		     . "\n" . $@ . "\n\n"
		     . "Please re-run 'perl Makefile.PL' and supply correct "
		     . "parameters.\n\n" if $@;
            $dbh->disconnect;

            # Save them if they do.
            $config{$store_type}{dbname} = $dbname;
            $config{$store_type}{dbuser} = $dbuser;
            $config{$store_type}{dbpass} = $dbpass;
            $config{$store_type}{dbhost} = $dbhost;
	} else {
            print "\nNo database name supplied... skipping...\n";
	    $config{$store_type}{dbname} = undef;
	}
    }

    print "\n";

    # Copy the config hash to the right namespace.
    %CGI::Wiki::TestConfig::config = %config;
}

# If we have a MySQL store configured, we can test the DBIx::FullTextSearch
# search backend.
eval { require DBIx::FullTextSearch;
       require Lingua::Stem;
};
my $fts_inst = $@ ? 0 : 1;
if ($CGI::Wiki::TestConfig::config{MySQL}{dbname} and $fts_inst) {
    print "You have DBIx::FullTextSearch and Lingua::Stem installed,\n";
    print " and a MySQL store configured... configuring for test...\n\n";
    $CGI::Wiki::TestConfig::config{dbixfts} = 1;
} else {
    print "Either DBIx::FullTextSearch or Lingua::Stem not installed,\n";
    print "or no MySQL store configured... so won't test that...\n\n";
    $CGI::Wiki::TestConfig::config{dbixfts} = undef;
}

# We can test the SQLite backend without asking questions, if it's installed.
eval { require DBD::SQLite; };
if ($@) {
    print "DBD::SQLite not installed... so won't test that...\n\n";
    $CGI::Wiki::TestConfig::config{SQLite} = { dbname => undef };
} else {
    print "You have DBD::SQLite... configuring test SQLite database...\n\n";
    $CGI::Wiki::TestConfig::config{SQLite} = { dbname => "t/sqlite-test.db" };
}

# If we have Search::InvertedIndex installed, we can test that without
# asking questions.
eval { require Search::InvertedIndex; };
my $sii_inst = $@ ? 0 : 1;
if ( $sii_inst ) {
    print "You have Search::InvertedIndex installed, so will test the S:II\n";
    print "search backend...\n\n";
    $CGI::Wiki::TestConfig::config{search_invertedindex} = 1;
} else {
    print "You do not have Search::InvertedIndex installed; skipping test\n";
    print "of S:II search backend...\n\n";
    $CGI::Wiki::TestConfig::config{search_invertedindex} = undef;
}

# If we have Plucene installed, we can test that without asking questions.
eval { require Plucene; require File::Spec::Functions };
my $plucene_inst = $@ ? 0 : 1;
if ( $plucene_inst ) {
    print "You have Plucene installed, so will test with that...\n\n";
    $CGI::Wiki::TestConfig::config{plucene} = 1;
} else {
    print "Either Plucene or File::Spec::Functions not installed; skipping test...\n\n";
    $CGI::Wiki::TestConfig::config{plucene} = undef;
}

# Write out the config for next run.
open OUT, ">lib/CGI/Wiki/TestConfig.pm"
  or die "Couldn't open lib/CGI/Wiki/TestConfig.pm for writing: $!";
# warning - blind copy and paste follows.  FIXME.
print OUT Data::Dumper->new([ \%CGI::Wiki::TestConfig::config ],
			    [ '*CGI::Wiki::TestConfig::config' ]
			   )->Dump,
  "\$CGI::Wiki::TestConfig::configured = 1;\n1;\n";
close OUT;

# Some modules are only prerequisites if we intend to test a
# particular backend.
my %config = %CGI::Wiki::TestConfig::config;
my %extras;
if ( $config{MySQL}{dbname} ) {
    $extras{'DBD::mysql'} = 0;
}
if ( $config{Pg}{dbname} ) {
    $extras{'DBD::Pg'} = 0;
}
if ( $config{SQLite}{dbname} ) {
    $extras{'DBD::SQLite'} = '0.25'; # some of my tests fail on earlier ones
}
if ( $config{dbixfts} ) {
    $extras{'DBIx::FullTextSearch'} = '0.71'; # earlier ones buggy
}
if ( $config{plucene} ) {
    $extras{'Plucene'} = '1.19'; # earlier has trouble with delete
}

# Write the Makefile.
WriteMakefile( NAME         => "CGI::Wiki",
	       VERSION_FROM => "lib/CGI/Wiki.pm",
	       PREREQ_PM    => { 'Text::WikiFormat' => '0.45', #earlier's buggy
				 'HTML::PullParser' => 0,
				 'Digest::MD5' => 0,
			         'Test::More' => 0,
			         'Time::Piece' => 0,
			         %extras },
               EXE_FILES => [ "bin/cgi-wiki-setupdb" ],
	       clean => { FILES => "Config lib/CGI/Wiki/TestConfig.pm "
			         . "t/sqlite-test.db t/sii-db-file-test.db "
                                 . "t/node.db t/plucene"
                        }
	     );
