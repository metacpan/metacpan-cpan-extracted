package Schema::Utils;

use Moose;

use Carp qw/croak/;
use Path::Class;
use Hash::Merge;
use Config::JFDI;
use MooseX::Types::Path::Class;


use FindBin '$Bin';
require UNIVERSAL::require;


our $VERSION = "0.01";

my $config_word = __PACKAGE__;


my $attrs = {
             # starting with v3.3, SQLite supports the "IF EXISTS" clause to "DROP TABLE",
             # even though SQL::Translator::Producer::SQLite 1.59 isn't passed along this option
             # see https://rt.cpan.org/Ticket/Display.html?id=48688
             sqlite_version => 3.3,
             add_drop_table => 0,
             no_comments => 0,
             RaiseError => 1,
             PrintError => 0,
            };


has 'debug' => (
                is       => 'rw',
               );


has 'conf' => (
               isa      => 'Path::Class::File',
               coerce   => 1,
               is       => 'rw',
               required => 1,
               trigger  => sub {
                 my $self = shift;
                 $self->_load_config;
               }
              );

has ns_conf => (
               isa      => "Str",
               is       => "rw",
               required => 1,
               default  => sub { __PACKAGE__ },
);

has config => (
               isa      => "HashRef",
               is       => "rw",
               required => 0,
               default  => sub { {} },
);


has model => (
                     is         => 'rw',
                     lazy_build => 1,
                    );

has 'schema'     => (
                     is        => 'rw',
                     predicate => 'has_schema',
                     lazy_build      => 1,
                     #builder   => '_build_schema',
                    );

sub _load_config {
  my $self = shift;

  my $config;
  if ( defined $self->conf && -e $self->conf ){

    my ($jfdi_h, $jfdi) = Config::JFDI->open($self->conf)
      or croak "Error (conf: ".$self->conf.") : $!\n";
    $config = $jfdi->get;
  }
  else{ $config = {} };

  $self->config($config);
  # get debug from args || from conf
  $self->debug($self->config->{'debug'} || 0)
    if ( ! defined $self->debug );

  if ( $self->debug ) {
    print " conf: " . $self->conf . "\n dsn: " . $self->dsn . "\n";
  }
}

sub _build_model {
  my $self = shift;
  my $config       = $self->config;

  my $model_conf = $self->config->{$self->ns_conf}->{model}
    or croak "'" . $self->ns_conf . ":
   model: XXX'
 is not defined in "  . $self->conf . " !";

  my $model = $config->{$model_conf}
    or croak "'$model_conf:
 is not defined in "  . $self->conf . " !";

  return $model
}


sub _connect_info {
  my $self = shift;

  my $model = $self->model;
  my ($dsn, $user, $password, $unicode_option, $db_type);
  eval {
        if (ref $model->{'connect_info'}) {

          $dsn      = $self->dsn;
          $user     = ${$model->{'connect_info'}}[1];
          $password = ${$model->{'connect_info'}}[2];

          # Determine database type amongst: SQLite, Pg or MySQL
          $dsn =~ m/^dbi:(\w+)/;
          $db_type = lc($1);
          my %unicode_connection_for_db = (
                'sqlite' => { sqlite_unicode    => 1 },
                'pg'     => { pg_enable_utf8    => 1 },
                'mysql'  => { mysql_enable_utf8 => 1 },

                );
          $unicode_option = $unicode_connection_for_db{$db_type};
        }
  };

  if ($@) {
    die "Your DSN line in " . $self->dsn . " doesn't look like a valid DSN. : $@";
  }
  die "No valid Data Source Name (DSN).\n" if !$dsn;
  $dsn =~ s/__HOME__/$FindBin::Bin\/\.\./g;

  if ( $db_type eq 'sqlite' ){
    $dsn =~ m/.*:(.*)$/;
    my $dir = dir($1)->parent;
    $dir->mkpath;
  }

  my $merge    = Hash::Merge->new( 'LEFT_PRECEDENT' );
  my $allattrs = $merge->merge( $unicode_option, $attrs );

  return $dsn, $user, $password, $allattrs;
}


sub _build_schema {
  my $self = shift;


  my $schema_class = $self->model->{schema_class};
  $schema_class->require or die $@;

  my ($dsn, $user, $pass, $args ) = $self->_connect_info;
  return $schema_class->connect($dsn, $user, $pass, $args )
    or die "Failed to connect to database";
}



sub schema_class {
  my $self = shift;

  return $self->model->{'connect_info'}->{schema_class};
}

sub dsn {
  my $self = shift;

  my $dsn = ${$self->model->{'connect_info'}}[0]
    or croak "dsn is not defined in " . $self->conf;

  return $dsn
}

=head2 init_schema

    use Schema::Utils;

    my $schema    = Schema::Utils->schema( conf => $conf  );
    $schema->init_schema(populate => 1);

This method creates a fresh test database. If the C<populate> flag is true,
it will call L</populate_schema>.

=cut

sub init_schema {
    my $self = shift;
    my %args = @_;

    my $schema = $self->schema;
    # if add_drop_table has been specified, it will try to drop tables beforehand, but not "IF EXISTS",
    # due to a BUG in SQL::Translator: https://rt.cpan.org/Ticket/Display.html?id=48688
    # This will cause failures if the tables don't exist (i.e. when you first deploy):
    #     ("DBI Exception: DBD::$driver::db do failed: no such table")
    #
    #-mxh This is fragile because it relies on fixed output in the regex.
    #     Recently, the output changed to include a "\n" and broke this code.
    #     I added the s (and i) regex modifiers, but it still needs a better implementation.
    local $SIG{__WARN__} = sub {
        die @_ unless $_[0] =~ /no such table.*DROP TABLE/is;
    };

    # Check if database is already deployed by
    # examining if the table User exists and has a record.
    eval { $schema->resultset('User')->count };
    if (!$@) {
      die "You have already deployed your database\n";
    }

    $schema->deploy( $attrs );

    $schema->populate_schema if $args{populate};

    return $self;
}

1;
