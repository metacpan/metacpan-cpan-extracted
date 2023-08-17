use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                        => 'Apache2::API',
    AUTHOR                      => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM                => 'lib/Apache2/API.pm',
    ABSTRACT_FROM               => 'lib/Apache2/API.pm',
    PL_FILES                    => {},
    PREREQ_PM                   => {
        'parent'                => 0,
        'strict'                => 0,
		'utf8'                  => 0,
        'version'		        => 0,
        'warnings'              => 0,
		'Apache2::Connection'	=> 0,
		'Apache2::Const'		=> 0,
		'Apache2::Log'			=> 0,
		'Apache2::Reload'		=> 0,
		'Apache2::Request'		=> 0,
		'Apache2::RequestIO'	=> 0,
		'Apache2::RequestRec'	=> 0,
		'Apache2::RequestUtil'	=> 0,
		'Apache2::Response'		=> 0,
		'Apache2::ServerUtil'	=> 0,
		'Apache2::SubRequest'	=> 0,
		'APR::Base64'			=> 0,
		'APR::Pool'				=> 0,
		'APR::Request::Apache2'	=> 0,
		'APR::Request::Cookie'	=> 0,
		'APR::Socket'			=> 0,
		'APR::UUID'				=> 0,
		'Cookie'                => 'v0.2.4',
        'DateTime'              => '1.57',
        'DateTime::Format::Strptime' => '1.79',
        'DateTime::TimeZone'    => '2.51',
        'DateTime::TimeZone::Catalog::Extend' => 'v0.3.0',
		'Devel::Confess'		=> 0,
        'Encode'                => '3.01',
        'Exporter'              => '5.70',
		'HTTP::AcceptLanguage'	=> '0.02',
        'JSON'                  => '4.03',
        'JSON::XS'              => '4.03',
        'Module::Generic'       => '0.30.5',
        'Nice::Try'             => 'v1.3.4',
		'Regexp::Common'		=> 0,
        'Scalar::Util'          => '1.50',
		'URI'					=> 0,
		'URI::Escape'			=> '3.31',
		'URI::Query'			=> '0.16',
        'Want'                  => '0.29',
    },
    TEST_REQUIRES =>
    {
        'lib'                   => 0,
        'File::Find'            => 0,
        'File::Spec'            => 0,
        'File::Which'           => 0,
		'Test::Mock::Apache2'	=> '0.05',
		'Test::MockObject'		=> '1.20180705',
		'Test::More'            => 0,
		'Test::Pod'             => 0,
		'Test::Time'            => 0,
        'Test2::V0'             => '0.000145',
		'utf8'                  => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Apache2-API-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Apache2-API.git',
                web         => 'https://gitlab.com/jackdeguest/Apache2-API',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Apache2-API/issues',
            },
        },
    }) : ()),
);

# NOTE: Apache2 test units preparation
# The rest below is for tests under Apache/modperl2
eval
{
    require Apache::TestMM;
};

my @scripts = ();

my $MY_DEBUG = $ENV{API_DEBUG};
if( !$@ && !$ENV{NO_MOD_PERL} )
{
    print( STDERR "Generating Makefile including modperl\n" ) if( $MY_DEBUG );
    Apache::TestMM->import( qw(test clean) ); #enable 'make test'
    $WriteMakefileArgs{PREREQ_PM}->{ 'Apache::Test' } = 0;

    @scripts = qw( t/TEST );
    # accept the configs from command line
    Apache::TestMM::filter_args();
    my $ref = {@Apache::TestMM::Argv};
    $ref->{_HAS_APACHE_TEST} = 1;
    
    my $config = Apache::TestConfig->thaw->httpd_config;
    my( $has_ssl, $has_perl_ssl, $has_error ) = ( 0, '', 0 );
    $ref->{_HAS_SSL} = 0;
    # require Data::Dump;
    if( $MY_DEBUG > 2 )
    {
        require Data::Dump;
        print( STDERR "Apache::TestConfig->thaw->httpd_config yields: ", Data::Dump::dump( $config ), "\n" );
    }
    if( ref( $config ) eq 'Apache::TestConfig' )
    {
        $has_ssl = $config->{modules}->{ $config->{vars}->{ssl_module} } ? 1 : 0;
        my $apache_bin = $config->{vars}->{httpd};
        if( !$apache_bin )
        {
            eval
            {
                require File::Which;
            };
            if( !$@ )
            {
                for( qw( apache2 httpd ) )
                {
                    if( $apache_bin = File::Which::which( $_ ) )
                    {
                        print( STDERR "Found Apache binary at $apache_bin" ) if( $MY_DEBUG );
                        last;
                    }
                }
            }
        }
        
        my $cmd = '';
        if( $apache_bin )
        {
            print( STDERR "Checking Apache2 configuration with binary $apache_bin\n" ) if( $MY_DEBUG );
            $cmd .= ". $config->{vars}->{conf_dir}/envvars; " if( $config->{vars}->{conf_dir} && -e( "$config->{vars}->{conf_dir}/envvars" ) );
            $cmd .= $apache_bin;
            open( my $io, "${cmd} -M 2>&1|" );
            while( <$io> )
            {
                print( STDERR $_ ) if( $MY_DEBUG );
                $has_ssl++, last if( /ssl/i );
                if( /Syntax[[:blank:]]+error[[:blank:]]+(?:on|at)[[:blank:]]+line[[:blank:]]+(\d+)/i )
                {
                    $has_error = $1;
                }
            }
            close( $io );
            print( STDERR "# Done\n" ) if( $MY_DEBUG );
        }
        warn( "[warning] You have syntax error in your Apache configuration file at line $has_error. You might want to do an apache2ctl configtest or (${cmd} -t)\n" ) if( $has_error );
        
        print( STDERR "Checking for SSL modules IO::Socket::SSL or Net::SSL\n" ) if( $MY_DEBUG );
        # IO::Socket::SSL or Net::SSL
        eval( 'require IO::Socket::SSL' );
        if( $@ )
        {
            my $io_ssl_err = $@;
            eval( 'require Net::SSL' );
            unless( $@ )
            {
                $has_perl_ssl = 'Net::SSL';
            }
        }
        else
        {
            $has_perl_ssl = 'IO::Socket::SSL';
        }
        
        if( $has_ssl && $has_perl_ssl )
        {
            print( STDERR "Found Apache module mod_ssl enabled and $has_perl_ssl module installed. Ok\n" ) if( $MY_DEBUG );
            $ref->{_HAS_SSL} = 1;
        }
        elsif( $has_ssl && !$has_perl_ssl )
        {
            print( STDERR "Found Apache module mod_ssl enabled, but missing perl modules (either IO::Socket::SSL or Net::SSL)\n" ) if( $MY_DEBUG );
        }
        elsif( !$has_ssl && $has_perl_ssl )
        {
            print( STDERR "Apache module mod_ssl is not enabled, but found $has_perl_ssl\n" ) if( $MY_DEBUG );
        }
        else
        {
            print( STDERR "Apache module mod_ssl is not enabled and could not find either IO::Socket::SSL nor Net::SSL, deactivating the use of SSL for our tests.\n" ) if( $MY_DEBUG );
        }
    }
    
    print( STDERR "apxs specified? ", ( $ref->{apxs} ? "yes at $ref->{apxs}" : 'no' ), "\n" ) if( $MY_DEBUG );
    if( !$ref->{apxs} )
    {
        my $apxs;
        eval
        {
            require Apache2::BuildConfig;
            require File::Spec;
            require File::Which;
        };
        # perl -MApache2::BuildConfig -MData::Dump -lE 'my $c=Apache2::BuildConfig->new; say Data::Dump::dump($c)'
        if( !$@ )
        {
            my $build = Apache2::BuildConfig->new;
            $apxs = File::Spec->catfile( $build->{APXS_BINDIR}, 'apxs' ) if( $build->{APXS_BINDIR} );
            undef( $apxs ) unless( -e( $apxs ) );
            print( STDERR "Found apxs at $apxs\n" ) if( $MY_DEBUG );
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
                print( STDERR "Found apxs at $apxs" ) if( $MY_DEBUG );
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
            # http://httpd.apache.org/docs/2.0/platform/windows.xml
            my @possible_bases = ();
            if( $^O eq 'linux' || $^O eq 'darwin' )
            {
                push( @possible_bases, File::Spec->catfile( File::Spec->rootdir, qw( usr local apache2 ) ) );
                push( @possible_bases, File::Spec->catfile( File::Spec->rootdir, qw( etc apache2 ) ) );
            }
            elsif( $^O eq 'win32' )
            {
                # C:\Program Files\Apache Group\Apache2
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
                print( STDERR "Found an Apache configuration at '$f'\n" ) if( $MY_DEBUG );
                if( -e( $env ) && -r( $env ) && ( $^O eq 'darwin' || $^O eq 'linux' ) )
                {
                    print( STDERR "Found an Apache environment variables setup at '$env'\n" ) if( $MY_DEBUG );
                    my $fh;
                    # Credits: <https://stackoverflow.com/a/3836009/4814971>
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
                        my $new = File::Spec->catfile( $tmpdir, 'httpd_for_cookies.conf' );
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
                            # $conf =~ s,(Include|IncludeOptional)[[:blank:]\h]+(.*?),$1 $base/$2,gs;
                            unless( $conf =~ /^ServerRoot[[:blank:]\h](.*?)/m )
                            {
                                $conf = qq{ServerRoot "$base"} . "\n" . $conf;
                            }
                            my $out;
                            # egrep -Ev '#' /etc/apache2/apache2.conf|egrep -Ev '^[[:blank:]]*$'
                            if( defined( $fh = IO::File->new( ">$new" ) ) )
                            {
                                print( $fh $conf );
                                close( $fh );
                            }
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
                # No /etc/apache2/envvars file
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
    
    # Set the necessary environment variable we stored in Apache::TestConfig::Argv in our Makefile.PL
    # We had to do a round-about way to achieve this, because there is no clean easy way with current Apache::Test version to achieve this
    open( my $fh, '>./t/env.pl' ) || die( "t/env.pl: $!\n" );
    foreach my $k ( sort( keys( %$ref ) ) )
    {
        if( substr( $k, 0, 1 ) eq '_' )
        {
            # print( STDERR "Setting environment variable \"", substr( $k, 1 ), "\"\n" );
            $ENV{ substr( $k, 1 ) } = $ref->{ $k };
            $fh->printf( "\$ENV{ '%s' } = q|%s|;\n", substr( $k, 1 ), $ref->{ $k } ) || die( "t/env.pl: $!\n" );
        }
    }
    $fh->print( "\n1;\n" ) || die( "t/env.pl: $!\n" );
    $fh->close;
    
    if( $ENV{API_DEBUG} )
    {
        my $extra = File::Spec->catfile( qw( t conf options.conf.in ) );
        my $fh;
        if( defined( $fh = IO::File->new( ">$extra" ) ) )
        {
            $fh->print( "PerlSetVar API_DEBUG ", int( $ENV{API_DEBUG} ), "\n" );
            $fh->close;
        }
    }
    Apache::TestMM::generate_script( 't/TEST' );
}
else
{
    print( STDERR "Generating Makefile without modperl\n" ) if( $MY_DEBUG );
}

WriteMakefile(%WriteMakefileArgs);

sub clean_files
{
    return( [@scripts] );
}

__END__

=encoding utf-8

=head1 NAME

Makefile.PL - Apache2::API Makefile

=head1 SYNOPSIS

    perl Makefile.PL -apxs /path/to/apxs
    APACHE_TEST_COLOR=1 perl Makefile.PL -apxs /path/to/apxs

=head2 OPTIONS

=head2 -access_module_name

access module name

=head2 -apxs

location of apxs (default is from C<Apache2::BuildConfig>)

=head2 -auth_module_name

auth module name

=head2 -bindir

Apache bin/ dir (default is C<apxs -q BINDIR>)

=head2 -cgi_module_name

cgi module name

=head2 -defines

values to add as C<-D> defines (for example, C<"VAR1 VAR2">)

=head2 -documentroot

DocumentRoot (default is C<$ServerRoot/htdocs>

=head2 -group

Group to run test server as (default is C<$GROUP>)

=head2 -httpd

server to use for testing (default is C<$bindir/httpd>)

=head2 -httpd_conf

inherit config from this file (default is apxs derived)

=head2 -httpd_conf_extra

inherit additional config from this file

=head2 -libmodperl

path to mod_perl's .so (full or relative to LIBEXECDIR)

=head2 -limitrequestline

global LimitRequestLine setting (default is C<128>)

=head2 -maxclients

maximum number of concurrent clients (default is C<minclients+1>)

=head2 -minclients

minimum number of concurrent clients (default is C<1>)

=head2 -perlpod

location of perl pod documents (for testing downloads)

=head2 -php_module_name

php module name

=head2 -port

Port [port_number|select] (default C<8529>)

=head2 -proxyssl_url

url for testing ProxyPass / https (default is localhost)

=head2 -sbindir

Apache sbin/ dir (default is C<apxs -q SBINDIR>)

=head2 -servername

ServerName (default is localhost)

=head2 -serverroot

ServerRoot (default is C<$t_dir>)

=head2 -src_dir

source directory to look for C<mod_foos.so>

=head2 -ssl_module_name

ssl module name

=head2 -sslca

location of SSL CA (default is C<$t_conf/ssl/ca>)

=head2 -sslcaorg

SSL CA organization to use for tests (default is asf)

=head2 -sslproto

SSL/TLS protocol version(s) to test

=head2 -startup_timeout

seconds to wait for the server to start (default is 60)

=head2 -t_conf

the conf/ test directory (default is C<$t_dir/conf>)

=head2 -t_conf_file

test httpd.conf file (default is C<$t_conf/httpd.conf>)

=head2 -t_dir

the t/ test directory (default is C<$top_dir/t>)

=head2 -t_logs

the logs/ test directory (default is C<$t_dir/logs>)

=head2 -t_pid_file

location of the pid file (default is C<$t_logs/httpd.pid>)

=head2 -t_state

the state/ test directory (default is C<$t_dir/state>)

=head2 -target

name of server binary (default is C<apxs -q TARGET>)

=head2 -thread_module_name

thread module name

=head2 -threadsperchild

number of threads per child when using threaded MPMs (default is C<10>)

=head2 -top_dir

top-level directory (default is C<$PWD>)

=head2 -user

User to run test server as (default is C<$USER>)

=cut

