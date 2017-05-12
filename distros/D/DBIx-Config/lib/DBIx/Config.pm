package DBIx::Config;
use 5.005;
use warnings;
use strict;
use DBI;
use File::HomeDir;

our $VERSION = '0.000002'; # 0.0.2
$VERSION = eval $VERSION;

sub new {
    my ( $class, $args ) = @_;
    
    my $self = bless {
        config_paths => [ 
            get_env_vars(),
            './dbic', 
            './dbi',  
            File::HomeDir->my_home . '/.dbic',  
            File::HomeDir->my_home . '/.dbi',
            '/etc/dbic', 
            '/etc/dbi',
        ],
        config_files => [],
    }, $class;

    for my $arg ( keys %{$args} ) {
        $self->$arg( delete $args->{$arg} ) if $self->can( $arg );
    }

   die "Unknown arguments to the constructor: " . join( " ", keys %$args )
       if keys( %$args );

    return $self;
}

sub get_env_vars {
    if ( exists $ENV{DBIX_CONFIG_DIR} ) {
        return ($ENV{DBIX_CONFIG_DIR}.'/dbic', $ENV{DBIX_CONFIG_DIR}.'/dbi');
    }
    return ();
}

sub connect {
    my ( $self, @info ) = @_;

    if ( ( ! ref($self) ) ||  ( ref($self) ne __PACKAGE__) ) {
        return $self->new->connect(@info);
    }
    
    return DBI->connect( $self->connect_info(@info) );
}

sub connect_info {
    my ( $self, @info ) = @_;

    if ( ( ! ref($self) ) ||  ( ref($self) ne __PACKAGE__) ) {
        return $self->new->connect_info(@info);
    }

    my $config = $self->_make_config(@info);

    # Take responsibility for passing through normal-looking
    # credentials.
    $config = $self->default_load_credentials($config)
        unless $config->{dsn} =~ /dbi:/i;

    return $self->_dbi_credentials($config);
}

# Normalize arguments into a single hash.  If we get a single hashref,
# return it.
# Check if $user and $pass are hashes to support things like
# ->connect( 'CONFIG_FILE', { hostname => 'db.foo.com' } ); 

sub _make_config {
    my ( $class, $dsn, $user, $pass, $dbi_attr, $extra_attr ) = @_;
    return $dsn if ref $dsn eq 'HASH';


    return { 
        dsn => $dsn, 
        %{ref $user eq 'HASH' ? $user : { user => $user }},
        %{ref $pass eq 'HASH' ? $pass : { password => $pass }},
        %{$dbi_attr || {} }, 
        %{ $extra_attr || {} } 
    }; 
}

# DBI's ->connect expects 
# ( "dsn", "user", "password", { option_key => option_value } )
# this function changes our friendly hashref into this format.

sub _dbi_credentials {
    my ( $class, $config ) = @_;

    return (
        delete $config->{dsn},
        delete $config->{user},
        delete $config->{password},
        $config,
    );
}

sub default_load_credentials {
    my ( $self,  $connect_args ) = @_;
    
    # To allow overriding without subclassing, if you pass a coderef
    # to ->load_credentials, we will replace our default load_credentials
    # without that function.
    if ( $self->load_credentials ) {
        return $self->load_credentials->( $self, $connect_args );
    }
    
    require Config::Any; # Only loaded if we need to load credentials.

    # While ->connect is responsible for returning normal-looking
    # credential information, we do it here as well so that it can be
    # independently unit tested.
    return $connect_args if $connect_args->{dsn} =~ /^dbi:/i; 

    # If we have ->config_files, we'll use those and load_files
    # instead of the default load_stems.
    my %cf_opts = ( use_ext => 1 );
    my $ConfigAny = @{$self->config_files}
        ? Config::Any->load_files({ files => $self->config_files, %cf_opts })
        : Config::Any->load_stems({ stems => $self->config_paths, %cf_opts });

    return $self->default_filter_loaded_credentials(
        $self->_find_credentials( $connect_args, $ConfigAny ),
        $connect_args
    );

}

# This will look through the data structure returned by Config::Any
# and return the first instance of the database credentials it can
# find.
sub _find_credentials {
    my ( $class, $connect_args, $ConfigAny ) = @_;
    
    for my $cfile ( @$ConfigAny ) {
        for my $filename ( keys %$cfile ) {
            for my $database ( keys %{$cfile->{$filename}} ) {
                if ( $database eq $connect_args->{dsn} ) {
                    return $cfile->{$filename}->{$database};
                }
            }
        }
    }
}

sub default_filter_loaded_credentials {
    my ( $self, $loaded_credentials,$connect_args ) = @_;
    if ( $self->filter_loaded_credentials ) {
        return $self->filter_loaded_credentials->( 
            $self, $loaded_credentials,$connect_args 
        );
    }
    return $loaded_credentials;
}

# Assessors
sub config_paths {
    my $self = shift;
    $self->{config_paths} = shift if @_;
    return $self->{config_paths};
}

sub config_files {
    my $self = shift;
    $self->{config_files} = shift if @_;
    return $self->{config_files};
}

sub filter_loaded_credentials {
    my $self = shift;
    $self->{filter_loaded_credentials} = shift if @_;
    return $self->{filter_loaded_credentials};
}

sub load_credentials {
    my $self = shift;
    $self->{load_credentials} = shift if @_;
    return $self->{load_credentials};
}

1;

=head1 NAME

DBIx::Config - Manage credentials for DBI

=head1 DESCRIPTION

DBIx::Config wraps around L<DBI> to provide a simple way of loading database 
credentials from a file.  The aim is make it simpler for operations teams to 
manage database credentials.  

=head1 SYNOPSIS

Given a file like C</etc/dbi.yaml>, containing:

    MY_DATABASE:
        dsn:            "dbi:Pg:host=localhost;database=blog"
        user:           "TheDoctor"
        password:       "dnoPydoleM"
        TraceLevel:     1

The following code would allow you to connect the database:

    #!/usr/bin/perl
    use warnings;
    use strict;
    use DBIx::Config;

    my $dbh = DBIx::Config->connect( "MY_DATABASE" );

Of course, backwards compatibility is kept, so the following would also work:

    #!/usr/bin/perl
    use warnings;
    use strict;
    use DBIx::Config;

    my $dbh = DBIx::Config->connect(
        "dbi:Pg:host=localhost;database=blog", 
        "TheDoctor", 
        "dnoPydoleM", 
        { 
            TraceLevel => 1, 
        },
    );

For cases where you may use something like C<DBIx::Connector>, a
method is provided that will simply return the connection credentials:


    !/usr/bin/perl
    use warnings;
    use strict;
    use DBIx::Connector;
    use DBIx::Config;

    my $conn = DBIx::Connector->new(DBIx::Config->connect_info("MY_DATABASE"));

=head1 CONFIG FILES

By default the following configuration files are examined, in order listed,
for credentials.  Configuration files are loaded with L<Config::Any>.  You
should append the extention that Config::Any will recognize your file in
to the list below.  For instance ./dbic will look for files such as
C<./dbic.yaml>, C<./dbic.conf>, etc.  For documentation on acceptable files
please see L<Config::Any>.  The first file which has the given credentials 
is used.

=over 4

=item * C<$ENV{DBIX_CONFIG_DIR}> . '/dbic', 

C<$ENV{DBIX_CONFIG_DIR}> can be configured at run-time, for instance:

    DBIX_CONFIG_DIR="/var/local/" ./my_program.pl

=item * C<$ENV{DBIX_CONFIG_DIR}> . '/dbi', 

C<$ENV{DBIX_CONFIG_DIR}> can be configured at run-time, for instance:

    DBIX_CONFIG_DIR="/var/local/" ./my_program.pl

=item * ./dbic 

=item * ./dbi

=item * $HOME/.dbic

=item * $HOME/.dbi 

=item * /etc/dbic

=item * /etc/dbi

=item * /etc/dbi

=back

=head1 USE SPECIFIC CONFIG FILES

If you would rather explicitly state the configuration files you
want loaded, you can use the class accessor C<config_files>
instead.

    #!/usr/bin/perl
    use warnings;
    use strict;
    use DBIx::Config

    my $DBI = DBIx::Config->new( config_files => [
        '/var/www/secret/dbic.yaml',
        '/opt/database.yaml',
    ]);
    my $dbh = $DBI->connect( "MY_DATABASE" );

This will check the files, C</var/www/secret/dbic.yaml>, 
and C</opt/database.yaml> in the same way as C<config_paths>, 
however it will only check the specific files, instead of checking 
for each extension that L<Config::Any> supports.  You MUST use the 
extension that corresponds to the file type you are loading.  
See L<Config::Any> for information on supported file types and 
extension mapping.

=head1 OVERRIDING

=head2 config_files

The configuration files may be changed by setting an accessor:

    #!/usr/bin/perl
    use warnings;
    use strict;
    use DBIx::Config

    my $DBI = DBIx::Config->new(config_paths => ['./dbcreds', '/etc/dbcreds']);
    my $dbh = $DBI->connect( "MY_DATABASE" );

This would check, in order, C<dbcreds> in the current directory, and then C</etc/dbcreds>,
checking for valid configuration file extentions appended to the given file.

=head2 filter_loaded_credentials

You may want to change the credentials that have been loaded, before they are used
to connect to the DB.  A coderef is taken that will allow you to make programatic
changes to the loaded credentials, while giving you access to the origional data
structure used to connect.

    DBIx::Config->new(
        filter_loaded_credentials => sub {
            my ( $self, $loaded_credentials, $connect_args ) = @_;
            ...
            return $loaded_credentials;
        }
    )

Your coderef will take three arguments.  

=over 4

=item * C<$self>, the instance of DBIx::Config your code was called from. C

=item * C<$loaded_credentials>, the credentials loaded from the config file.

=item * C<$connect_args>, the normalized data structure of the inital C<connect> call.

=back

Your coderef should return the same structure given by C<$loaded_credentials>.

As an example, the following code will use the credentials from C</etc/dbi>, but
use its a hostname defined in the code itself.

C</etc/dbi> (note C<host=%s>):

    MY_DATABASE:
        dsn: "DBI:mysql:database=students;host=%s;port=3306"
        user: "WalterWhite"
        password: "relykS"

The Perl script:

    #!/usr/bin/perl
    use warnings;
    use strict;
    use DBIx::Config;

    my $dbh = DBIx::Config->new(
        # If we have %s, replace it with a hostname.
        filter_loaded_credentials => sub {
            my ( $self, $loaded_credentials, $connect_args ) = @_;

                if ( $loaded_credentials->{dsn} =~ /\%s/ ) {
                    $loaded_credentials->{dsn} = sprintf( 
                        $loaded_credentials->{dsn}, $connect_args->{hostname} 
                    );
                }
                return $loaded_credentials;
            }
        )->connect( "MY_DATABASE", { hostname => "127.0.0.1" } );

=head2 load_credentials

Override this function to change the way that DBIx::Config loads credentials. 
The function takes the class name, as well as a hashref.

If you take the route of having ->connect('DATABASE') used as a key for whatever 
configuration you are loading, DATABASE would be $config->{dsn}

    $obj->connect( 
        "SomeTarget", 
        "Yuri", 
        "Yawny", 
        { 
            TraceLevel => 1 
        } 
    );

Would result in the following data structure as $config in load_credentials($self, $config):

    {
        dsn             => "SomeTarget",
        user            => "Yuri",
        password        => "Yawny",
        TraceLevel      => 1,
    }

Currently, load_credentials will NOT be called if the first argument to ->connect() 
looks like a valid DSN. This is determined by match the DSN with /^dbi:/i.

The function should return the same structure. For instance:

    #!/usr/bin/perl
    use warnings;
    use strict;
    use DBIx::Config;
    use LWP::Simple;
    use JSON;

    my $DBI = DBIx::Config->new(
        load_credentials => sub {
            my ( $self, $config ) = @_;
            
            return decode_json( 
                get( "http://someserver.com/v1.0/database?name=" . $config->{dsn} )
            );
        } 
    )

    my $dbh = $DBI->connect( "MAGIC_DATABASE" );

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class::Schema::Config>

=back

=head1 AUTHOR

=over 4

=item * Kaitlyn Parkhurst (SymKat) I<E<lt>symkat@symkat.comE<gt>> (L<http://symkat.com/>)

=back

=head1 CONTRIBUTORS

=over 4

=item * Matt S. Trout (mst) I<E<lt>mst@shadowcat.co.ukE<gt>>

=back

=head1 COPYRIGHT

Copyright (c) 2012 the DBIx::Config L</AUTHOR> and L</CONTRIBUTORS> as listed 
above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as 
perl itself.

=head1 AVAILABILITY

The latest version of this software is available at 
L<https://github.com/symkat/DBIx-Config>

