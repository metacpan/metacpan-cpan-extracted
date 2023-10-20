use ExtUtils::MakeMaker;
use strict;
use warnings;

sub MY::distsignature
{
    return << 'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

my %WriteMakefileArgs = (
    NAME                => 'Apache2::SSI',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Apache2/SSI.pm',
    ABSTRACT_FROM       => 'lib/Apache2/SSI.pm',
    PL_FILES            => {},
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'strict'        => 0,
        'warnings'      => 0,
        'parent'        => 0,
        'vars'          => 0,
        'version'       => 0,
        'Config'        => 0,
        'Cwd'           => 0,
        # Not required to function
        # 'Apache2::Const'=> '2.000011',
        # 'Apache2::RequestRec' => '2.000011',
        'DateTime'      => 0,
        'DateTime::Format::Strptime' => 0,
        'Digest::MD5'   => 0,
        'Digest::SHA'   => 0,
        'Encode'        => 0,
        'File::Basename'=> 0,
        'File::Spec'    => '3.26',
        'File::Which'   => 0,
        'HTML::Entities'=> 0,
        'IO::File'      => 0,
        'JSON'          => 0,
        'MIME::Base64'  => 0,
        'Module::Generic' => 'v0.28.3',
        'Net::Subnet'   => '1.03',
        'Nice::Try'     => 'v1.3.1',
        'PPI'           => '1.270',
        'Regexp::Common::Apache2' => 'v0.2.1',
        'Regexp::Common::net' => 0,
        # 'POSIX'         => '1.53_01',
        'Scalar::Util'  => '1.50',
        'URI'           => '5.05',
        'URI::file'     => '5.05',
        'URI::Escape::XS' => 0,
        'URL::Encode::XS' => 0,
    },
    TEST_REQUIRES =>
    {
        'Cwd'           => 0,
        'lib'           => 0,
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
        'utf8'          => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.22.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Apache2-SSI-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Apache2-SSI.git',
                web         => 'https://gitlab.com/jackdeguest/Apache2-SSI',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Apache2-SSI/issues',
            },
        },
    }) : ()),
);

# eval( "use Apache::TestMM" );
eval
{
    require Apache::TestMM;
};

my @scripts = ();

if( !$@ )
{
    my $MY_DEBUG = $ENV{APACHE2_SSI_DEBUG};
    $ENV{HAS_APACHE_TEST} = 1;
    Apache::TestMM->import( qw(test clean) ); #enable 'make test'
    $WriteMakefileArgs{PREREQ_PM}->{ 'Apache::Test' } = 0;

    @scripts = qw( t/TEST );
    # accept the configs from command line
    Apache::TestMM::filter_args();
    my $ref = {@Apache::TestMM::Argv};
    
    if( !$ref->{apxs} )
    {
        my $apxs;
        eval
        {
            require Apache2::BuildConfig;
            require File::Spec;
        };
        if( !$@ )
        {
            my $build = Apache2::BuildConfig->new;
            $apxs = File::Spec->catfile( $build->{APXS_BINDIR}, 'apxs' ) if( $build->{APXS_BINDIR} );
            undef( $apxs ) unless( -e( $apxs ) );
        }
        
        if( !$apxs )
        {
            eval
            {
                require File::Which;
            };
            if( !$@ && ( $apxs = File::Which::which( 'apxs' ) ) )
            {
                $ref->{apxs} = $apxs;
            }
        }
        
        if( $apxs )
        {
            print( STDERR "apxs found and set to $apxs\n" ) if( $MY_DEBUG );
            $ref->{apxs} = $apxs;
        }
        else
        {
            die( "You have not provided the arguement -apxs and the apxs binary could not be found. Maybe you need to install apache2-dev?\n" );
        }
    }
    
    if( !$ref->{httpd_conf} )
    {
        DEFAULT_APACHE_CONF_CHECK:
        {
            eval
            {
                require File::Spec;
                require IO::File;
            };
            print( STDERR "Error trying to load File::Spec and IO::File: $@\n" ) if( $@ && $MY_DEBUG );
            last DEFAULT_APACHE_CONF_CHECK if( $@ );
            my $base;
            ## http://httpd.apache.org/docs/2.0/platform/windows.xml
            my @possible_bases = ();
            if( $^O eq 'linux' || $^O eq 'darwin' )
            {
                push( @possible_bases, File::Spec->catfile( File::Spec->rootdir, 'usr', 'local', 'apache2' ) );
                push( @possible_bases, File::Spec->catfile( File::Spec->rootdir, 'etc', 'apache2' ) );
            }
            elsif( $^O eq 'win32' )
            {
                ## C:\Program Files\Apache Group\Apache2
                push( @possible_bases, File::Spec->catfile( File::Spec->rootdir, 'Program Files', 'Apache Group', 'Apache2' ) );
            }
            
            foreach my $path ( @possible_bases )
            {
                if( -e( $path ) && -d( $path ) && -x( $path ) )
                {
                    $base = $path;
                    last;
                }
            }
            print( STDERR "Existing Apache base installation path found: '$base'\n" ) if( $MY_DEBUG );
            last DEFAULT_APACHE_CONF_CHECK if( !length( $base ) );
        
            my $f = File::Spec->catfile( $base, 'apache2.conf' );
            my $old = File::Spec->catfile( $base, 'httpd.conf' );
            my $env = File::Spec->catfile( $base, 'envvars' );
            if( -e( $f ) && -r( $f ) )
            {
                print( STDERR "Foud an Apache configuration at '$f'\n" ) if( $MY_DEBUG );
                if( -e( $env ) && -r( $env ) && ( $^O eq 'darwin' || $^O eq 'linux' ) )
                {
                    print( STDERR "Found an Apache environment variables setup at '$env'\n" ) if( $MY_DEBUG );
                    my $fh;
                    ## Credits: <https://stackoverflow.com/a/3836009/4814971>
                    if( defined( $fh = IO::File->new( "sh -x $env 2>&1 1>/dev/null|" ) ) )
                    {
                        my $vars = {};
                        while( defined( $_ = $fh->getline ) )
                        {
                            chomp;
                            if( /^[[:blank:]\h]*\+[[:blank:]\h]+(?:export[[:blank:]\h]+)?(\w+)\=(.*?)$/ )
                            {
                                next unless( substr( $1, 0, 7 ) eq 'APACHE_' );
                                $vars->{ $1 } = $ref->{ "_$1" } = $2;
                            }
                        }
                        $fh->close;
                        printf( STDERR "%d Apache environment variables found: %s\n", scalar( keys( %$vars ) ), join( ', ', sort( keys( %$vars ) ) ) );
                        my $tmpdir = File::Spec->tmpdir();
                        my $new = File::Spec->catfile( $tmpdir, 'httpd_for_apache_ssi.conf' );
                        if( scalar( keys( %$vars ) ) &&
                            -w( $tmpdir ) && 
                            defined( $fh = IO::File->new( "<$f" ) ) )
                        {
                            my $conf = do{ local $/; $/ = undef; <$fh> };
                            my $regex = join( '|', keys( %$vars ) );
                            $conf =~ s
                            {
                                \$\{?($regex)\}?
                            }
                            {
                                $vars->{ $1 };
                            }xgems;
                            ## $conf =~ s,(Include|IncludeOptional)[[:blank:]\h]+(.*?),$1 $base/$2,gs;
                            unless( $conf =~ /^ServerRoot[[:blank:]\h](.*?)/m )
                            {
                                $conf = qq{ServerRoot "$base"} . "\n" . $conf;
                            }
                            my $out;
                            ## egrep -Ev '#' /etc/apache2/apache2.conf|egrep -Ev '^[[:blank:]]*$'
                            if( defined( $fh = IO::File->new( ">$new" ) ) )
                            {
                                $fh->print( $conf );
                            }
                            $fh->close;
                            if( -s( $new ) > 0 )
                            {
                                $ref->{httpd_conf} = $new;
                                push( @scripts, $new );
                                print( STDERR "All went well; using \"$new\" as the temporary Apache configuration file\n" ) if( $MY_DEBUG );
                            }
                            else
                            {
                                print( STDERR "Resulting temporary Apache configuration file \"$new\" seems empty. Falling back to \"$f\"\n" ) if( $MY_DEBUG );
                                $ref->{httpd_conf} = $f;
                            }
                        }
                        else
                        {
                            print( STDERR "Could not read Apache configuration file \"$f\", or there was no environment variables found, or the temporary directory \"$tmpdir\" is not writable.\n" ) if( $MY_DEBUG );
                            $ref->{httpd_conf} = $f;
                        }
                    }
                    else
                    {
                        print( STDERR "Failed to execute sh -x $env: $!" ) if( $MY_DEBUG );
                        $ref->{httpd_conf} = $f;
                    }
                }
                ## No /etc/apache2/envvars file
                else
                {
                    print( STDERR "No usable $env file found.\n" ) if( $MY_DEBUG );
                    $ref->{httpd_conf} = $f;
                }
            }
        };
        @Apache::TestMM::Argv = %$ref;
        print( STDERR "Apache::TestMM::Argv is now: '", join( "', '", @Apache::TestMM::Argv ), "'\n" ) if( $MY_DEBUG );
    }
    if( $ENV{APACHE2_SSI_DEBUG} )
    {
        my $extra = File::Spec->catfile( 't', 'conf', 'options.conf.in' );
        my $fh;
        if( defined( $fh = IO::File->new( ">$extra" ) ) )
        {
            $fh->print( "PerlSetVar Apache2_SSI_DEBUG ", int( $ENV{APACHE2_SSI_DEBUG} ), "\n" );
            $fh->close;
        }
    }
    Apache::TestMM::generate_script( 't/TEST' );
}

## Make sure the executable test cgi has the right path to the perl interpreter
my $fh = IO::File->new( "+<./t/htdocs/ssi/include.cgi" ) || die( "Unable to open file \"./t/htdocs/ssi/include.cgi\": $!\n" );
my @lines = $fh->getlines;
$lines[0] = '#!' . $^X . "\n";
$fh->seek(0, 0);
$fh->print( @lines );
$fh->truncate( $fh->tell );
$fh->close;

WriteMakefile(%WriteMakefileArgs);

sub clean_files
{
    return( [@scripts] );
}
