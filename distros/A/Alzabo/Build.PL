use strict;

use 5.005;

use Data::Dumper;
use File::Spec;

use lib 'inc';

use Alzabo::Build;

use Getopt::Long qw( :config pass_through );

my %opts;
GetOptions( 'dist'   => \$opts{dist},
            'root:s' => \$opts{root},
            'pg!'    => \$opts{pg},
            'mysql!' => \$opts{mysql},
            'automated' => \$opts{automated},
            'help'   => \$opts{help},
          );

if ( $opts{help} )
{
    print <<'EOF';

  perl Build.PL [--automated] [--pg] [--mysql]

This script accepts several options:

  --automated         Run without prompts

  --pg                Include prereqs for PostgreSQL support

  --mysql             Include prereqs for MySQL support

  --root              Root dir for storing Alzabos schemas

  --help              What you are reading

EOF

    exit;
}

{
    my ( $config, $prereqs, $tests );
    unless ( $opts{dist} )
    {
        ( $config, $prereqs, $tests ) = config();
        write_config_module($config);
    }
    else
    {
        $prereqs = dist_prereqs();
        $config = {};
    }

    my $build =
        Alzabo::Build->new( module_name => 'Alzabo',
                            license => 'perl',
                            %$prereqs,
                            sign => 1,
                          );

    $build->create_build_script;

    $build->notes( test_config => $tests );

    $build->add_to_cleanup( File::Spec->catdir( 't', 'schemas' ),
                            File::Spec->catfile( 'lib', 'Alzabo', 'Config.pm' ),
                          );
}

sub config
{
    # try to see if there is an existing Alzabo installation
    eval { require Alzabo; };
    eval { require Alzabo::Config; };

    if ( ! $@ &&
         %Alzabo::Config::CONFIG &&
         defined Alzabo::Config::root_dir() &&
         length Alzabo::Config::root_dir() &&
         -d Alzabo::Config::root_dir() &&
         Alzabo::Config::available_schemas() && $Alzabo::VERSION < 0.55 )
    {
        print <<'EOF';

You appear to have schemas created with an older version of Alzabo.
If you want to continue to use these, you may need to run the
convert.pl script in the eg/ directory _before_ installing this
version of Alzabo.

For newer versions, starting with the transition from 0.64 to 0.65,
Alzabo automatically converts schemas as needed.

EOF

        exit unless Module::Build->y_n( '  Continue?', 'no' );
    }

    my %config;

    $config{root_dir} = root_dir();

    my ( $prereqs, $tests ) = features();

    my $test_config = test_config($tests);

    return \%config, $prereqs, $test_config;
}

sub root_dir
{
    my $root_dir =
        ( $opts{root}
          ? $opts{root}
          : %Alzabo::Config::CONFIG
          ? Alzabo::Config::root_dir()
          : find_possible_root()
        );

    return $root_dir if $opts{automated};

    print <<'EOF';

Please select a root directory for Alzabo (schema files will be stored
under this root.
EOF

    return Module::Build->prompt( '  Alzabo root?', $root_dir );
}

sub find_possible_root
{
    my @dirs;

    if ( $^O =~ /win/i )
    {
	# A bit too thorough?
	foreach ('C'..'Z')
	{
	    unshift @dirs, "$_:\\Program Files";
	}
    }
    else
    {
	@dirs = qw( /var/lib /usr/local );
    }

    unshift @dirs, '/opt' if $^O =~ /solaris/i;

    foreach (@dirs)
    {
	$_ .= '/alzabo';

	return $_ if -e $_;
    }

    return '';
}

sub features
{
    # These are always needed
    my %prereqs = default_prereqs();

    my ( %tests );

    # extra prereqs for certain features
    my %features =
        ( mysql => { phrase   => 'to use the MySQL driver',
                     requires => { 'DBD::mysql' => 2.1017 },
                     test     => 'mysql',
                   },

          pg    => { phrase     => 'to use the PostgreSQL driver',
                     requires   => { 'DBD::Pg' => 1.13,
                                     'Text::Balanced' => 0,
                                     'Digest::MD5' => 0,
                                   },
                     test   => 'pg',
                   },
        );

    if ( $opts{automated} )
    {
        for my $k ( grep { $opts{$_} } keys %features )
        {
            _add_to_prereqs( \%prereqs, $features{$k} );
            $tests{$k} = 1;
        }

        return \%prereqs, \%tests;
    }

    print <<'EOF';

The following questions pertain to optional features of Alzabo.  These
questions help the installer determine what additional system checks
to perform.

EOF

    foreach my $feature ( map { $features{$_} } sort keys %features )
    {
	print "\n";

	my $has = 1;
        my $mods = '';
        foreach my $type ( qw( requires recommends ) )
        {
            if ( $feature->{$type} )
            {
                my $text = "$type";
                while ( my ( $mod, $ver ) = each %{ $feature->{$type} } )
                {
                    $text .= " $mod";
                    $text .= " ($ver)" if $ver;

                    $has = 0
                        unless Module::Build->check_installed_version( $mod, $ver );
                }

                $mods .= ' and ' if $mods;
                $mods .= $text;
            }
        }

	print "\u$feature->{phrase} $mods.\n";

	my $wanted =
            Module::Build->y_n( "  Do you want $feature->{phrase}?", $has ? 'yes' : 'no' );

	if ($wanted)
	{
            _add_to_prereqs( \%prereqs, $feature );

	    $tests{ $feature->{test} } = 1 if exists $feature->{test};
	}
    }

    return \%prereqs, \%tests;
}

sub _add_to_prereqs
{
    my $prereqs = shift;
    my $feature = shift;

    foreach my $type ( grep { $feature->{$_} } qw( requires recommends ) )
    {
        $prereqs->{$type} = { %{ $prereqs->{$type} },
                              %{ $feature->{$type} },
                            };
    }
}

sub default_prereqs
{
    return
        ( requires =>
          { 'Class::Factory::Util' => 1.3,
            'DBI' => minimum_dbi_version(),
            'Digest::MD5' => 0,
            'Exception::Class' => 0.97,
            'Params::Validate' => 0.58,
            'Scalar::Util' => 1.01,
            'Storable' => 0.7,
            'Test::Simple' => 0.47,
            'Test::Harness' => 1.26,
            'Tie::IxHash' => 0,
            'Time::HiRes' => 0,
            perl => 5.006,
          },
          recommends => {},
          build_requires => { 'Pod::Man' => 1.14 },
        );
}

sub dist_prereqs
{
    my %prereqs = default_prereqs();

    $prereqs{requires}{DBI} = 1.21;

    $prereqs{recommends}{'DBD::mysql'} = 2.1017;
    $prereqs{recommends}{'DBD::Pg'} = 1.13;

    return \%prereqs;
}

sub minimum_dbi_version
{
    if ( eval { require DBI } && $DBI::VERSION == 1.24 )
    {
        warn <<'EOF';
You appear to have DBI version 1.24 installed.  This version has a bug
which causes major problems with Alzabo.  Please upgrade or downgrade.
EOF
        return 1.25;
    }

    return 1.21;
}

sub write_config_module
{
    my $config = shift;

    # config items that the config module cares about
    my @keys = qw( root_dir );

    my $file = File::Spec->catfile( 'inc', 'Alzabo', 'Config.pm.tmpl' );
    local *MOD;
    open MOD, "<$file"
	or die "can't open $file: $!\n";
    my $mod = join '', <MOD>;
    close MOD
	or die "can't close $file: $!\n";

    my $c = "(\n";
    foreach my $k (@keys)
    {
	my $val;
	if ( length $config->{$k} )
	{
	    $val = "'$config->{$k}'";
	}
	else
	{
	    $val = "undef";
	}

	$c .= "'$k' => $val,\n";
    }
    $c .= ")";

    $mod =~ s/"'CONFIG'"/$c/;

    my $config_pm = File::Spec->catfile( 'lib', 'Alzabo', 'Config.pm' );
    open MOD, '>', $config_pm
	or die "can't write to $config_pm: $!\n";
    print MOD $mod
	or die "can't write to $config_pm: $!\n";
    close MOD
	or die "can't close $config_pm: $!\n";
}

sub test_config
{
    my $tests = shift;

    return if $opts{automated};

    my @config;

    my %names = ( mysql => 'Mysql',
		  pg => 'Postgres',
		  oracle => 'Oracle' );

    foreach my $t ( sort keys %$tests )
    {
	my $name = $names{$t};

	print <<'EOF';

The information from the following questions are used solely for
testing the pieces of Alzabo that require a real database for proper
testing.
EOF

	my $do = Module::Build->prompt( "  Do tests with $name RDBMS?", 'yes' );
	next unless $do =~ /^y/i;

	print <<"EOF";

Please provide a username that can be used to connect to the $name
RDBMS?  This user must have the ability to create a new
database/schema.
EOF

	my $user = Module::Build->prompt( '  Username?' );
	my $password;
	if ($user)
	{
	    $password = Module::Build->prompt( "  Password for $user?" );
	}

	print <<"EOF";

What host is the $name RDBMS located on.  Press enter to skip this if
the database server is located on the localhost or can be determined
in another way (for example, Oracle can use TNS to find the database).
EOF

	my $host = Module::Build->prompt( '  Host?' );

	print <<"EOF";

What port is the $name RDBMS located on.  Press enter to skip this.
EOF

	my $port = Module::Build->prompt( '  Port?' );

	print <<'EOF';

Please provide a database name that can be used for testing.  A
database/schema with this name will be created and dropped during the
testing process.
EOF

	my $db_name = Module::Build->prompt( '  Database name?', "test_alzabo_$t" );

        push @config,
        { rdbms    => $t,
          user     => $user,
          password => $password,
          host     => $host,
          port     => $port,
          schema_name => $db_name,
        };
    }

    return \@config;
}
