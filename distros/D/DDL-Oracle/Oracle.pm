# $Id: Oracle.pm,v 1.51 2002/05/22 15:26:01 rvsutherland Exp $ 
#
# Copyright (c) 2000, 2001 Richard Sutherland - United States of America
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#

require 5.004;

BEGIN
{
  $DDL::Oracle::VERSION = "1.11"; # Also update version in pod text below!
}

package DDL::Oracle;

use strict;

my $block_size;
my $dbh;
my $ddl;
my $host;
my $instance;
my $isasnapindx;
my $isasnaptabl;
my $oracle_major;
my $oracle_minor;
my $oracle_release;
my $sth;

my @size_arr;

my %attr;

my %compile = 
(
  'function'              => \&_compile,
  'package'               => \&_compile_package,
  'procedure'             => \&_compile,
  'trigger'               => \&_compile,
  'view'                  => \&_compile,
);

my %create = 
(
  'comments'              => \&_create_comments,
  'components'            => \&_create_components,
  'constraint'            => \&_create_constraint,
  'database link'         => \&_create_db_link,
  'exchange index'        => \&_create_exchange_index,
  'exchange table'        => \&_create_exchange_table,
  'function'              => \&_create_function,
  'index'                 => \&_create_index,
  'materialized view'     => \&_create_materialized_view,
  'materialized view log' => \&_create_materialized_view_log,
  'package'               => \&_create_package,
  'package body'          => \&_create_package_body,
  'procedure'             => \&_create_procedure,
  'profile'               => \&_create_profile,
  'role'                  => \&_create_role,
  'rollback segment'      => \&_create_rollback_segment,
  'schema'                => \&_create_schema,
  'sequence'              => \&_create_sequence,
  'snapshot'              => \&_create_snapshot,
  'snapshot log'          => \&_create_snapshot_log,
  'synonym'               => \&_create_synonym,
  'table'                 => \&_create_table,
  'table family'          => \&_create_table_family,
  'tablespace'            => \&_create_tablespace,
  'trigger'               => \&_create_trigger,
  'type'                  => \&_create_type,
  'user'                  => \&_create_user,
  'view'                  => \&_create_view,
);

my %drop = 
(
  'constraint'            => \&_drop_constraint,
  'database link'         => \&_drop_database_link,
  'dimension'             => \&_drop_schema_object,
  'directory'             => \&_drop_object,
  'function'              => \&_drop_schema_object,
  'index'                 => \&_drop_schema_object,
  'library'               => \&_drop_object,
  'materialized view'     => \&_drop_schema_object,
  'materialized view log' => \&_drop_materialized_view_log,
  'package'               => \&_drop_schema_object,
  'procedure'             => \&_drop_schema_object,
  'profile'               => \&_drop_profile,
  'role'                  => \&_drop_object,
  'rollback segment'      => \&_drop_object,
  'sequence'              => \&_drop_schema_object,
  'snapshot'              => \&_drop_schema_object,
  'snapshot log'          => \&_drop_snapshot_log,
  'synonym'               => \&_drop_synonym,
  'table'                 => \&_drop_table,
  'tablespace'            => \&_drop_tablespace,
  'trigger'               => \&_drop_schema_object,
  'type'                  => \&_drop_schema_object,
  'user'                  => \&_drop_user,
  'view'                  => \&_drop_schema_object,
);

my %show_space =
(
  'index'                 => \&_show_free_space,
  'table'                 => \&_show_free_space,
  'cluster'               => \&_show_free_space,
);

my %resize =
(
  'index'                 => \&_resize_index,
  'table'                 => \&_resize_table,
);

############################# Class Methods ############################

sub configure
{
  my ( $class, %args ) = @_;

  # Turn warnings off
  $^W = 0;

  $dbh               = $args{ 'dbh'  };
  $attr{ 'view' }    = ( "\U$args{ 'view'  }" eq 'USER' ) ? 'USER' : 'DBA';
  $attr{ 'schema'  } = ( exists $args{ 'schema'  } ) ? $args{ 'schema'  } : 1;
  $attr{ 'resize'  } = ( exists $args{ 'resize'  } ) ? $args{ 'resize'  } : 1;
  $attr{ 'prompt'  } = ( exists $args{ 'prompt'  } ) ? $args{ 'prompt'  } : 1;
  $attr{ 'grants'  } = ( exists $args{ 'grants'  } ) ? $args{ 'grants'  } : 0;
  $attr{ 'heading' } = ( exists $args{ 'heading' } ) ? $args{ 'heading' } : 1;
  $attr{ 'storage' } = ( exists $args{ 'storage' } ) ? $args{ 'storage' } : 1;
  $attr{ 'tblspace'} = ( exists $args{ 'tblspace'} ) ? $args{ 'tblspace'} : 1;

  _set_sizing();
  _get_oracle_release();
}

sub new
{
  my ( $class, %args ) = @_;

  my $self = {};

  $self->{ type }  = $args{ type } || die
                     "\nAttribute 'type' is required " .
                     "in call to method 'new'.\n\n";;
  $self->{ list }  = $args{ list } || die
                     "\nAttribute 'list' is required " .
                     "in call to method 'new'.\n\n";;

  return bless $self, $class;
}

########################### Instance Methods ###########################

sub compile
{
  my $self = shift;
  my $type = lc( $self->{ type } );

  die "\nObject type '$type' is invalid for 'compile' method.\n\n"
    unless $compile{ $type };

  my $list  = $self->{ list };
  my $class = ref( $self );
  _generate_heading( $class, 'COMPILE', $type, $list );

  foreach my $row ( @$list )
  {
    my ( $owner, $name ) = @$row;
    my $schema = _set_schema( $owner );

    $ddl .= $compile{ $type }->( 
                                 $schema, 
                                 $owner, 
                                 $name, 
                                 $attr{ view }, 
                                 $type,
                               ); 
  }

  _scratch_prompts()    unless $attr{ prompt };
  return $ddl;
}

sub create
{
  my $self = shift;
  my $type = lc( $self->{ type } );

  die "\nObject type '$type' is invalid for 'create' method.\n\n"
    unless $create{ $type };

  my $list  = $self->{ list };
  my $class = ref( $self );
  _generate_heading( $class, 'CREATE', $type, $list );

  foreach my $row ( @$list )
  {
    my ( $owner, $name ) = @$row;
    my $schema = _set_schema( $owner );

    $ddl .= $create{ $type }->( $schema, $owner, $name, $attr{ view } ); 
  }

  _scratch_prompts()    unless $attr{ prompt };
  return $ddl;
}

sub drop
{
  my $self = shift;
  my $type = lc( $self->{ type } );

  die "\nObject type '$type' is invalid for 'drop' method.\n\n"
    unless $drop{ $type };

  my $list  = $self->{ list };
  my $class = ref( $self );
  _generate_heading( $class, 'DROP', $type, $list );

  foreach my $row ( @{ $self->{ list } } )
  {
    my ( $owner, $name ) = @$row;
    my $schema = _set_schema( $owner );

    $ddl .= $drop{ $type }->( $schema, $name, $type, $owner,  $attr{ view } ); 
  }

  _scratch_prompts()    unless $attr{ prompt };
  return $ddl;
}

sub show_space
{
  my $self = shift;
  my $type = lc( $self->{ type } );

  die "\nObject type '$type' is invalid for 'show_space' method.\n\n"
    unless $show_space{ $type };

  my $list  = $self->{ list };
  my $class = ref( $self );
  _generate_heading( $class, 'FREE SPACE', $type, $list );

  foreach my $row ( @{ $self->{ list } } )
  {
    my ( $owner, $name ) = @$row;

    $ddl .= $show_space{ $type }->( $owner, $name, $type, $attr{ view } ); 
  }

  _scratch_prompts()    unless $attr{ prompt };
  return $ddl;
}

sub resize
{
  my $self = shift;
  my $type = lc( $self->{ type } );

  die "\nObject type '$type' is invalid for 'resize' method.\n\n"
   unless $resize{ $type };

  my $list  = $self->{ list };
  my $class = ref( $self );
  _generate_heading( $class, 'ALTER', $type, $list );

  foreach my $row ( @{ $self->{ list } } )
  {
    my ( $owner, $name ) = @$row;
    my $schema = _set_schema( $owner );

    $ddl .= $resize{ $type }->( $schema, $owner, $name, $attr{ view } ); 
  }

  _scratch_prompts()    unless $attr{ prompt };
  return $ddl;
}

############################ Private Methods ###########################

# sub _compile
#
# Returns DDL to compile the named object in the form of:
#
#     ALTER <type> [schema.]<name> COMPILE [PACKAGE|BODY]
# 
sub _compile
{
  my ( $schema, $owner, $name, $view, $type ) = @_;

  $type = uc( $type );
  my $type1 = ( $type eq 'PACKAGE BODY' ) ? 'PACKAGE' : $type;
  my $type2 = ( $type eq 'PACKAGE BODY' ) ? ' BODY'    :
              ( $type eq 'PACKAGE'      ) ? ' PACKAGE' : undef;

  my $stmt =
      "
       SELECT
              'Standing tall with my boots on!'
       FROM
              ${view}_objects
       WHERE
                  object_name = UPPER( ? )
              AND object_type = ?
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner       = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, $type );
  my @row = $sth->fetchrow_array;
  die "\u\L$type \U$name \Ldoes not exist.\n\n" unless @row;

  return "PROMPT " .
         "ALTER $type1 \L$schema$name \UCOMPILE$type2  \n\n" .
         "ALTER $type1 \L$schema$name \UCOMPILE$type2 ;\n\n";
}

# sub _compile_package
#
# Returns DDL to compile the named object in the form of:
#
#     ALTER <type> [schema.]<name> COMPILE [PACKAGE|BODY]
# 
sub _compile_package
{
  my ( $schema, $owner, $name, $view, $type ) = @_;

  my $sql;
  my $stmt =
      "
       SELECT
              'Standing around with only my socks on!'
       FROM
              ${view}_objects
       WHERE
                  object_name = UPPER( ? )
              AND object_type = ?
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner       = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, 'PACKAGE' );
  my @row = $sth->fetchrow_array;
  die "Package \U$name \Ldoes not exist.\n\n" unless @row;

  $sql = _compile( @_ );

  $sth->execute( $name, 'PACKAGE BODY' );
  @row  = $sth->fetchrow_array;
  $sql .= _compile( $schema, $owner, $name, $view, 'PACKAGE BODY' )    if @row;

  return $sql;
}

#sub _constraint_columns
#
# Returns a formatted string containing the constraint columns.
#
sub _constraint_columns
{
  my ( $owner, $name, $view, ) = @_;

  my $stmt =
      "
       SELECT
              LOWER(column_name)
       FROM
              ${view}_cons_columns
       WHERE
                  owner            = UPPER( ? )
              AND constraint_name  = UPPER( ? )
       ORDER
          BY
             position
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $owner, $name );
  my $aref = $sth->fetchall_arrayref;

  my @cols;
  foreach my $row ( @$aref )
  {
    push @cols, $row->[0];
  }

  return "(\n    " .
         join ( "\n  , ", @cols ) .
         "\n)\n";
}

# sub _create_comments
#
# Returns DDL to create the comments on the named table and its columns
# in the form of:
#
#     COMMENT ON TABLE [schema.]<name> IS '<text>'
#     COMMENT ON COLUMN [schema.]<name>.<column> IS '<text>'
#
sub _create_comments
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql;
  my $stmt =
      "
       SELECT
              comments
       FROM
              ${view}_tab_comments
       WHERE
                  table_name    = UPPER( ? )
              AND comments IS NOT null
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner         = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    @$row->[0] =~ s/'/''/g;

    $sql .= "PROMPT " .
            "COMMENT ON TABLE \L$schema$name \UIS \E'@$row->[0]'  \n\n" .
            "COMMENT ON TABLE \L$schema$name \UIS \E'@$row->[0]' ;\n\n";
  }

  $stmt =
      "
       SELECT
              column_name
            , comments
       FROM
              ${view}_col_comments
       WHERE
                  table_name    = UPPER( ? )
              AND comments IS NOT null
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner         = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    @$row->[1] =~ s/'/''/g;

    $sql .= "PROMPT " .
            "COMMENT ON COLUMN \L$schema$name.@$row->[0] " . 
              "IS '@$row->[1]'  \n\n" .
            "COMMENT ON COLUMN \L$schema$name.@$row->[0] " . 
              "IS '@$row->[1]' ;\n\n";
  }

  return $sql;
}

# sub _create_components
#
# Returns DDL to create ALL objects of the following object types:
#
#     TABLESPACE
#     ROLLBACK SEGMENT
#     PUBLIC DATABASE LINK
#     PUBLIC SYNONYM
#     PROFILE
#     ROLE
#     USER
#
sub _create_components
{
  ( undef, undef, undef, my $view ) = @_;

  die "\nYou must use the DBA views in order to CREATE COMPONENTS\n\n"
      unless $view eq 'DBA';

  my $sql;
  my $stmt;
  my $aref;
  my $row;

  # Get tablespaces
  $stmt =
      "
       SELECT
              tablespace_name
       FROM
              dba_tablespaces
       ORDER
          BY
              tablespace_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach $row ( @$aref )
  {
    $sql .= _create_tablespace( undef, undef, @$row->[0], $view );
  }

  # Get rollback segments
  $stmt =
      "
       SELECT
              segment_name
       FROM
              dba_rollback_segs
       ORDER
          BY
              segment_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach $row ( @$aref )
  {
    $sql .= _create_rollback_segment( undef, undef, @$row->[0], $view );
  }

  # Get PUBLIC database links
  $stmt =
      "
       SELECT
              db_link
       FROM
              dba_db_links
       WHERE
              owner = 'PUBLIC'
       ORDER
          BY
              db_link
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach $row ( @$aref )
  {
    $sql .= _create_db_link( 'PUBLIC ', 'PUBLIC', @$row->[0], $view );
  }

  # Get PUBLIC synonyms
  $stmt =
      "
       SELECT
              owner
            , synonym_name
       FROM
              dba_synonyms
       WHERE
              owner = 'PUBLIC'
       ORDER
          BY
              owner
            , synonym_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach $row ( @$aref )
  {
    my ( $owner, $name ) = @$row;
    my $schema = _set_schema( $owner );

    $sql .= _create_synonym( $schema, $owner, $name, $view );
  }

  # Get profiles
  $stmt =
      "
       SELECT DISTINCT
              profile
       FROM
              dba_profiles
       ORDER
          BY
              profile
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach $row ( @$aref )
  {
    $sql .= _create_profile( undef, undef, @$row->[0], $view );
  }

  # Get roles
  $stmt =
      "
       SELECT
              role
       FROM
              dba_roles
       ORDER
          BY
              role
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach $row ( @$aref )
  {
    $sql .= _create_role( undef, undef, @$row->[0], $view );
  }

  # Get users
  $stmt =
      "
       SELECT
              username
       FROM
              dba_users
       WHERE
              username NOT IN (
                                  'NEXT_USER'
                                , 'PUBLIC'
                                , 'SYS'
                                , 'SYSTEM'
                              )
       ORDER
          BY
              username
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach $row ( @$aref )
  {
    $sql .= _create_user( undef, undef, @$row->[0], $view );
  }

  return $sql;
}

#     
#
# sub _create_constraint
#
# Returns DDL to create the named constraint in the form of:
#
#     ALTER TABLE [schema.]<name> ADD CONSTRAINT <name> <TYPE>
#     [<column list>
#
sub _create_constraint
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql;
  my $stmt;

  if ( $oracle_major == 7 )
  {
     $stmt =
      "
       SELECT
              table_name
            , constraint_type
            , search_condition
            , r_owner
            , r_constraint_name
            , delete_rule
            , DECODE(
                      status
                     ,'ENABLED','ENABLE'
                     ,          'DISABLE'
                    )                          as enagle
       FROM
              ${view}_constraints cn
       WHERE
                  owner           = UPPER( ? )
              AND constraint_name = UPPER( ? )
      ";
  }
  else
  {
     $stmt =
      "
       SELECT
              table_name
            , constraint_type
            , search_condition
            , r_owner
            , r_constraint_name
            , delete_rule
            , DECODE(
                      status
                     ,'ENABLED','ENABLE'
                     ,          'DISABLE'
                    )                          as enagle
            , deferrable
            , deferred
       FROM
              ${view}_constraints cn
       WHERE
                  owner           = UPPER( ? )
              AND constraint_name = UPPER( ? )
      ";
  }

  $dbh->{ LongReadLen } = 8192;    # Allows SEARCH_CONDITION length of 8K
  $dbh->{ LongTruncOk } = 1;

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $owner, $name );
  my @row = $sth->fetchrow_array;

  my (
      $table,
      $cons_type,
      $condition,
      $r_owner,
      $r_cons_name,
      $delete_rule,
      $enable,
      $deferrable,
      $deferred,
     ) = @row;

  $sql  = "PROMPT " .
          "ALTER TABLE \L$schema$table \UADD CONSTRAINT \L$name ";
  $sql .= ( $cons_type eq 'P' ) ? "PRIMARY KEY\n\n" :
          ( $cons_type eq 'U' ) ? "UNIQUE\n\n"      :
          ( $cons_type eq 'R' ) ? "FOREIGN KEY\n\n" :
                                  "CHECK\n\n"; 

  $sql .= "ALTER TABLE \L$schema$table \UADD CONSTRAINT \L$name " ;
  $sql .= ( $cons_type eq 'P' ) ? "PRIMARY KEY\n" :
          ( $cons_type eq 'U' ) ? "UNIQUE\n"      :
          ( $cons_type eq 'R' ) ? "FOREIGN KEY\n" :
                                  "\nCHECK ($condition)\n";

  if ( $cons_type ne 'C' )
  {
    $sql .= _constraint_columns( $owner, $name, $view, );
  }

  if ( $cons_type eq 'R' )
  {
    $stmt =
        "
         SELECT
                table_name
         FROM
                ${view}_constraints
         WHERE
                    constraint_name  = UPPER( ? )
                AND owner            = UPPER( ? )
        ";

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $r_cons_name, $r_owner );
    my ( $table_name ) = $sth->fetchrow_array;

    $sql .= "REFERENCES \L$r_owner\.$table_name\n" .
            _constraint_columns( $r_owner, $r_cons_name, $view );

    if ( $delete_rule eq 'CASCADE' )
    {
      $sql .= "ON DELETE CASCADE\n";
    }
  }

  if ( $oracle_major < 8 )
  {
    # Syntax for Oracle7 doesn't like the ENABLE clause
    $sql .= "$enable\n"    unless $enable eq 'ENABLE';
  }
  else
  {
    $sql .= "$deferrable\n" .
            "INITIALLY $deferred\n";

    if ( $enable eq 'ENABLE' )
    {
      $sql .= "ENABLE NOVALIDATE\n";
    }
    else
    {
      $sql .= "DISABLE\n";
    }
  }

  return $sql .
         ";\n\n";
}

# sub _create_db_link
#
# Returns DDL to create the named database link in the form of:
#
#     CREATE [PUBLIC] DATABASE LINK <name>
#     CONNECT TO <user> IDENTIFIED BY <password>
#     USING '<connect string>'
#
sub _create_db_link
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $msg = "\nYou must use the DBA views in order to " .
            "CREATE a PUBLIC DATABASE LINK\n\n";
  if ( "\U$owner" eq 'PUBLIC' and $view ne 'DBA' )
  {
    die $msg;
  }

  my $sql;
  my $stmt;

  if ( $view eq 'DBA' )
  {
    $stmt =
      "
       SELECT
              l.userid
            , l.password
            , l.host
       FROM
              sys.link\$  l
            , sys.user\$  u
       WHERE
                  u.name    = UPPER('$owner')
              AND l.owner\# = u.user\#
              AND l.name LIKE UPPER('${name}%')
      ";
  }
  else      # view is USER
  {
    $stmt =
      "
       SELECT
              username
            , password
            , host
       FROM
              user_db_links
       WHERE
              db_link LIKE UPPER('${name}%')
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  my @row = $sth->fetchrow_array;
  die "Database Link \U$name \Ldoes not exist.\n\n" unless @row;

  my ( $user, $password, $host ) = @row;

  my $is_public = ( "\U$owner" eq 'PUBLIC' ) ? ' PUBLIC' : '';

  return "PROMPT " .
         "CREATE$is_public DATABASE LINK \L$name\n\n" .
         "CREATE$is_public DATABASE LINK \L$name\n" .
         "CONNECT TO \L$user \UIDENTIFIED BY \L$password\n" .
         "USING '$host'\n" .
         ";\n\n";
}

# sub _create_exchange_index
#
# Returns DDL to create a temporary table as a mirror of the named partition.
# See sub _create_table for the format.  Physical attributes come from the
# partition.
#
sub _create_exchange_index
{
  my ( $schema, $owner, $name, $view ) = @_;

  ( $name, my $partition ) = split /:/, $name;

  my $sql;
  my $stmt =
      "
       SELECT
              SUBSTR(segment_type,7)       AS type
            , blocks
       FROM
              ${view}_segments
       WHERE
                  segment_name   = UPPER( ? )
              AND partition_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner          = UPPER('$owner')
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, $partition );
  my @row = $sth->fetchrow_array;
  die "Partition \U$partition \Lof \EIndex \U$name \Ldoes not exist,\n"
    unless @row;

  my ( 
       $type,
       $blocks,
     ) = @row;

  $stmt =
      "
       SELECT
              LTRIM(i.degree)
            , LTRIM(i.instances)
            , i.table_name
            , DECODE(
                      i.uniqueness
                     ,'UNIQUE',' UNIQUE'
                     ,null
                    )                       AS uniqueness
            , DECODE(
                      i.index_type
                     ,'BITMAP',' BITMAP'
                     ,null
                    )                       AS index_type
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , p.pct_free
            , DECODE(
                      p.ini_trans
                     ,0,1
                     ,null,1
                     ,p.ini_trans
                    )                       AS ini_trans
            , DECODE(
                      p.max_trans
                     ,0,255
                     ,null,255
                     ,p.max_trans
                    )                       AS max_trans
              -- Storage Clause
            , p.initial_extent
            , p.next_extent
            , p.min_extent
            , DECODE(
                      p.max_extent
                     ,2147483645,'unlimited'
                     ,           p.max_extent
                    )                       AS max_extent
            , p.pct_increase
            , NVL(p.freelists,1)
            , NVL(p.freelist_groups,1)
            , LOWER(p.buffer_pool)          AS buffer_pool
            , DECODE(
                      p.logging
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(p.tablespace_name)      AS tablespace_name
            , $blocks                       AS blocks
       FROM
              ${view}_indexes       i
            , ${view}_ind_${type}s  p
       WHERE
                  p.index_name   = UPPER( ? )
              AND p.${type}_name = UPPER( ? )
              AND i.index_name   = p.index_name
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND p.index_owner  = UPPER('$owner')
              AND i.owner        = p.index_owner
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, $partition );
  @row = $sth->fetchrow_array;

  my $degree     = shift @row;
  my $instances  = shift @row;
  my $table      = shift @row;
  my $unique     = shift @row;
  my $bitmap     = shift @row;

  $sql = "PROMPT " .
         "CREATE$unique$bitmap INDEX \L$schema$name \UON \L$schema$table\n\n" .
         "CREATE$unique$bitmap INDEX \L$schema$name \UON \L$schema$table\n" .
         _index_columns( '', $owner, $name, $view, ) .
         "PARALLEL\n" .
         "(\n" .
         "  DEGREE            $degree\n" .
         "  INSTANCES         $instances\n" .
         ")\n";

  unshift @row, ( '' );        # Indent (none)

  $sql .= _segment_attributes( \@row ) .
          ";\n\n";

  return $sql;
}

# sub _create_exchange_table
#
# Returns DDL to create a temporary table as a mirror of the named partition.
# See sub _create_table for the format.  Physical attributes come from the
# partition.
#
sub _create_exchange_table
{
  my ( $schema, $owner, $name, $view ) = @_;

  ( $name, my $partition ) = split /:/, $name;

  my $stmt =
      "
       SELECT
              SUBSTR(segment_type,7)       AS type
            , blocks
       FROM
              ${view}_segments
       WHERE
                  segment_name   = UPPER( '$name' )
              AND partition_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner          = UPPER('$owner')
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $partition );
  my @row = $sth->fetchrow_array;
  die "Partition \U$partition \Lof \ETable \U$name \Ldoes not exist,\n"
    unless @row;

  my ( 
       $type,
       $blocks,
     ) = @row;

  $stmt =
      "
       SELECT
              DECODE(
                      t.monitoring
                     ,'NO','NOMONITORING'
                     ,     'MONITORING'
                    )                              AS monitoring
            , t.table_name
            , LTRIM(t.degree)                      AS degree
            , LTRIM(t.instances)                   AS instances
            , 'HEAP'                               AS organization
            , DECODE(
                      t.cache
                     ,'y','CACHE'
                     ,    'NOCACHE'
                    )                              AS cache
            , p.pct_used
            , p.pct_free
            , p.ini_trans
            , p.max_trans
            , p.initial_extent
            , p.next_extent
            , p.min_extent
            , DECODE(
                      p.max_extent
                     ,2147483645,'unlimited'
                     ,p.max_extent
                    )                              AS max_extents
            , p.pct_increase
            , p.freelists
            , p.freelist_groups
            , LOWER(p.buffer_pool)                 AS buffer_pool
            , DECODE(
                      p.logging
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                              AS logging
            , LOWER(p.tablespace_name)             AS tablespace_name
            , $blocks - NVL(p.empty_blocks,0)      AS blocks
       FROM
              dba_tables        t
            , dba_tab_${type}s  p
       WHERE
                  p.table_name   = UPPER('$name')
              AND p.${type}_name = UPPER('$partition')
              AND t.table_name   = p.table_name
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND p.table_owner    = UPPER('$owner')
              AND t.owner          = p.table_owner
      ";
  }

  return _create_table_text( $stmt, $schema, $owner, $name, $view ) .
         ";\n\n";
}

# sub _create_function
#
# Returns DDL to create the named procedure in the form of:
#
#     CREATE OR REPLACE FUNCTION [schema.]<name>
#     AS
#     <source>
# 
# by calling _display_source
#
sub _create_function
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql =  _display_source( $schema, $owner, $name, $view, 'FUNCTION' );

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql ;
}

# sub _create_index
#
# Returns DDL to create the named index and its partition(s) in the form of:
#
#     CREATE INDEX [schema1.]<name> ON [schema2.]<table>
#     (
#       <column list>
#     )
#     INDEXTYPE IS <value>  -- for domain indexes
#     PARAMETERS   <value>  -- for domain indexes
#     [NO]MONIOTORING
#     PARALLEL
#     (
#       DEGREE     <value>
#       INSTANCES  <value>
#     )
#     PCTFREE      <value>
#     INITRANS     <value>
#     MAXTRANS     <value>
#     STORAGE
#     (
#       <storage clause>
#     )
#     [NO]LOGING
#     TABLESPACE   <name>
#     [<partitioning clause>]
#
sub _create_index
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql;
  my $stmt;

  if ( $oracle_major == 7 )
  {
     $stmt =
      "
       SELECT
              'N/A'                           AS partitioned
            , table_name
            , table_owner
            , DECODE(
                      uniqueness
                     ,'UNIQUE',' UNIQUE'
                     ,null
                    )
            , null                            AS bitmap
            , null                            AS domain
       FROM
              ${view}_indexes
       WHERE
                  index_name = UPPER( ? )
      ";
  }
  else               # We're Oracle8 or newer
  {
     $stmt =
      "
       SELECT
              partitioned
            , table_name
            , table_owner
            , DECODE(
                      uniqueness
                     ,'UNIQUE',' UNIQUE'
                     ,null
                    )
            , DECODE(
                      index_type
                     ,'BITMAP',' BITMAP'
                     ,null
                    )
            , DECODE(
                      index_type
                     ,'DOMAIN','DOMAIN'
                     ,null
                    )
       FROM
              ${view}_indexes
       WHERE
                  index_name = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner      = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  die "Index \U$name \Ldoes not exist.\n\n" unless @row;

  my ( 
       $partitioned,
       $table,
       $table_owner,
       $unique,
       $bitmap,
       $domain, 
     ) = @row;

  my (
       $dom_owner,
       $dom_name,
       $dom_param
     );

  if ( $domain eq 'DOMAIN')
  {
     $stmt =
      "
       SELECT
              ityp_owner
            , ityp_name
            , parameters
       FROM
              ${view}_indexes
       WHERE
                  index_name = UPPER( ? )
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
        "
              AND owner      = UPPER('$owner')
        ";
    }

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my @row = $sth->fetchrow_array;

    (
      $dom_owner,
      $dom_name,
      $dom_param
    ) = @row;
  }

  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              'N/A'                         AS degree
            , 'N/A'                         AS instances
            , 0                             AS compressed
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , i.pct_free
            , DECODE(
                      i.ini_trans
                     ,0,1
                     ,null,1
                     ,i.ini_trans
                    )                       AS ini_trans
            , DECODE(
                      i.max_trans
                     ,0,255
                     ,null,255
                     ,i.max_trans
                    )                       AS max_trans
              -- Storage Clause
            , i.initial_extent
            , i.next_extent
            , i.min_extents
            , DECODE(
                      i.max_extents
                     ,2147483645,'unlimited'
                     ,           i.max_extents
                    )                       AS max_extents
            , i.pct_increase
            , NVL(i.freelists,1)
            , NVL(i.freelist_groups,1)
            , 'N/A'                         AS buffer_pool
            , 'N/A'                         AS logging
            , LOWER(i.tablespace_name)      AS tablespace_name
            , s.blocks
       FROM
              ${view}_indexes   i
            , ${view}_segments  s
       WHERE
                  i.index_name   = UPPER( ? )
              AND s.segment_name = i.index_name
      ";
  }
  elsif ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              LTRIM(i.degree)
            , LTRIM(i.instances)
            , 0                             AS compressed
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , i.pct_free
            , DECODE(
                      i.ini_trans
                     ,0,1
                     ,null,1
                     ,i.ini_trans
                    )                       AS ini_trans
            , DECODE(
                      i.max_trans
                     ,0,255
                     ,null,255
                     ,i.max_trans
                    )                       AS max_trans
              -- Storage Clause
            , i.initial_extent
            , i.next_extent
            , i.min_extents
            , DECODE(
                      i.max_extents
                     ,2147483645,'unlimited'
                     ,           i.max_extents
                    )                       AS max_extents
            , i.pct_increase
            , NVL(i.freelists,1)
            , NVL(i.freelist_groups,1)
            , LOWER(i.buffer_pool)          AS buffer_pool
            , DECODE(
                      i.logging
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(i.tablespace_name)      AS tablespace_name
            , s.blocks
       FROM
              ${view}_indexes   i
            , ${view}_segments  s
       WHERE
                  i.index_name   = UPPER( ? )
              AND s.segment_name = i.index_name
      ";
  }
  else               # We're Oracle8i or newer
  {
    $stmt =
      "
       SELECT
              LTRIM(i.degree)
            , LTRIM(i.instances)
            , DECODE(
                      i.compression
                     ,'ENABLED',i.prefix_length
                     ,0
                    )                             AS compressed
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , i.pct_free
            , DECODE(
                      i.ini_trans
                     ,0,1
                     ,null,1
                     ,i.ini_trans
                    )                       AS ini_trans
            , DECODE(
                      i.max_trans
                     ,0,255
                     ,null,255
                     ,i.max_trans
                    )                       AS max_trans
              -- Storage Clause
            , i.initial_extent
            , i.next_extent
            , i.min_extents
            , DECODE(
                      i.max_extents
                     ,2147483645,'unlimited'
                     ,           i.max_extents
                    )                       AS max_extents
            , i.pct_increase
            , NVL(i.freelists,1)
            , NVL(i.freelist_groups,1)
            , LOWER(i.buffer_pool)          AS buffer_pool
            , DECODE(
                      i.logging
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(i.tablespace_name)      AS tablespace_name
            , s.blocks
       FROM
              ${view}_indexes   i
            , ${view}_segments  s
       WHERE
                  i.index_name   = UPPER( ? )
              AND s.segment_name = i.index_name
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND i.owner        = UPPER('$owner')
              AND s.owner        = i.owner
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  @row = $sth->fetchrow_array;

  my $degree     = shift @row;
  my $instances  = shift @row;
  my $compressed = shift @row;

  my $schema2 = _set_schema( $table_owner );

  $sql = "PROMPT " .
         "CREATE$unique$bitmap INDEX \L$schema$name \UON \L$schema2$table\n\n" .
         "CREATE$unique$bitmap INDEX \L$schema$name \UON \L$schema2$table\n" .
         _index_columns( '', $owner, $name, $view, );

  if ( $domain eq 'DOMAIN' )
  {
    return $sql .
    qq!INDEXTYPE IS "$dom_owner"."$dom_name"\nPARAMETERS ('$dom_param') ;\n\n!;
  }

  if ( $oracle_major > 7 )
  {
    $sql .= "PARALLEL\n" .
            "(\n" .
            "  DEGREE            $degree\n" .
            "  INSTANCES         $instances\n" .
            ")\n";
  }

  if ( $partitioned eq 'YES' )
  {
    return _create_partitioned_index( $schema, $owner, $name, $view, $sql )
  }
  else         # Plain ol' non-partitioned index
  {
    unshift @row, ( '' );        # Indent (none)

    $sql .= _segment_attributes( \@row );

    if ( $compressed )
    {
      $sql .= "COMPRESS            $compressed\n";
    }

    return $sql .= ";\n\n";
  }
}

# sub _create_iot
#
# Returns DDL to create the index organized table and its partition(s).
# See _create_table for format.
#
sub _create_iot
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $stmt;

  if ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              'N/A'                         AS monitoring
            , logging
            , blocks - NVL(empty_blocks,0)
       FROM
              ${view}_all_tables
       WHERE
                  table_name = UPPER( ? )
      ";
  }
  else
  {
    $stmt =
      "
       SELECT
              DECODE(
                      monitoring
                     ,'NO','NOMONITORING'
                     ,     'MONITORING'
                    )                       AS monitoring
            , logging
            , blocks - NVL(empty_blocks,0)
       FROM
              ${view}_all_tables
       WHERE
                  table_name = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner      = UPPER('$owner')
      ";
  }

  my $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my (
       $monitoring,
       $logging,
       $blocks,
     ) = $sth->fetchrow_array;

  if ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              'N/A'                         AS monitoring
            , 'N/A'                         AS table_name
              -- Parallel Clause
            , LTRIM(degree)
            , LTRIM(instances)
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , pct_free
            , DECODE(
                      ini_trans
                     ,0,1
                     ,null,1
                     ,ini_trans
                    )                       AS ini_trans
            , DECODE(
                      max_trans
                     ,0,255
                     ,null,255
                     ,max_trans
                    )                       AS max_trans
              -- Storage Clause
            , initial_extent
            , next_extent
            , min_extents
            , DECODE(
                      max_extents
                     ,2147483645,'unlimited'
                     ,           max_extents
                    )                       AS max_extents
            , pct_increase
            , NVL(freelists,1)
            , NVL(freelist_groups,1)
            , LOWER(buffer_pool)          AS buffer_pool
            , DECODE(
                      '$logging'
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(tablespace_name)      AS tablespace_name
            , DECODE(
                      '$blocks'
                      ,null,GREATEST(initial_extent,next_extent) 
                            / ($block_size * 1024)
                      ,'0' ,GREATEST(initial_extent,next_extent)
                            / ($block_size * 1024)
                      ,'$blocks'
                    )                       AS blocks
       FROM
              ${view}_indexes
       WHERE
                  table_name  = UPPER('$name')
      ";
  }
  else
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              DECODE(
                      '$monitoring'
                     ,'NO','NOMONITORING'
                     ,     'MONITORING'
                    )
            , 'N/A'                         AS table_name
              -- Parallel Clause
            , LTRIM(degree)
            , LTRIM(instances)
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , pct_free
            , DECODE(
                      ini_trans
                     ,0,1
                     ,null,1
                     ,ini_trans
                    )                       AS ini_trans
            , DECODE(
                      max_trans
                     ,0,255
                     ,null,255
                     ,max_trans
                    )                       AS max_trans
              -- Storage Clause
            , initial_extent
            , next_extent
            , min_extents
            , DECODE(
                      max_extents
                     ,2147483645,'unlimited'
                     ,           max_extents
                    )                       AS max_extents
            , pct_increase
            , NVL(freelists,1)
            , NVL(freelist_groups,1)
            , LOWER(buffer_pool)          AS buffer_pool
            , DECODE(
                      '$logging'
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(tablespace_name)      AS tablespace_name
            , DECODE(
                      '$blocks'
                      ,null,GREATEST(initial_extent,next_extent) 
                            / ($block_size * 1024)
                      ,'0' ,GREATEST(initial_extent,next_extent)
                            / ($block_size * 1024)
                      ,'$blocks'
                    )                       AS blocks
       FROM
              ${view}_indexes
       WHERE
                  table_name  = UPPER('$name')
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND table_owner = UPPER('$owner')
      ";
  }

  my $sql = _create_table_text( $stmt, $schema, $owner, $name, $view ) .
            "; \n\n" .
            _create_comments( $schema, $owner, $name, $view );

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql;
}

# sub _create_materialized_view
#
# Returns DDL to create the named materialized view
# by calling _create_mview (which is shared with
# _create_snapshot)
#
sub _create_materialized_view
{
  _create_mview( @_, 'MATERIALIZED VIEW' );
}

# sub _create_materialized_view_log
#
# Returns DDL to create the named materialized view log
# by calling _create_mview_log (which is shared with
# _create_snapshot_log)
#
sub _create_materialized_view_log
{
  _create_mview_log( @_, 'MATERIALIZED VIEW' );
}

# sub _create_mview
# 
# Returns DDL to create the named snapshot or materialized view
# in the form of:
#
#     CREATE {MATERIALIZED VIEW|SNAPSHOT} [schema.]<name>
#     <table properties>
#
sub _create_mview
{
  my ( $schema, $owner, $name, $view, $type ) = @_;

  my $sql;
  my $stmt;

  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              table_name
            , null                                     AS build_mode
            , null                                     AS refresh_method
            ,DECODE(
                     type
                    ,null,null
                    ,'REFRESH ' || type || CHR(10)
                   )                                   AS refresh_mode
            , TO_CHAR(start_with, 'DD-MON-YYYY HH24:MI:SS')
                                                       AS start_with
            , next
            , null                                     AS using_pk
            , null                                     AS master_rollback_seg
            , DECODE(
                      updatable
                     ,'TRUE','FOR UPDATE'
                     ,null
                    )                                  AS updatable
            , query
       FROM
             ${view}_snapshots
       WHERE
                  name  = UPPER( ? )
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
        "
              AND owner = UPPER('$owner')
        "
    }
  }
  elsif ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              table_name
            , null                                     AS build_mode
            , null                                     AS refresh_method
            ,DECODE(
                     type
                    ,null,null
                    ,'REFRESH ' || type || CHR(10)
                   )                                   AS refresh_mode
            , TO_CHAR(start_with, 'DD-MON-YYYY HH24:MI:SS')
                                                       AS start_with
            , next
            , DECODE(
                      refresh_method
                     ,'PRIMARY KEY','WITH  PRIMARY KEY'
                     ,'ROWID'      ,'WITH  ROWID'
                     ,null
                    )                                  AS using_pk
            , master_rollback_seg
            , DECODE(
                      updatable
                     ,'YES','FOR UPDATE'
                     ,null
                    )                                  AS updatable
            , query
       FROM
             ${view}_snapshots
       WHERE
                  name  = UPPER( ? )
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
        "
              AND owner = UPPER('$owner')
        "
    }
  }
  else
  {
    $stmt =
      "
       SELECT
              m.container_name
            , DECODE(
                      m.build_mode
                     ,'YES','USING PREBUILT TABLE'
                     ,DECODE(
                              m.last_refresh_date
                             ,null,'BUILD DEFERRED'
                             ,'BUILD IMMEDIATE'
                            )
                    ) || CHR(10)                       AS build_mode
            , DECODE(
                      m.refresh_method
                     ,'NEVER','NEVER REFRESH'
                     ,'REFRESH ' || m.refresh_method
                    )                                  AS refresh_method
            , DECODE(
                      m.refresh_mode
                     ,'NEVER',CHR(10)
                     ,'ON ' || m.refresh_mode || CHR(10)
                    )                                  AS refresh_mode
            , TO_CHAR(s.start_with, 'DD-MON-YYYY HH24:MI:SS')
                                                       AS start_with
            , s.next
            , DECODE(
                      s.refresh_method
                     ,'PRIMARY KEY','WITH  PRIMARY KEY'
                     ,'ROWID'      ,'WITH  ROWID'
                     ,null
                    )                                  AS using_pk
            , s.master_rollback_seg
            , DECODE(
                      m.updatable
                     ,'N',null
                     ,DECODE(
                              m.rewrite_enabled
                             ,'Y','FOR UPDATE ENABLE QUERY REWRITE'
                             ,'N','FOR UPDATE DISABLE QUERY REWRITE'
                            )
                    )                                  AS updatable
            , s.query
       FROM
              ${view}_mviews     m
            , ${view}_snapshots  s
       WHERE
                  m.mview_name  = UPPER( ? )
              AND s.name        = m.mview_name
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
        "
              AND m.owner       = UPPER('$owner')
              AND s.owner       = m.owner
        "
    }
  }

  $dbh->{ LongReadLen } = 65536;    # Allows Query to be 64K
  $dbh->{ LongTruncOk } = 1;

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  my $lctype = ( $type eq 'SNAPSHOT' ) ? 'Snapshpt' : 'Materialized View';
  die "\n$lctype \U$name \Ldoes not exist.\n\n" unless @row;

  my ( 
       $table, 
       $build_mode, 
       $refresh_method, 
       $refresh_mode,
       $start_with,
       $next,
       $using_pk,
       $master_rb_seg,
       $updatable,
       $query,
     ) = @row;

  $stmt =
      "
       SELECT
              index_name
       FROM
              ${view}_indexes
       WHERE
                  table_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner      = UPPER('$owner')
        "; }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $table );
  @row = $sth->fetchrow_array;

  my ( $index ) = @row;

  $sql  = "PROMPT " .
          "CREATE $type \L$schema$name\n\n" .
          "CREATE $type \L$schema$name  \n" .
          _create_mview_table( $owner, $owner, $table, $view ) .
          "$build_mode" .
          "USING INDEX\n" .
          _create_mview_index( $schema, $owner, $index, $view );

  $sql .= "$refresh_method "    if $refresh_method;

  $sql .= $refresh_mode;

  if ( $refresh_method ne 'NEVER REFRESH' )
  {
    $sql .= "START WITH TO_DATE('$start_with','DD-MON-YYYY HH24:MI:SS')\n"
      if $start_with;

    $sql .= "NEXT  $next\n"    if $next;

    $sql .= "$using_pk\n"      if $using_pk;

    $sql .= "USING MASTER ROLLBACK SEGMENT \L$master_rb_seg\n"
      if $master_rb_seg;
  }

  $sql .= "$updatable\n"     if $updatable;

  $sql .= "AS\n" . $query;

  $sql =~ s/\n+\Z//;

  $sql .= " ;\n\n";

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql;
}

# sub _create_mview_index
#
# Returns DDL for the USING INDEX definition part of:
#
#     CREATE MATERIALIZED VIEW
#     CREATE SNAPSHOT
#
# statements.  This is created by calling _create_index, and
# then stripping off the PROMPT and CREATE INDEX portions and the
# column list, leaving just the physical attributes and partitioning clauses
#
sub _create_mview_index
{
  # Snapshots don't use attributes PCTUSED and PCTFREE.
  # This will prevent sub _segment_attributes from including them.
  $isasnapindx = 1;

  my $done;
  my $started;
  my @lines_in = split /\n/, _create_index( @_ );
  my @lines_out;

  LINE:
    foreach my $line ( @lines_in )
    {
      # Ignore everything before the INITRANS clause.
      # This includes REMs, CREATE INDEX, columns, etc.
      $started++    if $line =~ /^INITRANS/;
      next LINE     if not $started;

      # Set $done when we hit a semicolon
      $done = $line =~ s/\;$//;

      # But keep everything in between except blank lines
      # and any [NO]LOGGINING clauses
      push @lines_out, $line    unless $line =~ /^$|LOGGING/;

      # Exit when we get to the semicolon and ignore the rest.
      # This eliminates the ';' and any COMMENTs.
      last LINE if $done;
    }

  my $sql = join "\n", @lines_out;
  
  $isasnapindx = 0;

  return $sql .  "\n";
}

# sub _create_mview_log
# 
# Returns DDL to create the named log (snapshot or materialized view)
# in the form of:
#
#     CREATE {MATERIALIZED VIEW|SNAPSHOT} LOG [schema.]<name>
#     <table properties>
#     WITH {PRIMARY KEY|ROWID|PRIMARY KEY, ROWID}
#     [<filter columns>]
#
sub _create_mview_log
{
  my ( $schema, $owner, $name, $view, $type ) = @_;

  my $sql;
  my $stmt =
      "
       SELECT
              log_table
            , rowids
            , primary_key
            , filter_columns
       FROM
              ${view}_snapshot_logs
       WHERE
                  master     = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND log_owner  = UPPER('$owner')
        "; }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  my $lctype = ( $type eq 'SNAPSHOT' ) ? 'Snapshpt' : 'Materialized View';
  die "\n$lctype Log on \U$name \Ldoes not exist.\n\n" unless @row;

  my ( $table, $rowids, $primary_key, $filter_columns, $refreshable ) = @row;

  $sql  = "PROMPT " .
          "CREATE $type LOG ON \L$schema$name\n\n" .
          "CREATE $type LOG ON \L$schema$name  \n" .
          _create_mview_table( $schema, $owner, $table, $view );

  if ( $rowids eq 'YES' and $primary_key eq 'YES' )
  {
    $sql .= "WITH PRIMARY KEY, ROWID "
  }
  elsif ( $rowids eq 'YES' )
  {
    $sql .= "WITH ROWID "
  }
  elsif ( $primary_key eq 'YES' )
  {
    $sql .= "WITH PRIMARY KEY "
  }

  $stmt =
      "
       SELECT
              column_name
       FROM
              dba_snapshot_log_filter_cols
       WHERE
                  name  = UPPER( ? )
              AND owner = UPPER( ? )
       MINUS
       SELECT
              column_name
       FROM
              ${view}_cons_columns  c
            , ${view}_constraints   d
       WHERE
                  d.table_name      = UPPER( ? )
              AND d.constraint_type = 'P'
              AND c.table_name      = d.table_name
              AND c.constraint_name = d.constraint_name
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND d.owner           = UPPER('$owner')
              AND c.owner           = d.owner
        "; }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, $owner, $name );
  my $aref = $sth->fetchall_arrayref;

  if ( @$aref )
  {

    my $comma  = '   ';
    $sql .= "\n(\n";

    foreach my $row ( @$aref )
    {
      $sql .= "$comma \L$row->[0]\n";
      $comma = '  ,'
    }

    $sql .= ") ";
  }

  return $sql .
         ";\n\n";
}

# sub _create_mview_table
#
# Returns DDL for the table definition part of:
#
#     CREATE MATERIALIZED VIEW
#     CREATE MATERIALIZED VIEW LOG
#     CREATE SNAPSHOT
#     CREATE SNAPSHOT LOG
#
# statements.  This is created by calling _create_table, and
# then stripping off the PROMPT and CREATE TABLE portions and the
# column list, leaving just the physical attributes and partitioning clauses
#
sub _create_mview_table
{
  # Snapshots and their logs don't use attribute INITRANS.
  # Prior to 8i, they don't use FREELISTS and FREELIST GROUPS, either.
  # This will prevent sub _segment_attributes from including it.
  $isasnaptabl = 1;

  my $done;
  my $started;
  my @lines_in = split /\n/, _create_table( @_ );
  my @lines_out;

  LINE:
    foreach my $line( @lines_in )
    {
      # Ignore everything before the PARALLEL clause.
      # This includes REMs, CREATE TABLE, column definitions, etc.
      $started++    if $line =~ /^PARALLEL/;
      next LINE     if not $started;

      # Set $done when we hit a semicolon
      $done = $line =~ s/\;$//;

      # But keep everything in between
      push @lines_out, $line    unless $line =~ /^$/;

      # Exit when we get to the semicolon and ignore the rest.
      # This eliminates the ';' and any COMMENTs.
      last LINE if $done;
    }

  my $sql = join "\n", @lines_out;
  
  $isasnaptabl = 0;

  return $sql .  "\n";
}

# sub _create_package
#
# Returns DDL to create the named package in the form of:
#
#     CREATE OR REPLACE PACKAGE [schema.]<name>
#     AS
#     <source>
# 
# by calling _display_source
#
sub _create_package
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql =  _display_source( $schema, $owner, $name, $view, 'PACKAGE' );

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql ;
}

# sub _create_package_body
#
# Returns DDL to create the named procedure in the form of:
#
#     CREATE OR REPLACE PACKAGE BODY [schema.]<name>
#     AS
#     <source>
# 
# by calling _display_source
#
sub _create_package_body
{
  return _display_source( @_, 'PACKAGE BODY' );
}

# sub _create_partitioned_index
#
# Creates the GLOBAL/LOCAL partition syntax part of a CREATE INDEX statement.
#
sub _create_partitioned_index
{
  my ( $schema, $owner, $name, $view, $sql ) = @_;

  my $stmt;

  if ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              -- 8.0 Indexes may partition only by RANGE
              i.partitioning_type
            , 'N/A'                         AS subpartitioning_type
            , i.locality
            , 0                             AS compressed
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , i.def_pct_free
            , DECODE(
                      i.def_ini_trans
                     ,0,1
                     ,null,1
                     ,i.def_ini_trans
                    )                       AS ini_trans
            , DECODE(
                      i.def_max_trans
                     ,0,255
                     ,null,255
                     ,i.def_max_trans
                    )                       AS max_trans
              -- Storage Clause
            ,DECODE(
                     i.def_initial_extent
                    ,'DEFAULT',s.initial_extent
                    ,i.def_initial_extent * $block_size * 1024
                   )                        AS initial_extent
            ,DECODE(
                     i.def_next_extent
                    ,'DEFAULT',s.next_extent
                    ,i.def_next_extent * $block_size * 1024
                   )                        AS next_extent
            , DECODE(
                      i.def_min_extents
                     ,'DEFAULT',s.min_extents
                     ,i.def_min_extents
                    )                       AS min_extents
            , DECODE(
                      i.def_max_extents
                     ,'DEFAULT',DECODE(
                                        s.max_extents
                                       ,2147483645,'unlimited'
                                       ,s.max_extents
                                      )
                     ,2147483645,'unlimited'
                     ,i.def_max_extents
                    )                       AS max_extents
            , DECODE(
                      i.def_pct_increase
                     ,'DEFAULT',s.pct_increase
                     ,i.def_pct_increase
                    )                       AS pct_increase
            , DECODE(
                      i.def_freelists
                     ,0,1
                     ,null,1
                     ,i.def_freelists
                    )                       AS freelists
            , DECODE(
                      i.def_freelist_groups
                     ,0,1
                     ,null,1
                     ,i.def_freelist_groups
                    )                       AS freelist_groups
            , 'N/A'                         AS buffer_pool
            , DECODE(
                      i.def_logging
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(NVL(i.def_tablespace_name,s.tablespace_name))
              -- Don't have default blocks, so use larger of initial/next
            , GREATEST(
                        DECODE(
                                i.def_initial_extent
                               ,'DEFAULT',s.initial_extent / $block_size / 1024
                               ,i.def_initial_extent
                              )
                       ,DECODE(
                                i.def_next_extent
                               ,'DEFAULT',s.next_extent / $block_size / 1024
                               ,i.def_next_extent
                              )
                      )                     AS blocks
       FROM
              ${view}_part_indexes  i
            , ${view}_indexes       n
            , ${view}_tablespaces   s
            , ${view}_part_tables   t
       WHERE
                  -- def_tablspace is sometimes NULL in PART_INDEXES,
                  -- we'll have to go over to the table for the defaults
                  i.index_name      = UPPER( ? )
              AND n.index_name      = UPPER( ? )
              AND t.table_name      = n.table_name
              AND s.tablespace_name = t.def_tablespace_name
      ";
  }
  else               # We're Oracle8i or newer
  {
    $stmt =
      "
       SELECT
              -- Indexes may partition only by RANGE or RANGE/HASH
              i.partitioning_type
            , i.subpartitioning_type
            , i.locality
            , DECODE(
                      n.compression
                     ,'ENABLED',n.prefix_length
                     ,0
                    )                             AS compressed
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , i.def_pct_free
            , DECODE(
                      i.def_ini_trans
                     ,0,1
                     ,null,1
                     ,i.def_ini_trans
                    )                       AS ini_trans
            , DECODE(
                      i.def_max_trans
                     ,0,255
                     ,null,255
                     ,i.def_max_trans
                    )                       AS max_trans
              -- Storage Clause
            ,DECODE(
                     i.def_initial_extent
                    ,'DEFAULT',s.initial_extent
                    ,i.def_initial_extent * $block_size * 1024
                   )                        AS initial_extent
            ,DECODE(
                     i.def_next_extent
                    ,'DEFAULT',s.next_extent
                    ,i.def_next_extent * $block_size * 1024
                   )                        AS next_extent
            , DECODE(
                      i.def_min_extents
                     ,'DEFAULT',s.min_extents
                     ,i.def_min_extents
                    )                       AS min_extents
            , DECODE(
                      i.def_max_extents
                     ,'DEFAULT',DECODE(
                                        s.max_extents
                                       ,2147483645,'unlimited'
                                       ,s.max_extents
                                      )
                     ,2147483645,'unlimited'
                     ,i.def_max_extents
                    )                       AS max_extents
            , DECODE(
                      i.def_pct_increase
                     ,'DEFAULT',s.pct_increase
                     ,i.def_pct_increase
                    )                       AS pct_increase
            , DECODE(
                      i.def_freelists
                     ,0,1
                     ,null,1
                     ,i.def_freelists
                    )                       AS freelists
            , DECODE(
                      i.def_freelist_groups
                     ,0,1
                     ,null,1
                     ,i.def_freelist_groups
                    )                       AS freelist_groups
            , LOWER(i.def_buffer_pool)        AS buffer_pool
            , DECODE(
                      i.def_logging
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(NVL(i.def_tablespace_name,s.tablespace_name))
              -- Don't have default blocks, so use larger of initial/next
            , GREATEST(
                        DECODE(
                                i.def_initial_extent
                               ,'DEFAULT',s.initial_extent / $block_size / 1024
                               ,i.def_initial_extent
                              )
                       ,DECODE(
                                i.def_next_extent
                               ,'DEFAULT',s.next_extent / $block_size / 1024
                               ,i.def_next_extent
                              )
                      )                     AS blocks
       FROM
              ${view}_part_indexes  i
            , ${view}_indexes       n
            , ${view}_tablespaces   s
            , ${view}_part_tables   t
       WHERE
                  -- def_tablspace is sometimes NULL in PART_INDEXES,
                  -- we'll have to go over to the table for the defaults
                  i.index_name      = UPPER( ? )
              AND n.index_name      = UPPER( ? )
              AND t.table_name      = i.table_name
              AND s.tablespace_name = t.def_tablespace_name
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND i.owner           = UPPER('$owner')
              AND n.owner           = UPPER('$owner')
              AND t.owner           = UPPER('$owner')
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, $name );
  my @row = $sth->fetchrow_array;

  my $partitioning_type      = shift @row;
  my $subpartitioning_type   = shift @row;
  my $locality               = shift @row;
  my $compressed             = shift @row;

  unshift @row, ( '' );    #indent (none)

  $sql .= _segment_attributes( \@row );

  if ( $compressed )
  {
    $sql .= "COMPRESS            $compressed\n";
  }

  if ( $locality eq 'GLOBAL' )
  {
    $sql .= "GLOBAL PARTITION BY RANGE\n" . # Only RANGE on global indexes
            "(\n    " .
            _partition_key_columns( $owner, $name, 'INDEX', $view ) .
            "\n)\n" .
            _range_partitions($owner, $name, $view,
                              $subpartitioning_type, 'GLOBAL' );
  }
  else     # Must be partitione by RANGE or RANGE/HASH
  {
    $sql .= "LOCAL\n";

    if ( $partitioning_type eq 'RANGE' )
    {
      $sql .= _range_partitions( $owner, $name, $view,
                                 $subpartitioning_type, 'LOCAL' );
    }
  }

  return $sql;
}

# sub _create_partitioned_iot
#
# Returns DDL to create the partitioned index organized table 
# and its partition(s).
# See _create_table for format.
#
sub _create_partitioned_iot
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $stmt;

  if ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              'N/A'                         AS monitoring
            , t.table_name
              -- Parallel Clause
            , LTRIM(t.degree)               AS degree
            , LTRIM(t.instances)            AS instances
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , DECODE(
                      LTRIM(t.cache)
                     ,'Y','CACHE'
                     ,    'NOCACHE'
                    )                       AS cache
            , 'N/A'                         AS pct_used
            , p.def_pct_free                AS pct_free
            , p.def_ini_trans               AS ini_trans
            , p.def_max_trans               AS max_trans
              -- Storage Clause
            ,DECODE(
                     p.def_initial_extent
                    ,'DEFAULT',s.initial_extent
                    ,p.def_initial_extent * $block_size * 1024
                   )                        AS initial_extent
            ,DECODE(
                     p.def_next_extent
                    ,'DEFAULT',s.next_extent
                    ,p.def_next_extent * $block_size * 1024
                   )                        AS next_extent
            , DECODE(
                      p.def_min_extents
                     ,'DEFAULT',s.min_extents
                     ,p.def_min_extents
                    )                       AS min_extents
            , DECODE(
                      p.def_max_extents
                     ,'DEFAULT',DECODE(
                                        s.max_extents
                                       ,2147483645,'unlimited'
                                       ,s.max_extents
                                      )
                     ,2147483645,'unlimited'
                     ,p.def_max_extents
                    )                       AS max_extents
            , DECODE(
                      p.def_pct_increase
                     ,'DEFAULT',s.pct_increase
                     ,p.def_pct_increase
                    )                       AS pct_increase
            , DECODE(
                      p.def_freelists
                     ,0,1
                     ,NVL(p.def_freelists,1)
                    )                       AS freelists
            , DECODE(
                      p.def_freelist_groups
                     ,0,1
                     ,NVL(p.def_freelist_groups,1)
                    )                       AS freelist_groups
            , 'N/A'                         AS buffer_pool
            , DECODE(
                      p.def_logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(p.def_tablespace_name)  AS tablespace_name
            , t.blocks - NVL(t.empty_blocks,0)
       FROM
              ${view}_all_tables    t
            , ${view}_part_indexes  p
            , ${view}_tablespaces   s
       WHERE
                  t.table_name      = UPPER('$name')
              AND p.table_name      = t.table_name
              AND s.tablespace_name = p.def_tablespace_name
      ";
  }
  else               # We're Oracle8i or newer
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              DECODE(
                      t.monitoring
                     ,'NO','NOMONITORING'
                     ,     'MONITORING'
                    )                       AS monitoring
            , t.table_name
              -- Parallel Clause
            , LTRIM(t.degree)               AS degree
            , LTRIM(t.instances)            AS instances
              -- Physical Properties
            , 'INDEX'                       AS organization
              -- Segment Attributes
            , DECODE(
                      LTRIM(t.cache)
                     ,'Y','CACHE'
                     ,    'NOCACHE'
                    )                       AS cache
            , 'N/A'                         AS pct_used
            , p.def_pct_free                AS pct_free
            , p.def_ini_trans               AS ini_trans
            , p.def_max_trans               AS max_trans
              -- Storage Clause
            ,DECODE(
                     p.def_initial_extent
                    ,'DEFAULT',s.initial_extent
                    ,p.def_initial_extent * $block_size * 1024
                   )                        AS initial_extent
            ,DECODE(
                     p.def_next_extent
                    ,'DEFAULT',s.next_extent
                    ,p.def_next_extent * $block_size * 1024
                   )                        AS next_extent
            , DECODE(
                      p.def_min_extents
                     ,'DEFAULT',s.min_extents
                     ,p.def_min_extents
                    )                       AS min_extents
            , DECODE(
                      p.def_max_extents
                     ,'DEFAULT',DECODE(
                                        s.max_extents
                                       ,2147483645,'unlimited'
                                       ,s.max_extents
                                      )
                     ,2147483645,'unlimited'
                     ,p.def_max_extents
                    )                       AS max_extents
            , DECODE(
                      p.def_pct_increase
                     ,'DEFAULT',s.pct_increase
                     ,p.def_pct_increase
                    )                       AS pct_increase
            , DECODE(
                      p.def_freelists
                     ,0,1
                     ,NVL(p.def_freelists,1)
                    )                       AS freelists
            , DECODE(
                      p.def_freelist_groups
                     ,0,1
                     ,NVL(p.def_freelist_groups,1)
                    )                       AS freelist_groups
            , LOWER(p.def_buffer_pool)      AS buffer_pool
            , DECODE(
                      p.def_logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(p.def_tablespace_name)  AS tablespace_name
            , t.blocks - NVL(t.empty_blocks,0)
       FROM
              ${view}_all_tables    t
            , ${view}_part_indexes  p
            , ${view}_tablespaces   s
       WHERE
                  t.table_name      = UPPER('$name')
              AND p.table_name      = t.table_name
              AND s.tablespace_name = p.def_tablespace_name
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND t.owner           = UPPER('$owner')
              AND p.owner           = t.owner 
      ";
  }

  my $sql = _create_table_text( $stmt, $schema, $owner, $name, $view );

  $stmt =
      "
       SELECT
              constraint_name
       FROM
              ${view}_constraints
       WHERE
                  table_name      = UPPER( ? )
              AND constraint_type = 'P'
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner           = UPPER('$owner')
      ";
  }

  my $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my ( $index ) = $sth->fetchrow_array;

  $sql .= "PARTITION BY RANGE\n" .  # Only RANGE allowed on IOT's
          "(\n    " .
          _partition_key_columns( $owner, $name, 'TABLE', $view ) .
          "\n)\n" .
          _range_partitions( $owner, $index, $view, 'NONE', 'IOT' ) .
          _create_comments( $schema, $owner, $name, $view );

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql;
}

# sub _create_partitioned_table
#
# Returns DDL to create the partitioned table and its partition(s).
# See _create_table for format.
#
sub _create_partitioned_table
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $stmt;

  if ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              'N/A'                         AS monitoring
            , t.table_name
              -- Parallel Clause
            , LTRIM(t.degree)               AS degree
            , LTRIM(t.instances)            AS instances
              -- Physical Properties
            , DECODE(
                      t.iot_type
                     ,'IOT','INDEX'
                     ,      'HEAP'
                    )                       AS organization
              -- Segment Attributes
            , DECODE(
                      LTRIM(t.cache)
                     ,'Y','CACHE'
                     ,    'NOCACHE'
                    )                       AS cache
            , p.def_pct_used
            , p.def_pct_free                AS pct_free
            , p.def_ini_trans               AS ini_trans
            , p.def_max_trans               AS max_trans
              -- Storage Clause
            ,DECODE(
                     p.def_initial_extent
                    ,'DEFAULT',s.initial_extent
                    ,p.def_initial_extent * $block_size * 1024
                   )                        AS initial_extent
            ,DECODE(
                     p.def_next_extent
                    ,'DEFAULT',s.next_extent
                    ,p.def_next_extent * $block_size * 1024
                   )                        AS next_extent
            , DECODE(
                      p.def_min_extents
                     ,'DEFAULT',s.min_extents
                     ,p.def_min_extents
                    )                       AS min_extents
            , DECODE(
                      p.def_max_extents
                     ,'DEFAULT',DECODE(
                                        s.max_extents
                                       ,2147483645,'unlimited'
                                       ,s.max_extents
                                      )
                     ,2147483645,'unlimited'
                     ,p.def_max_extents
                    )                       AS max_extents
            , DECODE(
                      p.def_pct_increase
                     ,'DEFAULT',s.pct_increase
                     ,p.def_pct_increase
                    )                       AS pct_increase
            , DECODE(
                      p.def_freelists
                     ,0,1
                     ,NVL(p.def_freelists,1)
                    )                       AS freelists
            , DECODE(
                      p.def_freelist_groups
                     ,0,1
                     ,NVL(p.def_freelist_groups,1)
                    )                       AS freelist_groups
            , 'N/A'                         AS buffer_pool
            , DECODE(
                      p.def_logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(p.def_tablespace_name)  AS tablespace_name
            , t.blocks - NVL(t.empty_blocks,0)
       FROM
              ${view}_all_tables   t
            , ${view}_part_tables  p
            , ${view}_tablespaces  s
       WHERE
                  t.table_name      = UPPER('$name')
              AND p.table_name      = t.table_name
              AND s.tablespace_name = p.def_tablespace_name
      ";
  }
  else               # We're Oracle8i or newer
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              DECODE(
                      t.monitoring
                     ,'NO','NOMONITORING'
                     ,     'MONITORING'
                    )                       AS monitoring
            , t.table_name
              -- Parallel Clause
            , LTRIM(t.degree)               AS degree
            , LTRIM(t.instances)            AS instances
              -- Physical Properties
            , DECODE(
                      t.iot_type
                     ,'IOT','INDEX'
                     ,      'HEAP'
                    )                       AS organization
              -- Segment Attributes
            , DECODE(
                      LTRIM(t.cache)
                     ,'Y','CACHE'
                     ,    'NOCACHE'
                    )                       AS cache
            , p.def_pct_used
            , p.def_pct_free                AS pct_free
            , p.def_ini_trans               AS ini_trans
            , p.def_max_trans               AS max_trans
              -- Storage Clause
            ,DECODE(
                     p.def_initial_extent
                    ,'DEFAULT',s.initial_extent
                    ,p.def_initial_extent * $block_size * 1024
                   )                        AS initial_extent
            ,DECODE(
                     p.def_next_extent
                    ,'DEFAULT',s.next_extent
                    ,p.def_next_extent * $block_size * 1024
                   )                        AS next_extent
            , DECODE(
                      p.def_min_extents
                     ,'DEFAULT',s.min_extents
                     ,p.def_min_extents
                    )                       AS min_extents
            , DECODE(
                      p.def_max_extents
                     ,'DEFAULT',DECODE(
                                        s.max_extents
                                       ,2147483645,'unlimited'
                                       ,s.max_extents
                                      )
                     ,2147483645,'unlimited'
                     ,p.def_max_extents
                    )                       AS max_extents
            , DECODE(
                      p.def_pct_increase
                     ,'DEFAULT',s.pct_increase
                     ,p.def_pct_increase
                    )                       AS pct_increase
            , DECODE(
                      p.def_freelists
                     ,0,1
                     ,NVL(p.def_freelists,1)
                    )                       AS freelists
            , DECODE(
                      p.def_freelist_groups
                     ,0,1
                     ,NVL(p.def_freelist_groups,1)
                    )                       AS freelist_groups
            , LOWER(p.def_buffer_pool)      AS buffer_pool
            , DECODE(
                      p.def_logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(p.def_tablespace_name)  AS tablespace_name
            , t.blocks - NVL(t.empty_blocks,0)
       FROM
              ${view}_all_tables   t
            , ${view}_part_tables  p
            , ${view}_tablespaces  s
       WHERE
                  t.table_name      = UPPER('$name')
              AND p.table_name      = t.table_name
              AND s.tablespace_name = p.def_tablespace_name
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND t.owner           = UPPER('$owner')
              AND p.owner           = t.owner 
      ";
  }

  my $sql = _create_table_text( $stmt, $schema, $owner, $name, $view );

  $sql =~ /ORGANIZATION\s+(\w+)/gm;
  my $organization = $1;

  if ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              partitioning_type
            , partition_count
            , 'N/A'                        AS subpartitioning_type
            , 'N/A'                        AS def_subpartition_count
       FROM
              ${view}_part_tables
       WHERE
                  table_name = UPPER( ? )
      ";
  }
  else               # We're Oracle8i or newer
  {
    $stmt =
      "
       SELECT
              partitioning_type
            , partition_count
            , subpartitioning_type
            , def_subpartition_count
       FROM
              ${view}_part_tables
       WHERE
                  table_name = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner      = UPPER('$owner')
      ";
  }

  my $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my (
       $partitioning_type,
       $partition_count,
       $subpartitioning_type,
       $subpartition_count
      ) = $sth->fetchrow_array;

  $sql .= "PARTITION BY $partitioning_type\n" .
          "(\n    " .
          _partition_key_columns( $owner, $name, 'TABLE', $view ) .
          "\n)\n";

  if ( $partitioning_type eq 'RANGE' )
  {
    if ( $subpartitioning_type eq 'HASH' )
    {
      $sql .= "SUBPARTITION BY HASH\n" .
              "(\n    " .
              _subpartition_key_columns( $owner, $name, 'TABLE', $view ) .
              "\n)\n" .
              "SUBPARTITIONS $subpartition_count" .
              "\n";
    }

    $sql .= "(\n";

    if ( $oracle_major == 8 and $oracle_minor == 0 )
    {
       $stmt =
      "
       SELECT
              partition_name
            , high_value
            , 'N/A'
            , pct_used
            , pct_free
            , ini_trans
            , max_trans
              -- Storage Clause
            , initial_extent
            , next_extent
            , min_extent
            , DECODE(
                      max_extent
                     ,2147483645,'unlimited'
                     ,           max_extent
                    )                       AS max_extents
            , pct_increase
            , NVL(freelists,1)
            , NVL(freelist_groups,1)
            , 'N/A'                         AS buffer_pool
            , DECODE(
                      logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(tablespace_name)
            , blocks - NVL(empty_blocks,0)
       FROM
              ${view}_tab_partitions
       WHERE
                  table_name =  UPPER( ? )
      ";
    }
    else               # We're Oracle8i or newer
    {
      $stmt =
      "
       SELECT
              partition_name
            , high_value
            , 'N/A'
            , pct_used
            , pct_free
            , ini_trans
            , max_trans
              -- Storage Clause
            , initial_extent
            , next_extent
            , min_extent
            , DECODE(
                      max_extent
                     ,2147483645,'unlimited'
                     ,           max_extent
                    )                       AS max_extents
            , pct_increase
            , NVL(freelists,1)
            , NVL(freelist_groups,1)
            , LOWER(buffer_pool)
            , DECODE(
                      logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(tablespace_name)
            , blocks - NVL(empty_blocks,0)
       FROM
              ${view}_tab_partitions
       WHERE
                  table_name =  UPPER( ? )
      ";
    }

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND table_owner = UPPER('$owner')
      ";
    }

    $stmt .=
      "
       ORDER
          BY
              partition_name
      ";

    $dbh->{ LongReadLen } = 8192;    # Allows HIGH_VALUE length of 8K
    $dbh->{ LongTruncOk } = 1;

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my $aref = $sth->fetchall_arrayref;

    my $comma = '    ';

    foreach my $row ( @$aref )
    {
      my $partition  = shift @$row;
      my $high_value = shift @$row;

      $sql .= "${comma}PARTITION \L$partition \UVALUES LESS THAN\n" .
              "      (\n" .
              "        $high_value\n" .
              "      )\n";

      unshift @$row, ( '      ', $organization );

      $sql .= _segment_attributes( $row );

      $comma = '  , ';

      if ( $subpartitioning_type eq 'HASH' )
      {
        $stmt =
          "
           SELECT
                  subpartition_name
                , tablespace_name
           FROM
                  ${view}_tab_subpartitions
           WHERE
                      table_name     =  UPPER( ? )
                  AND partition_name = '$partition'
          ";

        if ( $view eq 'DBA' )
        {
          $stmt .=
          "
                  AND table_owner    = UPPER('$owner')
          ";
        }

        $stmt .=
          "
           ORDER
              BY
                  subpartition_name
          ";

        $sth = $dbh->prepare( $stmt );
        $sth->execute( $name );
        my $aref = $sth->fetchall_arrayref;

        $sql .= "        (\n            ";

        my @cols;
        foreach my $row ( @$aref )
        {
          push @cols, "SUBPARTITION \L$row->[0] \UTABLESPACE \L$row->[1]";
        }
        $sql .= join ( "\n          , ", @cols );

        $sql .= "\n        )\n";
      }
    }
    $sql .= ");\n\n";
  }
  else   # It's HASH partitioning
  {
    $sql .= "(\n    ";

    $stmt =
      "
       SELECT
              partition_name
            , tablespace_name
       FROM
              ${view}_tab_partitions
       WHERE
                  table_name =  UPPER( ? )
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND table_owner= UPPER('$owner')
      ";
    }

    $stmt .=
      "
       ORDER
          BY
              partition_name
      ";

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my $aref = $sth->fetchall_arrayref;

    my @cols;
    foreach my $row ( @$aref )
    {
      push @cols, "PARTITION \L$row->[0] \UTABLESPACE \L$row->[1]";
    }
    $sql .= join ( "\n  , ", @cols );

    $sql .= "\n) ;\n\n";
  }

  $sql .= _create_comments( $schema, $owner, $name, $view );

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql ;
}

# sub _create_procedure
#
# Returns DDL to create the named procedure in the form of:
#
#     CREATE OR REPLACE PROCEDURE [schema.]<name>
#     AS
#     <source>
# 
# by calling _display_source
#
sub _create_procedure
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql =  _display_source( $schema, $owner, $name, $view, 'PROCEDURE' );

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql ;
}

# sub _create_profile
#
# Returns DDL to create the named profile in the form of:
#
#     CREATE PROFILE <name>
#     LIMIT
#       SESSIONS_PER_USER   <value>
#       CPU_PER_SESSION     <value>
#       CPU_PER_CALL        <value>
#       etc
#
sub _create_profile
{
  my ( $schema, $owner, $name, $view ) = @_;

  $sth = $dbh->prepare(
      "
       SELECT
              RPAD(resource_name,27)
            , DECODE(
                      RESOURCE_NAME
                     ,'PASSWORD_VERIFY_FUNCTION',DECODE(
                                                         limit
                                                        ,'UNLIMITED','null'
                                                        ,LOWER(limit)
                                                       )
                     ,                           LOWER(limit)
                    )
       FROM
              dba_profiles
       WHERE
              profile = UPPER( ? )
       ORDER
          BY
              DECODE(
                      SUBSTR(resource_name,1,8)
                     ,'FAILED_L',2
                     ,'PASSWORD',2
                     ,1
                    )
            , resource_name
      ");

  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;
  die "\nProfile '\U$name' \Ldoes not exist.\n\n" unless @$aref;

  my $sql = "PROMPT " .
            "CREATE PROFILE \L$name\n\n" .
            "CREATE PROFILE \L$name\n" .
            "LIMIT\n";

  foreach my $row ( @$aref )
  {
    $sql .= "   $row->[0]$row->[1]\n";
  }

  $sql .= ";\n\n";

  return $sql;
}

# sub _create_role
#
# Returns DDL to create the named role in the form of:
#
#     CREATE ROLE <name> IDENTIFIED {EXTERNALLY|BY VALUES '<values>'}
#     or
#     CREATE ROLE <name> NOT IDENTIFIED
# 
sub _create_role
{
  my ( $schema, $owner, $name, $view ) = @_;

  die "\nYou must use the DBA views in order to CREATE ROLE\n\n"
      unless $view eq 'DBA';

  my $stmt =
      "
       SELECT
              DECODE(
                      r.password_required
                     ,'YES', DECODE(
                                     u.password
                                    ,'EXTERNAL','IDENTIFIED EXTERNALLY'
                                    ,'IDENTIFIED BY VALUES ''' 
                                      || u.password || ''''
                                   )
                     ,'NOT IDENTIFIED'
                    )                         AS password
       FROM
              dba_roles   r
            , sys.user\$  u
       WHERE
                  r.role = UPPER( ? )
              AND u.name = UPPER( ? )
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, $name );
  my @row = $sth->fetchrow_array;
  die "\nRole \U$name \Ldoes not exist.\n\n" unless @row;

  my ( $password ) = @row;

  my $sql  =
          "PROMPT " .
          "CREATE ROLE \L$name\n\n" .
          "CREATE ROLE \L$name \U$password;\n\n";

  $sql .= _granted_privs( $name );

  return $sql;
}

# sub _create_rollback_segment
#
# Returns DDL to create the named rollback segment in the form of:
#
#     CREATE [PUBLIC] ROLLBACK SEGMENT <name>
#     STORAGE
#     (
#       storage clause
#     )
#     TABLESPACE tablespace
#
sub _create_rollback_segment
{
  my ( $schema, $owner, $name, $view ) = @_;

  $sth = $dbh->prepare(
      "
       SELECT
              DECODE(
                      r.owner
                     ,'PUBLIC',' PUBLIC '
                     ,         ' '
                    )                                  AS is_public
            , r.tablespace_name
            , NVL(r.initial_extent,t.initial_extent)   AS initial_extent
            , NVL(r.next_extent,t.next_extent)         AS next_extent
            , r.min_extents
            , DECODE(
                      r.max_extents
                     ,2147483645,'unlimited'
                     ,           r.max_extents
                    )                                  AS max_extents
       FROM
              dba_rollback_segs    r
            , ${view}_tablespaces  t
       WHERE
                  r.segment_name    = UPPER( ? )
              AND t.tablespace_name = r.tablespace_name
      ");

  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  die "\nRollback Segment '\U$name' \Ldoes not exist.\n\n" unless @row;

  my (
       $is_public,
       $tablespace_name,
       $initial_extent,
       $next_extent,
       $min_extents,
       $max_extents,
     ) = @row;

  return "PROMPT " .
         "CREATE${is_public}ROLLBACK SEGMENT \L$name\n\n" .
         "CREATE${is_public}ROLLBACK SEGMENT \L$name\n" .
         "STORAGE\n" .
         "(\n" .
         "  INITIAL      $initial_extent\n" .
         "  NEXT         $next_extent\n" .
         "  MINEXTENTS   $min_extents\n" .
         "  MAXEXTENTS   $max_extents\n" .
         ")\n" .
         "TABLESPACE     \L$tablespace_name\n" .
         ";\n\n" ; 
}

# sub _create_schema
#
# Returns DDL to create all objects of the following type:
#
#     TYPE
#     TABLE
#     INDEX
#     CONSTRAINT
#     TRIGGER
#     VIEW
#     SNAPSHOT
#     SNAPSHOT LOG
#     SYNONYM
#     DATABASE LINK
#     FUNCTION
#     PROCEDURE
#     PACKAGE
#     PACKAGE BODY
#     SEQUENCE
# 
sub _create_schema
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql;
  my $aref;
  my $stmt;

  #
  # Start with schema's types (they may be a data type in CREATE TABLE)
  #
  $stmt =
      "
       SELECT
              object_name
       FROM
              ${view}_objects
       WHERE
                  object_type = 'TYPE'
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner       = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              object_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_type( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's tables
  #
  $stmt =
      "
       SELECT
              table_name
       FROM
              ${view}_tables
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE
              owner = UPPER('$owner')
      ";
  }

  if ( $oracle_major > 7 )
  {
    $stmt .=
      "
       MINUS
       SELECT
              table_name
       FROM
              ${view}_tables
       WHERE
                  iot_type = 'IOT_OVERFLOW'
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
        "
              AND owner    = UPPER('$owner')
        ";
    }
  }

  $stmt .=
      "
       MINUS
       SELECT
              log_table
       FROM
              ${view}_snapshot_logs
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE  log_owner  = UPPER('$owner')
      ";
  }

  $stmt .=
      "
       MINUS
       SELECT
              table_name
       FROM
              ${view}_snapshots
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE
              owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              1
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_table( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's indexes
  #

  # If we're an IOT (Oracle8 or newer), skip the PK index
  # because it was in the CREATE TABLE

  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              index_name
       FROM
              ${view}_indexes  i
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
       WHERE
              i.table_owner = UPPER('$owner')
      ";
    }
  }
  else   # we're Oracle8 or newer
  {
  $stmt =
      "
       SELECT
              index_name
       FROM
              ${view}_indexes  i
            , ${view}_tables   t
       WHERE
                  i.table_owner = UPPER('$owner')
              AND t.table_name  = i.table_name
              AND (
                       t.iot_type <> 'IOT'
                    OR (
                         NOT EXISTS (
                                      SELECT
                                             null
                                      FROM
                                             ${view}_constraints
                                      WHERE
                                                 constraint_type = 'P'
                                             AND constraint_name =
                                                 i.index_name
                                             AND owner           =
                                                 i.table_owner
                                    )
                       )
                  )
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND t.owner       = i.table_owner
      ";
    }
  }

  $stmt .= 
      "
       ORDER
          BY
              i.table_name
            , i.index_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_index( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's constraints
  #

  # If we're an IOT (Oracle8 or newer), skip the PK constraint
  # because it was in the CREATE TABLE

  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              c.constraint_name
            , c.constraint_type
            , c.search_condition
       FROM
              ${view}_constraints  c
       WHERE
                  constraint_type IN('P','U','R','C')
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND c.owner = UPPER('$owner')
      ";
    }
  }
  else   # we're Oracle8 or newer
  {
    $stmt =
      "
       SELECT
              c.constraint_name
            , c.constraint_type
            , c.search_condition
       FROM
              ${view}_constraints  c
            , ${view}_tables       t
       WHERE
                  t.table_name = c.table_name
              AND (
                       (
                             (
                                  t.iot_type <> 'IOT'
                               OR t.iot_type IS NULL
                             )
                         AND c.constraint_type IN('P','U','R','C')
                       )
                    OR (
                             t.iot_type         = 'IOT'
                         AND c.constraint_type IN ('U','R','C')
                       )
                  )
              AND NOT EXISTS (
                               SELECT
                                      null
                               FROM
                                      ${view}_snapshot_logs
                               WHERE
                                          log_table = c.table_name
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
                                      AND log_owner = c.owner
      ";
    }

    $stmt .=
      "
                             )
              AND NOT EXISTS (
                               SELECT
                                      null
                               FROM
                                      ${view}_snapshots
                               WHERE
                                          table_name = c.table_name
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
                                      AND owner      = c.owner
      ";
    }

    $stmt .=
      "
                             )
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND c.owner      = UPPER('$owner')
              AND t.owner      = c.owner
      ";
    }
  }

  $stmt .=
      "
       ORDER
          BY
              DECODE(
                      c.constraint_type
                     ,'P',1
                     ,'U',2
                     ,'R',3
                     ,'C',4
                    )
            , c.table_name
            , c.constraint_name
      ";

  $dbh->{ LongReadLen } = 8192;    # Allows SEARCH_CONDITION length of 8K
  $dbh->{ LongTruncOk } = 1;

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    my ( $cons_name, $cons_type, $condition ) = @$row;

    if ( $cons_type ne 'C' )
    {
      $sql .= _create_constraint( $schema, $owner, $cons_name, $view );
    }
    elsif ( $condition !~ /IS NOT NULL/ )
    {
      $sql .= _create_constraint( $schema, $owner, $cons_name, $view );
    }
  }

  #
  # Add schema's triggers
  #
  $stmt =
      "
       SELECT
              trigger_name
       FROM
              ${view}_triggers
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE
              table_owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              table_name
            , trigger_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_trigger( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's views
  #
  $stmt =
      "
       SELECT
              view_name
       FROM
              ${view}_views
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE
              owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              view_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_view( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's snapshot logs
  #
  $stmt =
      "
       SELECT
              master
       FROM
              ${view}_snapshot_logs
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE  log_owner  = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              master
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_snapshot_log( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's snapshots
  #
  $stmt =
      "
       SELECT
              name
       FROM
              ${view}_snapshots
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE
              owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_snapshot( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's synonyms
  #
  $stmt =
      "
       SELECT
              synonym_name
       FROM
              ${view}_synonyms
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE
              owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              synonym_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_synonym( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's database links
  #
  $stmt =
      "
       SELECT
              db_link
       FROM
              ${view}_db_links
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE
              owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              db_link
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_db_link( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's functions
  #
  $stmt =
      "
       SELECT
              object_name
       FROM
              ${view}_objects
       WHERE
                  object_type = 'FUNCTION'
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner       = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              object_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_function( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's procedures
  #
  $stmt =
      "
       SELECT
              object_name
       FROM
              ${view}_objects
       WHERE
                  object_type = 'PROCEDURE'
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner       = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              object_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_procedure( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's packages
  #
  $stmt =
      "
       SELECT
              object_name
       FROM
              ${view}_objects
       WHERE
                  object_type = 'PACKAGE'
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner       = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              object_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_package( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's package bodies
  #
  $stmt =
      "
       SELECT
              object_name
       FROM
              ${view}_objects
       WHERE
                  object_type = 'PACKAGE BODY'
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner       = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              object_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_package_body( $schema, $owner, @$row->[0], $view );
  }

  #
  # Add schema's sequences
  #
  $stmt =
      "
       SELECT
              sequence_name
       FROM
              ${view}_sequences
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
       WHERE
              sequence_owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
              sequence_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_sequence( $schema, $owner, @$row->[0], $view );
  }

  $sql .= "PROMPT Recompile schema \U$owner\n\n" .
          "BEGIN dbms_utility.compile_schema('\U$owner') ; END ;\n/\n\n"
      unless $schema eq 'PUBLIC';

  return $sql;
}

# sub _create_sequence
#
# Returns DDL to create the named sequence in the form of:
#
#     CREATE SEQUENCE [schema.]<name>
#        START WITH     <integer>
#        INCREMENT BY   <integer>
#        [NO]MINVALUE   <integer>
#        [NO]MAXVALUE   <integer>
#        [NO]CACHE      <integer>
#        [NO]CYCLE
#        [NO]ORDER
# 
sub _create_sequence
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $stmt =
      "
       SELECT
              'START WITH       '
               || LTRIM(TO_CHAR(last_number + cache_size,'fm999999999'))
                                               AS start_with
            , 'INCREMENT BY     '
               || LTRIM(TO_CHAR(increment_by,'fm999999999')) AS imcrement_by
            , DECODE(
                      min_value
                     ,0,'NOMINVALUE'
                     ,'MINVALUE         ' || TO_CHAR(min_value)
                    )                          AS min_value
            , DECODE(
                      TO_CHAR(max_value,'fm999999999999999999999999999')
                     ,'999999999999999999999999999','NOMAXVALUE'
                     ,'MAXVALUE         ' || TO_CHAR(max_value)
                    )                          AS max_value
            , DECODE(
                      cache_size
                     ,0,'NOCACHE'
                     ,'CACHE            ' || TO_CHAR(cache_size)
                    )                          AS cache_size
            , DECODE(
                      cycle_flag
                     ,'Y','CYCLE'
                     ,'N', 'NOCYCLE'
                    )                          AS cycle_flag
            , DECODE(
                      order_flag
                     ,'Y','ORDER'
                     ,'N', 'NOORDER'
                    )                          AS order_flag
       FROM
              ${view}_sequences
       WHERE
                  sequence_name  = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND sequence_owner = UPPER('$owner')
        "; }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  die "\nSequence \U$name \Ldoes not exist.\n\n" unless @row;

  my (
       $start_with,
       $increment_by,
       $min_value,
       $max_value,
       $cache_size,
       $cycle_flag,
       $order_flag,
     ) = @row;

  my $sql = "PROMPT " .
            "CREATE SEQUENCE \L$schema$name\n\n" .
            "CREATE SEQUENCE \L$schema$name\n" .
            "   $start_with\n" .
            "   $increment_by\n" .
            "   $min_value\n" .
            "   $max_value\n" .
            "   $cache_size\n" .
            "   $cycle_flag\n" .
            "   $order_flag\n" .
            ";\n\n";

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql;
}

# sub _create_snapshot
#
# Returns DDL to create the named materialized view
# by calling _create_mview (which is shared with
# _create_materialized_view)
#
sub _create_snapshot
{
  _create_mview( @_, 'SNAPSHOT' );
}

# sub _create_snapshot_log
#
# Returns DDL to create the named snapshot log
# by calling _create_mview (which is shared with
# _create_materialized_log)
#
sub _create_snapshot_log
{
  _create_mview_log( @_, 'SNAPSHOT' );
}

# sub _create_synonym
#
# Returns DDL to create the named synonym in the form of:
#
#     CREATE [PUBLIC] SYNONYM <name> FOR [schema.]<object>[@dblink]
#
sub _create_synonym
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $stmt =
      "
       SELECT
              table_owner
            , table_name
            , NVL(db_link,'NULL')
       FROM
              ${view}_synonyms
       WHERE
                  synonym_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner        = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  die "Synonym \U$name \Ldoes not exist.\n\n" unless @row;

  my ( $table_owner, $table_name, $db_link ) = @row;

  $db_link      = ( $db_link   eq 'NULL' )   ? ''        : "\@$db_link";
  $schema       = ( $schema    eq 'PUBLIC' ) ? ''        : $schema;
  my $is_public = ( "\U$owner" eq 'PUBLIC' ) ? ' PUBLIC' : '';
  my $table_schema = _set_schema( $table_owner );

  my $sql = "PROMPT " .
            "CREATE$is_public SYNONYM \L$schema$name " .
               "FOR \L$table_schema$table_name$db_link \n\n" .
            "CREATE$is_public SYNONYM \L$schema$name " .
               "FOR \L$table_schema$table_name$db_link;\n\n";

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $table_owner, $table_name, $view );
  }

  return $sql;
}

# sub _create_table
#
# Returns DDL to create the named table and its comments
# and its partition(s) in the form of:
#
#     CREATE TABLE [schema.]<name>
#     (
#       <column list>
#     )
#     ORGANIZATION {HEAP|INDEX}
#     [NO]MONIOTORING
#     PARALLEL 
#     ( 
#       DEGREE     <value> 
#       INSTANCES  <value> 
#     ) 
#     [NO]CACHE 
#     [PCTUSED]    <value>
#     PCTFREE      <value>
#     INITRANS     <value>
#     MAXTRANS     <value>
#     STORAGE
#     (
#       <storage clause>
#     )
#     [NO]LOGING
#     TABLESPACE   <name>
#     [<partitioning clause>]
#
sub _create_table
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql;
  my $stmt;

  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              'NO'                    AS partitioned
            , 'NOT IOT'               AS iot_type
       FROM
              ${view}_tables
       WHERE
                  table_name = UPPER( ? )
      ";
  }
  else
  {
    $stmt =
      "
       SELECT
              partitioned
            , iot_type
       FROM
              ${view}_tables
       WHERE
                  table_name = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner      = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  die "Table \U$name \Ldoes not exist.\n\n" unless @row;

  my ( $partitioned, $iot_type ) = @row;

  if ( $iot_type eq 'IOT' )
  {
    if ( $partitioned eq 'YES' )
    {
      return _create_partitioned_iot( $schema, $owner, $name, $view )
    }
    else
    {
      return _create_iot( $schema, $owner, $name, $view )
    }
  }
  elsif ( $partitioned eq 'YES' )
  {
    return _create_partitioned_table( $schema, $owner, $name, $view )
  }

  # We must be a plain, vanilla, non-partitioned, relational table.

  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              'N/A'                         AS monitoring
            , 'N/A'                         AS table_name
              -- Parallel Clause
            , LTRIM(t.degree)
            , LTRIM(t.instances)
              -- Physical Properties
            , 'N/A'                         AS organization
              -- Segment Attributes
            , DECODE(
                      LTRIM(t.cache)
                     ,'Y','CACHE'
                     ,    'NOCACHE'
                    )
            , t.pct_used
            , t.pct_free
            , DECODE(
                      t.ini_trans
                     ,0,1
                     ,null,1
                     ,t.ini_trans
                    )                       AS ini_trans
            , DECODE(
                      t.max_trans
                     ,0,255
                     ,null,255
                     ,t.max_trans
                    )                       AS max_trans
              -- Storage Clause
            , t.initial_extent
            , t.next_extent
            , t.min_extents
            , DECODE(
                      t.max_extents
                     ,2147483645,'unlimited'
                     ,           t.max_extents
                    )                       AS max_extents
            , NVL(t.pct_increase,0)
            , NVL(t.freelists,1)
            , NVL(t.freelist_groups,1)
            , 'N/A'                         AS buffer_pool
            , 'N/A'                         AS logging
            , LOWER(t.tablespace_name)      AS tablespace_name
            , s.blocks - NVL(t.empty_blocks,0)
       FROM
              ${view}_tables    t
            , ${view}_segments  s
       WHERE
                  t.table_name   = UPPER('$name')
              AND t.table_name   = s.segment_name
      ";
  }
  elsif ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              'N/A'                         AS monitoring
            , 'N/A'                         AS table_name
              -- Parallel Clause
            , LTRIM(t.degree)
            , LTRIM(t.instances)
              -- Physical Properties
            , DECODE(
                      t.iot_type
                     ,'IOT','INDEX'
                     ,      'HEAP'
                    )                       AS organization
              -- Segment Attributes
            , DECODE(
                      LTRIM(t.cache)
                     ,'Y','CACHE'
                     ,    'NOCACHE'
                    )
            , t.pct_used
            , t.pct_free
            , DECODE(
                      t.ini_trans
                     ,0,1
                     ,null,1
                     ,t.ini_trans
                    )                       AS ini_trans
            , DECODE(
                      t.max_trans
                     ,0,255
                     ,null,255
                     ,t.max_trans
                    )                       AS max_trans
              -- Storage Clause
            , t.initial_extent
            , t.next_extent
            , t.min_extents
            , DECODE(
                      t.max_extents
                     ,2147483645,'unlimited'
                     ,           t.max_extents
                    )                       AS max_extents
            , NVL(t.pct_increase,0)
            , NVL(t.freelists,1)
            , NVL(t.freelist_groups,1)
            , 'N/A'                         AS buffer_pool
            , DECODE(
                      t.logging
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(t.tablespace_name)      AS tablespace_name
            , s.blocks - NVL(t.empty_blocks,0)
       FROM
              ${view}_tables    t
            , ${view}_segments  s
       WHERE
                  t.table_name   = UPPER('$name')
              AND t.table_name   = s.segment_name
      ";
  }
  else                   # We're Oracle8i or newer
  {
    $stmt =
      "
       SELECT
              -- Table Properties
              DECODE(
                      t.monitoring
                     ,'NO','NOMONITORING'
                     ,     'MONITORING'
                    )                       AS monitoring
            , 'N/A'                         AS table_name
              -- Parallel Clause
            , LTRIM(t.degree)
            , LTRIM(t.instances)
              -- Physical Properties
            , DECODE(
                      t.iot_type
                     ,'IOT','INDEX'
                     ,      'HEAP'
                    )                       AS organization
              -- Segment Attributes
            , DECODE(
                      LTRIM(t.cache)
                     ,'Y','CACHE'
                     ,    'NOCACHE'
                    )
            , t.pct_used
            , t.pct_free
            , DECODE(
                      t.ini_trans
                     ,0,1
                     ,null,1
                     ,t.ini_trans
                    )                       AS ini_trans
            , DECODE(
                      t.max_trans
                     ,0,255
                     ,null,255
                     ,t.max_trans
                    )                       AS max_trans
              -- Storage Clause
            , t.initial_extent
            , t.next_extent
            , t.min_extents
            , DECODE(
                      t.max_extents
                     ,2147483645,'unlimited'
                     ,           t.max_extents
                    )                       AS max_extents
            , NVL(t.pct_increase,0)
            , NVL(t.freelists,1)
            , NVL(t.freelist_groups,1)
            , LOWER(t.buffer_pool)          AS buffer_pool
            , DECODE(
                      t.logging
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , LOWER(t.tablespace_name)      AS tablespace_name
            , s.blocks - NVL(t.empty_blocks,0)
       FROM
              ${view}_tables    t
            , ${view}_segments  s
       WHERE
                  t.table_name   = UPPER('$name')
              AND t.table_name   = s.segment_name
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND s.owner        = UPPER('$owner')
              AND t.owner        = s.owner
      ";
  }

  $sql = _create_table_text( $stmt, $schema, $owner, $name, $view ) .
         ";\n\n" .
         _create_comments( $schema, $owner, $name, $view );

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql;
}

# sub _create_table_family
#
# Combines the CREATE TABLE statement with its "family" -- Comments,
# Triggers and Constraints
#
sub _create_table_family
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $stmt;
  my $sql = _create_table( @_ );

  # Add table's indexes
  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              'NOT IOT'               AS iot_type
       FROM
              ${view}_tables
       WHERE
                  table_name = UPPER( ? )
      ";
  }
  else
  {
    $stmt =
      "
       SELECT
              iot_type
       FROM
              ${view}_tables
       WHERE
                  table_name = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
        "
              AND owner      = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my ( $iot ) = $sth->fetchrow_array;

  $stmt =
      "
       SELECT
              index_name
       FROM
              ${view}_indexes
       WHERE
                  table_name  = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND table_owner = UPPER('$owner')
      ";
  }

  if ( $iot eq 'IOT' )
  {
    # Omit the PK, it's in the CREATE TABLE on an IOT
    $stmt .=
      "
       MINUS
       SELECT
              constraint_name
       FROM
              ${view}_constraints
       WHERE
                  table_name      = UPPER( '$name' )
              AND constraint_type = 'P'
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND owner           = UPPER('$owner')
      ";
    }
  }

  $stmt .= 
      "
       ORDER
          BY
             1
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_index( $schema, $owner, @$row->[0], $view );
  }

  # Add table's constraints
  $stmt =
      "
       SELECT
              constraint_name
            , constraint_type
            , search_condition
       FROM
              ${view}_constraints cn
       WHERE
                  owner            = UPPER( ? )
              AND table_name       = UPPER( ? )
      ";

  if ( $iot eq 'IOT' )
  {
    $stmt .=
      "
              AND constraint_type IN('U','R','C')
      ";
  }
  else
  {
    $stmt .=
      "
              AND constraint_type IN('P','U','R','C')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
             DECODE(
                     constraint_type
                    ,'P',1
                    ,'U',2
                    ,'R',3
                    ,'C',4
                   )
           , constraint_name
      ";

  $dbh->{ LongReadLen } = 8192;    # Allows SEARCH_CONDITION length of 8K
  $dbh->{ LongTruncOk } = 1;

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $owner, $name );
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    my ( $cons_name, $cons_type, $condition ) = @$row;

    if ( $cons_type ne 'C' )
    {
      $sql .= _create_constraint( $schema, $owner, $cons_name, $view );
    }
    elsif ( $condition !~ /IS NOT NULL/ )
    {
      $sql .= _create_constraint( $schema, $owner, $cons_name, $view );
    }
  }


  # Add table's triggers
  $stmt =
      "
       SELECT
              trigger_name
       FROM
              ${view}_triggers
       WHERE
                  table_name  = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND table_owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
             trigger_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= _create_trigger( $schema, $owner, @$row->[0], $view );
  }

  return $sql;
}

# sub _create_table_text
#
# Formats the CREATE TABLE statement
#
sub _create_table_text
{
  my ( $stmt, $schema, $owner, $name, $view ) = @_;

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  my @row = $sth->fetchrow_array;

  # Turn warnings off
  $^W = 0;

  my $monitoring   = shift @row;
  my $table        = shift @row;
  my $degree       = shift @row;
  my $instances    = shift @row;
  my $organization = shift @row;

  my (
       # Segment Attributes
       $cache,
       $pct_used,
       $pct_free,
       $ini_trans,
       $max_trans,
       $initial,
       $next,
       $min_extents,
       $max_extents,
       $pct_increase,
       $freelists,
       $freelist_groups,
       $buffer_pool,
       $logging,
       $tablespace,
       $blocks,
     ) = @row;

  ( $initial, $next ) = _initial_next( $blocks ) if $attr{ 'resize' };

  my $sql  =
          "PROMPT " .
          "CREATE TABLE \L$schema$name\n\n" .
          "CREATE TABLE \L$schema$name\n" .
          "(\n    " .
          _table_columns( $owner, $name, $view );

  if ( $organization eq 'INDEX' )
  {
    $stmt =
        "
         SELECT
                constraint_name
         FROM
                ${view}_constraints
         WHERE
                    table_name      = UPPER( ? )
                AND constraint_type = 'P'
        ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
          "
                AND owner           = UPPER('$owner')
          ";
    }

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my ( $index ) = $sth->fetchrow_array;

    $sql .= "  , CONSTRAINT \L$index \UPRIMARY KEY\n" .
            _index_columns( '      ', $owner, $index, $view, );
  }

  $sql .= ")\n";

  $sql .= "ORGANIZATION        $organization\n"    if $oracle_major > 7;

  if (
          $oracle_major > 8
       or ( $oracle_major == 8 and $oracle_minor > 0 )
     )
  {
    $sql .= "$monitoring\n";
  }

  unless (     $organization eq 'INDEX'
           and $oracle_major == 8
           and $oracle_minor == 0
         )
  {
    $sql .= "PARALLEL\n" .
            "(\n" .
            "  DEGREE            $degree\n" .
            "  INSTANCES         $instances\n" .
            ")\n";
  }

  unshift @row, ( '', $organization );

  $sql .= _segment_attributes( \@row );

  if ( $organization eq 'INDEX' )
  {
    if ( $oracle_major == 8 and $oracle_minor == 0 )
    {
      $stmt =
        "
         SELECT
                c.column_name
              , i.pct_threshold
              , 'HEAP'                        AS organization
                -- Segment Attributes
              , 'N/A'                         AS cache
              , t.pct_used
              , t.pct_free
              , DECODE(
                        t.ini_trans
                       ,0,1
                       ,null,1
                       ,t.ini_trans
                      )                       AS ini_trans
              , DECODE(
                        t.max_trans
                       ,0,255
                       ,null,255
                       ,t.max_trans
                      )                       AS max_trans
                -- Storage Clause
              , t.initial_extent
              , t.next_extent
              , t.min_extents
              , DECODE(
                        t.max_extents
                       ,2147483645,'unlimited'
                       ,           t.max_extents
                      )                       AS max_extents
              , NVL(t.pct_increase,0)
              , NVL(t.freelists,1)
              , NVL(t.freelist_groups,1)
              , 'N/A'                         AS buffer_pool
              , DECODE(
                        t.logging
                       ,'NO','NOLOGGING'
                       ,     'LOGGING'
                      )                       AS logging
              , LOWER(t.tablespace_name)      AS tablespace_name
              , s.blocks - NVL(t.empty_blocks,0)
         FROM
                ${view}_tables       t
              , ${view}_indexes      i
              , ${view}_segments     s
              , ${view}_tab_columns  c
         WHERE
                    t.iot_name       = UPPER('$name')
                AND i.table_name     = t.iot_name
                AND c.table_name (+) = i.table_name
                AND c.column_id  (+) = i.include_column
                AND s.segment_name   = t.table_name
        ";
    }
    else                   # We're Oracle8i or newer
    {
      $stmt =
        "
         SELECT
                c.column_name
              , i.pct_threshold
              , 'HEAP'                        AS organization
                -- Segment Attributes
              , 'N/A'                         AS cache
              , t.pct_used
              , t.pct_free
              , DECODE(
                        t.ini_trans
                       ,0,1
                       ,null,1
                       ,t.ini_trans
                      )                       AS ini_trans
              , DECODE(
                        t.max_trans
                       ,0,255
                       ,null,255
                       ,t.max_trans
                      )                       AS max_trans
                -- Storage Clause
              , t.initial_extent
              , t.next_extent
              , t.min_extents
              , DECODE(
                        t.max_extents
                       ,2147483645,'unlimited'
                       ,           t.max_extents
                      )                       AS max_extents
              , NVL(t.pct_increase,0)
              , NVL(t.freelists,1)
              , NVL(t.freelist_groups,1)
              , LOWER(t.buffer_pool)          AS buffer_pool
              , DECODE(
                        t.logging
                       ,'NO','NOLOGGING'
                       ,     'LOGGING'
                      )                       AS logging
              , LOWER(t.tablespace_name)      AS tablespace_name
              , s.blocks - NVL(t.empty_blocks,0)
         FROM
                ${view}_tables       t
              , ${view}_indexes      i
              , ${view}_segments     s
              , ${view}_tab_columns  c
         WHERE
                    t.iot_name       = UPPER('$name')
                AND i.table_name     = t.iot_name
                AND c.table_name (+) = i.table_name
                AND c.column_id  (+) = i.include_column
                AND s.segment_name   = t.table_name
        ";
    }

    if ( $view eq 'DBA' )
    {
      $stmt .=
        "
                AND t.owner          = UPPER('$owner')
                AND s.owner          = t.owner
                AND c.owner      (+) = i.table_owner
                AND i.table_owner    = t.owner
        ";
    }

    $sth = $dbh->prepare( $stmt );
    $sth->execute;
    my @row = $sth->fetchrow_array;

    if ( @row )
    {
      my $column        = shift @row;
      my $pct_threshold = shift @row;

      $sql .= "PCTTHRESHOLD        $pct_threshold\n";
      $sql .= "INCLUDING           $column\n"    if $column;
      $sql .= "OVERFLOW\n";
    }
  }

  return $sql;
}

# sub _create_tablespace
#
# Returns DDL to create the named tablespace in the form of:
#
#     CREATE [TEMPORARY] TABLESPACE <name>
#     {DATA|TEMP}FILE
#        '<filespec>'
#      , '<filespec>'
#     DEFAULT STORAGE
#     (
#       <storage clause>
#     )
#     [MINIMUM EXTENT  <bytes>]
#     ]PERMANENT|TEMPORARY]
#     [EXTENT MANAGEMENT {DICTIONARY|LOCAL <extent spec>}]
#     [[NO]LOGGING]
#
sub _create_tablespace
{
  my ( $schema, $owner, $name, $view ) = @_;

  die "\nYou must use the DBA views in order to CREATE TABLESPACE\n\n"
      unless $view eq 'DBA';

  my $sql;
  my $stmt;
  my $file_type;

  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              initial_extent
            , next_extent
            , min_extents
            , DECODE(
                      max_extents
                     ,2147483645,'unlimited'
                     ,null,DECODE(
                                   $block_size
                                  , 1,  57
                                  , 2, 121
                                  , 4, 249
                                  , 8, 505
                                  ,16,1017
                                  ,32,2041
                                  ,'???'
                                 )
                     ,max_extents
                    )                       AS max_extents
            , pct_increase
            , 0                             AS min_extlen
            , contents
            , 'N/A'                         AS logging
            , 'N/A'                         AS extent_management
            , 'N/A'                         AS allocation_type
       FROM
              dba_tablespaces
       WHERE
              tablespace_name = UPPER( ? )
      ";
  }
  elsif ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              initial_extent
            , next_extent
            , min_extents
            , DECODE(
                      max_extents
                     ,2147483645,'unlimited'
                     ,null,DECODE(
                                   $block_size
                                  , 1,  57
                                  , 2, 121
                                  , 4, 249
                                  , 8, 505
                                  ,16,1017
                                  ,32,2041
                                  ,'???'
                                 )
                     ,max_extents
                    )                       AS max_extents
            , pct_increase
            , min_extlen
            , contents
            , DECODE(
                      logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , 'N/A'                         AS extent_management
            , 'N/A'                         AS allocation_type
       FROM
              dba_tablespaces
       WHERE
              tablespace_name = UPPER( ? )
      ";
  }
  else             # We're newer than Oracle 8.0
  {
    $stmt =
      "
       SELECT
              initial_extent
            , next_extent
            , min_extents
            , DECODE(
                      max_extents
                     ,2147483645,'unlimited'
                     ,null,DECODE(
                                   $block_size
                                  , 1,  57
                                  , 2, 121
                                  , 4, 249
                                  , 8, 505
                                  ,16,1017
                                  ,32,2041
                                  ,'???'
                                 )
                     ,max_extents
                    )                       AS max_extents
            , pct_increase
            , min_extlen
            , contents
            , logging
            , extent_management
            , allocation_type
       FROM
              dba_tablespaces
       WHERE
              tablespace_name = UPPER( ? )
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  die "Tablespace \U$name \Ldoes not exist.\n\n" unless @row;

  my (
       $initial,
       $next,
       $min_extents,
       $max_extents,
       $pct_increase,
       $min_extlen,
       $contents,
       $logging,
       $extent_management,
       $allocation_type,
     ) = @row;

  if ( $extent_management eq 'LOCAL' and $contents eq 'TEMPORARY' )
  {
    $sql  = "PROMPT " .
            "CREATE TEMPORARY TABLESPACE \L$name\n\n" .
            "CREATE TEMPORARY TABLESPACE \L$name\n";
  }
  else
  {
    $sql  = "PROMPT " .
            "CREATE TABLESPACE \L$name\n\n" .
            "CREATE TABLESPACE \L$name\n";
  }

  if ( $oracle_major == 7 )
  {
    $file_type = 'DATA';

    $stmt =
      "
       SELECT
              file_name
            , bytes
            , 'N/A'                                 AS autoextensible
            , 'N/A'                                 AS maxbytes
            , 'N/A'                                 AS increment_by
       FROM
              dba_data_files
       WHERE
              tablespace_name = UPPER( ? )
       ORDER
          BY
              file_name
      ";
  }
  else             # We're newer than Oracle7
  {
    $stmt =
      "
       SELECT
              count(*)
       FROM
              dba_data_files
       WHERE
              tablespace_name = UPPER( ? )
      ";

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my ( $cnt ) = $sth->fetchrow_array;
    $file_type  = ( $cnt == 0 ) ? 'TEMP' : 'DATA';

    $stmt =
      "
       SELECT
              file_name
            , bytes
            , autoextensible
            , DECODE(
                      SIGN(2147483645 - maxbytes)
                     ,-1,'unlimited'
                     ,maxbytes
                    )                               AS maxbytes
            , increment_by * $block_size * 1024     AS increment_by
       FROM
              dba_${file_type}_files
       WHERE
              tablespace_name = UPPER( ? )
       ORDER
          BY
              file_name
      ";
  }

  $sql .= "${file_type}FILE\n";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;

  my $comma = '  ';
  foreach my $row ( @$aref )
  {
    my (
         $file_name,
         $bytes,
         $autoextensible,
         $maxbytes,
         $increment_by,
       ) = @$row;

    $sql .= "$comma '$file_name' SIZE $bytes REUSE\n";

    if ( $oracle_major > 7 )
    {
      $sql .= "       AUTOEXTEND ";

      if ( $autoextensible eq 'YES' )
      {
        $sql .= "ON NEXT $increment_by MAXSIZE $maxbytes\n";
      }
      else
      {
        $sql .= "OFF\n";
      }
    }

    $comma = ' ,';
  }

  if ( $extent_management eq 'LOCAL' )
  {
    $sql .= "EXTENT MANAGEMENT LOCAL ";

    if ( $allocation_type eq 'SYSTEM' )
    {
      $sql .= "AUTOALLOCATE\n";
    }
    else
    {
      $sql .= "UNIFORM SIZE $next\n";
    }
  }
  else  # It's Dictionary Managed, Oracle8.0 or Oracle7
  {
    $sql .= "DEFAULT STORAGE\n" .
            "(\n" .
            "  INITIAL           $initial\n" .
            "  NEXT              $next\n" .
            "  MINEXTENTS        $min_extents\n" .
            "  MAXEXTENTS        $max_extents\n" .
            "  PCTINCREASE       $pct_increase\n" .
            ")\n" .
            "$contents\n";;

    if ( $min_extlen > 0 )
    {
      $sql .= "MINUMUM EXTENT      $min_extlen\n";
    }

    if (
            $oracle_major > 8
         or ( $oracle_major == 8 and $oracle_minor > 0 )
       )
    {
      $sql .= "EXTENT MANAGEMENT DICTIONARY\n";
    }
  }

  if ( $oracle_major > 7 )
  {
    $sql .= "$logging\n"    unless (
                                         $contents          eq 'TEMPORARY'
                                     and $extent_management eq 'LOCAL'
                                   );
  }

  $sql .= ";\n\n";

  return $sql;
}

# sub _create_trigger
#
# Returns DDL to create the named trigger in the form of:
#
#     CREATE OR REPLACE TRIGGER [schema.]<name>
#     {BEFORE|AFTER|INSTEAD OF} <triggering event>
#     [OF <column list ]ON {[schema.]<table>|DATABASE|SCHEMA}
#     REFERENCING <new> AS NEW <old> AS OLD
#     [WHEN <whatever>]
#     [FOR EACH ROW]
#     <code>
# 
sub _create_trigger
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $stmt;
  if (
          $oracle_major > 8
       or ( $oracle_major == 8 and $oracle_minor > 0 )
     )
  {
    $stmt =
      "
       SELECT
              trigger_type
            , RTRIM(triggering_event)
            , table_owner
            , table_name
            , base_object_type
            , referencing_names
            , DECODE(
                      when_clause
                     ,null,null
                     ,'WHEN (' || when_clause || ')' || CHR(10)
                    )
            , trigger_body
       FROM
              ${view}_triggers
       WHERE
                  trigger_name = UPPER( ? )
      ";
  }
  else
  {
    $stmt =
      "
       SELECT
              trigger_type
            , RTRIM(triggering_event)
            , table_owner
            , table_name
              -- Only table triggers before 8i
            , 'TABLE'                           AS base_object_type
            , referencing_names
            , DECODE(
                      when_clause
                     ,null,null
                     ,'WHEN (' || when_clause || ')' || CHR(10)
                    )
            , trigger_body
       FROM
              ${view}_triggers
       WHERE
                  trigger_name = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND table_owner  = UPPER('$owner')
      ";
  }

  $dbh->{ LongReadLen } = 65536;    # Allows TRIGGER_BODY length of 64K
  $dbh->{ LongTruncOk } = 1;

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  die "\nTrigger \U$schema$name \Ldoes not exist.\n\n" unless @row;

  my (
       $trigger_type,
       $event,
       $table_owner,
       $table,
       $base_type,
       $ref_names,
       $when,
       $body,
     ) = @row;

  my ( $trg_type ) = $trigger_type =~ /(BEFORE|AFTER|INSTEAD OF)/;
  my $schema2 = _set_schema( $table_owner );
  my $object = ( $base_type eq 'TABLE'  ) ? $schema2 . $table   :
               ( $base_type eq 'SCHEMA' ) ? $schema  . 'SCHEMA' : $base_type;
  $ref_names =~ s/ING (\w+) AS NEW (\w+)/ING \L$1 \UAS NEW \L$2/;

  # When clause sometimes ends in a null
  $when =~ s/\c@//g;

  # Body sometimes ends in a null
  $body =~ s/\c@//g;

  my $columns;
  if ( $event =~ /UPDATE/ )
  {
    $stmt =
      "
       SELECT
              LOWER(column_name)
       FROM
              ${view}_trigger_cols
       WHERE
                  trigger_name = UPPER( ? )
              AND column_list  = 'YES'
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND table_owner  = UPPER('$owner')
      ";
    }

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );

    my (@columns) = map { $_->[0] } @{ $sth->fetchall_arrayref };

    $columns = "\nOF\n    " . join ("\n  , ", @columns) . "\n" if ( @columns );
  }


  my $sql = "PROMPT " .
            "CREATE OR REPLACE TRIGGER \L$schema$name\n\n" .
            "CREATE OR REPLACE TRIGGER \L$schema$name\n" .
            "$trg_type $event ${columns}ON \L$object\n";

  $sql .= "$ref_names\n"      if $base_type =~ /TABLE|VIEW/;
  $sql .= "FOR EACH ROW\n"    if $trigger_type =~ /EACH ROW/;
  $sql .= $when               if $when;

  $sql .= $body;
  $sql .= "\n"    unless $sql =~ /\Z\n/;
  $sql .= "/\n\n";

  return $sql;
}

# sub _create_type
#
# Returns DDL to create the named procedure in the form of:
#
#     CREATE OR REPLACE TYPE [schema.]<name>
#     AS
#     <source>
# 
# by calling _display_source
#
sub _create_type
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql = _display_source( $schema, $owner, $name, $view, 'TYPE' );

  if ( $attr{ 'grants' } )
  {
    $sql .= _object_privs( $schema, $owner, $name, $view );
  }

  return $sql;
}

# sub _create_user
#
# Returns DDL to create the named user in the form of:
#
#     CREATE USER <name> IDENTIFIED {EXTERNALLY|BY VALUES '<values>'}
#        PROFILE               <profile>
#        DEFAULT TABLESPACE    <tablespace>
#        TEMPORARY TABLESPACE  <tablespace>
#        [QUOTA {UNLIMITED|<bytes>} ON TABLESPACE <tablespace1>]
#        [QUOTA {UNLIMITED|<bytes>} ON TABLESPACE <tablespace2>]
#
#     [GRANT <role >            TO <name> [WITH ADMIN OPTION]]
#     [GRANT <system privilege> TO <name> [WITH ADMIN OPTION]]
#     [GRANT <privilege> ON <object> TO <name> [WITH GRANT OPTION]]
# 
sub _create_user
{
  my ( $schema, $owner, $name, $view ) = @_;

  die "\nYou must use the DBA views in order to CREATE USER\n\n"
      unless $view eq 'DBA';

  my $stmt =
      "
       SELECT
              DECODE(
                      password
                     ,'EXTERNAL','EXTERNALLY'
                     ,'BY VALUES ''' || password || ''''
                    )                         AS password
            , profile
            , default_tablespace
            , temporary_tablespace
       FROM
              dba_users
       WHERE
              username = UPPER( ? )
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my @row = $sth->fetchrow_array;
  die "\nUser \U$name \Ldoes not exist.\n\n" unless @row;

  my (
       $password,
       $profile,
       $default_tablespace,
       $temporary_tablespace,
     ) = @row;

  my $sql  =
          "PROMPT " .
          "CREATE USER \L$name\n\n" .
          "CREATE USER \L$name \UIDENTIFIED $password\n" .
          "   \UPROFILE              \L$profile\n" .
          "   \UDEFAULT TABLESPACE   \L$default_tablespace\n" .
          "   \UTEMPORARY TABLESPACE \L$temporary_tablespace\n";

  # Add tablespace quotas
  $stmt =
      "
       SELECT
              DECODE(
                      max_bytes
                     ,-1,'unlimited'
                     ,TO_CHAR(max_bytes,'99999999')
                    )                         AS max_bytes
            , tablespace_name
       FROM
              dba_ts_quotas
       WHERE
              username = UPPER( ? )
       ORDER
          BY
              tablespace_name
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= "   QUOTA  @$row->[0]  ON \L@$row->[1]\n";
  }

  $sql .= ";\n\n";

  $sql .= _granted_privs( $name );

  return $sql;
}

# sub _create_view
#
# Returns DDL to create the named view in the form of:
#
#     CREATE OR REPLACE VIEW [schema.]<name>
#     (
#       <column aliases>
#     )
#     AS
#     <query>
# 
sub _create_view
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $stmt =
      "
       SELECT
              text
       FROM
              ${view}_views
       WHERE
                  view_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner     = UPPER('$owner')
      ";
  }

  $dbh->{ LongReadLen } = 65536;    # Allows View TEXT length of 64K
  $dbh->{ LongTruncOk } = 1;

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my ( $text ) = $sth->fetchrow_array;
  die "\nView \U$name \Ldoes not exist.\n\n" unless $text;

  $stmt =
      "
       SELECT
              LOWER(column_name)
       FROM
              ${view}_tab_columns
       WHERE
                  table_name = UPPER( ? )
      ";
 
  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner      = UPPER('$owner')
      ";
  }
 
  $stmt .= 
      "
       ORDER
          BY
              column_id
      ";
 
  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my (@columns) = map { $_->[0] } @{ $sth->fetchall_arrayref };

  return "PROMPT " .
         "CREATE OR REPLACE VIEW \L$schema$name\n\n" .
         "CREATE OR REPLACE VIEW \L$schema$name\n" .
         "(\n    " .
         join ("\n  , ", @columns) .
         "\n)\n" .
         "AS\n" .
         "$text" .
         ";\n\n";
}

# sub _display_source
#
# Returns DDL to create the named stored item in the form of:
#
#     CREATE OR REPLACE <TYPE> [schema.]<name>
#     <source>
#
# where TYPE is one of:  PROCEDURE, FUNCTION, PACKAGE, PACKAGE BODY
# 
sub _display_source
{
  my ( $schema, $owner, $name, $view, $type ) = @_;

  my $sql;
  my $stmt =
      "
       SELECT
              text
       FROM
              ${view}_source
       WHERE
                  type  = '$type'
              AND name  = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
             line
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;
  die "\n\u\L$type \U$name \Ldoes not exist.\n\n" unless @$aref;

  $sql = "PROMPT " .
         "CREATE OR REPLACE $type \L$schema$name\n\n" .
         "CREATE OR REPLACE ";

  my $i = 1;
  foreach my $row ( @$aref )
  {
    if ( $i++ == 1 )
    {
      # source.text already includes <TYPE> <name> 
      # We want to insert the schema right before the name

#      @$row->[0] =~ s/$type\s+\S+/$type \L$schema$name/i;
#     The following line was submitted by Sandor Toth, to fix the condition
#     where parameters immediately followed the name, as in
#        CREATE OR REPLACE PROCEDURE foo( var1 IN VARCHAR2)
#                                       ^
#                                       |
#                                observe, no space between 'foo' and '('

      @$row->[0] =~ s/($type)\s+($name)\s*(.*)$/$1 \L$schema$2 $3/i;
    }

    $sql .= "@$row->[0]";
  }

  $sql .= "\n"    unless $sql =~ /\Z\n/;
  $sql .= "/\n\n";

  return $sql;
}

# sub _drop_constraint
#
# Returns DDL to drop the named constraint in the form of:
#
#     ALTER TABLE [schema.]<name> DROP CONSTRAINT <name>
#
sub _drop_constraint
{
  my ( $schema, $name, $type, $owner,  $view ) = @_;

  my $stmt =
      "
       SELECT
              table_name
       FROM
              ${view}_constraints
       WHERE
                  owner           = UPPER( ? )
              AND constraint_name = UPPER( ? )
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $owner, $name );
  my ( $table_name ) = $sth->fetchrow_array;

  return "PROMPT " .
         "ALTER TABLE \L$schema$table_name \UDROP CONSTRAINT \L$name \n\n" .
         "ALTER TABLE \L$schema$table_name \UDROP CONSTRAINT \L$name;\n\n";
}

# sub _drop_database_link
#
# Returns DDL to drop the named database link in the form of:
#
#     DROP [PUBLIC] DATABASE LINK <name>
#
sub _drop_database_link
{
  my ( $schema, $name, $type ) = @_;

  my $public = ( $schema eq 'PUBLIC' ) ? ' PUBLIC' : '';

  return "PROMPT " .
         "DROP$public DATABASE LINK \L$name  \n\n" .
         "DROP$public DATABASE LINK \L$name ;\n\n" ;
}

# sub _drop_materialized_view_log
#
# Returns DDL to drop the named materialized view
# by calling _drop_mview_log (which is shared with
# _drop_snapshot_log)
#
sub _drop_materialized_view_log
{
  my ( $schema, $name, $type ) = @_;

  _drop_mview_log( $schema, $name, 'MATERIALIZED VIEW' );
}

# sub _drop_mview_log
#
# Returns DDL to drop the named database link in the form of:
#
#     DROP MATERIALIZED VIEW LOG ON [schema.]<name>
#     or
#     DROP SNAPSHOT LOG ON [schema.]<name>
#
sub _drop_mview_log
{
  my ( $schema, $name, $type ) = @_;

  return "PROMPT " .
         "DROP $type LOG ON \L$schema$name  \n\n" .
         "DROP $type LOG ON \L$schema$name ;\n\n" ;
}

# sub _drop_object
# 
# Returns generic DDL to drop the named object in the form of:
# 
#     DROP <TYPE> <name>
#
sub _drop_object
{
  my ( $schema, $name, $type ) = @_;

  return "PROMPT " .
         "DROP \U$type \L$name  \n\n" .
         "DROP \U$type \L$name ;\n\n";
}

# sub _drop_profile
#
# Returns DDL to drop the named profile in the form of:
#
#     DROP PROFILE <name> CASCADE
#
sub _drop_profile
{
  my ( $schema, $name, $type ) = @_;

  my $public = ( $schema eq 'PUBLIC' ) ? ' PUBLIC' : '';

  return "PROMPT " .
         "DROP PROFILE \L$name \UCASCADE   \n\n" .
         "DROP PROFILE \L$name \UCASCADE ; \n\n" ;
}

# sub _drop_schema_object
# 
# Returns generic DDL to drop the named object in the form of:
# 
#     DROP <TYPE> [schema.]<name>
#
sub _drop_schema_object
{
  my ( $schema, $name, $type ) = @_;

  return "PROMPT " .
         "DROP \U$type \L$schema$name  \n\n" .
         "DROP \U$type \L$schema$name ;\n\n";
}

# sub _drop_snapshot_log
#
# Returns DDL to drop the named snapshot log
# by calling _drop_mview_log (which is shared with
# _drop_materialized_view_log)
#
sub _drop_snapshot_log
{
  my ( $schema, $name, $type ) = @_;

  _drop_mview_log( $schema, $name, 'SNAPSHOT' );
}

# sub _drop_synonym
#
# Returns DDL to drop the named object in the form of:
#
#     DROP PUBLIC SYNONYM  <name>
#      or
#     DROP SYNONYM [schema.]<name> 
#
sub _drop_synonym
{
  my ( $schema, $name, $type ) = @_;

  my $public = ( $schema eq 'PUBLIC' ) ? ' PUBLIC' : '';

  if ( $public )
  {
      return "PROMPT " .
             "DROP PUBLIC SYNONYM \L$name  \n\n" .
             "DROP PUBLIC SYNONYM \L$name ;\n\n" ; 
  } else
  {
      return "PROMPT " .
             "DROP SYNONYM  \L$schema$name  \n\n" .
             "DROP SYNONYM  \L$schema$name ;\n\n";
  }
}

# sub _drop_table
# 
# Returns DDL to drop the named table in the form of:
# 
#     DROP TABLE [schema.]<name> CASCADE CONSTRAINTS
#
sub _drop_table
{
  my ( $schema, $name, $type ) = @_;

  return "PROMPT " .
         "DROP TABLE \L$schema$name \UCASCADE CONSTRAINTS  \n\n" .
         "DROP TABLE \L$schema$name \UCASCADE CONSTRAINTS ;\n\n";
}

# sub _drop_tablespace
# 
# Returns DDL to drop the named tablespace in the form of:
# 
#     DROP TABLESPACE <name> INCLUDING CONTENTS CASCADE CONSTRAINTS
#
sub _drop_tablespace
{
  my ( $schema, $name, $type ) = @_;

  return "PROMPT " .
         "DROP TABLESPACE \L$name " .
              "\UINCLUDING CONTENTS CASCADE CONSTRAINTS  \n\n" .
         "DROP TABLESPACE \L$name " .
              "\UINCLUDING CONTENTS CASCADE CONSTRAINTS ;\n\n";
}

# sub _drop_user
# 
# Returns DDL to drop the named user in the form of:
# 
#     DROP USER <name> CASCADE
#
sub _drop_user
{
  my ( $schema, $name, $type ) = @_;

  return "PROMPT " .
         "DROP USER \L$name \UCASCADE  \n\n" .
         "DROP USER \L$name \UCASCADE ;\n\n";
}

#sub _generate_heading
#
# Initializes $ddl
#
sub _generate_heading
{
  $ddl = "";
  return unless $attr{ heading };

  my ( $module, $action, $type, $list ) = @_;

  $ddl =  "REM This DDL was reverse engineered by\n" .
          "REM Perl module $module, Version $DDL::Oracle::VERSION\n" .
          "REM\n" .
          "REM at:   $host\n" .
          "REM from: $instance, an Oracle Release $oracle_release instance\n" .
          "REM\n" .
          "REM on:   " . scalar ( localtime ) . "\n" .
          "REM\n";

  if ( $action eq 'FREE SPACE' )
  {
    $ddl .= "REM Generating $action \Lreport";
  }
  elsif ( "\U$type" eq 'COMPONENTS' )
  {
    $ddl .= "REM Generating CREATE <component> statements\n\n";
    return;
  }
  elsif ( "\U$type" eq 'SCHEMA' )
  {
    $ddl .= "REM Generating CREATE statements for all Objects in schema";
  }
  else
  {
    $ddl .= "REM Generating $action \U$type \Lstatement";
  }

  $ddl .= ( @$list == 1 ) ? '' : "s";

  if ( "\U$type" eq 'SCHEMA' )
  {
    $ddl .= "\n";
  }
  else
  {
    $ddl .= " for:\n";
  }

  $ddl .= "REM\n"; 

  # Only include the schema if the Type has such a beast.
  foreach my $row ( @$list )
  {
    # These don't
    if (
            "\L$type" eq 'directory'
         or "\L$type" eq 'library'
         or "\L$type" eq 'profile'
         or "\L$type" eq 'role'
         or "\L$type" eq 'rollback segment'
         or "\L$type" eq 'tablespace'
         or "\L$type" eq 'user'
         or (
                  "\L@$row->[0]" ne 'public'
              and (
                       "\L$type" eq 'database link'
                    or "\L$type" eq 'synonym'
                  )
            )
       )
    {
      $ddl .= "REM\t\U@$row->[1]\n";
    }
    # Schema's don't name individual objects
    elsif ( "\L$type" eq 'schema' )
    {
      $ddl .= "REM\t\U@$row->[0]\n";
    }
    # The rest do.
    else
    {
      $ddl .= "REM\t\U@$row->[0].@$row->[1]\n";
    }
  }

  return $ddl .= "\n";
};

# sub _get_oracle_release
#
# Determines Oracle Release number
#
sub _get_oracle_release
{
  $sth = $dbh->prepare(
      "
       SELECT
              version
       FROM
              product_component_version
       WHERE
              product LIKE 'Oracle%'
      ");

  $sth->execute;
  my $version = $sth->fetchrow_array;

  (
    $oracle_release,
    $oracle_major,
    $oracle_minor
  ) = $version =~ /((\d+)\.(\d+)\S+)/;

  if ( $attr{ heading } )
  {
    $sth = $dbh->prepare(
      "
       SELECT
              LOWER(name)
       FROM
              v\$database
      ");

    $sth->execute;
    ( $instance ) = $sth->fetchrow_array;

    $host = `hostname`;
    chomp( $host );
  }
}

# sub _granted_privs
#
# Returns DDL to create GRANT statements to the named grantee 
# in the form of:
#
#     [GRANT <role >            TO <name> {WITH ADMIN OPTION]]
#     [GRANT <system privilege> TO <name> {WITH ADMIN OPTION]]
#
sub _granted_privs
{
  my ( $name ) = @_;

  my $sql;

  # Add role privileges
  my $stmt =
      "
       SELECT
              granted_role
            , DECODE(
                      admin_option
                     ,'YES','WITH ADMIN OPTION '
                     ,null
                    )                         AS admin_option
       FROM
              dba_role_privs
       WHERE
              grantee = UPPER( ? )
       ORDER
          BY
              granted_role
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= "PROMPT " .
            "GRANT \L@$row->[0] \UTO \L$name \U@$row->[1] \n\n" .
            "GRANT \L@$row->[0] \UTO \L$name \U@$row->[1];\n\n";
  }

  # Add system privileges
  $stmt =
      "
       SELECT
              privilege
            , DECODE(
                      admin_option
                     ,'YES','WITH ADMIN OPTION '
                     ,null
                    )                         AS admin_option
       FROM
              dba_sys_privs
       WHERE
              grantee = UPPER( ? )
       ORDER
          BY
              privilege
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    $sql .= "PROMPT " .
            "GRANT \L@$row->[0] \UTO \L$name \U@$row->[1] \n\n" .
            "GRANT \L@$row->[0] \UTO \L$name \U@$row->[1];\n\n";
  }

  return $sql;
}

#sub _index_columns
#
# Returns a formatted string containing the index columns.
# Starting with Oracle8i, columns may be DESCending.
#
sub _index_columns
{
  my ( $indent, $owner, $name, $view, ) = @_;

  my $stmt;
  if (
          $oracle_major > 8
       or ( $oracle_major == 8 and $oracle_minor > 0 )
     )
  {
    $stmt =
      "
       SELECT
              LOWER(column_name)
            , descend
       FROM
              ${view}_ind_columns
       WHERE
                  index_name  = UPPER( ? )
      ";
  }
  else
  {
    $stmt =
      "
       SELECT
              LOWER(column_name)
            , 'ASC'
       FROM
              ${view}_ind_columns
       WHERE
                  index_name  = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND index_owner = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
             column_position
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;

  my @cols;
  foreach my $row ( @$aref )
  {
    my ( $column, $direction ) = @$row;

    if ( $column =~ /^sys_nc\d+\$$/ )
    {
      $stmt =
        "
         SELECT
                c.default\$
         FROM
                sys.col\$        c           -- User needs SELECT on this
              , ${view}_indexes  i
              , ${view}_objects  o
         WHERE
                    i.index_name  = UPPER( ? )
                AND o.object_name = i.table_name
                AND c.obj#        = o.object_id
                AND c.name        = UPPER( ? )
        ";

      if ( $view eq 'DBA' )
      {
        $stmt .=
        "
                AND i.owner       = UPPER('$owner')
                AND o.owner       = i.table_owner
        ";
      }

      $dbh->{ LongReadLen } = 1024;
      $dbh->{ LongTruncOk } = 1;

      $sth = $dbh->prepare( $stmt );
      $sth->execute( $name, $column );
      my ( $real_column ) = $sth->fetchrow_array;
      # Get rid of double quotes
      $real_column =~ s|\"||g;

      if ( $direction eq 'DESC' )
      {
        push @cols, "\L$real_column" . 
                    '  ' . 
                    ' ' x ( 30 - length( $real_column ) ) .
                    "DESC";
      }
      else   # Must be a function-based index
      {
        push @cols, $real_column;
      }
    }
    else
    {
      push @cols, $column;
    }
  }

  return "${indent}(\n$indent    " .
         join ( "\n$indent  , ", @cols ) .
         "\n${indent})\n";
}

# sub _initial_next
#
# Given the number of blocks in a object, returns the smallest
# INITIAL/NEXT values appropriate for an object of this size.
#
sub _initial_next
{
  my $blocks  = shift;

  # Turn warnings off
  $^W = 0;

  my $i = 0;
  my $initial;
  my $next;

  until ( $initial ) 
  {
    $initial = ( $size_arr[$i][0] eq "UNLIMITED" ) ? $size_arr[$i][1] :
               ( $size_arr[$i][0]  > $blocks     ) ? $size_arr[$i][1] :
                                                     undef;

    $next    = ( $size_arr[$i][0] eq "UNLIMITED" ) ? $size_arr[$i][1] :
               ( $size_arr[$i][0]  > $blocks     ) ? $size_arr[$i][1] :
                                                     undef;
    $i++;
  }
  return $initial, $next;
}

#sub _key_columns
#
# Returns a formatted string containing the partitioning key columns.
# Called from _partition_key_columns and _subpartition_key_columns,
# which merely control which key columns table to query.
#
sub _key_columns
{
  my ( $owner, $name, $object_type, $view, $table ) = @_;

  my $stmt =
      "
       SELECT
              LOWER(column_name)
       FROM
              ${view}_${table}_key_columns
       WHERE
                  name           = UPPER( ? )
              AND object_type LIKE UPPER('$object_type%')
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner          = UPPER('$owner')
      ";
  }

  $stmt .= 
      "
       ORDER
          BY
             column_position
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;

  my @cols;
  foreach my $row ( @$aref )
  {
    push @cols, $row->[0];
  }

  return join ( "\n  , ", @cols );
}

# sub _object_privs
#
# Returns DDL to create GRANT statements in the form of:
#
#     GRANT <privilege> ON <object> TO <name> [WITH GRANT OPTION]
#
#       and/or
#
#     GRANT <privilege>
#     (
#         column_name
#       , column_name
#     )
#     ON <object> TO <name> [WITH GRANT OPTION]
#
sub _object_privs
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $sql;

  my $stmt =
      "
       SELECT
              grantee
            , privilege
            , DECODE(
                      grantable
                     ,'YES','WITH GRANT OPTION '
                     ,null
                    )                         AS grantable
       FROM
              ${view}_tab_privs
       WHERE
                  grantor    = UPPER( ? )
              AND table_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner      = UPPER('$owner')
      ";
  }

  $stmt .=
      "
       ORDER
          BY
              grantee
            , privilege
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $owner, $name );
  my $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    my (
         $grantee,
         $privilege,
         $grantable,,
       ) = @$row;

    $sql .= "PROMPT " .
            "GRANT \L$privilege \UON \L$schema$name \UTO \L$grantee " .
            "\U$grantable \n\n" .
            "GRANT \L$privilege \UON \L$schema$name \UTO \L$grantee " .
            "\U$grantable;\n\n";
  }

  $stmt =
      "
       SELECT DISTINCT
              grantee
            , privilege
            , DECODE(
                      grantable
                     ,'YES','WITH GRANT OPTION '
                     ,null
                    )                         AS grantable
       FROM
              ${view}_col_privs
       WHERE
                  grantor    = UPPER( ? )
              AND table_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner      = UPPER('$owner')
      ";
  }

  $stmt .=
      "
       ORDER
          BY
              grantee
            , privilege
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $owner, $name );
  $aref = $sth->fetchall_arrayref;

  foreach my $row ( @$aref )
  {
    my (
         $grantee,
         $privilege,
         $grantable,,
       ) = @$row;

    $sql .= "PROMPT " .
            "GRANT \L$privilege \UON \L$schema$name \UTO \L$grantee " .
            "\U$grantable\n\n" .
            "GRANT \L$privilege \n(\n    ";

    $stmt =
      "
       SELECT
              LOWER(column_name)
       FROM
              ${view}_col_privs
       WHERE
                  grantor    = UPPER( ? )
              AND privilege  = UPPER( ? )
              AND table_name = UPPER( ? )
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND owner      = UPPER('$owner')
      ";
    }

    $stmt .=
      "
       ORDER
          BY
              grantee
            , privilege
      ";

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $owner, $privilege, $name );
    my $aref = $sth->fetchall_arrayref;

    my @cols;
    foreach my $row ( @$aref )
    {
      push @cols, $row->[0];
    }

    $sql .= join ( "\n  , ", @cols );

    $sql .= "\n)\n\UON \L$schema$name \UTO \L$grantee \U$grantable;\n\n";
  }

  return $sql;
}

# sub _partition_key_columns
#
# Returns a formatted string containing the partitioning key columns
#
sub _partition_key_columns
{
  return _key_columns( @_, 'PART' );
}

# sub _print_space
#
# Returns a formatted string containing the space analysis report.
#
sub _print_space
{
  my ( $owner, $name, $type, $partition ) = @_;

  my (
       $total_blocks,
       $total_bytes,
       $unused_blocks,
       $unused_bytes,
       $last_file_id,
       $last_block_id,
       $last_block,
       $free_blocks,
     );

  my $max_length = 20;
  my $freelist_group_id = 0;

  if ( $partition )
  {
    $sth = $dbh->prepare(
                          "
                           BEGIN 
                             dbms_space.unused_space (
                                                       ?,?,?,?,?,?,?,?,?,?,?
                                                     ) ;
                           END ;
                          "
                        );
    $sth->bind_param( 1, "\U$owner" );
    $sth->bind_param( 2, "\U$name"  );
    $sth->bind_param( 3, "\U$type"  );
    $sth->bind_param_inout( 4 , \$total_blocks , $max_length );
    $sth->bind_param_inout( 5 , \$total_bytes  , $max_length );
    $sth->bind_param_inout( 6 , \$unused_blocks, $max_length );
    $sth->bind_param_inout( 7 , \$unused_bytes , $max_length );
    $sth->bind_param_inout( 8 , \$last_file_id , $max_length );
    $sth->bind_param_inout( 9 , \$last_block_id, $max_length );
    $sth->bind_param_inout( 10, \$last_block   , $max_length );
    $sth->bind_param( 11, $partition );
    $sth->execute;

    $sth = $dbh->prepare(
                          "
                           BEGIN 
                             dbms_space.free_blocks(
                                                      ?,?,?,?,?,?,?
                                                    ) ;
                           END ;
                          "
                        );
    $sth->bind_param( 1, "\U$owner"          );
    $sth->bind_param( 2, "\U$name"           );
    $sth->bind_param( 3, "\U$type"           );
    $sth->bind_param( 4, $freelist_group_id  );
    $sth->bind_param_inout( 5 , \$free_blocks, $max_length );
    $sth->bind_param( 6, '' );
    $sth->bind_param( 7, $partition );
    $sth->execute;
  }
  else
  {
    $sth = $dbh->prepare(
                          "
                           BEGIN 
                             dbms_space.unused_space (
                                                       ?,?,?,?,?,?,?,?,?,?
                                                     ) ;
                           END ;
                          "
                        );
    $sth->bind_param( 1, "\U$owner" );
    $sth->bind_param( 2, "\U$name"  );
    $sth->bind_param( 3, "\U$type"  );
    $sth->bind_param_inout( 4 , \$total_blocks , $max_length );
    $sth->bind_param_inout( 5 , \$total_bytes  , $max_length );
    $sth->bind_param_inout( 6 , \$unused_blocks, $max_length );
    $sth->bind_param_inout( 7 , \$unused_bytes , $max_length );
    $sth->bind_param_inout( 8 , \$last_file_id , $max_length );
    $sth->bind_param_inout( 9 , \$last_block_id, $max_length );
    $sth->bind_param_inout( 10, \$last_block   , $max_length );
    $sth->execute;

    $sth = $dbh->prepare(
                          "
                           BEGIN 
                             dbms_space.free_blocks(
                                                      ?,?,?,?,?
                                                    ) ;
                           END ;
                          "
                        );
    $sth->bind_param( 1, "\U$owner"          );
    $sth->bind_param( 2, "\U$name"           );
    $sth->bind_param( 3, "\U$type"           );
    $sth->bind_param( 4, $freelist_group_id  );
    $sth->bind_param_inout( 5 , \$free_blocks, $max_length );
    $sth->execute;
  }

  my $text;

  if ( $partition )
  {
    $text = "Partition $partition         BYTES";
  }
  else
  {
    $text = "                                                 BYTES";
  }

  $text .= "     BLOCKS\n" .
           "                                          ============" .
           "  =========\n" .
           sprintf(
                    "Used BELOW the high water mark            %12d  %9d\n",
                    $total_bytes - $unused_bytes 
                      - $free_blocks * $block_size * 1024,
                    $total_blocks - $unused_blocks - $free_blocks
                  ) .
           sprintf(
                    "Free ABOVE the high water mark            %12d  %9d\n",
                    $unused_bytes, $unused_blocks
                  ) .
           sprintf(
                    "Free BELOW the high water mark            %12d  %9d\n",
                    $free_blocks * $block_size * 1024, $free_blocks
                  ) .
           "                                          ------------" .
           "  ---------\n" .
           sprintf(
                    "              TOTAL in segment            %12d  %9d\n\n",
                    $total_bytes, $total_blocks
                  ) .
           "                                     FILE_ID  BLOCK_ID" .
           "  BLOCK_NBR\n" .
           "                                     =======  ========" .
           "  =========\n" .
           sprintf(
                    "Last extent having data              %7d  %8d  %9d\n\n",
                    $last_file_id, $last_block_id, $last_block
                  );

  return (
           $text,
           $total_blocks,
           $total_bytes,
           $unused_blocks,
           $unused_bytes,
           $free_blocks,
         );
}

# sub _range_partitions
#
# Returns the ordered list of index range partitions with segment attributes
#
sub _range_partitions
{
  my ( $owner, $index, $view, $subpartitioning_type, $caller ) = @_;

  my $sql .= "(\n";
  my $stmt;

  if ( $oracle_major == 8 and $oracle_minor == 0 )
  {
    $stmt =
      "
       SELECT
              partition_name
            , high_value
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , pct_free
            , ini_trans
            , max_trans
              -- Storage Clause
            , initial_extent
            , next_extent
            , min_extent
            , DECODE(
                      max_extent
                     ,2147483645,'unlimited'
                     ,           max_extent
                    )                       AS max_extents
            , pct_increase
            , NVL(freelists,1)
            , NVL(freelist_groups,1)
            , 'N/A'                         AS buffer_pool
            , DECODE(
                      logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , tablespace_name
            , leaf_blocks                   AS blocks
       FROM
              ${view}_ind_partitions
       WHERE
                  index_name =  UPPER( ? )
      ";
  }
  else               # We're Oracle8i or newer
  {
    $stmt =
      "
       SELECT
              partition_name
            , high_value
            , 'N/A'                         AS cache
            , 'N/A'                         AS pct_used
            , pct_free
            , ini_trans
            , max_trans
              -- Storage Clause
            , initial_extent
            , next_extent
            , min_extent
            , DECODE(
                      max_extent
                     ,2147483645,'unlimited'
                     ,           max_extent
                    )                       AS max_extents
            , pct_increase
            , NVL(freelists,1)
            , NVL(freelist_groups,1)
            , LOWER(buffer_pool)
            , DECODE(
                      logging 
                     ,'NO','NOLOGGING'
                     ,     'LOGGING'
                    )                       AS logging
            , tablespace_name
            , leaf_blocks                   AS blocks
       FROM
              ${view}_ind_partitions
       WHERE
                  index_name =  UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
    "
            AND index_owner = UPPER('$owner')
    ";
  }

  $stmt .=
      "
       ORDER
          BY
              partition_name
      ";

  $dbh->{ LongReadLen } = 8192;    # Allows HIGH_VALUE length of 8K
  $dbh->{ LongTruncOk } = 1;

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $index );
  my $aref = $sth->fetchall_arrayref;

  my $comma = '    ';

  foreach my $row ( @$aref )
  {
    my $partition  = shift @$row;
    my $high_value = shift @$row;

    $sql .= "${comma}PARTITION \L$partition";

    if ($caller ne 'LOCAL' )
    {
      $sql .= " VALUES LESS THAN\n" .
              "      (\n" .
              "        $high_value\n" .
              "      )\n";
    }
    else
    {
      $sql .= "\n";
    }

    unshift @$row, ( '      ', 'INDEX' );

    $sql .= _segment_attributes( $row );

    if ( $subpartitioning_type eq 'HASH' )
    {
      $stmt =
        "
         SELECT
                subpartition_name
              , tablespace_name
         FROM
                ${view}_ind_subpartitions
         WHERE
                    index_name     =  UPPER( ? )
                AND partition_name = '$partition'
        ";

      if ( $view eq 'DBA' )
      {
        $stmt .=
        "
                AND index_owner    = UPPER('$owner')
        ";
      }

      $stmt .=
        "
         ORDER
            BY
                subpartition_name
        ";

      $sth = $dbh->prepare( $stmt );
      $sth->execute( $index );
      my $aref = $sth->fetchall_arrayref;

      $sql .= "        (\n            ";

      my @cols;
      foreach my $row ( @$aref )
      {
        push @cols, "SUBPARTITION \L$row->[0] \UTABLESPACE \L$row->[1]";
      }
      $sql .= join ( "\n          , ", @cols );

      $sql .= "\n        )\n";
    }

    $comma = '  , ';
  }
  $sql .= ");\n\n";

  return $sql;
}

# sub _resize_index
#
# Returns DDL to rebuild the named index or its partition(s) in the form of:
#
#     ALTER INDEX [schema.]<name> REBUILD
#     [PARTITION <partition>]
#     STORAGE
#     (
#       INITIAL  <bytes>
#       NEXT     <bytes>
#     )
#
sub _resize_index
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $cnt;
  my $sql;
  ( $name, my $partition ) = split /:/, $name;

  my $stmt =
      "
       SELECT
              count(*) AS cnt
       FROM
              ${view}_indexes
       WHERE
                  index_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .= 
      "
              AND owner      = UPPER('$owner')
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  $cnt = $sth->fetchrow_array;
  die "Index \U$name \Ldoes not exist.\n\n" unless $cnt;

  if ( $partition ) # User wants one partition resized
  {
    $stmt =
      "
       SELECT
              SUBSTR(segment_type,7)   -- PARTITION or SUBPARTITION
       FROM
              ${view}_segments      s
       WHERE
                  s.segment_name   = UPPER( ? )
              AND s.partition_name = UPPER( ? )
      ";
    if ( $view eq 'DBA' )
    {
      $stmt .=
      "      
              AND s.owner          = UPPER('$owner')
      ";
    }

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name, $partition );
    my ( $seq_type, $partitioning_type ) = $sth->fetchrow_array;
    die "Partition \U$partition \Lof \UI\Lndex \U$name \Ldoes not exist,\n",
        "  OR it is the parent of Hash subpartition(s)\n",
        "  (i.e., it is not a segment and has no size).\n\n"
        unless $seq_type;

    $sql .= _resize_index_partition(
                                     $schema,
                                     $owner,
                                     $name,
                                     $partition,
                                     $seq_type,
                                     $view
                                   );

    return $sql;
  }

  # Find out if the object is partitioned

  $stmt =
      "
       SELECT
              partitioned
       FROM
              ${view}_indexes
       WHERE
                  index_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .= 
      "
              AND owner      = UPPER('$owner')
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $partitioned = $sth->fetchrow_array;

  if ( $partitioned eq 'NO' )
  {
    $stmt =
        "
         SELECT
                s.blocks
              , s.initial_extent
              , s.next_extent
         FROM
                ${view}_segments s
         WHERE
                    s.segment_name = UPPER( ? )
                AND s.segment_type = 'INDEX'
        ";
    if ( $view eq 'DBA' )
    {
      $stmt .= 
        "
                AND s.owner        = UPPER('$owner')
        ";
    }
    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my ( $blocks, $initial, $next ) = $sth->fetchrow_array;

    ( $initial, $next ) = _initial_next( $blocks ) if $attr{ 'resize' };

    $sql .= "PROMPT " .
            "ALTER INDEX \L$schema$name \UREBUILD\n\n" .
            "ALTER INDEX \L$schema$name \UREBUILD\n" .
            "STORAGE\n" .
            "(\n" .
            "  INITIAL  $initial\n" .
            "  NEXT     $next\n" .
            ") ;\n\n";

    return $sql;
  }
  else
  {
    # It's partitioned -- get list of partitions
    # and call _resize_index_partition for each one
    $stmt =
      "
       SELECT
              partition_name
            , SUBSTR(segment_type,7)   -- PARTITION or SUBPARTITION
       FROM
              ${view}_segments
       WHERE
                  segment_name = UPPER( ? )
      ";
    if ( $view eq 'DBA' )
    {
      $stmt .= 
      " 
              AND owner        = UPPER('$owner')
      ";
    }
    $stmt .= "
       ORDER
          BY
              partition_name
      ";

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my $aref = $sth->fetchall_arrayref;

    foreach my $row ( @$aref )
    {
      my ( $partition, $seg_type ) = @$row;

      $sql .= _resize_index_partition(
                                       $schema,
                                       $owner,
                                       $name,
                                       $partition,
                                       $seg_type,
                                       $view
                                     );
    }

    return $sql;
  }
}

# sub _resize_index_partition
#
# Returns DDL to rebuild one partition of the named object in the form of:
#
#     ALTER INDEX [schema.]<name> REBUILD [SUB]PARTITION <partition>
#     STORAGE
#     (
#       INITIAL  <bytes>
#       NEXT     <bytes>
#     )
#
sub _resize_index_partition
{
  my(
      $schema, $owner, $name, $partition, $seg_type, $view ) = @_;

  my $sql;
  my $stmt =
      "
       SELECT
              s.blocks
            , s.initial_extent
            , s.next_extent
            , p.partitioning_type
       FROM
              ${view}_segments      s
            , ${view}_part_indexes  p
       WHERE
                  s.segment_name   = UPPER( ? )
              AND s.partition_name = UPPER( ? )
              AND p.index_name     = UPPER( ? )
      ";
    if ( $view eq 'DBA' )
    {
      $stmt .= 
      "
              AND s.owner          = UPPER('$owner')
              AND p.owner          = UPPER('$owner')
      ";
    }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, $partition, $name );
  my ( $blocks, $initial, $next, $partitioning_type ) = $sth->fetchrow_array;

  ( $initial, $next ) = _initial_next( $blocks ) if $attr{ 'resize' };

  $sql .= "PROMPT " .
          "ALTER INDEX \L$schema$name \UREBUILD $seg_type \L$partition\n\n" .
          "ALTER INDEX \L$schema$name \UREBUILD $seg_type \L$partition ";

  # Cannot specify storage parameters for a HASH [SUB]PARTITION
  if ( $seg_type eq 'PARTITION' and $partitioning_type eq 'RANGE' )
  {
    $sql .= "\nSTORAGE\n" .
            "(\n" .
            "  INITIAL  $initial\n" .
            "  NEXT     $next\n" .
            ") ";
  }

  $sql .= ";\n\n";

  return $sql;
}

# sub _resize_table
#
# Returns DDL to rebuild the named table or its partition(s) in the form of:
#
#     ALTER TABLE [schema.]<name> MOVE [[SUB]PARTITION <partition>]
#     STORAGE
#     (
#       INITIAL  <bytes>
#       NEXT     <bytes>
#     )
#
sub _resize_table
{
  my ( $schema, $owner, $name, $view ) = @_;

  my $cnt;
  my $sql;
  ( $name, my $partition ) = split /:/, $name;

  my $stmt =
      "
       SELECT
              count(*) AS cnt
       FROM
              ${view}_tables
       WHERE
                  table_name = UPPER( ? )
      ";

  if ( $view eq 'DBA' )
  {
    $stmt .= 
      "
              AND owner      = UPPER('$owner')
      ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  $cnt = $sth->fetchrow_array;
  die "Table \U$name \Ldoes not exist.\n\n" unless $cnt;

  if ( $partition ) # User wants one partition resized
  {
    $stmt =
      "
       SELECT
              SUBSTR(segment_type,7)   -- PARTITION or SUBPARTITION
       FROM
              ${view}_segments
       WHERE
                  segment_name   = UPPER( ? )
              AND partition_name = UPPER( ? )
      ";
    if ( $view eq 'DBA' )
    {
      $stmt .=
      "
              AND owner          = UPPER('$owner')
      ";
    }

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name, $ partition );
    my $type = $sth->fetchrow_array;
    die "Partition \U$partition \Lof \UT\Lable \U$name \Ldoes not exist,\n",
        "  OR it is the parent of Hash subpartition(s)\n",
        "  (i.e., it is not a segment and has no size).\n\n"
        unless $type;

    $sql .= _resize_table_partition(
                                     $schema,
                                     $owner,
                                     $name,
                                     $partition,
                                     $type,
                                     $view
                                   );

    # Rebuild this partition on all LOCAL indexes
    if ( $view eq 'DBA' )
    {
      $stmt = 
        "
         SELECT
                owner
              , index_name
         FROM
                dba_part_indexes
         WHERE
                    table_name = UPPER( ? )
                AND owner      = UPPER('$owner')
                AND locality   = 'LOCAL'
        ";
    }
    else        # We're a mortal USER
    {
      $stmt = 
        "
         SELECT
                '$owner'
              , index_name
         FROM
                user_part_indexes
         WHERE
                    table_name = UPPER( ? )
                AND locality   = 'LOCAL'
        ";
    }
  
    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my $aref = $sth->fetchall_arrayref;

    foreach my $row ( @$aref )
    {
      my ( $owner, $index ) = @$row;
      my $schema = _set_schema( $owner );

      $sql .= _resize_index(
                             $schema,
                             $owner,
                             "$index:$partition",
                             $view
                           );
    }
  }
  else
  # Didn't want single partition, so move entire table.
  # First, find out if the object is partitioned
  {
    $stmt =
        "
         SELECT
                partitioned
         FROM
                ${view}_tables
         WHERE
                    table_name = UPPER( ? )
        ";
  
    if ( $view eq 'DBA' )
    {
      $stmt .=
        "
                AND owner      = UPPER('$owner')
        ";
  
    }
  
    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my $partitioned = $sth->fetchrow_array;
  
    if ( $partitioned eq 'NO' )
    {
      $stmt =
        "
         SELECT
                s.blocks - NVL(t.empty_blocks,0)
              , s.initial_extent
              , s.next_extent
         FROM
                ${view}_segments s
              , ${view}_tables   t
         WHERE
                    s.segment_name = UPPER( ? )
                AND s.segment_type = 'TABLE'
                AND t.table_name   = s.segment_name
        ";
      if ( $view eq 'DBA' )
      {
        $stmt .= 
        "
                  AND s.owner        = UPPER('$owner')
                  AND t.owner        = s.owner
        ";
      }
      $sth = $dbh->prepare( $stmt );
      $sth->execute( $name );
      my ( $blocks, $initial, $next ) = $sth->fetchrow_array;
  
      ( $initial, $next ) = _initial_next( $blocks ) if $attr{ 'resize' };
  
      $sql .= "PROMPT " .
              "ALTER TABLE \L$schema$name \UMOVE\n\n" .
              "ALTER TABLE \L$schema$name \UMOVE\n" .
              "STORAGE\n" .
              "(\n" .
              "  INITIAL  $initial\n" .
              "  NEXT     $next\n" .
              ") ;\n\n";
  
      return $sql;
    }
    else
    {
      # It's partitioned -- get list of partitions
      # and call _resize_table_partition for each one
      $stmt =
        "
         SELECT
                partition_name
              , SUBSTR(segment_type,7)   -- PARTITION or SUBPARTITION
         FROM
                ${view}_segments
         WHERE
                    segment_name = UPPER( ? )
        ";
      if ( $view eq 'DBA' )
      {
        $stmt .= 
        " 
                AND owner        = UPPER('$owner')
        ";
      }
      $stmt .=
        "
         ORDER
            BY
                partition_name
        ";
  
      $sth = $dbh->prepare( $stmt );
      $sth->execute( $name );
      my $aref = $sth->fetchall_arrayref;
  
      foreach my $row ( @$aref )
      {
        my ( $partition, $type ) = @$row;
  
        $sql .= _resize_table_partition(
                                         $schema,
                                         $owner,
                                         $name,
                                         $partition,
                                         $type,
                                         $view
                                       );
      }
    }

    # Rebuild all indexes (partitioned or not)
    if ( $view eq 'DBA' )
    {
      $stmt = 
        "
         SELECT
                owner
              , index_name
         FROM
                dba_part_indexes
         WHERE
                    table_name = UPPER( ? )
                AND owner      = UPPER('$owner')
        ";
    }
    else        # We're a mortal USER
    {
      $stmt = 
        "
         SELECT
                '$owner'
              , index_name
         FROM
                user_part_indexes
         WHERE
                    table_name = UPPER( ? )
        ";
    }
  
    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my $aref = $sth->fetchall_arrayref;

    foreach my $row ( @$aref )
    {
      my ( $owner, $index ) = @$row;
      my $schema = _set_schema( $owner );

      $sql .= _resize_index(
                             $schema,
                             $owner,
                             $index,
                             $view
                           );
    }
  }

  return $sql;
}

# sub _resize_table_partition
#
# Returns DDL to rebuild one partition of the named object in the form of:
#
#     ALTER TABLE [schema.]<name> MOVE [SUB]PARTITION <partition>
#     STORAGE
#     (
#       INITIAL  <bytes>
#       NEXT     <bytes>
#     )
#
sub _resize_table_partition
{
  my( $schema, $owner, $name, $partition, $seg_type, $view ) = @_;

  my $sql;
  my $stmt =
      "
       SELECT
              s.blocks - NVL(t.empty_blocks,0)
            , s.initial_extent
            , s.next_extent
            , p.partitioning_type
       FROM
              ${view}_segments          s
            , ${view}_tab_${seg_type}s  t
            , ${view}_part_tables       p
       WHERE
                  s.segment_name   = UPPER( ? )
              AND s.partition_name = UPPER( ? )
              AND t.table_name     = UPPER( ? )
              AND t.partition_name = UPPER( ? )
              AND p.table_name     = UPPER( ? )
      ";
    if ( $view eq 'DBA' )
    {
      $stmt .= 
      "
              AND s.owner          = UPPER('$owner')
              AND p.owner          = UPPER('$owner')
              AND t.table_owner    = UPPER('$owner')
      ";
    }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name, $partition, $name, $partition, $name );
  my ( $blocks, $initial, $next, $partitioning_type ) = $sth->fetchrow_array;

  ( $initial, $next ) = _initial_next( $blocks ) if $attr{ 'resize' };

  $sql .= "PROMPT " .
          "ALTER TABLE \L$schema$name \UMOVE $seg_type \L$partition\n\n" .
          "ALTER TABLE \L$schema$name \UMOVE $seg_type \L$partition ";

  # Cannot specify storage parameters for a HASH [SUB]PARTITION
  if ( $seg_type eq 'PARTITION' and $partitioning_type eq 'RANGE' )
  {
    $sql .= "\nSTORAGE\n" .
            "(\n" .
            "  INITIAL  $initial\n" .
            "  NEXT     $next\n" .
            ") ";
  }

  $sql .= ";\n\n";

  return $sql;
}

# sub _scratch_prompts
#
# Eliminates all PROMPT statements
#
sub _scratch_prompts
{
  # Drop all lines beginning with PROMPT
  $ddl = ( join "\n",grep !/^PROMPT/,split /\n/,$ddl );

  # This would have left the first line blank, so drop it
  $ddl =~ s|\A\n||;

  # Get rid of double blank lines
  $ddl =~ s|\n\n+|\n\n|g;
}

# sub _segments_attributes
#
# Formats the segment attributes portion of CREATE TABLE and CREATE INDEX
# statements
#
sub _segment_attributes
{
  my ( $arrayref ) = @_;

  my $sql;
  my (
       $indent,
       # Physical Properties
       $organization,
       # Segment Attributes
       $cache,
       $pct_used,
       $pct_free,
       $ini_trans,
       $max_trans,
       $initial,
       $next,
       $min_extents,
       $max_extents,
       $pct_increase,
       $freelists,
       $freelist_groups,
       $buffer_pool,
       $logging,
       $tablespace,
       $blocks,
     ) = @$arrayref;

  unless ( $attr{ 'storage' } )
  {
    if ( $attr{ 'tblspace' } )
    {
      $sql .= "${indent}TABLESPACE          \L$tablespace\n";
    }

    return $sql;
  }

  ( $initial, $next ) = _initial_next( $blocks ) if $attr{ 'resize' };

  if ( $organization eq 'HEAP' )
  {
    $sql = "${indent}$cache\n"       unless $cache eq 'N/A';
    $sql .="${indent}PCTUSED             $pct_used\n"    unless $isasnapindx;
  }

  $sql .= "${indent}PCTFREE             $pct_free\n"     unless $isasnapindx;
 
  $sql .= "${indent}INITRANS            $ini_trans\n"    unless $isasnaptabl; 

  $sql .= "${indent}MAXTRANS            $max_trans\n" .
          "${indent}STORAGE\n" .
          "${indent}(\n" .
          "${indent}  INITIAL           $initial\n" .
          "${indent}  NEXT              $next\n" .
          "${indent}  MINEXTENTS        $min_extents\n" .
          "${indent}  MAXEXTENTS        $max_extents\n" .
          "${indent}  PCTINCREASE       $pct_increase\n";

    if (
            $oracle_major < 8
         or ( $oracle_major == 8 and $oracle_minor == 0 )
       )
    {
      unless (
                  $isasnaptabl
               or $isasnapindx
             )
      {
        $sql .= "${indent}  FREELISTS         $freelists\n" .
                "${indent}  FREELIST GROUPS   $freelist_groups\n";
      }
    }
    else
    {
      $sql .= "${indent}  FREELISTS         $freelists\n" .
              "${indent}  FREELIST GROUPS   $freelist_groups\n";
    }


    if (
            $oracle_major > 8
         or ( $oracle_major == 8 and $oracle_minor > 0 )
       )
    {
      $sql .= "${indent}  BUFFER_POOL       $buffer_pool\n";
    }

  $sql .= "${indent})\n";

  $sql .= "${indent}$logging\n"    if $oracle_major > 7;

  if ( $attr{ 'tblspace' } )
  {
    $sql .= "${indent}TABLESPACE          \L$tablespace\n";
  }

  return $sql;
}

sub _set_schema
{
  my $owner = shift;

  my $schema = ( "\U$owner" eq 'PUBLIC' ) ? 'PUBLIC'               :
               ( $attr{ schema } == 1   ) ? $owner . '.'           :
               ( $attr{ schema } )        ? $attr{ schema }  . '.' : '';

  return $schema;
}

# sub _set_sizing
#
# If %attr has an entry for "resize" == l, generates an arbitrary sizing
# algorithm wherein the database block size is used to create an array such
# that each object will have no more than 8 extents.  The INITIAL and NEXT
# sizes of Tables and Indexes are set to the calculated value.
#
# If %attr DOES contain an entry for "resize", it is parsed and stored in the
# array called @size_arr.
#
sub _set_sizing 
{
  $sth = $dbh->prepare(
      "
       SELECT
              block_size
       FROM
              (
                SELECT
                       bytes / blocks   AS block_size
                FROM
                       user_segments
                WHERE
                           bytes  IS NOT NULL
                       AND blocks IS NOT NULL
                       AND rownum  < 2
                UNION
                SELECT
                       bytes / blocks   AS block_size
                FROM
                       user_free_space
                WHERE
                           bytes  IS NOT NULL
                       AND blocks IS NOT NULL
                       AND rownum  < 2
              )
       WHERE
              rownum < 2
      ");

  $sth->execute;
  $block_size = $sth->fetchrow_array / 1024;

  if ( $attr{ 'resize' } == 1 )
  {
    # Create default array
    for my $i ( 0 .. 4 )
    {
      my $limit = ( 4 * ( 10 ** ( $i + 1 ) ) + 1 );
      my $initial = my $next = ( 5 * $block_size ) * ( 10 ** $i ) . "K";
      push @size_arr, [$limit, $initial, $next];
    }
    # Force upper limit bound
    $size_arr[$#size_arr][0] = 'UNLIMITED';
  }
  elsif ( $attr{ 'resize' } )
  {
    # parse user supplied string into @size_arr
    my $remainder = $attr{ 'resize' };
    while ( $remainder ) 
    {
      ( my ($limit,$initial,$next),$remainder ) = split /:/, $remainder, 4;

      die "\nSupplied resize string is malformed.\n\n" unless $initial;
      die "\nSupplied resize string is malformed.\n\n" unless $next;

      push @size_arr, [$limit, $initial, $next];
    }
    # Force upper limit bound
    $size_arr[$#size_arr][0] = 'UNLIMITED';
  }
}

#sub _show_free_space
#
# Reutrns a report in the form of:
#
# Space analysis for: [schema.]<object name>
# 
#                                                  BYTES     BLOCKS
#                                           ============  =========
# Used BELOW the high water mark                 1325056        647
# Free ABOVE the high water mark                  716800        350
# Free BELOW the high water mark                    6144          3
#                                           ------------  ---------
#               TOTAL in segment                 2048000       1000
# 
#                                      FILE_ID  BLOCK_ID  BLOCK_NBR
#                                      =======  ========  =========
# Last extent having data                    9     10287        150
#
sub _show_free_space
{
  my ( $owner, $name, $type, $view ) = @_;

  my $stmt =
      "
       SELECT
              'Yes, I can execute package DBMS_SPACE'
       FROM
              all_tab_privs
       WHERE
                  privilege    = 'EXECUTE'
              AND table_name   = 'DBMS_SPACE'
              AND table_schema = 'SYS'
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  my ( $can_execute ) = $sth->fetchrow_array;
  die "Either you or PUBLIC must have EXECUTE privilege on package\n",
      "sys.DBMS_SPACE in order to produce the FREE SPACE report.\n\n"
    unless $can_execute;

  if ( $oracle_major == 7 or "\U$type" eq 'CLUSTER' )
  {
    $stmt =
      "
       SELECT
              'NO'                    AS partitioned
       FROM
              ${view}_segments
       WHERE
                  segment_name = UPPER( ? )
              AND segment_type = UPPER( '$type' )
      ";
  }
  else
  {
    my $plural = ( "\U$type" eq 'INDEX' ) ? 'ES' : 'S';

    $stmt =
      "
       SELECT
              partitioned
       FROM
              ${view}_$type$plural
       WHERE
                  ${type}_name = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
      $stmt .=
        "
              AND owner       = UPPER('$owner')
        ";
  }

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my ( $partitioned ) = $sth->fetchrow_array;
  die "\u\L$type \U$name \Ldoes not exist.\n\n" unless $partitioned;

  my $text  = "Space analysis for: \U$owner.$name\n\n";

  if ( $partitioned eq 'YES' )
  {
    my (
         $section,
         $total_blocks,
         $total_bytes,
         $unused_blocks,
         $unused_bytes,
         $free_blocks,
         $sum_total_blocks,
         $sum_total_bytes,
         $sum_unused_blocks,
         $sum_unused_bytes,
         $sum_free_blocks,
       );

    $stmt =
      "
       SELECT
              RPAD(partition_name,30)
            , segment_type
       FROM
              ${view}_segments
       WHERE
                  segment_name = UPPER( ? )
      ";

    if ( $view eq 'DBA' )
    {
      $stmt .=
        "
              AND owner       = UPPER('$owner')
        ";
    }

    $stmt .=
      "
       ORDER
          BY
              partition_name
      ";

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $name );
    my $aref = $sth->fetchall_arrayref;

    foreach my $row (@$aref )
    {
      my ( $partition, $seg_type ) = @$row;

      (
        $section,
        $total_blocks,
        $total_bytes,
        $unused_blocks,
        $unused_bytes,
        $free_blocks,
      ) = _print_space( $owner, $name, $seg_type, $partition );

      $text .= $section;

      $sum_total_blocks  += $total_blocks;
      $sum_total_bytes   += $total_bytes;
      $sum_unused_blocks += $unused_blocks;
      $sum_unused_bytes  += $unused_bytes;
      $sum_free_blocks   += $free_blocks;
    }

    $text .= "TOTAL segment                                    BYTES" .
             "     BLOCKS\n" .
             "                                          ============" .
             "  =========\n" .
             sprintf(
                      "Used BELOW the high water mark            %12d  %9d\n",
                      $sum_total_bytes - $sum_unused_bytes 
                        - $sum_free_blocks * $block_size * 1024,
                      $sum_total_blocks - $sum_unused_blocks - $sum_free_blocks
                    ) .
             sprintf(
                      "Free ABOVE the high water mark            %12d  %9d\n",
                      $sum_unused_bytes, $sum_unused_blocks
                    ) .
             sprintf(
                      "Free BELOW the high water mark            %12d  %9d\n",
                      $sum_free_blocks * $block_size * 1024, $sum_free_blocks
                    ) .
             "                                          ------------" .
             "  ---------\n" .
             sprintf(
                      "        GRAND TOTAL in segment            %12d  %9d\n\n",
                      $sum_total_bytes, $sum_total_blocks
                    );

    return $text;
  }
  else  # Not partitioned
  {
    ( my $section ) = _print_space( $owner, $name, $type );
    return $text . $section;
  }
}

#sub _subpartition_key_columns
#
# Returns a formatted string containing the subpartitioning key columns
#
sub _subpartition_key_columns
{
  return _key_columns( @_, 'SUBPART' );
}

# sub _table_columns
#
# Returns a formatted string containing the column names, datatype and
# length, and NOT NULL (if appropriate) for use in a CREATE TABLE
# statement.
#
sub _table_columns
{
  my ( $owner, $name, $view ) = @_;

  my $stmt;

  if ( $oracle_major == 7 )
  {
    $stmt =
      "
       SELECT
              RPAD(LOWER(column_name),32)
           || RPAD(
                   DECODE(
                           data_type
                          ,'NUMBER',DECODE(
                                            data_precision
                                           ,null,DECODE(
                                                         data_scale
                                                        ,0,'INTEGER'
                                                        ,  'NUMBER   '
                                                       )
                                           ,'NUMBER   '
                                          )
                          ,'RAW'     ,'RAW      '
                          ,'CHAR'    ,'CHAR     '
                          ,'NCHAR'   ,'NCHAR    '
                          ,'UROWID'  ,'UROWID   '
                          ,'VARCHAR2','VARCHAR2 '
                          ,data_type
                         )
                     || DECODE(
                                data_type
                               ,'DATE',null
                               ,'LONG',null
                               ,'NUMBER',DECODE(
                                                 data_precision
                                                ,null,null
                                                ,'('
                                               )
                               ,'RAW'      ,'('
                               ,'CHAR'     ,'('
                               ,'NCHAR'    ,'('
                               ,'UROWID'   ,'('
                               ,'VARCHAR2' ,'('
                               ,'NVARCHAR2','('
                               ,null
                              )
                     || DECODE(
                                data_type
                               ,'RAW'      ,data_length
                               ,'CHAR'     ,data_length
                               ,'NCHAR'    ,data_length
                               ,'UROWID'   ,data_length
                               ,'VARCHAR2' ,data_length
                               ,'NVARCHAR2',data_length
                               ,'NUMBER'   ,data_precision
                               , null
                              )
                     || DECODE(
                                data_type
                               ,'NUMBER',DECODE(
                                 data_precision
                                ,null,null
                                ,DECODE(
                                         data_scale
                                        ,null,null
                                        ,0   ,null
                                        ,',' || data_scale
                                       )
                                    )
                              )
                     || DECODE(
                                data_type
                               ,'DATE',null
                               ,'LONG',null
                               ,'NUMBER',DECODE(
                                                 data_precision
                                                ,null,null
                                                ,')'
                                               )
                               ,'RAW'      ,')'
                               ,'CHAR'     ,')'
                               ,'NCHAR'    ,')'
                               ,'UROWID'   ,')'
                               ,'VARCHAR2' ,')'
                               ,'NVARCHAR2',')'
                               ,null
                              )
                   ,33
                  )
            , nullable
            , data_default
       FROM
              ${view}_tab_columns
       WHERE
                  table_name = UPPER( ? )
      ";
  }
  else                  # We're newer than Oracle7
  {
    $stmt =
      "
       SELECT
              RPAD(LOWER(column_name),32)
           || RPAD(
                   DECODE(
                           data_type
                          ,'NUMBER',DECODE(
                                            data_precision
                                           ,null,DECODE(
                                                         data_scale
                                                        ,0,'INTEGER'
                                                        ,  'NUMBER   '
                                                       )
                                           ,'NUMBER   '
                                          )
                          ,'RAW'     ,'RAW      '
                          ,'CHAR'    ,'CHAR     '
                          ,'NCHAR'   ,'NCHAR    '
                          ,'UROWID'  ,'UROWID   '
                          ,'VARCHAR2','VARCHAR2 '
                          ,data_type
                         )
                     || DECODE(
                                data_type
                               ,'DATE',null
                               ,'LONG',null
                               ,'NUMBER',DECODE(
                                                 data_precision
                                                ,null,null
                                                ,'('
                                               )
                               ,'RAW'      ,'('
                               ,'CHAR'     ,'('
                               ,'NCHAR'    ,'('
                               ,'UROWID'   ,'('
                               ,'VARCHAR2' ,'('
                               ,'NVARCHAR2','('
                               ,null
                              )
                     || DECODE(
                                data_type
                               ,'RAW'      ,data_length
                               ,'CHAR'     ,data_length
                               ,'NCHAR'    ,data_length
                               ,'UROWID'   ,data_length
                               ,'VARCHAR2' ,data_length
                               ,'NVARCHAR2',data_length
                               ,'NUMBER'   ,data_precision
                               , null
                              )
                     || DECODE(
                                data_type
                               ,'NUMBER',DECODE(
                                 data_precision
                                ,null,null
                                ,DECODE(
                                         data_scale
                                        ,null,null
                                        ,0   ,null
                                        ,',' || data_scale
                                       )
                                    )
                              )
                     || DECODE(
                                data_type
                               ,'DATE',null
                               ,'LONG',null
                               ,'NUMBER',DECODE(
                                                 data_precision
                                                ,null,null
                                                ,')'
                                               )
                               ,'RAW'      ,')'
                               ,'CHAR'     ,')'
                               ,'NCHAR'    ,')'
                               ,'UROWID'   ,')'
                               ,'VARCHAR2' ,')'
                               ,'NVARCHAR2',')'
                               ,null
                              )
                   ,32
                  )
            , nullable
            , data_default
       FROM
              ${view}_tab_columns
       WHERE
                  table_name = UPPER( ? )
      ";
  }

  if ( $view eq 'DBA' )
  {
    $stmt .=
      "
              AND owner      = UPPER('$owner')
      ";

  }

  $stmt .= 
      "
       ORDER
          BY
             column_id
      ";

  $dbh->{ LongReadLen } = 1024;    # Allows Default to be 1K
  $dbh->{ LongTruncOk } = 1;

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $name );
  my $aref = $sth->fetchall_arrayref;

  my @cols;
  foreach my $row ( @$aref )
  {
    my ( $column, $nullable, $default ) = @$row;

    # Knock off any trailing newlines
    chomp $default;

    $column .= "DEFAULT $default "   if defined $default;
    $column .= 'NOT NULL'            if $nullable eq 'N';

    push @cols, $column;
  }

  return join ( "\n  , ", @cols ) . "\n";
}

1;

__END__

########################################################################

=head1 NAME

DDL::Oracle - a DDL generator for Oracle databases

=head1 VERSION

VERSION = 1.11

=head1 SYNOPSIS

 use DBI;
 use DDL::Oracle;

 my $dbh = DBI->connect(
                         "dbi:Oracle:dbname",
                         "username",
                         "password",
                         {
                          PrintError => 0,
                          RaiseError => 1
                         }
                       );

 # Use default resize and schema options.
 # query default DBA_xxx tables (could use USER_xxx for non-DBA types)
 DDL::Oracle->configure( 
                         dbh    => $dbh,
                       );

 # Create a list of one or more objects
 my $sth = $dbh->prepare(
        "SELECT
                owner
              , table_name
         FROM
                dba_tables
         WHERE
                tablespace_name = 'MY_TBLSP'    -- your mileage may vary
        "
     );

 $sth->execute;
 my $list = $sth->fetchall_arrayref;

 my $obj = DDL::Oracle->new(
                             type  => 'table',
                             list  => $list,                          );
                           );

 my $ddl = $obj->create;      # or $obj->resize;  or $obj->drop;  etc.

 print $ddl;    # Use STDOUT so user can redirect to desired file.

 # Here's another example, this time for type 'components'.  This type
 # differs from the norm, because it has no owner and no name.

 my $obj = DDL::Oracle->new(
                             type => 'components',
                             list => [[ 'no owner','no name' ]]
                           );

 my $ddl = $obj->create;

 print $ddl;


=head1 DESCRIPTION

=head2 Overview

Designed for Oracle DBA's and users.  It reverse engineers database
objects (tables, indexes, users, profiles, tablespaces, roles, 
constraints, etc.).  It generates DDL to *resize* tables and indexes 
to the provided standard or to a user defined standard.

We originally wrote a script to defrag tablespaces, but as DBA's 
we regularly find a need for the DDL of a single object or a list 
of objects (such as all of the indexes for a certain table).  So 
we took all of the DDL statement creation logic out of defrag.pl, 
and put it into the general purpose DDL::Oracle module, then 
expanded that to include tablespaces, users, roles, and all other 
dictionary objects.

Oracle tablespaces tend to become fragmented (now THAT's an 
understatement).  Even when object sizing standards are adopted, 
it is difficult to get 100% compliance from users.  And even if 
you get a high degree of compliance, objects turn out to be a 
different size than originally thought/planned -- small tables 
grow to become large (i.e., hundreds of extents), what was thought 
would be a large table ends up having only a few rows, etc.  So 
the main driver for DDL::Oracle was the object management needs of 
Oracle DBA's.  The "resize" method generates DDL for a list of 
tables or indexes.  For partitioned objects, the "appropriate" 
size of EACH partition is calculated and supplied in the generated 
DDL.

=head2 Initialization and Constructor 

configure

The B<configure> method is used to supply the DBI connection and to set
several session level attributes.  These are:

      dbh      A reference to a valid DBI connection (obtained via
               DBI->connect).  This is the only mandatory attribute.

               NOTE: The user connecting should have SELECT privileges
                     on the following views (in addition to the DBA or
                     USER views), but see attributes 'heading' for
                     exceptions:

                         V$DATABASE [i.e., sys.V_$DATABASE table]

                     And, in order to generate CREATE SNAPSHOT LOG
                     statements, you will also need to create a PUBLIC
                     SYNONYM for DBA_SNAPSHOT_LOG_FILTER_COLS.  In
                     order for non-DBA users to do the same, you will
                     need to grant SELECT on this view to them (e.g.,
                     to PUBLIC).  Why Oracle Corp. feels this view is
                     of no interest to non-replication users is a
                     mystery to the author.

                     And, in order to generate CREATE INDEX statements
                     for indexes which have DESCending column(s) and/or
                     include FUNCTION based column(s), you must have
                     select privileges on SYS.COL$, wherein the real
                     name of the column or function definition is held.

      schema   Defines whether and what to use as the schema for DDL
               on objects which use this syntax.  "1" means use the
               owner of the object as the schema; "0" or "" means
               omit the schema syntax; any other arbtrary string will
               be imbedded in the DDL as the schema.  The default is "1".

      resize   Defines whether and what to use in resizing segments.
               "1" means resize segments using the default algorithm;
               "0" or "" means keep the current INITIAL and NEXT
               values; any other string will be interpreted as a
               resize definition.  The default is "1".

               To establish a user defined algorithm, define this with
               a string consisting of n sets of LIMIT:INITIAL:NEXT.
               LIMIT is expressed in Database Blocks.  The highest LIMIT
               may contain the string 'UNLIMITED', and in any event will
               be forced to be so by DDL::Oracle.

      view     Defines which Dictionary views to query:  DBA or USER
               (e.g., DBA_TABLES or USER_TABLES).  The default is DBA.

      heading  Defines whether to include a Heading having Host, Instance,
               Date/Time, List of generated Objects, etc.  "1" means 
               include the heading; "0" or "" means to suppress the
               heading (and eliminate the query against V$DATABASE).
               The default is "1".

      prompt   Defines whether to include a PROMPT statement along
               with the DDL.  If the output is intended for use in
               SQL*Plus, this will cause SQL*Plus to display a comment
               about each statement before it executes, which can be
               helpful in a multi-statement file.  "1" means include
               the prompt; "0" or "" means to suppress the prompt.

      grants   Defines whether to include object grants following a
               CREATE statement for Tables, Views, Materialized Views
               [Snapshots], Sequences, Procedures, Functions, Packages,
               Types and Synonyms.   "1" means include the grant state-
               ments; "0" or "" means to suppress the grant statements.
               The default is "0".

      storage  Defines whether to include the STORAGE clause [plus
               PCTUSED, PCTFREE, INITRANS and MAXTRANS] in DDL for tables
               and indexes. "1" means include these clauses; "0" or ""
               means omit them. The default is "1".

      tblspace Defines whether to include the TABLESPACE clause in DDL
               for tables and indexes.  "1" means include this clause;
               "0" or "" means omit it. The default is "1".
new  

The B<new> method is the object constructor.  The two mandatory object
definitions are supplied with this method, to wit:

      type    The type of object (e.g., TABLE, INDEX, SYNONYM, family,
              etc.).

              For 'table family', supply the name(s) of tables -- the
              DDL will include the table and its:
                  Comments (Table and Column)
                  Indexes
                  Constraints
                  Triggers

      list    An arrayref to an array of arrayrefs (as in the DBI's 
             "fetchall_arrayref" method) containing pairs of owner and
              name.

=head2 Object methods

create

The B<create> method generates the DDL to create the list of Oracle objects.
Virtually every type of Oracle object (table, index, user, synonym, trigger,
etc.) can be CREATEd via this method -- see hash %create for a complete list.
There is also a type called 'components' which is an aggregate type.  It
generates the DDL for all objects of types which do not have an owner
(tablespace, rollback segment, profile, role, user) and for PUBLIC database
links and synonyms.  See the SYNOPSIS for an example of this.

drop

The B<drop> method generates the DDL to drop the list of Oracle objects.

resize

The B<resize> method generates the DDL to resize the list of Oracle objects.
The 'type' defined in the 'new' method is limited to 'index' and 'table'.
For tables, this generates an ALTER TABLE MOVE statement; for indexes, it
generates an ALTER INDEX REBUILD statement.  If the table or index is
partitioned, then a statement for each partition is generated.

To generate DDL for a single partition of an index or table, define the 'name'
as a colon delimited field (e.g., 'name:partition'). 

compile

The B<compile> method generates the DDL to compile the list of Oracle objects.
The 'type' defined in the 'new' method is limited to 'function', 'package',
'procedure', 'trigger' and 'view'.

show_space

The B<show_space> method produces a report showing used/unused bytes and
blocks above/below the high water mark in a segment.  It includes the
free blocks below the high water mark.  For partitioned objects, it shows
the information for each partition, with grand totals for the table/index.
The object does NOT need to be analyzed for this report to be accurate --
it uses package sys.DBMS_SPACE to collect the data.

=head1 BUGS

=head1 FILES

 copy_user.pl
 copy_user.sh
 ddl.pl
 defrag.pl
 query.pl

=head1 AUTHOR

 Richard V. Sutherland
 rvsutherland@yahoo.com

=head1 COPYRIGHT

Copyright (c) 2000, 2001 Richard V. Sutherland.  All rights reserved.
This module is free software.  It may be used, redistributed,
and/or modified under the same terms as Perl itself.  See:

    http://www.perl.com/perl/misc/Artistic.html

=cut

