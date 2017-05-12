#$Id: Oracle.pm,v 1.18 2007/01/24 15:22:57 jef539 Exp $
package DBIx::Fun::Oracle;
use strict;
use warnings;
use DBD::Oracle;
use Carp ();

use base 'DBIx::Fun';
our $VERSION = '0.01';

# proc
# package . proc
# schema  . package . proc
# syn
# syn     . proc
# schema  . syn
# schema  . syn     . proc

sub _lookup_synonym {

    # print STDERR "LOOKUP SYNONYM @_\n";
    my ( $self, $syn ) = @_;
    my @path = $self->_path;
    return if @path > 1;

    my $schema = $path[0];

    my ( $sth, $count );

    if ( defined $schema ) {
        $sth = $self->dbh->prepare(<<EOQ);
        SELECT COUNT(*)
        FROM ALL_SYNONYMS
        WHERE SYNONYM_NAME = UPPER(?) 
        AND OWNER = UPPER(?)
EOQ
        $sth->execute( $syn, $schema );
        ($count) = $sth->fetchrow_array;
        $sth->finish;
    }
    else {
        $sth = $self->dbh->prepare(<<EOQ);
        SELECT TABLE_OWNER, TABLE_NAME
        FROM USER_SYNONYMS
        WHERE SYNONYM_NAME = UPPER(?) 
EOQ
        $sth->execute($syn);
        ($count) = $sth->fetchrow_array;
        $sth->finish;

        if ( not $count ) {
            $sth = $self->dbh->prepare(<<EOQ);
            SELECT TABLE_OWNER, TABLE_NAME
            FROM ALL_SYNONYMS
            WHERE SYNONYM_NAME = UPPER(?) 
            AND OWNER = 'PUBLIC'
EOQ
            $sth->execute($syn);
            ($count) = $sth->fetchrow_array;
            $sth->finish;
        }
    }
    return $count;
}

sub _lookup_user {

    # print STDERR "LOOKUP USER @_\n";
    my ( $self, $user ) = @_;
    return if $self->_path;

    my $sth = $self->dbh->prepare(<<EOQ);
    SELECT COUNT(*)
    FROM ALL_USERS
    WHERE USERNAME = UPPER(?)
EOQ
    $sth->execute($user);
    my ($count) = $sth->fetchrow_array;
    $sth->finish;

    return $count;
}

sub _lookup_package {

    # print STDERR "LOOKUP PACKAGE @_\n";
    my ( $self, $package ) = @_;
    my @path = $self->_path;
    return if @path > 1;

    my $owner = $path[0];
    if ( defined $owner ) {
        my $sth = $self->dbh->prepare(<<EOQ);
       SELECT COUNT(*)
         FROM ALL_OBJECTS
        WHERE OBJECT_NAME = UPPER(?)
          AND OWNER = UPPER(?)
          AND OBJECT_TYPE = 'PACKAGE'
EOQ
        $sth->execute( $package, $owner );
        my ($count) = $sth->fetchrow_array;
        $sth->finish;
        return $count;
    }
    my $sth = $self->dbh->prepare(<<EOQ);
       SELECT COUNT(*)
         FROM USER_OBJECTS
        WHERE OBJECT_NAME = UPPER(?)
          AND OBJECT_TYPE = 'PACKAGE'
EOQ
    $sth->execute($package);
    my ($count) = $sth->fetchrow_array;
    $sth->finish;
    return $count;
}

sub _lookup_procedure {

    # print STDERR "LOOKUP PROCEDURE @_\n";
    my ( $self, $proc ) = @_;
    my @path = $self->_path;
    return unless _path_ok( @path, $proc );

    my $path = uc join '.', map { qq("$_") } @path, $proc;

    my $ref = eval { $self->_describe_procedure($path) };

    # retry if invalid
    $ref = eval { $self->_describe_procedure($path) }
      if $@ =~ /ORA-20003/;

    # Carp::croak $@ if $@ and $@ !~ /ORA-06564|ORU-10035|ORU-10032/;

    return $ref;
}

sub _lookup_standard_procedure {

    # print STDERR "LOOKUP STANDARD PROCEDURE @_\n";
    my ( $self, $proc ) = @_;
    my @path = $self->_path;
    return if @path != 0 and @path != 2;
    return
      if @path == 2
      and ( uc( $path[0] ) ne 'SYS' or uc( $path[0] ) ne 'STANDARD' );

    local $self->dbh->{FetchHashKeyName} = 'NAME_lc';

    my $ref = $self->dbh->selectall_arrayref( <<EOQ, {}, $proc );
       SELECT OVERLOAD, SEQUENCE, POSITION, 
         ARGUMENT_NAME, DATA_LEVEL, IN_OUT, DATA_TYPE
         FROM ALL_ARGUMENTS
        WHERE OBJECT_NAME = UPPER(?) 
        AND OWNER = 'SYS'
        AND PACKAGE_NAME = 'STANDARD'
        ORDER BY OBJECT_NAME, OVERLOAD, SEQUENCE
EOQ
    return if not $ref or not @$ref;

    my @over;

    for my $row (@$ref) {
        my ( $overload, $sequence, $position, $name, $level, $inout, $type ) =
          @$row;

        $overload ||= 0;

        my $ref = $over[$overload] ||= {};

        my $l = $level;

        $ref = $ref->{pos}[-1]{type} while ( $l-- > 0 );
        $ref->{pos} ||= [undef];

        next if not $type;

        $position-- if $level;

        $ref->{pos}[$position] = {
            name => $name,
            type => DBIx::Fun::Oracle::type->new( name => $type ),
            $level > 0
            ? ()
            : (
                in  => scalar( $inout =~ /in/i ),
                out => scalar( $inout =~ /out/i ),
            ),
        };

        $ref->{arg}{ uc $name } = $ref->{pos}[$position]
          if defined $name
          and length $name;
    }

    return \@over;
}

sub _lookup {
    my ( $self, $name ) = @_;
    return unless _path_ok($name);

    # HASH = context
    # CODE = procedure

    my $ref = $self->{cache}{$name};

    if ( not $self->{cache}{$name} ) {

        my $obj = $self->_lookup_procedure($name);

        if ( not $obj ) {
            $obj = $self->_lookup_package($name);
        }
        if ( not $obj ) {
            $obj = $self->_lookup_synonym($name);
        }
        if ( not $obj ) {
            $obj = $self->_lookup_user($name);
        }

        if ( not $obj ) {
            $obj = $self->_lookup_standard_procedure($name);
        }

        if ( ref $obj ) {
            $self->{cache}{$name} = $self->_make_procedure( $name, $obj );
        }
        elsif ($obj) {
            $self->{cache}{$name} =
              { name => $name, path => [ $self->_path, $name ], cache => {} };
        }

        $ref = $self->{cache}{$name};
    }
    return $ref if ref($ref) eq 'CODE';
    return $self->context(%$ref) if $ref;
    return \&_fetch_variable;
}

sub _fetch_variable {
    my ( $self, $name ) = @_;

    my @path = $self->_path;

    $self->_croak_notfound($name) unless _path_ok( @path, $name );

    my $path = uc join '.', map { qq("$_") } @path, $name;
    my $out;

    local $self->dbh->{RaiseError}  = 1;
    local $self->dbh->{HandleError} = undef;
    local $self->dbh->{PrintError}  = 0;

    eval {
        my $sth = $self->dbh->prepare(<<EOQ);
BEGIN
    :out := $path;
END;
EOQ
        $sth->bind_param_inout( ':out', \$out, 4096 );
        $sth->execute;
    };

    if ($@) {
        $self->_croak_notfound($name) if $@ =~ /PLS-00302|PLS-00201|PLS-00222/;
        Carp::croak $@;
    }

    return $out;
}

sub _path_ok {
    shift if ref( $_[0] ) and UNIVERSAL::isa( $_[0], __PACKAGE__ );
    return unless @_;
    for (@_) {
        return unless defined and /^[A-Za-z][\w\$\#]*\z/;
    }
    return 1;
}

#=== DESCRIBE

# ALL_ARGUMENTS does not properly return defaults
# so we call DBMS_DESCRIBE.DESCRIBE_PROCEDURE

my %datatype = (
    0,   undef,
    1,   'VARCHAR2',
    2,   'NUMBER',
    3,   'BINARY_INTEGER',                   # 'NATIVE INTEGER',
    8,   'LONG',
    9,   'VARCHAR',
    11,  'ROWID',
    12,  'DATE',
    23,  'RAW',
    24,  'LONG RAW',
    29,  'BINARY_INTEGER',
    69,  'ROWID',
    96,  'CHAR',
    102, 'REF CURSOR',
    104, 'UROWID',
    105, 'MLSLABEL',
    106, 'MLSLABEL',
    110, 'REF',
    111, 'REF',
    112, 'CLOB',
    113, 'BLOB',
    114, 'BFILE',
    115, 'CFILE',
    121, 'OBJECT',
    122, 'TABLE',
    123, 'VARRAY',
    178, 'TIME',
    179, 'TIME WITH TIME ZONE',
    180, 'TIMESTAMP',
    181, 'TIMESTAMP WITH TIME ZONE',
    231, 'TIMESTAMP WITH LOCAL TIME ZONE',
    182, 'INTERVAL YEAR TO MONTH',
    183, 'INTERVAL DAY TO SECOND',
    250, 'PL/SQL RECORD',
    251, 'PL/SQL TABLE',
    252, 'BOOLEAN',                          # 'PL/SQL BOOLEAN',
);
my %inout = ( 0, 'IN', 1, 'OUT', 2, 'IN/OUT' );

sub _describe_procedure {

    my ( $self, $path ) = @_;

    # print STDERR "DESCRIBE $path\n";
    my $sql = <<EOQ;
DECLARE
   overload        DBMS_DESCRIBE.NUMBER_TABLE;
   position        DBMS_DESCRIBE.NUMBER_TABLE;
   level           DBMS_DESCRIBE.NUMBER_TABLE;
   argument_name   DBMS_DESCRIBE.VARCHAR2_TABLE;
   datatype        DBMS_DESCRIBE.NUMBER_TABLE;
   default_value   DBMS_DESCRIBE.NUMBER_TABLE;
   in_out          DBMS_DESCRIBE.NUMBER_TABLE;
   length          DBMS_DESCRIBE.NUMBER_TABLE;
   precision       DBMS_DESCRIBE.NUMBER_TABLE;
   scale           DBMS_DESCRIBE.NUMBER_TABLE;
   radix           DBMS_DESCRIBE.NUMBER_TABLE;
   spare           DBMS_DESCRIBE.NUMBER_TABLE; 
   
   buffer VARCHAR2(32000) := '';
   i NUMBER;
BEGIN

DBMS_DESCRIBE.DESCRIBE_PROCEDURE(
   :input         , NULL, NULL ,
   overload       ,
   position       ,
   level          ,
   argument_name  ,
   datatype       ,
   default_value  ,
   in_out         ,
   length         ,
   precision      ,
   scale          ,
   radix          ,
   spare          ); 
  
  i := overload.FIRST;
  WHILE i IS NOT NULL
  LOOP
      buffer := buffer || 
                overload(i)      || ',' ||
                position(i)      || ',' ||
                level(i)         || ',' ||
                argument_name(i) || ',' ||
                in_out(i)        || ',' ||
                default_value(i) || ',' ||
                datatype(i)      || chr(10);
       i := overload.next(i);
  END LOOP;

  :output := buffer;
END;
EOQ

    my $dbh = $self->dbh;
    local $dbh->{RaiseError}  = 1;
    local $dbh->{HandleError} = undef;
    local $dbh->{PrintError}  = 0;

    my $sth = $dbh->prepare($sql);
    my $output;

    $sth->bind_param( ":input", $path );
    $sth->bind_param_inout( ":output", \$output, 32767 );
    $sth->execute();

    my @lines = split /\n/, $output;

    my %fulltype;

    for my $line (@lines) {
        my ( $overload, $position, $level, $name, $inout, $default, $type ) =
          split /,\s*/, $line;
        $type = $datatype{ $type || 0 } || $type;

        if ( $type =~ /record|table|varray/i ) {

            for my $desc ( _lookup_procedure_types( $dbh, $path ) ) {
                my ( $overload, $sequence, $position, $level, @type ) = @$desc;
                $position-- if $level;
                $fulltype{ $overload || 0 }{$position}{$level} = join '.',
                  grep $_, @type;
            }
            last;
        }
    }

    my @over;

    for my $line (@lines) {
        my ( $overload, $position, $level, $name, $inout, $default, $type ) =
          split /,\s*/, $line;

        #print "$line\n";
        $overload ||= 0;
        $type  = $datatype{ $type || 0 } || $type;
        $inout = $inout{ $inout   || 0 } || $inout;

        my $ref = $over[$overload] ||= {};

        my $l = $level;

        $ref = $ref->{pos}[-1]{type} while ( $l-- > 0 );
        $ref->{pos} ||= [undef];

        next if not $type;

        $position-- if $level;
        $ref->{pos}[$position] = {
            name => $name,
            type => DBIx::Fun::Oracle::type->new(
                name     => $type,
                fulltype => $fulltype{$overload}{$position}{$level},
            ),
            $level > 0
            ? ()
            : (
                default => $default,
                in      => scalar( $inout =~ /in/i ),
                out     => scalar( $inout =~ /out/i ),
            ),
        };

        $ref->{arg}{ uc $name } = $ref->{pos}[$position]
          if defined $name
          and length $name;
    }

    return \@over;
}

sub _lookup_procedure_types {
    my ( $dbh, $proc ) = @_;

    local $dbh->{RaiseError}       = 1;
    local $dbh->{HandleError}      = undef;
    local $dbh->{PrintError}       = 0;
    local $dbh->{FetchHashKeyName} = 'NAME_lc';

    my $sth = $dbh->prepare( <<EOQ );
    BEGIN
      DBMS_UTILITY.NAME_RESOLVE (
        :p_name, :p_context,
        :p_schema, :p_part1, :p_part2, :p_dblink,
        :p_part1_type, :p_object_number
      );
    END;
EOQ
    $sth->bind_param( ':p_name',    $proc );
    $sth->bind_param( ':p_context', 1 );
    $sth->bind_param_inout( ':p_schema',        \my $schema,        1024 );
    $sth->bind_param_inout( ':p_part1',         \my $part1,         1024 );
    $sth->bind_param_inout( ':p_part2',         \my $part2,         1024 );
    $sth->bind_param_inout( ':p_dblink',        \my $dblink,        1024 );
    $sth->bind_param_inout( ':p_part1_type',    \my $part1_type,    1024 );
    $sth->bind_param_inout( ':p_object_number', \my $object_number, 1024 );
    $sth->execute();

    my $ref = $dbh->selectall_arrayref( <<EOQ, {}, $schema, $part1, $part2 );
       SELECT OVERLOAD, SEQUENCE, POSITION,
         DATA_LEVEL, TYPE_OWNER, TYPE_NAME, TYPE_SUBNAME
         FROM ALL_ARGUMENTS
        WHERE OWNER = UPPER(?)
        AND NVL(PACKAGE_NAME, ' ') = NVL(UPPER(?), ' ')
        AND OBJECT_NAME = UPPER(?)
        ORDER BY OVERLOAD, SEQUENCE
EOQ
    return @$ref;
}

#=== MAKE

sub _make_procedure {
    my ( $self, $name, $desc ) = @_;
    my $fullname = uc join '.', map { qq("$_") } $self->_path, $name;

    # closure on $fullname, $desc;

    return sub {
        my ( $self, $name ) = @_;
        my $wantfunction = defined wantarray;
        my $retval;

        # args = @_[2 .. $#_]
        # argct = @_ - 2;

        my $dbh = $self->dbh;
        eval {
            my ( $spec, $named ) =
              _match_spec( $desc, $wantfunction, @_[ 2 .. $#_ ] );
            my $sql = _build_plsql( $spec, $fullname, $named, @_[ 2 .. $#_ ] );

            #print $sql; exit;

            local $dbh->{LongReadLen} = $dbh->{LongReadLen};
            $dbh->{LongReadLen} = 1_000_000 if $dbh->{LongReadLen} < 1_000_000;

            my $sth = $dbh->prepare($sql);

            $retval = _bind_execute( $sth, $spec, $named, @_[ 2 .. $#_ ] );
        };
        Carp::croak $@ if $@;
        return $retval;
    };
}

sub _match_spec {
    my ( $desc, $wantfunction ) = @_;
    my @nh = (undef);
    unshift @nh, $_[-1] if @_ > 2 and ref $_[-1] eq 'HASH';

    my ( $func, $proc, $fnamed, $pnamed );

    for my $named (@nh) {
        for my $spec (@$desc) {
            next unless $spec;
            my $have_named = $named ? 1 : 0;

            # args = @_[2 .. $#_]
            # argct = @_ - 2;

            my $spargc = $#{ $spec->{pos} };
            my $argc   = @_ - 2 - $have_named;

            # Too many input arguments ?
            next if $argc > $spargc;

            # All OUT args are refs

            next
              if grep {
                $spec->{pos}[$_]{out}
                  and ref( $_[ $_ + 1 ] ) !~ /SCALAR|REF/
              } ( 1 .. $argc );

            if ($named) {

                # Named args don't match?
                next if grep { not exists $spec->{arg}{ uc $_ } } keys %$named;

                # All OUT named args are refs
                next
                  if grep {
                    $spec->{arg}{ uc $_ }{out}
                      and ref( $named->{$_} ) !~ /SCALAR|REF/
                  }
                  keys %$named;
            }

            if ( $spec->{pos}[0] ) {
                $func   ||= $spec;
                $fnamed ||= $named;
            }
            else {
                $proc   ||= $spec;
                $pnamed ||= $named;
            }
        }
    }

    # choose the function if we want a result
    return $func, $fnamed if !$proc or ( $func and $wantfunction );

    return $proc, $pnamed;
}

sub _build_plsql {
    my ( $spec, $name, $named ) = @_;

    my $retval;

    my ( @plargs, @declare, @assign );

    my @keys = sort keys %{$named} if $named;

    # i = 0: \$retval
    # i = 1: $args->[$i-1]
    # i = $#$args:  $args[$#args-1]
    # i = @$args:   $args[$#args]   or key[0]

    my $posargct = @_ - 3;
    my $argct    = 1 + $posargct;
    $argct += @keys - 1 if $named;

    my @bind;
    for ( my $i = 0 ; $i < $argct ; $i++ ) {
        my $k    = $i - $posargct;
        my $spec =
            $named && $k >= 0
          ? $spec->{arg}{ uc $keys[$k] }
          : $spec->{pos}[$i];

        my $type = $spec->{type};

        # if ( plsql format )
        if ( $type && $type->needs_plsql_map ) {

            push @declare,
              $spec->{in}
              ? $type->initialize_plsql( "v_$i", ":p_$i" )
              : $type->declare_plsql("v_$i");

            push @assign, $type->assign_plsql( ":p_$i", "v_$i" )
              if $spec->{out};

            push @plargs, "v_$i";
        }
        else {
            push @plargs, ":p_$i";
        }

        $plargs[-1] = "$keys[ $k ] => $plargs[-1]"
          if $named && $i >= $posargct;

    }

    my $plargs  = join ', ',     @plargs[ 1 .. $#plargs ];
    my $declare = join "\n    ", @declare;
    my $assign  = join "\n    ", @assign;

    # do this if function
    my $return  = $spec->{pos}[0] ? "$plargs[0] := " : "";
    my $prelude = DBIx::Fun::Oracle::type::spec_pack( $spec );

    my $sql = <<EOQ;
DECLARE
  $prelude   
BEGIN
  DECLARE
    $declare
  BEGIN
    $return$name($plargs);

    $assign
  END;
END;
EOQ

    return $sql;
}

sub _bind_execute {
    my ( $sth, $spec, $named ) = @_;
    my $retval;

    my @keys = sort keys %{$named} if $named;

    # i = 0: \$retval
    # i = 1: $args->[$i-1]
    # i = $#$args:  $args[$#args-1]
    # i = @$args:   $args[$#args]   or key[0]

    my $posargct = @_ - 3;
    my $argct    = 1 + $posargct;
    $argct += @keys - 1 if $named;

    my ( @in, @out );

    for ( my $i = 0 ; $i < $argct ; $i++ ) {
        my $k   = $i - $posargct;
        my $arg =
            $named && $k >= 0
          ? $spec->{arg}{ uc $keys[$k] }
          : $spec->{pos}[$i];

        next if not $i and not $arg;

        my $type = $arg->{type};
        my $name = ":p_$i";

        my %attr;
        my $map = $type->typemap;
        if ( $map->{ora_type} ) {
            $attr{ora_type} = $map->{ora_type};
        }

        my $ref =
            !$i ? \$retval
          : $named && $k >= 0 ? \$named->{ $keys[$k] }
          : \$_[ $i + 2 ];

        $ref = $$ref if $i && $arg->{out};

        $in[$i] = $ref;

        if ( $arg->{out} and not $arg->{in} ) {
            $$ref = undef;
        }

        if ( $map->{perl_in} and $arg->{in} ) {
            my $temp = $map->{perl_in}( $$ref, $type );
            $ref = \$temp;
        }

        $out[$i] = $ref;

        if ( $arg->{out} ) {
            $sth->bind_param_inout( $name, $ref, 32767, \%attr );
        }
        else {
            $sth->bind_param( $name, $$ref, \%attr );
        }
    }

    $sth->execute or return;

    for ( my $i = 0 ; $i < $argct ; $i++ ) {
        next unless my $arg = $spec->{pos}[$i];
        my $type = $arg->{type};
        my $map  = $type->typemap;
        next unless $arg->{out} and $in[$i] and $out[$i];
        ${ $in[$i] } = ${ $out[$i] } if $in[$i] != $out[$i];
        ${ $in[$i] } = $map->{perl_out}( ${ $in[$i] }, $type )
          if $map->{perl_out};
    }

    return $retval;
}

package DBIx::Fun::Oracle::type;

use DBD::Oracle;
use Date::Parse;
use POSIX ();

sub new {
    my ( $class, @args ) = @_;
    if ( @args == 1 and ref $args[0] eq 'HASH' ) {
        @args = %{ $args[0] };
    }
    my $self = bless {@args}, $class;
    return $self;
}

our %typemap = (

    # treat undef as FALSE
    # should be NULL, but perl uses undef as false everywhere

    'BOOLEAN' => {

        #perl_in => sub { $_[0] ? 1 : 0 },
        plsql_in  => "CASE NVL(%s,0) WHEN 0 THEN FALSE ELSE TRUE END",
        plsql_out => "CASE %s WHEN TRUE THEN 1 ELSE 0 END",
    },

    # Date::Parse date handling
    # allow a numeric string as a UNIX time

    # ALWAYS return as ISO format

    'DATE' => {
        perl_in => sub {
            my $date = shift;
            return undef unless defined $date;

            # UNIX timestamp
            return POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime $date )
              if $date =~ /^[\-+]?\d*\.?\d*\s*$/;

            my ( $ss, $mm, $hh, $day, $month, $year, $zone ) =
              Date::Parse::strptime($date);
            
            # Date::Parse oddness with 2/4 digit years.
            # Try to find the year
            if ( $date =~ /(\d{4})/ ) {
                my $possible_year = $1;
                $year = $possible_year - 1900
                  if $year == $possible_year
                  or $year == $possible_year - 1900;
            }

            $year += 1900;

            $hh ||= 0;
            $mm ||= 0;
            $ss ||= 0;
            
            #strptime - month starts at 0
            return sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
                $year, $month+1, $day, $hh, $mm, $ss );
          },
        plsql_in  => "TO_DATE(%s, 'YYYY-MM-DD HH24:MI:SS')",
        plsql_out => "TO_CHAR(%s, 'YYYY-MM-DD HH24:MI:SS')",
    },

    'TIMESTAMP WITH TIME ZONE' => {
        perl_in => sub {
            my $date = shift;
            return undef unless defined $date;
            $date = Date::Parse::str2time($date)
              if $date !~ /^[\-+]?\d*\.?\d*\s*$/;
            my $fraction = '000';
            $fraction = $1 if $date =~ /\.(\d+)/;
            return POSIX::strftime( "%Y-%m-%d %H:%M:%S.$fraction%z",
                localtime $date );
        },
        plsql_in  => "TO_TIMESTAMP_TZ(%s,'YYYY-MM-DD HH24:MI:SS.FFTZH:TZM')",
        plsql_out => "TO_CHAR(%s, 'YYYY-MM-DD HH24:MI:SS.FFTZH:TZM')",
    },

    'TIMESTAMP' => {
        perl_in => sub {
            my $date = shift;
            return undef unless defined $date;
            $date = Date::Parse::str2time($date)
              if $date !~ /^[\-+]?\d*\.?\d*\s*$/;
            my $fraction = '000';
            $fraction = $1 if $date =~ /\.(\d+)/;
            return POSIX::strftime( "%Y-%m-%d %H:%M:%S.$fraction",
                localtime $date );
        },
        plsql_in  => "TO_TIMESTAMP_TZ(%s,'YYYY-MM-DD HH24:MI:SS.FF')",
        plsql_out => "TO_CHAR(%s, 'YYYY-MM-DD HH24:MI:SS.FF')",
    },

    # strip trailing spaces from CHAR output
    # all spaces => single space, to distinguish from NULL

    'CHAR' => {
        perl_out => sub { local $_ = $_[0]; s/^(.+?) +\z/$1/s if defined; $_ },
    },

    # These can go in/out, but need to be bound by type
    'REF CURSOR' => { ora_type => DBD::Oracle::ORA_RSET, },
    'RAW'        => { ora_type => DBD::Oracle::ORA_RAW, },
    'LONG RAW'   => { ora_type => DBD::Oracle::ORA_RAW, },
    'CLOB'       => { ora_type => DBD::Oracle::ORA_CLOB, },
    'BLOB'       => { ora_type => DBD::Oracle::ORA_BLOB, },
);

sub typemap {
    my ($type) = @_;
    return undef unless $type;

    #use YAML; print YAML::Dump($type);
    if ( !$type->{typemap} ) {
        $type->{typemap} = $typemap{ $type->{name} };
    }
    if ( !$type->{typemap} && $type->{name} =~ /TABLE|RECORD|ARRAY/ ) {
        my $shortname = $type->{fulltype};
        $shortname =~ s/^.*\.//;
        $shortname =~ s/\W/_/g;
        $type->{typemap} = {
            perl_in          => sub { pack_type(@_); },
            perl_out         => sub { unpack_type(@_); },
            plsql_in         => "unpack_$shortname(%s)",
            plsql_assign_out => sub {
                sprintf
                  "DBMS_LOB.CREATETEMPORARY(%s,TRUE); pack_$shortname(%s,%s);",
                  $_[0], $_[0], $_[1];
            },
            ora_type => DBD::Oracle::ORA_BLOB(),
        };
    }
    return $type->{typemap};
}

sub needs_plsql_map {
    my ($type) = @_;
    my $map = typemap($type);
    return $map && ( $map->{plsql_in} || $map->{plsql_out} );
}

sub declare_plsql {
    my ( $type, $var, $init ) = @_;
    $init = '' if not defined $init;
    my $name = $type->{fulltype} || $type->{name};
    "$var $name $init;";
}

sub to_plsql {
    my ( $type, $var ) = @_;
    my $map = typemap($type);
    my $in  = $map->{plsql_in};
    return $var if not $in;
    return $in->($var) if ref($in) eq 'CODE';
    return sprintf $in, $var;
}

sub initialize_plsql {
    my ( $type, $dest, $src ) = @_;
    declare_plsql( $type, $dest, ":= " . to_plsql( $type, $src ) );
}

sub from_plsql {
    my ( $type, $var ) = @_;
    my $map = typemap($type);
    my $out = $map->{plsql_out};
    return $var if not $out;
    return $out->($var) if ref($out) eq 'CODE';
    return sprintf $out, $var;
}

sub assign_plsql {
    my ( $type, $dest, $src ) = @_;
    my $map = typemap($type);
    if ( my $out = $map->{plsql_assign_out} ) {
        return $out->( $dest, $src ) if ref($out) eq 'CODE';
        return sprintf( $out, $dest, $src );
    }
    return "$dest := " . from_plsql( $type, $src ) . ';';
}


sub pack_array {
    my ( $value, $type ) = @_;
    return "\0" unless $value;
    die "Can't pack " . ( ref($value) || 'scalar' ) . " as '$type->{name}'"
      if ref $value ne 'ARRAY';
    my $str = "A\0" . (@$value) . "\0";
    for my $val (@$value) {
        $str .= pack_type( $val, $type->{pos}[0]{type} );
    }
    return $str;
}

sub pack_indextable {
    my ( $value, $type ) = @_;
    return "\0" unless $value;

    if ( ref $value eq 'ARRAY' ) {
        my %temp = map { $_, $value->[$_] } 0 .. $#$value;
        return pack_indextable( \%temp, $type );
    }

    die "Can't pack " . ( ref($value) || 'scalar' ) . " as '$type->{name}'"
      if ref $value ne 'HASH';

    my $str = "I\0" . ( 2 * keys %$value ) . "\0";
    for my $key ( keys %$value ) {
        $str .= pack_type($key);
        $str .= pack_type( $value->{$key}, $type->{pos}[0]{type} );
    }
    return $str;
}

sub pack_record {
    my ( $value, $type ) = @_;
    return "\0" unless $value;
    die "Can't pack " . ( ref($value) || 'scalar' ) . " as '$type->{name}'"
      if ref $value ne 'HASH';
    my $str = "R\0" . ( 2 * keys %$value ) . "\0";
    for my $key ( keys %$value ) {
        die "Type '$type->{fulltype}' does not have field '$key'"
          unless $type->{arg}{ uc $key };

        $str .= pack_type( uc $key );
        $str .= pack_type( $value->{$key}, $type->{arg}{ uc $key }{type} );
    }
    return $str;
}

sub pack_type {
    my ( $value, $type ) = @_;
    my $typename = $type->{name} || 'VARCHAR2';
    return pack_array( $value, $type ) if $typename =~ /^(VARRAY|TABLE)$/;
    return pack_indextable( $value, $type ) if $typename =~ /PL\/SQL TABLE$/;
    return pack_record( $value, $type )
      if $typename =~ /^(PL\/SQL RECORD|OBJECT)$/;

    die "Can't pack " . ref($value) . " as '$typename'" if ref $value;

    return "\0" unless defined $value;

    # perl_in!

    return length($value) . "\0" . $value;
}

sub unpack_array {
    my $type = $_[1];
    return "\0" unless $_[0];

    $_[0] =~ s/^(\w*)\0// or die "Unpack array header not found";
    my $header = $1;
    return undef                             if not $header;
    die "Header '$header' is not array type" if $header !~ /[AVT]/;
    $_[0] =~ s/^(\d+)\0// or die "Unpack array count not found";
    my $count = $1;

    my @ret;
    for my $i ( 1 .. $count ) {
        push @ret, _unpack_type( $_[0], $type->{pos}[0]{type} );
    }
    return \@ret;
}

sub unpack_indextable {
    my $type = $_[1];
    return "\0" unless $_[0];

    $_[0] =~ s/^(\w*)\0// or die "Unpack index table header not found";
    my $header = $1;
    return undef                                   if not $header;
    die "Header '$header' is not index table type" if $header !~ /[IH]/;
    $_[0] =~ s/^(\d+)\0// or die "Unpack index table count not found";
    my $count = $1;

    my @ret;
    for my $i ( 1 .. $count ) {
        if ( $i % 2 ) {
            push @ret, _unpack_type( $_[0] );
        }
        else {
            push @ret, _unpack_type( $_[0], $type->{pos}[0]{type} );
        }
    }
    return {@ret};
}

sub unpack_record {
    my $type = $_[1];
    return "\0" unless $_[0];

    $_[0] =~ s/^(\w*)\0// or die "Unpack record header not found";
    my $header = $1;
    return undef                              if not $header;
    die "Header '$header' is not record type" if $header !~ /[RH]/;
    $_[0] =~ s/^(\d+)\0// or die "Unpack record count not found";
    my $count = $1;

    my @ret;
    my $key;
    for my $i ( 1 .. $count ) {
        if ( $i % 2 ) {
            $key = _unpack_type( $_[0] );
            push @ret, $key;
        }
        else {
            push @ret, _unpack_type( $_[0], $type->{arg}{ uc $key }{type} );
        }
    }
    return {@ret};
}

sub _unpack_type {
    my $type = $_[1];
    my $typename = $type->{name} || 'VARCHAR2';
    return unpack_array( $_[0], $type ) if $typename =~ /^(VARRAY|TABLE)$/;
    return unpack_indextable( $_[0], $type )
      if $typename =~ /^(PL\/SQL TABLE)$/;
    return unpack_record( $_[0], $type ) if $typename =~ /^(PL\/SQL RECORD)$/;
    $_[0] =~ s/^(\w*)\0// or die "Unpack record header not found";
    my $header = $1;
    return undef if not length $header;
    die "Header '$header' is not string type" if $header =~ /\D/;
    return substr( $_[0], 0, $header, '' );
}

sub unpack_type {
    my ( $value, $type ) = @_;
    _unpack_type( $_[0], $type );
}

sub packname {
    my $p = $_[0];
    $p =~ s/.*\.//;
    lc "pack_$p";
}

sub gen_pack_array {
    my ($ref) = @_;
    my $name  = $ref->{fulltype};
    my $fname = packname($name);

    my $put_arg = 'pack_string';
    my $put_val = 'p_val(v_key)';

    my $el = $ref->{pos}[0]{type};

    $put_arg = 'pack_raw' if $el->{name} =~ /RAW$/i;
    if ( $el->{fulltype} ) {
        $put_arg = packname( $el->{fulltype} );
    }
    if ( my $plsql_out = $typemap{ $el->{name} }{plsql_out} ) {
        $put_val = sprintf $plsql_out, $put_val;
    }
    $put_arg = "$put_arg( p_out, $put_val )";

    my $sql = <<EOQ;
   PROCEDURE $fname(p_out IN OUT BLOB, p_val $name) IS
     v_key NUMBER;
   BEGIN
     IF p_val IS NULL THEN put_zval(p_out, NULL); RETURN; END IF;
     put_collsize(p_out, 'A', p_val.count);
     v_key := p_val.first;
     WHILE v_key IS NOT NULL
     LOOP
        $put_arg;
        v_key := p_val.next(v_key);
     END LOOP;
   END;
EOQ
}

sub gen_pack_table {
    my ($ref) = @_;
    my $name  = $ref->{fulltype};
    my $fname = packname($name);

    my $put_arg = 'pack_string';
    my $put_val = 'p_val(v_key)';

    my $el = $ref->{pos}[0]{type};
    $put_arg = 'pack_raw' if $el->{name} =~ /RAW$/i;
    if ( $el->{fulltype} ) {
        $put_arg = packname( $el->{fulltype} );
    }

    if ( my $plsql_out = $typemap{ $el->{name} }{plsql_out} ) {
        $put_val = sprintf $plsql_out, $put_val;
    }

    $put_arg = "$put_arg( p_out, $put_val )";

    my $sql = <<EOQ;
   PROCEDURE $fname(p_out IN OUT BLOB, p_val $name) IS
     v_key VARCHAR2(32767);
   BEGIN
     -- IF p_val IS NULL THEN put_zval(p_out, NULL); RETURN; END IF;
     put_collsize(p_out, 'I', p_val.count * 2);
     v_key := p_val.first;
     WHILE v_key IS NOT NULL
     LOOP
        pack_string( p_out, v_key );
        $put_arg;
        v_key := p_val.next(v_key);
     END LOOP;
   END;
EOQ
}

sub gen_pack_record {
    my ($ref) = @_;
    my $name  = $ref->{fulltype};
    my $fname = packname($name);

    my $put   = '';
    my $count = 0;
    for my $i ( 0 .. $#{ $ref->{pos} } ) {
        my $key = lc $ref->{pos}[$i]{name};
        next unless $key;
        $count++;
        my $el = $ref->{pos}[$i]{type};
        $put .= <<EOQ;
    pack_string( p_out, '$key' );
EOQ
        $count++;
        my $put_arg = 'pack_string';
        my $put_val = "p_val.$key";
        $put_arg = 'pack_raw' if $el->{name} =~ /RAW$/i;

        if ( $el->{fulltype} ) {
            $put_arg = packname( $el->{fulltype} );
        }
        elsif ( my $plsql_out = $typemap{ $el->{name} }{plsql_out} ) {
            $put_val = sprintf $plsql_out, $put_val;
        }
        $put_arg = "$put_arg( p_out, $put_val )";
        $put .= <<EOQ;
     $put_arg;
EOQ
    }
    my $sql = <<EOQ;
   PROCEDURE $fname(p_out IN OUT BLOB, p_val $name)
   IS
   BEGIN
     -- IF p_val IS NULL THEN put_zval(p_out, NULL); RETURN; END IF;
     put_collsize(p_out, 'R', $count);
$put
   END;
EOQ
}

sub unpackname {
    "un" . packname( $_[0] );
}

sub unpname {
    my $u = unpackname( $_[0] );
    $u =~ s/unpack/unp/;
    $u;
}

sub gen_unpack_array {
    my ($ref)    = @_;
    my $name     = $ref->{fulltype};
    my $fullname = unpackname($name);
    my $fname    = unpname($name);

    my $get_arg = 'unpack_string';
    my $el      = $ref->{pos}[0]{type};
    $get_arg = 'unpack_raw' if $el->{name} =~ /RAW$/i;
    if ( $el->{fulltype} ) {
        $get_arg = unpname( $el->{fulltype} );
    }
    $get_arg = "$get_arg( p_in, p_offset )";
    if ( my $plsql_in = $typemap{ $el->{name} }{plsql_in} ) {
        $get_arg = sprintf $plsql_in, $get_arg;
    }

    my $sql = <<EOQ;
   FUNCTION $fname(p_in BLOB, p_offset IN OUT INT) 
   RETURN $name IS
     v_ret $name := $name();
     v_count INT;
   BEGIN
     IF p_in IS NULL OR DBMS_LOB.GETLENGTH(p_in) = 0 THEN RETURN NULL; END IF;
     v_count := get_collsize( p_in, p_offset );
     IF v_count IS NULL THEN RETURN NULL; END IF;
     FOR i IN 1 .. v_count 
     LOOP
        v_ret.extend;
        v_ret(v_ret.count) := $get_arg( p_in, p_offset );
     END LOOP;
     RETURN v_ret;
   END;

   FUNCTION $fullname(p_in BLOB)
   RETURN $name IS
     v_offset INT :=1;
   BEGIN
     RETURN $fname(p_in, v_offset);
   END;
EOQ
}

sub gen_unpack_table {
    my ($ref)    = @_;
    my $name     = $ref->{fulltype};
    my $fullname = unpackname($name);
    my $fname    = unpname($name);

    my $get_arg = 'unpack_string';
    my $el      = $ref->{pos}[0]{type};
    $get_arg = 'unpack_raw' if $el->{name} =~ /RAW$/i;
    if ( $el->{fulltype} ) {
        $get_arg = unpname( $el->{fulltype} );
    }
    $get_arg = "$get_arg( p_in, p_offset )";
    if ( my $plsql_in = $typemap{ $el->{name} }{plsql_in} ) {
        $get_arg = sprintf $plsql_in, $get_arg;
    }

    my $sql = <<EOQ;
   FUNCTION $fname(p_in BLOB, p_offset IN OUT INT) 
   RETURN $name IS
     v_ret $name;
     v_count INT;
     v_key VARCHAR2(32767);
   BEGIN
     IF p_in IS NULL OR DBMS_LOB.GETLENGTH(p_in) = 0 THEN RETURN v_ret; END IF;
     v_count := get_collsize( p_in, p_offset );
     IF v_count IS NULL THEN RETURN v_ret; END IF;
     FOR i IN 1 .. (v_count / 2)
     LOOP
        v_key := unpack_string( p_in, p_offset );
        v_ret(v_key) := $get_arg;
     END LOOP;
     RETURN v_ret;
   END;
   FUNCTION $fullname(p_in BLOB)
   RETURN $name IS
     v_offset INT :=1;
   BEGIN
     RETURN $fname(p_in, v_offset);
   END;
EOQ
}

sub gen_unpack_record {
    my ($ref)    = @_;
    my $name     = $ref->{fulltype};
    my $fullname = unpackname($name);
    my $fname    = unpname($name);

    my $get = '';

    for my $i ( 0 .. $#{ $ref->{pos} } ) {
        my $key = lc $ref->{pos}[$i]{name};
        next unless $key;
        my $get_arg = 'unpack_string';
        my $el      = $ref->{pos}[$i]{type};
        $get_arg = 'unpack_raw' if $el->{name} =~ /RAW$/i;
        if ( $el->{fulltype} ) {
            $get_arg = unpname( $el->{fulltype} );
        }
        $get_arg = "$get_arg( p_in, p_offset )";
        if ( my $plsql_in = $typemap{ $el->{name} }{plsql_in} ) {
            $get_arg = sprintf $plsql_in, $get_arg;
        }

        # map string type?
        $get .= "ELS" if $get;
        $get .= <<EOQ;
       IF LOWER(v_key) = '$key'
       THEN 
         v_ret.$key := $get_arg;
EOQ
    }
    $get =~ s/ELS(\s+)IF/$1ELSIF/g;
    my $sql = <<EOQ;
   FUNCTION $fname(p_in BLOB, p_offset IN OUT INT) 
   RETURN $name IS
     v_ret $name;
     v_count INT;
     v_key VARCHAR2(32767);
   BEGIN
     IF p_in IS NULL THEN RETURN NULL; END IF;
     IF DBMS_LOB.GETLENGTH(p_in) = 0 THEN RETURN NULL; END IF;
     v_count := get_collsize( p_in, p_offset );
     IF v_count IS NULL THEN RETURN NULL; END IF;
     FOR i IN 1 .. (v_count / 2)
     LOOP
       v_key := unpack_string( p_in, p_offset );
$get
       ELSE
         RAISE value_error;
       END IF;
     END LOOP;
     RETURN v_ret;
   END;
   FUNCTION $fullname(p_in BLOB)
   RETURN $name IS
     v_offset INT :=1;
   BEGIN
     RETURN $fname(p_in, v_offset);
   END;
EOQ
}

my $packcode = <<EOQ;
  PROCEDURE put_zval(p_out IN OUT BLOB, p_val VARCHAR2)
  IS
  BEGIN
    DBMS_LOB.WRITEAPPEND(p_out, length(p_val), UTL_RAW.CAST_TO_RAW(p_val));
    DBMS_LOB.WRITEAPPEND(p_out, 1, '00');
  END;

  PROCEDURE put_collsize(p_out IN OUT BLOB, p_type VARCHAR2, p_size INT)
  IS
  BEGIN
    put_zval(p_out, p_type);
    put_zval(p_out, p_size);
  END;

  PROCEDURE pack_raw(p_out IN OUT BLOB, p_raw RAW) 
  IS
  BEGIN
    put_zval(p_out, nvl(utl_raw.length(p_raw), 0));
    IF p_raw IS NOT NULL THEN
      DBMS_LOB.WRITEAPPEND(p_out, utl_raw.length(p_raw), p_raw);
    END IF;
  END;

  PROCEDURE pack_string(p_out IN OUT BLOB, p_str VARCHAR2)
  IS
  BEGIN
    pack_raw(p_out, UTL_RAW.CAST_TO_RAW(p_str));
  END;

EOQ

my $unpackcode = <<EOQ;
  FUNCTION valid_lob(p_in IN BLOB) RETURN BLOB
  IS
    v_len INT; 
    v_blob BLOB;
  BEGIN
    BEGIN
        v_len := dbms_lob.getlength(p_in);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_LOB.CREATETEMPORARY(v_blob, TRUE);
            RETURN v_blob;
    END;
    RETURN p_in;
  END;

  FUNCTION get_zval(p_in BLOB, p_offset IN OUT INT) RETURN VARCHAR2
  IS
    v_delimpos INT;
    v_offset INT := p_offset;
  BEGIN
    v_delimpos := DBMS_LOB.INSTR( p_in, '00', p_offset );
    p_offset := v_delimpos + 1;
    RETURN UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(p_in, v_delimpos - v_offset, v_offset));
  END;

  FUNCTION get_collsize(p_in BLOB, p_offset IN OUT INT) RETURN INT
  IS
    colltype VARCHAR2(64); 
  BEGIN
    colltype := get_zval( p_in, p_offset );
    if NVL(colltype, '0') = '0' THEN RETURN NULL; END IF;
    RETURN TO_NUMBER( get_zval( p_in, p_offset ) );
  END;

  FUNCTION unpack_raw(p_in BLOB, p_offset IN OUT INT) RETURN VARCHAR2
  IS
    v_strlen INT;
    v_offset INT;
  BEGIN
    v_strlen := TO_NUMBER( get_zval( p_in, p_offset ) );
    IF v_strlen IS NULL THEN RETURN NULL; END IF;
    v_offset := p_offset;
    p_offset := p_offset + v_strlen;
    RETURN DBMS_LOB.SUBSTR(p_in, v_strlen, v_offset);
  END;

  FUNCTION unpack_string(p_in BLOB, p_offset IN OUT INT) RETURN VARCHAR2
  IS
  BEGIN
    RETURN UTL_RAW.CAST_TO_VARCHAR2(unpack_raw(p_in, p_offset));
  END;
EOQ

sub gen_unpack {
    my ($ref) = @_;
    return gen_unpack_table($ref)  if ( $ref->{name} =~ /PL.SQL TABLE/ );
    return gen_unpack_record($ref) if ( $ref->{name} =~ /PL.SQL RECORD/ );
    return gen_unpack_array($ref)  if ( $ref->{name} =~ /VARRAY|TABLE/ );
    return;
}

sub gen_pack {
    my ($ref) = @_;
    return gen_pack_table($ref)  if ( $ref->{name} =~ /PL.SQL TABLE/ );
    return gen_pack_record($ref) if ( $ref->{name} =~ /PL.SQL RECORD/ );
    return gen_pack_array($ref)  if ( $ref->{name} =~ /VARRAY|TABLE/ );
    return;
}

sub spec_pack {
    my ( $ref, $seen, $str ) = @_;
    return unless $ref;
    $seen ||= {};
    $str  ||= \my $anon;

    if ( ref $ref eq 'ARRAY' ) {
        for my $r (@$ref) {
            spec_pack( $r, $seen, $str );
        }
    }
    elsif ( ref $ref eq 'HASH' or ref $ref eq __PACKAGE__ ) {
        spec_pack( $ref->{pos},  $seen, $str ) if $ref->{pos};
        spec_pack( $ref->{type}, $seen, $str ) if $ref->{type};
        my $full = $ref->{fulltype};

        if ( $full && not $seen->{$full} ) {

            #print "pack $ref->{name} $ref->{fulltype}\n";
            $seen->{$full}++;

            #print Dumper($ref);
            $$str .= gen_pack($ref) . "\n" . gen_unpack($ref) . "\n";
        }
    }
    if ( @_ == 1 and %$seen ) {
        return <<EOQ;
$packcode
$unpackcode
$$str
EOQ
    }
    return '';
}

1;

