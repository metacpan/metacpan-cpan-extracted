package Class::Usul::TraitFor::ConnectInfo;

use namespace::autoclean;

use Class::Usul::Constants   qw( EXCEPTION_CLASS CONFIG_EXTN FALSE TRUE );
use Class::Usul::Crypt::Util qw( decrypt_from_config );
use Class::Usul::File;
use Class::Usul::Functions   qw( merge_attributes throw );
use File::Spec::Functions    qw( catfile );
use Scalar::Util             qw( blessed );
use Unexpected::Functions    qw( Unspecified );
use Moo::Role;

requires qw( config ); # As a class method

my $_cache = {};

# Private functions
my $_connect_attr = sub {
   return [ qw( class ctlfile ctrldir database dataclass_attr extension
                prefix read_secure salt seed seed_file subspace tempdir ) ];
};

my $_get_cache_key = sub {
   my $param = shift;
   my $db    = $param->{database}
      or throw 'Class [_1] has no database name', [ $param->{class} ];

   return $param->{subspace} ? "${db}.".$param->{subspace} : $db;
};

my $_get_credentials_file = sub {
   my $param = shift; my $file = $param->{ctlfile};

   defined $file and -f $file and return $file;

   my $dir = $param->{ctrldir}; my $db = $param->{database};

      $dir or throw Unspecified, [ 'ctrldir' ];
   -d $dir or throw 'Directory [_1] not found', [ $dir ];
       $db or throw 'Class [_1] has no database name', [ $param->{class} ];

   $file = catfile( $dir, $db.($param->{extension} // CONFIG_EXTN) );

   -f $file and return $file;

   return catfile( $dir, 'connect-info'.($param->{extension} // CONFIG_EXTN) );
};

my $_get_dataclass_schema = sub {
   return Class::Usul::File->dataclass_schema( @_ );
};

my $_unicode_options = sub {
   return { mysql  => { mysql_enable_utf8 => TRUE },
            pg     => { pg_enable_utf8    => TRUE },
            sqlite => { sqlite_unicode    => TRUE }, };
};

my $_dump_config_data = sub {
   my ($param, $cfg_data) = @_;

   my $ctlfile = $_get_credentials_file->( $param );
   my $schema  = $_get_dataclass_schema->( $param->{dataclass_attr} );

   return $schema->dump( { data => $cfg_data, path => $ctlfile } );
};

my $_extract_creds_from = sub {
   my ($param, $cfg_data) = @_; my $key = $_get_cache_key->( $param );

   ($cfg_data->{credentials} and defined $cfg_data->{credentials}->{ $key })
      or throw 'Path [_1] database [_2] no credentials',
               [ $_get_credentials_file->( $param ), $key ];

   return $cfg_data->{credentials}->{ $key };
};

my $_get_connect_options = sub {
   my $creds = shift;
   my $uopt  = $creds->{unicode_option}
            // $_unicode_options->()->{ lc $creds->{driver} } // {};

   return { AutoCommit =>  $creds->{auto_commit  } // TRUE,
            PrintError =>  $creds->{print_error  } // FALSE,
            RaiseError =>  $creds->{raise_error  } // TRUE,
            %{ $uopt }, %{ $creds->{database_attr} // {} }, };
};

my $_load_config_data = sub {
   my $schema = $_get_dataclass_schema->( $_[ 0 ]->{dataclass_attr} );

   return $schema->load( $_get_credentials_file->( $_[ 0 ] ) );
};

# Private methods
my $_merge_attributes = sub {
   return merge_attributes { class => blessed $_[ 0 ] || $_[ 0 ] },
                  $_[ 1 ], ($_[ 2 ] // {}), $_connect_attr->();
};

# Public methods
sub dump_config_data {
   my ($self, $config, $db, $cfg_data) = @_;

   my $param = $self->$_merge_attributes( $config, { database => $db } );

   return $_dump_config_data->( $param, $cfg_data );
}

sub extract_creds_from {
   my ($self, $config, $db, $cfg_data) = @_;

   my $param = $self->$_merge_attributes( $config, { database => $db } );

   return $_extract_creds_from->( $param, $cfg_data );
}

sub get_connect_info {
   my ($self, $app, $param) = @_; $app //= $self; $param //= {};

   merge_attributes $param, $app->config, $self->config, $_connect_attr->();

   my $class    = $param->{class} = blessed $self || $self;
   my $key      = $_get_cache_key->( $param );

   defined $_cache->{ $key } and return $_cache->{ $key };

   my $cfg_data = $_load_config_data->( $param );
   my $creds    = $_extract_creds_from->( $param, $cfg_data );
   my $dsn      = 'dbi:'.$creds->{driver}.':database='.$param->{database};
   my $password = decrypt_from_config $param, $creds->{password};
   my $opts     = $_get_connect_options->( $creds );

   $creds->{host} and $dsn .= ';host='.$creds->{host};
   $creds->{port} and $dsn .= ';port='.$creds->{port};

   return $_cache->{ $key } = [ $dsn, $creds->{user}, $password, $opts ];
}

sub load_config_data {
   my ($self, $config, $db) = @_;

   my $param = $self->$_merge_attributes( $config, { database => $db } );

   return $_load_config_data->( $param );
}

1;

=pod

=encoding utf-8

=head1 Name

Class::Usul::TraitFor::ConnectInfo - Provides the DBIC connect info array ref

=head1 Synopsis

   package YourClass;

   use Moo;
   use Class::Usul::Constants;
   use Class::Usul::Types qw( NonEmptySimpleStr Object );

   with 'Class::Usul::TraitFor::ConnectInfo';

   has 'database' => is => 'ro', isa => NonEmptySimpleStr,
      default     => 'database_name';

   has 'schema' => is => 'lazy', isa => Object, builder => sub {
      my $self = shift; my $extra = $self->config->connect_params;
      $self->schema_class->connect( @{ $self->get_connect_info }, $extra ) };

   has 'schema_class' => is => 'ro', isa => NonEmptySimpleStr,
      default         => 'dbic_schema_class_name';

   sub config { # A class method
      return { ...config parameters... }
   }

=head1 Description

Provides the DBIC connect information array reference

=head1 Configuration and Environment

The JSON data looks like this:

  {
     "credentials" : {
        "schedule" : {
           "driver" : "mysql",
           "host" : "localhost",
           "password" : "{Twofish}U2FsdGVkX1/xcBKZB1giOdQkIt8EFgfNDFGm/C+fZTs=",
           "port" : "3306",
           "user" : "username"
        }
     }
   }

where in this example C<schedule> is the database name

=head1 Subroutines/Methods

=head2 dump_config_data

   $dumped_data = $self->dump_config_data( $app_config, $db, $cfg_data );

Call the L<dump method|File::DataClass::Schema/dump> to write the
configuration file back to disk

=head2 extract_creds_from

   $creds = $self->extract_creds_from( $app_config, $db, $cfg_data );

Returns the credential info for the specified database and (optional)
subspace. The subspace attribute of C<$app_config> is appended
to the database name to create a unique cache key

=head2 get_connect_info

   $db_info_arr = $self->get_connect_info( $app_config, $db );

Returns an array ref containing the information needed to make a
connection to a database; DSN, user id, password, and options hash
ref. The data is read from the configuration file in the config
C<ctrldir>. Multiple sets of data can be stored in the same file,
keyed by the C<$db> argument. The password is decrypted if
required

=head2 load_config_data

   $cfg_data = $self->load_config_data( $app_config, $db );

Returns a hash ref of configuration file data. The path to the file
can be specified in C<< $app_config->{ctlfile} >> or it will default
to the F<connect-info.$extension> file in the C<< $app_config->{ctrldir} >>
directory.  The C<$extension> is either C<< $app_config->{extension} >>
or C<< $self->config->{extension} >> or the default extension given
by the C<CONFIG_EXTN> constant

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

=item L<Class::Usul::Crypt::Util>

=item L<Class::Usul::File>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
