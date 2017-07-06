package Class::Usul::Schema;

use namespace::autoclean;

use Class::Usul::Constants   qw( AS_PARA AS_PASSWORD EXCEPTION_CLASS COMMA
                                 FAILED FALSE NUL OK QUOTED_RE SPC TRUE );
use Class::Usul::Crypt::Util qw( encrypt_for_config );
use Class::Usul::Functions   qw( distname ensure_class_loaded io throw trim );
use Class::Usul::Types       qw( ArrayRef Bool HashRef Maybe NonEmptySimpleStr
                                 PositiveInt SimpleStr Str );
use Data::Record;
use Try::Tiny;
use Unexpected::Functions    qw( inflate_placeholders Unspecified );
use Moo;
use Class::Usul::Options;

extends q(Class::Usul::Programs);
with    q(Class::Usul::TraitFor::ConnectInfo);

# Attribute constructors
my $_build_connect_options = sub {
   my $self  = shift;
   my $copts = { password => NUL, user => NUL, };
   my $text  = 'Need the database administrators id and password';

   $self->output( $text, AS_PARA );

   my $prompt = '+Database administrator id';
   my $user = $self->db_admin_ids->{ lc $self->driver } || NUL;

   $copts->{user} = $self->get_line( $prompt, $user, TRUE, 0 );
   $prompt = '+Database administrator password';
   $copts->{password} = $self->get_line( $prompt, AS_PASSWORD );
   return $copts;
};

my $_build_qdb = sub {
   my $self = shift;
   my $cmds = $self->ddl_commands->{ lc $self->driver };
   my $code = $cmds ? $cmds->{ '-qualify_db' } : undef;

   return $code ? $code->( $self, $self->database ) : $self->database;
};

my $_connect_info = sub {
   my $self = shift;

   return $self->get_connect_info( $self, { database => $self->database } );
};

my $_extract_from_dsn = sub {
   my ($self, $field, $dsn) = @_;

   $self->options and $self->options->{bootstrap} and return;

   return (map  { s{ \A $field [=] }{}mx; $_ }
           grep { m{ \A $field [=] }mx }
           split  m{           [;] }mx, $dsn // $self->dsn)[ 0 ];
};

my $_qualify_database_path = sub {
   return $_[ 0 ]->config->datadir->catfile( $_[ 1 ].'.db' )->pathname;
};

my $_rebuild_dsn = sub {
   my $self = shift;
   my $dsn  = 'dbi:'.$self->driver.':database='.$self->_qualified_db;

   $self->host and $dsn .= ';host='.$self->host;
   $self->port and $dsn .= ';port='.$self->port;

   return $self->_set_dsn( $dsn );
};

my $_rebuild_qdb = sub {
   my $self = shift; $self->_set__qualified_db( $self->$_build_qdb ); return;
};

# Public attributes
option 'all'            => is => 'ro',  isa => Bool, default => FALSE,
   documentation        => 'Perform operation for all possible schema',
   short                => 'a';

option 'database'       => is => 'rwp', isa => NonEmptySimpleStr,
   documentation        => 'The database to connect to',
   format               => 's', lazy => TRUE, required => TRUE,
   trigger              => $_rebuild_qdb;

option 'db_admin_accounts' => is => 'ro', isa => HashRef,
   documentation        => 'For each RDBMS the name of the system database',
   default              => sub { { mysql  => 'mysql',
                                   pg     => 'postgres',
                                   sqlite => NUL, } },
   format               => 's%';

option 'db_admin_ids'   => is => 'ro',   isa => HashRef,
   documentation        => 'The default admin user ids for each RDBMS',
   default              => sub { { mysql  => 'root',
                                   pg     => 'postgres',
                                   sqlite => NUL, } },
   format               => 's%';

option 'db_attr'        => is => 'ro',   isa => HashRef,
   documentation        => 'Default database connection attributes',
   default              => sub { { add_drop_table    => TRUE,
                                   no_comments       => TRUE,
                                   quote_identifiers => TRUE, } },
   format               => 's%';

option 'dry_run'        => is => 'ro',   isa => Bool, default => FALSE,
   documentation        => 'Prints out commands, do not execute them',
   short                => 'd';

option 'preversion'     => is => 'rwp',  isa => Str, default => NUL,
   documentation        => 'Previous schema version',
   format               => 's';

option 'rdbms'          => is => 'lazy', isa => ArrayRef, autosplit => COMMA,
   documentation        => 'List of supported RDBMSs',
   default              => sub { [ qw( MySQL PostgreSQL SQLite ) ] },
   format               => 's@';

option 'schema_classes' => is => 'lazy', isa => HashRef, default => sub { {} },
   documentation        => 'The database schema classes',
   format               => 's%';

option 'schema_version' => is => 'ro',   isa => NonEmptySimpleStr,
   documentation        => 'Current schema version',
   default              => '0.1', format => 's';

option 'unlink'         => is => 'rwp',  isa => Bool, default => FALSE,
   documentation        => 'If true remove DDL file before creating new ones';

option 'yes'            => is => 'ro',   isa => Bool, default => FALSE,
   documentation        => 'When true flips the defaults for yes/no questions',
   short                => 'y';

has 'connect_options'   => is => 'lazy', isa => HashRef,
   builder              => $_build_connect_options;

has 'ddl_commands'      => is => 'lazy', isa => HashRef, builder => sub { {
   'mysql'              => {
      'create_user'     => "create user '[_2]'\@'%' identified by '[_3]';",
      'create_db'       => 'create database [_3] default '
                         . 'character set utf8 collate utf8_unicode_ci;',
      'drop_db'         => 'drop database if exists [_3];',
      'drop_user'       => "drop user '[_2]'\@'%';",
      'exists_db'       => 'select 1 from information_schema.SCHEMATA '
                         . "where SCHEMA_NAME = '[_3]';",
      'exists_user'     => 'select 1 from mysql.user '
                         . "where User = '[_2]' and Host = '%';",
      'grant_all'       => "grant all privileges on [_3].* to '[_2]'\@'%' "
                         . 'with grant option;',
      '-execute_ddl'    => 'mysql -A -h [_1] -u [_2] -p"[_3]" [_5]', },
   'pg'                 => {
      'create_user'     => "create role [_2] login password '[_3]';",
      'create_db'       => "create database [_3] owner [_2] encoding 'UTF8';",
      'drop_db'         => 'drop database if exists [_3];',
      'drop_user'       => 'drop user if exists [_2];',
      'exists_db'       => "select 1 from pg_database where datname = '[_3]';",
      'exists_user'     => "select 1 from pg_user where usename = '[_2]';",
      '-execute_ddl'    => 'PGPASSWORD=[_3] '
                         . 'psql -h [_1] -q -t -U [_2] -w -c "[_4]"',
      '-no_pipe'        => TRUE, },
   'sqlite'             => {
      '-execute_ddl'    => "sqlite3 [_6] '[_4]'",
      '-no_pipe'        => TRUE,
      '-qualify_db'     => $_qualify_database_path, }, } };

has 'driver'            => is => 'rwp',  isa => NonEmptySimpleStr,
   builder              => sub { (split m{ [:] }mx, $_[ 0 ]->dsn)[ 1 ] },
   lazy                 => TRUE, trigger => $_rebuild_dsn;

has 'dsn'               => is => 'rwp',  isa => NonEmptySimpleStr,
   builder              => sub { $_[ 0 ]->$_connect_info->[ 0 ] },
   lazy                 => TRUE;

has 'host'              => is => 'rwp',  isa => Maybe[SimpleStr],
   builder              => sub { $_[ 0 ]->$_extract_from_dsn( 'host' ) },
   lazy                 => TRUE, trigger => $_rebuild_dsn;

has 'password'          => is => 'rwp',  isa => SimpleStr,
   builder              => sub { $_[ 0 ]->$_connect_info->[ 2 ] },
   lazy                 => TRUE;

has 'port'              => is => 'rwp',  isa => Maybe[PositiveInt],
   builder              => sub { $_[ 0 ]->$_extract_from_dsn( 'port' ) },
   lazy                 => TRUE, trigger => $_rebuild_dsn;

has 'user'              => is => 'rwp',  isa => SimpleStr,
   builder              => sub { $_[ 0 ]->$_connect_info->[ 1 ] },
   lazy                 => TRUE;

has '_qualified_db'     => is => 'rwp',  isa => NonEmptySimpleStr,
   builder              => $_build_qdb, lazy => TRUE, trigger => $_rebuild_dsn;

# Private functions
my $_inflate = sub {
   return inflate_placeholders [ 'undef', 'null', TRUE ], @_;
};

my $_unquote = sub {
   local $_ = $_[ 0 ]; s{ \A [\'\"] }{}mx; s{ [\'\"] \z }{}mx; return $_;
};

# Private methods
my $_connect_attr = sub {
   return { %{ $_[ 0 ]->$_connect_info->[ 3 ] }, %{ $_[ 0 ]->db_attr } };
};

my $_create_ddl = sub {
   my ($self, $schema_class, $dir) = @_;

   my $version = $self->schema_version;
   my $schema  = $schema_class->connect
      ( $self->dsn, $self->user, $self->password, $self->$_connect_attr );

   if ($self->unlink) {
      for my $path ($self->ddl_paths( $schema, $version, $dir )) {
         $path->is_file and $path->unlink;
      }
   }

   $schema->create_ddl_dir
      ( $self->rdbms, $version, $dir, $self->preversion, $self->$_connect_attr);
   return;
};

my $_list_population_classes = sub {
   my ($self, $schema_class, $dir) = @_; my $res = [];

   my $dist = distname $schema_class;
   my $extn = $self->config->extension;
   my $re   = qr{ \A $dist [-] \d+ [-] (.*) \Q$extn\E \z }mx;
   my $io   = io( $dir )->filter( sub { $_->filename =~ $re } );

   for my $path ($io->all_files) {
      my ($class) = $path->filename =~ $re; push @{ $res }, [ $class, $path ];
   }

   return $res;
};

my $_deploy_and_populate = sub {
   my ($self, $schema_class, $dir) = @_; my $res; my $schema;

   if ($self->dry_run) {
      $self->output( "Would deploy schema ${schema_class} from ${dir}" );
      $self->dumper( map { $_->basename }
                     $dir->filter( sub { m{ \.sql \z }mx } )->all_files );
   }
   else {
      $self->info( "Deploying schema ${schema_class} and populating" );
      $schema = $schema_class->connect
         ( $self->dsn, $self->user, $self->password, $self->$_connect_attr );
      $schema->storage->ensure_connected;
      $schema->deploy( $self->$_connect_attr, $dir );
   }

   my $split = Data::Record->new( { split => COMMA, unless => QUOTED_RE, } );

   for my $tuple (@{ $self->$_list_population_classes( $schema_class, $dir ) }){
      $res->{ $tuple->[ 0 ] }
         = $self->populate_class( $schema, $split, @{ $tuple } );
   }

   return $res;
};

my $_test_for_existance = sub {
   my ($self, $copts, $test, @args) = @_;

   $test or return FALSE; $test = $_inflate->( $test, @args );

   my $r = $self->execute_ddl( $test, $copts, { out => 'buffer' } );

   $self->debug and $self->dumper( $r );

   return $r && $r->out =~ m{ 1 }mx ? TRUE : FALSE;
};

# Public methods
sub create_database : method {
   my $self   = shift;
   my $driver = $self->driver;
   my $cmds   = $self->ddl_commands->{ lc $driver };
   my @dbs    = $self->all ? keys %{ $self->schema_classes } : $self->database;
   my $copts  = $self->connect_options;

   for my $db (@dbs) {
      my $ddl  = $cmds->{create_db} or return FAILED;
      my @args = ($self->host, $self->user, $db);

      my $r; not $self->$_test_for_existance( $copts, $cmds->{exists_db}, @args)
         and $self->info( "Creating ${driver} database ${db}" )
         and $r = $self->execute_ddl( $_inflate->( $ddl, @args ), $copts );

      $self->debug and $r and $self->dumper( $r ); $r = FALSE;

      $ddl = $cmds->{grant_all}
         and $r = $self->execute_ddl( $_inflate->( $ddl, @args ), $copts );

      $self->debug and $r and $self->dumper( $r );
   }

   return OK;
}

sub create_ddl : method {
   my $self = shift; $self->info( 'Creating DDL for '.$self->dsn );

   for my $schema_class (values %{ $self->schema_classes }) {
      ensure_class_loaded  $schema_class;
      $self->dry_run and $self->output( "Would create ${schema_class}" )
                     and next;
      $self->$_create_ddl( $schema_class, $self->config->sharedir );
   }

   return OK;
}

sub create_schema : method { # Create databases and edit credentials
   my $self    = shift;
   my $default = $self->yes;
   my $text    = 'Schema creation requires a database, id and password. '
               . 'For Postgres the driver is Pg and the port 5432. For '
               . 'MySQL the driver is mysql and the port 3306';

   $self->output( $text, AS_PARA );
   $self->yorn( '+Create database schema', $default, TRUE, 0 ) or return OK;
   $self->edit_credentials;
   $self->connect_options;
   $self->drop_database;
   $self->drop_user;
   $self->create_user;
   $self->create_database;
   $self->deploy_and_populate;
   return OK;
}

sub create_user : method {
   my $self   = shift;
   my $user   = $self->user;
   my $driver = $self->driver;
   my $cmds   = $self->ddl_commands->{ lc $driver };
   my $ddl    = $cmds->{create_user} or return FAILED;
   my @args   = ($self->host, $user, $self->password);
   my $copts  = $self->connect_options;

   my $r; not $self->$_test_for_existance( $copts, $cmds->{exists_user}, @args )
      and $self->info( "Creating ${driver} user ${user}" )
      and $r = $self->execute_ddl( $_inflate->( $ddl, @args ), $copts  );

   $self->debug and $r and $self->dumper( $r );
   return OK;
}

sub ddl_paths {
   my ($self, $schema, $version, $dir) = @_; my @paths = ();

   for my $rdb (@{ $self->rdbms }) {
      push @paths, io( $schema->ddl_filename( $rdb, $version, $dir ) );
   }

   return @paths;
}

sub deploy_and_populate : method {
   my $self = shift;

   my @classes = $self->all ? values %{ $self->schema_classes }
                            : $self->schema_classes->{ $self->database };

   for my $schema_class (@classes) {
      $self->info( "Deploy and populate ${schema_class}" );
      $self->yorn( '+Continue', $self->yes, TRUE, 0 ) or next;
      ensure_class_loaded $schema_class;
      $schema_class->can( 'config' ) and $schema_class->config( $self->config );
      $self->$_deploy_and_populate( $schema_class, $self->config->sharedir );
   }

   return OK;
}

sub deploy_file { # Deprecated
   my $self = shift; return $self->populate_class( @_ );
};

sub drop_database : method {
   my $self   = shift;
   my $driver = $self->driver;
   my $cmds   = $self->ddl_commands->{ lc $driver };
   my @dbs    = $self->all ? keys %{ $self->schema_classes } : $self->database;
   my $copts  = $self->connect_options;

   $self->yorn( '+Really drop the database', $self->yes, TRUE, 0 ) or return OK;

   for my $db (@dbs) {
      my $ddl  = $cmds->{ 'drop_db' } or return FAILED;
      my @args = ($self->host, $self->user, $db);

      $self->info( "Droping ${driver} database ${db}" );

      my $r = $self->execute_ddl( $_inflate->( $ddl, @args ), $copts );

      $self->debug and $self->dumper( $r );
   }

   return OK;
}

sub drop_user : method {
   my $self     = shift;
   my $user     = $self->user;
   my $driver   = $self->driver;
   my $cmds     = $self->ddl_commands->{ lc $driver };
   my $ddl      = $cmds->{ 'drop_user' } or return FAILED;
   my @args     = ($self->host, $user, $self->database);
   my $cmd_opts = { expected_rv => 1, out => 'buffer' };
   my $copts    = $self->connect_options;

   $self->yorn( '+Really drop the user', $self->yes, TRUE, 0 ) or return OK;
   $self->$_test_for_existance( $copts, $cmds->{exists_user}, @args )
      or return OK;
   $self->info( "Droping ${driver} user ${user}" );

   my $r = $self->execute_ddl( $_inflate->( $ddl, @args ), $copts, $cmd_opts );

   $self->debug and $self->dumper( $r );
   return OK;
}

sub edit_credentials : method {
   my $self      = shift;
   my $self_cfg  = $self->config;
   my $db        = $self->database;
   my $bootstrap = $self->options->{bootstrap};
   my $cfg_data  = $bootstrap ? {} : $self->load_config_data( $self_cfg, $db );
   my $copts     = $bootstrap ? {}
                 : $self->extract_creds_from( $self_cfg, $db, $cfg_data );
   my $stored_pw = $copts->{password};
   my $prompts   = { name     => 'Database name',
                     driver   => 'Driver type',
                     host     => 'Host name',
                     port     => 'Port number',
                     user     => 'User name',
                     password => 'User password' };
   my $defaults  = { name     => $db,
                     driver   => '_field',
                     host     => 'localhost',
                     port     => '_field',
                     user     => '_field',
                     password => NUL };

   for my $field (qw( name driver host port user password )) {
      my $setter = "_set_${field}";
      my $prompt = '+'.$prompts->{ $field };
      my $is_pw  = $field eq 'password' ? TRUE : FALSE;
      my $value  = $defaults->{ $field } ne '_field' ? $defaults->{ $field }
                                                     :    $copts->{ $field };

      $value = $self->get_line( $prompt, $value, TRUE, 0, FALSE, $is_pw );
      $field ne 'name' and $self->$setter( $value // NUL );
      $is_pw and $value = encrypt_for_config $self_cfg, $value, $stored_pw;
      $copts->{ $field } = $value // NUL;
   }

   $cfg_data->{credentials}->{ $copts->{name} } = $copts;
   $self->dry_run and $self->dumper( $cfg_data ) and return OK;
   $self->dump_config_data( $self_cfg, $copts->{name}, $cfg_data );
   return OK;
}

sub execute_ddl {
   my ($self, $ddl, $connect_opts, $cmd_opts) = @_;

   my $drvr = $connect_opts->{driver  } // lc $self->driver;
   my $db   = $connect_opts->{database} // $self->db_admin_accounts->{ $drvr };
   my $host = $connect_opts->{host    } // $self->host || 'localhost';
   my $user = $connect_opts->{user    } // $self->db_admin_ids->{ $drvr };
   my $pass = $connect_opts->{password};
   my $cmds = $self->ddl_commands->{ $drvr }
      or $self->fatal( 'Driver [_1] unknown', { args => [ $drvr ] } );
   my $code = $cmds->{ '-qualify_db' };
   my $qdb  = $code ? $code->( $self, $db ) : $db;
   my $cmd  = $cmds->{ '-execute_ddl' };

   $cmd = $_inflate->( $cmd, $host, $user, $pass, $ddl, $db, $qdb );
   $cmds->{ '-no_pipe' } or $cmd = "echo \"${ddl}\" | ${cmd}";
   $self->dry_run and $self->output( $cmd ) and return;
   $self->verbose and $self->output( $cmd );

   return $self->run_cmd( $cmd, { out => 'stdout', %{ $cmd_opts // {} } } );
}

sub populate_class {
   my ($self, $schema, $split, $class, $path) = @_; my $res;

   if ($class) { $self->output( "Populating ${class}" ) }
   else        { $self->fatal ( 'No class in [_1]', $path->filename ) }

   my $data = $self->file->dataclass_schema->load( $path );
   my $flds = [ split SPC, $data->{fields} ];
   my @rows = map { [ map { $_unquote->( trim $_ ) } $split->records( $_ ) ] }
                 @{ $data->{rows} };

   try {
      if ($self->dry_run) { $self->dumper( $flds, \@rows ) }
      else { $res = $schema->populate( $class, [ $flds, @rows ] ) }
   }
   catch {
      if ($_->can( 'class' ) and $_->class eq 'ValidationErrors') {
         $self->warning( "${_}" ) for (@{ $_->args });
      }

      throw $_;
   };

   return $res;
}

sub repopulate_class : method {
   my $self = shift;
   my $dir = $self->config->sharedir;
   my $class = $self->next_argv or throw Unspecified, [ 'class name' ];
   my $schema_class = $self->schema_classes->{ $self->database };
   my $tuples = $self->$_list_population_classes( $schema_class, $dir );
   my $split = Data::Record->new( { split => COMMA, unless => QUOTED_RE, } );

   ensure_class_loaded $schema_class;

   my $schema = $schema_class->connect
      ( $self->dsn, $self->user, $self->password, $self->$_connect_attr );

   for my $tuple (grep { $_->[ 0 ] =~ m{ \A $class \z }imx } @{ $tuples }) {
      my $data = $self->file->dataclass_schema->load( $tuple->[ 1 ] );
      my $flds = [ split SPC, $data->{fields} ];
      my @rows = map { [ map { $_unquote->( trim $_ ) }
                         $split->records( $_ ) ] } @{ $data->{rows} };
      my $rs   = $schema->resultset( $tuple->[ 0 ] );

      for my $row (@rows) {
         my $name = $row->[ 0 ]; my $type = $row->[ 1 ];

         try {
            $rs->create( { name => $name, type_class => $type } );
            $self->info( "Create a ${type} type called ${name}" );
         }
         catch {};
      }
   }

   return OK;
}

1;

__END__

=pod

=encoding utf8

=head1 Name

Class::Usul::Schema - Support for database schemas

=head1 Synopsis

   package YourApp::Schema;

   use Moo;
   use Class::Usul::Functions qw( arg_list );
   use YourApp::Schema::Authentication;
   use YourApp::Schema::Catalog;

   extends 'Class::Usul::Schema';

   my %DEFAULTS = ( database          => 'library',
                    schema_classes    => {
                       authentication => 'YourApp::Schema::Authentication',
                       catalog        => 'YourApp::Schema::Catalog', }, );

   sub new_with_options {
      my ($self, @args) = @_; my $attr = arg_list @args;

      return $self->next::method( %DEFAULTS, %{ $attr } );
   }

=head1 Description

Methods used to install and uninstall database applications

=head1 Configuration and Environment

Defines the following attributes

=over 3

=item C<all>

Optional boolean. Perform operation for all possible schema

=item C<database>

String which is required. The name of the database to connect to

=item C<db_admin_accounts>

Hash reference keyed by the lower case driver value. The hash's value is the
name of the administration database for that RDBMS

=item C<db_admin_ids>

Hash reference which defaults to C<< { mysql => 'root', pg => 'postgres', } >>
The default administration identity for each supported RDBMS

=item C<db_attr>

Hash reference which defaults to
C<< { add_drop_table => TRUE, no_comments => TRUE, } >>

=item C<ddl_commands>

A hash reference keyed by database driver. The DDL commands used to create
users and databases

=item C<dry_run>

A boolean that defaults for false. Can be set from the command line with
the C<-d> option. Prints out commands, do not execute them

=item C<preversion>

String which defaults to null. The previous schema version number

=item C<rdbms>

Array reference which defaults  to C<< [ qw(MySQL PostgreSQL) ] >>. List
of supported RDBMS

=item C<schema_classes>

Hash reference which defaults to C<< {} >>. Keyed by model name, the DBIC
class names for each model

=item C<schema_version>

String which defaults to C<0.1>. The schema version number is used in the
DDL filenames

=item C<unlink>

Boolean which defaults to false. Unlink DDL files if they exist before
creating new ones

=item C<yes>

Boolean which defaults to false. When true flips the defaults for
yes/no questions

=back

=head1 Subroutines/Methods

=head2 create_database - Creates a database

   $self->create_database;

Understands how to do this for different RDBMSs, e.g. MySQL and PostgreSQL

=head2 create_ddl - Dump the database schema definition

   $self->create_ddl;

Creates the DDL for multiple RDBMs

=head2 create_schema - Creates a database then deploys and populates the schema

   $self->create_schema;

Calls L<edit_credentials>, L<create_database>, L<create_user>, and
L<deploy_and_populate>

=head2 create_user - Creates a database user

   $self->create_user;

Creates a database user

=head2 deploy_and_populate - Create tables and populates them with initial data

   $self->deploy_and_populate;

Called as part of the application install

=head2 ddl_paths

   @paths = $self->ddl_paths( $schema, $version, $dir );

Returns a list of io objects for each of the DDL files

=head2 deploy_file

Deprecated in favour of L</populate_class>

=head2 driver

   $self->driver;

The database driver string, derived from the L</dsn> method

=head2 drop_database - Drops a database

   $self->drop_database;

The database is selected by the C<database> attribute

=head2 drop_user - Drops a user

   $self->drop_user;

The user is selected by the C<user> attribute

=head2 dsn

   $self->dsn;

Returns the DSN from the call to
L<get_connect_info|Class::Usul::TraitFor::ConnectInfo/get_connect_info>

=head2 edit_credentials - Edits the database login information

   $self->edit_credentials;

Encrypts the database connection password before storage

=head2 execute_ddl

   $self->execute_ddl( $ddl, \%connect_opts, \%command_opts );

Executes the DDL

=head2 host

   $self->host;

Returns the hostname of the database server derived from the call to
L</dsn>

=head2 password

   $self->password;

The unencrypted password used to connect to the database

=head2 populate_class

   $result = $self->populate_class( $schema, $split, $class, $path );

Populates one table from a single file

=head2 repopulate_class - Reloads the given class from the initial load data

   $self->repopulate_class;

Specify the class to reload on the command line

=head2 user

   $self->user;

The user id used to connect to the database

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul::TraitFor::ConnectInfo>

=item L<Class::Usul::Programs>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

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
