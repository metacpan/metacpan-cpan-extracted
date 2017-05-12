package DBIx::Perform::Field;

use strict;
use warnings;
use Curses;
use Math::Trig;
use DBIx::Perform::Widgets::ButtonSet;
use DBIx::Perform::AttributeGrammar;
use Parse::RecDescent;
use Data::Dumper;
use base 'Exporter';

our $VERSION = '0.695';

# debug: set (unset) in runtime env
$::TRACE      = $ENV{TRACE};
$::TRACE_DATA = $ENV{TRACE_DATA};

# Global User Interface
#our $GlobalUi = $DBIx::Perform::GlobalUi;

# $Field methods
our @EXPORT_OK = qw(
  &new
  &duplicate
  &parse_line
  &print
  &print_lookup_hash
  &print_field_tag_join_hash
  &print_include_values
  &scalar_number_or_letter
  &is_number
  &is_char
  &is_serial
  &get_comments
  &set_comments
  &get_field_tag
  &get_names
  &set_value
  &get_value
  &display_status_message
  &display_error_message
  &is_any_numeric_db_type
  &is_real_db_type
  &is_integer_db_type
  &is_numeric_db_type
  &parse_db_type
  &set_field_null_ok
  &set_field_size
  &set_field_type
  &format_value_for_display
  &format_value_for_database
  &handle_verify_joins
  &handle_queryclear_attribute
  &handle_shift_attributes
  &handle_right_attribute
  &handle_subscript_attribute
  &handle_picture_attribute
  &handle_date_attribute
  &handle_format_attribute
  &handle_money_attribute
  &validate_input
  &allows_focus
);

=pod
##optimization attempt
#bit masks 1 = number type in db
#          2 = integer
#          4 = float
#          8 = "numeric" type 
our $MASKF = 4;
our $MASKDB = 1;
our $MASKI = 2;
our $MASKN = 8;
our %DTNAMES = (
    'FLOAT'      => 5,
    'SMALLFLOAT' => 5,
    'REAL'       => 5,
    'NUMERIC'    => 9,
    'DECIMAL'    => 13,
    'DEC'        => 13,
    'INTEGER'    => 3,
    'INT'        => 3,
    'SMALLINT'   => 3,
    'MONEY'      => 4, 
    'SERIAL'     => 2,
);
=cut

# Field ctor
sub new {
    my $class = shift;

    bless my $self = {
#        line            => undef,
        field_tag       => undef,
#        table_name      => undef,
#        column_name     => undef,
#        join_table      => undef,    # lookup fields objs
#        join_column     => undef,    # lookup fields objs
#        screen_name     => undef,
#        value           => undef,    # Fields have a value at runtime
#        type            => undef,    # Fields values have a type  at runtime
#        db_type         => undef,    # table.column type in the database
#        size            => undef,

        # attributes
#        active_tabcol  => undef, # for joining fields, active table & column
#        allowing_input => undef,
#        autonext       => undef,
#        comments       => undef,
#        compress       => undef,
#        displayonly    => undef,
#        disp_only_type => undef,
#        subscript_floor     => undef,
#        subscript_ceiling   => undef,
#        downshift           => undef,
#        format              => undef,
#        include             => undef,    # some form of include is defined
#        include_values      => undef,
#        null_ok             => undef,
#        db_null_ok          => undef,
#        invisible           => undef,
#        field_tag_join_hash => undef,
#        lookup_hash         => undef,
#        picture             => undef,
#        noentry             => undef,
#        noupdate            => undef,
#        queryclear          => undef,
#        range_ceiling       => undef,
#        range_floor         => undef,
#        required            => undef,
#        reverse             => undef,
#        right               => undef,
#        upshift             => undef,
#        verify              => undef,
#        wordwrap            => undef,
#        zerofill            => undef,

    } => ( ref $class || $class );

    return $self;
}

sub duplicate {
    my $self = shift;

    my $new_field = $self->new;

    foreach my $att ( keys( %{$self} ) ) {
        $new_field->{$att} = $self->{$att};
    }

    return $new_field;
}

sub parse_line {
    my $self   = shift;
    my $line   = shift;
    my $parser = shift;

    my $val = undef;
    $self->{line} = $line;

    if ( my $ref = $parser->startrule( $line ) ) {
        my $href = @$ref[0];    # returned from the parser

        $self->{line} = $line;
        $val = lc $href->{field_tag};

        $self->{field_tag} = $val if defined $val;

        $val = lc $href->{table_name};
        $self->{table_name} = $val if defined $val;

        $val = lc $href->{column_name};
        $self->{column_name} = $val if defined $val;

        $val = lc $href->{data_type};
        $self->{type} = $val if $val;

        $val = $href->{value};
        $self->{value} = $val if defined $val;

        # attributes

        $val = $href->{ALLOWING_INPUT};
        $self->{allowing_input} = $val if defined $val;

        $val = $href->{AUTONEXT};
        $self->{autonext} = $val if defined $val;

        $val = $href->{COMMENTS};
        $self->{comments} = $val if defined $val;

        $val = $href->{COMPRESS};
        $self->{compress} = $val if defined $val;

        $val = $href->{DEFAULT};
        $self->{default} = $val if defined $val;

        $val = $href->{DISPLAYONLY};
        $self->{displayonly} = $val if defined $val;

        $val = $href->{data_type};
        $self->{disp_only_type} = $val if defined $val;

        $val = $href->{SUBSCRIPT_FLOOR};
        $self->{subscript_floor} = $val if defined $val;

        $val = $href->{SUBSCRIPT_CEILING};
        $self->{subscript_ceiling} = $val if defined $val;

        $val = $href->{DOWNSHIFT};
        $self->{downshift} = $val if defined $val;

        $val = $href->{FORMAT};
        $self->{format} = $val if defined $val;

        $val = $href->{INCLUDE_VALUES};
        $self->{include_values} = $val if defined $val;

        $val = $href->{INCLUDE_NULL_OK};
        $self->{null_ok} = $val if defined $val;

        $val = $href->{INVISIBLE};
        $self->{invisible} = $val if defined $val;

        $val = $href->{LOOKUP_HASH};
        $self->{lookup_hash} = $val if defined $val;

        $val = $href->{NOENTRY};
        $self->{noentry} = $val if defined $val;

        $val = $href->{NOTNULL};
        $self->{noentry} = $val if defined $val;

        $val = $href->{NOUPDATE};
        $self->{noupdate} = $val if defined $val;

        $val = $href->{PICTURE};
        $self->{picture} = $val if defined $val;

        $val = $href->{QUERYCLEAR};
        $self->{queryclear} = $val if defined $val;

        $val = $href->{RANGE};
        $self->{range} = $val if defined $val;

        $val = $href->{REQUIRED};
        $self->{required} = $val if defined $val;

        $val = $href->{REVERSE};
        $self->{reverse} = $val if defined $val;

        $val = $href->{RIGHT};
        $self->{right} = $val if defined $val;

        $val = $href->{UPSHIFT};
        $self->{upshift} = $val if defined $val;

        $val = $href->{VERIFY};
        $self->{verify} = $val if defined $val;

        $val = $href->{WORDWRAP};
        $self->{wordwrap} = $val if defined $val;

        $val = $href->{ZEROFILL};
        $self->{zerofill} = $val if defined $val;

        $val = $href->{FIELD_TAG_JOIN_HASH};
        $self->{field_tag_join_hash} = $val if defined $val;

        $ref =
          undef;    # reset the grammar return hash to parse the next input line
        return $self;

    }
    else {
        warn "\nLINE: $line\n";
        warn "...line seems invalid\n\n";
        return undef;
    }
}

sub print {
    my $self = shift;
    my $str;

    print STDERR "-----------------------\n";
    $str = $self->{line};
    print STDERR "line: $str\n" if $str;
    print STDERR "- - - - - - - - - - - -\n";
    $str = $self->{field_tag};
    print STDERR "field_tag:           $str\n" if defined($str);
    $str = $self->{table_name};
    print STDERR "table name:          $str\n" if defined($str);
    $str = $self->{column_name};
    print STDERR "column name:         $str\n" if defined($str);
    $str = $self->{join_table};
    print STDERR "join table:          $str\n" if defined($str);
    $str = $self->{join_column};
    print STDERR "join column:         $str\n" if defined($str);
    $str = $self->{screen_name};
    print STDERR "screen name:         $str\n" if defined($str);
    $str = $self->{type};
    print STDERR "type:                $str\n" if defined($str);
    $str = $self->{db_type};
    print STDERR "db_type:             $str\n" if defined($str);
    $str = $self->{size};
    print STDERR "size:                $str\n" if defined($str);
    $str = $self->{value};
    print STDERR "value:               $str\n" if defined($str);

    print STDERR "\nattributes:\n" if defined( $self->{column_name} );

    $str = $self->{displayonly};
    print STDERR "   displayonly:      $str\n" if defined($str);
    $str = $self->{disp_only_type};
    print STDERR "   displayonly type: $str\n" if defined($str);
    $str = $self->{subscript_floor};
    print STDERR "   subscript floor:  $str\n" if defined($str);
    $str = $self->{subscript_ceiling};
    print STDERR "   subscript ceiling:$str\n" if defined($str);
    $str = $self->{active_tabcol};
    print STDERR "   active t\/c:      $str\n" if defined($str);
    $str = $self->{allowing_input};
    print STDERR "   allowing_input:   $str\n" if defined($str);
    $str = $self->{autonext};
    print STDERR "   autonext:         $str\n" if defined($str);
    $str = $self->{comments};
    print STDERR "   comments:         $str\n" if defined($str);
    $str = $self->{compress};
    print STDERR "   compress:         $str\n" if defined($str);
    $str = $self->{default};
    print STDERR "   default:          $str\n" if defined($str);
    $str = $self->{downshift};
    print STDERR "   downshift:        $str\n" if defined($str);
    $str = $self->{format};
    print STDERR "   format:           $str\n" if defined($str);
    $str = $self->{include};
    print STDERR "   include:          $str\n" if defined($str);
    $str = $self->{null_ok};
    print STDERR "   null_ok:          $str\n" if defined($str);
    $str = $self->{db_null_ok};
    print STDERR "   db_null_ok:       $str\n" if defined($str);
    $str = $self->{invisible};
    print STDERR "   invisible:        $str\n" if defined($str);
    $str = $self->{noentry};
    print STDERR "   noentry:          $str\n" if defined($str);
    $str = $self->{noupdate};
    print STDERR "   noupdate:         $str\n" if defined($str);
    $str = $self->{picture};
    print STDERR "   picture:          $str\n" if defined($str);
    $str = $self->{queryclear};
    print STDERR "   queryclear:       $str\n" if defined($str);
#    $str = $self->{range_floor};
#    print STDERR "   range floor:      $str\n" if defined($str);
#    $str = $self->{range_ceiling};
#    print STDERR "   range ceiling:    $str\n" if defined($str);
    $str = $self->{required};
    print STDERR "   required:         $str\n" if defined($str);
    $str = $self->{reverse};
    print STDERR "   reverse:          $str\n" if defined($str);
    $str = $self->{right};
    print STDERR "   right:            $str\n" if defined($str);
    $str = $self->{upshift};
    print STDERR "   upshift:          $str\n" if defined($str);
    $str = $self->{verify};
    print STDERR "   verify:           $str\n" if defined($str);
    $str = $self->{wordwrap};
    print STDERR "   wordwrap:         $str\n" if defined($str);
    $str = $self->{zerofill};
    print STDERR "   zerofill:         $str\n" if defined($str);

    $self->print_include_values;
    print STDERR "\n";

    $self->print_lookup_hash;
    print STDERR "\n";

    $self->print_field_tag_join_hash;
    print STDERR "\n";

    return $self;
}

sub print_lookup_hash {
    my $self = shift;

    my %lookup1;
    my %lookup;
    if ( defined( $self->{lookup_hash} ) ) {
        %lookup1 = %{ $self->{lookup_hash} };
    }
    else { return; }

    foreach my $n ( keys(%lookup1) ) {
        my $instance_number = $n;
        my %lookup          = %{ $lookup1{$n} };

        foreach my $k ( keys(%lookup) ) {
            my $tag = $k;

            my $table_name  = $lookup{$k}->{table_name};
            my $column_name = $lookup{$k}->{column_name};
            my $join_table  = $lookup{$k}->{join_table};
            my $join_column = $lookup{$k}->{join_column};
            my $join_index  = $lookup{$k}->{join_index};
            my $active_tc   = $lookup{$k}->{active_tabcol};
            my $verify      = $lookup{$k}->{verify};

            print STDERR "   lookup:\n";
            print STDERR "      instance number:       $instance_number\n";
            print STDERR "            field tag:       $tag\n";
            print STDERR "           table name:       $table_name\n";
            print STDERR "          column name:       $column_name\n";
            print STDERR "           join_table:       $join_table\n"
              if defined($join_table);
            print STDERR "          join_column:       $join_column\n"
              if defined($join_column);
            print STDERR "               verify:       $verify\n"
              if defined($verify);
            print STDERR "               index:       $join_index\n"
              if defined($join_index);
        }
    }
}

sub print_field_tag_join_hash {
    my $self = shift;
    my %join;

    if ( defined( $self->{field_tag_join_hash} ) ) {
        %join = %{ $self->{field_tag_join_hash} };
    }
    else { return; }

    foreach my $k ( keys(%join) ) {
        my $tag = $k;

        my $join_table  = $join{$k}{join_table};
        my $join_column = $join{$k}->{join_column};
        my $verify      = $join{$k}->{verify};

        print STDERR "   join:\n";
        print STDERR "        hash id:           $tag\n";
        print STDERR "           join_table:       $join_table\n";
        print STDERR "          join_column:       $join_column\n";
        print STDERR "               verify:       $verify\n"
          if defined($verify);
    }
}

sub print_include_values {
    my $self = shift;

    my %values = %{ $self->{include_values} }
      if defined( $self->{include_values} );
    return if !defined( $self->{include_values} );

    print STDERR "   include values:\n";
    print STDERR "        ";
    foreach my $k ( keys(%values) ) {
        print STDERR "$k, ";
    }
    print STDERR "\n";
}

sub scalar_number_or_letter {
    my $self = shift;
    my $char = shift;

    return undef if !defined($char);

    if ( $char    =~ /[-+.0-9]/ ) { return "NUMBER"; }
    if ( $char =~ /[A-Z]/i ) { return "LETTER"; }

    return undef;
}

sub is_number {
    my $self = shift;
    my $char = shift;

    return 0 if !defined($char);

    return 1 if $char =~ /[-+.0-9]/;
    return 0;
}

sub is_char {
    my $self = shift;
    my $char = shift;

    return 0 if !defined($char);
    return 1 if $char =~ /[A-Z]/i;
    return 0;
}

sub is_serial {
    my $self = shift;

    if ( defined( $self->{db_type} ) ) {
        return 1 if $self->{db_type} eq "SERIAL";
    }

    return 0;
}

sub get_comments {
    my $self = shift;
    return $self->{comments};
}

sub set_comments {
    my $self = shift;
    my $str  = shift;

    $self->{comments} = $str;
}

sub get_field_tag {
    my $self = shift;

    return $self->{field_tag};
}

sub get_names {
    my $self = shift;
    return undef if !defined($self);

    return ( $self->{field_tag}, $self->{table_name}, $self->{column_name} );
}

sub set_value {
    my $self  = shift;
    my $value = shift;

    $self->{value} = $value;
    return $value;
}

sub get_value {
    my $self = shift;

    return $self->{value};
}

# attribute support routines

sub display_status_message {
    my $self   = shift;
    my $msg_id = shift;

    my $GlobalUi = $DBIx::Perform::GlobalUi;

    return undef
      if !defined $msg_id;

    my $msg = $GlobalUi->{error_messages}->{$msg_id};

    $GlobalUi->display_status($msg) if defined($msg);

    return undef;
}

sub display_error_message {
    my $self   = shift;
    my $msg_id = shift;

    my $GlobalUi = $DBIx::Perform::GlobalUi;

    return undef
      if !defined $msg_id;

    my $app = $GlobalUi->{app_object};
    my $msg = $GlobalUi->{error_messages}->{$msg_id};

    $GlobalUi->display_error($msg) if defined($msg);

    return undef;
}

# bool - true if db field supports any number input
sub is_any_numeric_db_type {
    my $self = shift;

    my $db_type = uc ($self->{db_type} || '');
    my ($type) = $db_type =~ /([^(]*)/;

    if (   $type eq "FLOAT"
        || $type eq "SMALLFLOAT"
        || $type eq "REAL"
        || $type eq "NUMERIC"
        || $type eq "DECIMAL"
        || $type eq "DEC"
        || $type eq "INTEGER"
        || $type eq "INT"
        || $type eq "SMALLINT" )
    {
        return 1;
    }

    return 0;
}

# bool - true if supports real numbers "m.n" input
sub is_real_db_type {
    my $self = shift;

    my $db_type = uc ($self->{db_type} || '');
    my ($type) = $db_type =~ /([^(]*)/;

    if (   $type eq "FLOAT"
        || $type eq "SMALLFLOAT"
        || $type eq "REAL"
        || $type eq "NUMERIC"
        || $type eq "DECIMAL"
        || $type eq "DEC" )
    {
        return 1;
    }

    return 0;
}

# bool - true if db field supports natural number input
sub is_integer_db_type {

    my $self = shift;

    my $db_type = uc ($self->{db_type} || '');
    my ($type) = $db_type =~ /([^(]*)/;

    if (   $type eq "INTEGER"
        || $type eq "INT"
        || $type eq "SMALLINT" )
    {
        return 1;
    }

    return 0;
}

# bool - true if db field supports only decimal input "m.n"
sub is_numeric_db_type {

    my $self = shift;

    my $db_type = uc ($self->{db_type} || '');

    my ($type) = $db_type =~ /([^(]*)/;

    if (   $type eq "NUMERIC"
        || $type eq "DECIMAL"
        || $type eq "DEC" )
    {
        return 1;
    }

    return 0;
}

# break apart type info from the db
sub parse_db_type {
    my $self = shift;

    if ( defined $self->{displayonly} ) {
        my $type = uc ($self->{type} || '');
        return ( $type, 80 );    # guess at max
    }

    my ( $type, $size, $dc, $more, $mn );
    my $db_type = ($self->{db_type} || '');

    ( $type, $more ) = split( /\(/, $db_type );

    if (   $type eq "INTEGER"
        || $type eq "INT"
        || $type eq "SMALLINT"
        || $type eq "FLOAT"
        || $type eq "SMALLFLOAT"
        || $type eq "REAL"
        || $type eq "MONEY"
        || $type eq "SERIAL" )
    {

        # return an arbitrary, large value for size
        return ( $type, 10000 );
    }

    if (   $type eq "NUMERIC"
        || $type eq "DECIMAL"
        || $type eq "DEC" )
    {

        # handle n and m values for decimal digits

        ( $size, $mn ) = split( /\)/, $more );
        my ( $n, $m ) = split( /\./, $mn );
        $size = $n + $m + 1;
        warn "decimal: n: $n, m: $n, type: $type size: $size"
          if $::TRACE_DATA;

        return ( $type, $size );
    }

    if ( $type eq "DATE" ) { return ( $type, 9 ); }

    # handle the rest

    ( $size, $dc ) = split( /\)/, $more ) if defined $more;
    warn "char: t: $type, size: $size" if $::TRACE_DATA;
    return ( $type, $size );
}

# include attribute null vs db null
sub set_field_null_ok {
    my $self = shift;

    my $db_null = $self->{db_null_ok};

    if ( !defined $db_null
        || ( defined $self->{include} && !defined $self->{null_ok} ) )
    {
        undef $self->{null_ok};
    }
    else { $self->{null_ok} = 1; }

    return $self->{null_ok};
}

# defined size vs db size
# no attempt is made to discover definition errors
sub set_field_size {
    my $self = shift;

    my ( $type, $size ) = $self->parse_db_type;

    # DB
    $self->{size} = $size;

    # PICTURE
    $self->{size} = length( $self->{picture} )
      if defined $self->{picture};

    # FORMAT
    $self->{size} = length( $self->{format} )
      if defined $self->{format};

    # SUBSCRIPTS
    if ( defined $self->{subscript_floor} ) {
        my $len = $self->{subscript_ceiling} - $self->{subscript_floor};
        $self->{size} = $len;
    }
    return undef;
}

# displayonly attribute type vs db type
# doesn't check for define errors
sub set_field_type {
    my $self = shift;

    my ( $type, $size ) = $self->parse_db_type;

    $self->{type} = $type;

    $self->{type} = $self->{disp_only_type}
      if defined $self->{disp_only_type};

#my $dtype = $self->{disp_only_type} || '';
#warn "set_field_type: $type $dtype\n";

    return undef;
}

#----------------------------------------------------------------------
# this calls most of the attribute "handle" routines
sub format_value_for_display {
    my $self = shift;
    my $val  = shift;

    my $dtype = $self->{db_type} || $self->{type};
    return ( $val, 0 ) if !defined $val || !defined $dtype;
#warn "format_val_for_display as $dtype :$val:\n";

#    $val = $self->get_value if $val =~ /^\*+$/;
    my $rc = 0;

    # default: format numbers to db type
    # FORMAT - FLOAT REAL DECIMAL db_types
    if (   $dtype eq 'DECIMAL'
        || $dtype eq 'DEC'
        || $dtype eq 'FLOAT'
        || $dtype eq 'SMALLFLOAT'
        || $dtype eq 'REAL' )
    {
        $val .= '.0' if $val =~ /^\s*[+-]?\d+$/;
    }

    ( $val, $rc ) = $self->handle_subscript_attribute( $val )
      if defined $self->{subscript_ceiling};

    # needs much more testing
    ( $val, $rc ) = $self->handle_money_attribute( $val )
      if $dtype eq 'MONEY' && $rc == 0;

    ( $val, $rc ) = $self->do_picture($val);

    if ( defined $self->{format} && $rc == 0 ) {
        if ( $self->{format} =~ /((^|[^YMD]+)(YY(YY)?|MMM?|DDD?)){3}/i )
        {
            ( $val, $rc ) = $self->handle_date_attribute( $val );
        }
        else {
            ( $val, $rc ) = $self->handle_format_attribute( $val );
        }
    }

    my $GlobalUi = $DBIx::Perform::GlobalUi;
    my ( $tag, $table, $col ) = $self->get_names;

    my @w    = $GlobalUi->get_screen_subform_widget($tag);
    my $conf = $w[0]->{CONF};
    my $max  = $$conf{COLUMNS};                           # maximum display size

    ( $val, $rc ) = $self->handle_right_attribute( $val, $max )
      if defined $self->{right} && $rc == 0;

#    $val = '*' x $max if length ($val) > $max;
    return ( $val, $rc );
}

# Prepares a value for db operations
sub format_value_for_database {

    my $self = shift;
    my $mode = shift;
    my $fo   = shift;    # optional

    my $val = $self->get_value;
    $val = '' if !defined $val;

    my $rc = 0;

    # test field value

    $rc = $self->validate_input( $val, $mode );
    return $rc if $rc != 0;

    # handle special cases for db input

    # SUBSCRIPT
    if (   defined $fo->{subscript_floor}
        && defined $fo->{subscript_ceiling} )
    {

        # get subscript info from $fo
        my $min  = $fo->{subscript_floor};
        my $max  = $fo->{subscript_ceiling};
        my $size = $max - $min;

        my $fo_val = $fo->get_value;
        $fo_val = '' if !defined $fo_val;

        my $vsize = length $val;

        if ( $vsize <= $max ) {

            my @val = split //, $val;
            my $start = $#val + 1;

            # pad @val to $max
            for ( my $i = $start ; $i < $max ; $i++ ) {
                $val[$i] = ' ';
            }
            $val = join '', @val;
            substr( $val, $min - 1, $size ) = $fo_val if defined $fo_val;
            $self->{value} = $val;
        }
    }

    return $rc;
}

# UPSHIFT / DOWNSHIFT
sub handle_shift_attributes {
    my $self = shift;
    my $val  = shift;

    my $us = $self->{upshift};
    $val = uc($val) if defined($us);

    my $ds = $self->{downshift};
    $val = lc($val) if defined($ds);

    return $val;
}

# RIGHT
sub handle_right_attribute {
    my $self         = shift;
    my $screen_value = shift;    # complete string
    my $max          = shift;

#    return ( $screen_value, 0 )
#      if !defined $self->{right};
    return ( $screen_value, 0 )
      if $self->{type} eq 'SERIAL';

    $screen_value = sprintf ("%${max}s", $screen_value);
    return ( $screen_value, 0 );
}

# SUBSCRIPT
sub handle_subscript_attribute {
    my $self         = shift;
    my $screen_value = shift;    # complete string

    return ( $screen_value, 0 )
      if $self->{type} eq 'SERIAL';

    my $vsize = 0;
    $vsize = length $screen_value if defined $screen_value;

    my $min  = $self->{subscript_floor};
    my $max  = $self->{subscript_ceiling};
    my $size = $max - $min + 1;

    my $val   = $screen_value;
    $val = substr( $screen_value, $min - 1, $size )
	if defined $screen_value && ( $vsize >= $min );
#warn "subscript\na:$screen_value:\nb:$val\nc:$self->{value}\n";
    $self->{value} = $val;    # needs to be set directly

    return ( $val, 0 );
}

# PICTURE
sub handle_picture_attribute {
    my $self = shift;
    my $val  = shift;         # one charcter at a time
    my $pos  = shift;         # cursor position in field

    # A - any letter
    # # - any number
    # X - any character

    return ( $val, $pos )
      if !defined( $self->{picture} );

    my @format = split( //, $self->{picture} );
    my $fsz = $#format;

    return ( $val, $pos, -1 )    # no more input
      if $pos > $fsz;

    my $rc = 0;

    my $f  = $format[$pos];

    if ( $f eq '#' ) {
        $rc = -1 unless $val =~ /\d/;
    }
    elsif ( uc $f eq 'A' ) {
        $rc = -1 unless $val =~ /[A-Z]/i;
    }
    return ( $val, $pos, $rc );
}

sub do_picture {
    my $self = shift;
    my $val  = shift;
    my $undo = shift;         #true if removal of picture characters wanted

    return ($val, 0) if !defined( $self->{picture} );

    my $SPACES = '                    '
               . '                    '
               . '                    '
               . '                    ';
    my @chars = split (//, $val . $SPACES);
    my @format = split( //, $self->{picture} );
    my @outs = split (//, substr($SPACES, 0, @format));
    my $rc = 0;
    my ($j, $k) = (0, 0);
    for (my $i = 0; $i < length($self->{picture}); $i++) {
        my $f = $format[$i];
        if ($f =~ /A|X|#/i) {
            $f = uc $f;
            my $c = $chars[$j];
            $j++;
            if (!$undo && (   ($f eq '#' && $c !~ /[\d\s]/)
                           || ($f eq 'A' && $c !~ /[A-Z\s]/i)) ) {
                $rc = -1;
                last;
            }
            $outs[$k] = $c;
            $k++;
        } else {
            if ($undo) {
                $j++;
            } else {
                $outs[$k] = $f;
                $k++;
            }
        }
    }
    my $out = join ('', @outs);
    return ($out, $rc);
}
sub is_picture_char {
    my $self = shift;
    my $pos = shift;
    return 0 unless defined ($self->{picture});
    my @format = split( //, $self->{picture} );
    return 0 if $pos > $#format || $pos < 0;
    return 0 if $format[$pos] =~ /[AX#]/;
    return 1;
}

# DATE
sub handle_date_attribute {
    my $self         = shift;
    my $screen_value = shift;    # complete string

#    return ( $screen_value, -1 )
#      if !defined $self->{format};
    my @MONTHNAME = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
    my @DAYNAME = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
    my @MAXDAY = (0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    my ( $m, $d, $y ) = (0, 0, 0);

    my $format = $self->{format};
    $format =~ s/DDD/KKK/g;  # using 'k' to mean day of the week.
    $format =~ s/ddd/kkk/g;
    my $val = $screen_value;
    my $date = '';

    do {
        $date .= $1 if ($format =~ s/^([^YMD]+)//i);
        if ($format =~ s/^YY(YY)?//i) {
            my $yp = $1;
            $val =~ s/^\D*//;
            $val =~ s/^(\d+)//;
            $y = $1;
#FIX:  this introduces a "Y21C" bug
            $y += 2000 if ($y >= 0 && $y < 100 && $yp);
            $date .= $y;
        }
        if ($format =~ s/^MM//i) {
            $val =~ s/^\s*//;
            $val =~ s/^(\D+)//;
            my $mn = $1;
            if ($mn) {
                for ($m = 12; $m > 0; $m--) {
                    my $i = $m - 1;
                    last if $mn =~ /$MONTHNAME[$i]/i;
                }
            } else {
                $val =~ s/^(\d+)//;
                $m = '0' . $1;
                $m =~ s/.*(\d\d)$/$1/;
            }
            return ( $screen_value, -1) if ($m < 1 || $m > 12);
            $mn = $m;
            $mn = $MONTHNAME[$m] if $format =~ s/^m//;
            $mn = uc $MONTHNAME[$m] if $format =~ s/^M//;
            $date .= $mn;
        }
        if ($format =~ s/^DD//) {
            $val =~ s/^\D*//;
            $val =~ s/^(\d+)//;
            $d = '0' . $1;
            return ( $screen_value, -1) if ($d < 1 || $d > 31);
            $d =~ s/.*(\d\d)$/$1/;
            $date .= $d;
        }
    } until ($format !~ /YY|MM|DD/i);

#check for valid date
    return ( $screen_value, -1) if ($m > 0 && $d > $MAXDAY[$m] );
    return ( $screen_value, -1) if ($m == 2 && $d == 29
                                    && ($y%4!=0 || $y%100==0 && $y%400!=0) );

#day of week -- not implemented
#    $wkl = $y/400
#    $date =~ s/KKK/$wku/;
#    $date =~ s/kkk/$wkl/;

    return ($date, 0);

}

# FORMAT
sub handle_format_attribute {
    my $self         = shift;
    my $screen_value = shift;    # complete string

    my ( $tag, $table, $col ) = $self->get_names;

#    return ( $screen_value, 0 )
#      if !defined $self->{format};

    # unsupported
    return ( $screen_value, 0 )
      if ( $self->{type} eq 'DATETIME'
        || $self->{type} eq 'INTERVAL'
        || $self->{type} eq 'SERIAL');

    # FLOAT, INT and REAL

#perhaps should return an error, but instead are stripping out bad chars
    $screen_value =~ tr/0-9.+-//cd;
    $screen_value =~ tr/-//d if $self->{format} !~ /-/;

    my $t = 32 - length $self->{format};
    my ($frac) = $self->{format} =~ /\.([#&]*)/;
    my $f = length $frac;
    my $val = sprintf("%32.${f}f", $screen_value);
    $val =~ s/^\s{$t}//;
    for (my $i = length ($self->{format})-1; $i >= 0; $i--) {
        my $c = substr($self->{format}, $i, 1);
        substr($val, $i, 1) = $c if $c !~ /[#&-.]/;
    }
    return ( $val, 0);

=pod
    my ( $tout, @vm, @vn, @fm, @fn, @tmp );
    my ( @out, @mout, @nout, $out, $mout, $nout, $i, $vpos );

    @tmp = split /\./, $screen_value;
    if ( defined $tmp[1] ) {
        @vm = split //, $tmp[0];
        @vn = split //, $tmp[1];
    }
    else {
        @vm = defined $tmp[0] ? split //, $tmp[0] : ();
        @vn = ();
    }
    undef @tmp;
    @tmp = split /\./, $self->{format};
    @fm = split //, $tmp[0];
    if ( defined $tmp[1] ) {
        @fn = split //, $tmp[1];
    }

    $vpos = $#vm;
    for ( $i = $#fm ; $i >= 0 ; $i-- )
    {    # treat '-' and '&' as '#' -  not clear what these chars mean
        my $c = $fm[$i];
        if ( $c eq '#' || $c eq '-' || $c eq '&' )
        {
            if ($vpos >= 0) {
                my $num = $vm[$vpos];
                if ( !$self->is_number($num) ) {
                    return ( $screen_value, -1 );
                }
                $mout[$i] = $num;
            } else {
                $mout[$i] = ' ';
            }
        } else {
            $mout[$i] = $c;
        }
        $vpos--;
    }

    $vpos = 0;
    for ( $i = 0 ; $i <= $#fn ; $i++ ) {
        if ( $fn[$i] eq '#' && $vpos <= $#vn ) {
            my $num = $vn[$vpos];
            if ( !$self->is_number($num) ) {
                return ( $screen_value, -1 );
            }
            $nout[$i] = $vn[$vpos];
        }
        elsif ( ( $fn[$i] eq '#' || $fn[$i] eq '-' )
            && $vpos > $#vn )
        {
            $nout[$i] = '0';
        }
        else {
            $nout[$i] = $fn[$i];
        }
        $vpos++;
    }

    # calculate if too many to display

    $mout = join '', @mout;
    $nout = join '', @nout;
    $out = $mout . '.' . $nout;

    return ( $out, 0 );
=cut
}

# FORMAT - money
# this is not a real thing.  but it may be needed insome other form
sub handle_money_attribute {
    my $self         = shift;
    my $screen_value = shift;    # complete string

#warn "handle_money_attr: $screen_value\n";

    $screen_value = '$' . $screen_value;
    return ( $screen_value, 0 );
}

sub is_num {
    my $n = shift;
    return 1 if $n =~ /^[+-]?\d+(\.\d+)?$/;
    return 0;
}
# checks the field value against the attributes
# to determine if a sql operation is in order
# returns undef on success
# assumes nulls are "undefined"
# returns a msg on error - prepend msg to $field->{comments}
# caller must validate comments
#FIX:  maybe the return msg can be wrapped...

sub validate_input {
    my $self         = shift;
    my $screen_value = shift;
    my $mode         = shift;

    warn "TRACE: entering validate_input\n" if $::TRACE;
    my $value = $self->get_value;

    my $GlobalUi = $DBIx::Perform::GlobalUi;
    my $tag      = $self->{field_tag};
    return 0 if !$self->allows_focus($mode);

    if ( !defined($value) ) {

        # include statement with "null" set
        return 0 if defined( $self->{null_ok} );

        # REQUIRED
        if ( defined( $self->{required} ) ) {
            warn "TRACE: leaving validate_input on fail\n" if $::TRACE;
            $GlobalUi->display_error('th44s');
            $GlobalUi->change_focus_to_field_in_current_table($tag);
            return -1;
        }
        if ( !defined $self->{null_ok} ) {
            my $col = $self->{column_name};
            my $m = sprintf($GlobalUi->{error_messages}->{'th41.'}, $col);
            $GlobalUi->display_error($m);
            $GlobalUi->change_focus_to_field_in_current_table($tag);
            return -1;
        }
    }

    #INCLUDE
    if ( defined( $self->{include} ) ) {
        $value =~ s/\s*$// if $value;
	return 0 if $value eq '' && defined $self->{null_ok};

        # INCLUDE - list of values
        my $inc_vals = $self->{include_values};
        if ( defined($inc_vals) ) {
	    return 0 if $inc_vals->{ uc $value };
	}

        # INCLUDE - numeric range
	my $ranges = $self->{range};
	foreach my $r (keys(%$ranges)) {
	    my $r2 = $ranges->{$r};
	    if (is_num($r) && is_num($r2)) {
	        return 0 if ($value >= $r && $value <= $r2);
	    } else {
		$r  =~ s/^"(.*)"$/$1/;
		$r2 =~ s/^"(.*)"$/$1/;
		return 0 if ($value ge $r && $value le $r2);
	    }
        }

        $GlobalUi->display_error('th44s');
        $GlobalUi->change_focus_to_field_in_current_table($tag);
        return -1;
    }

    if ($self->is_any_numeric_db_type) {
	if ($value =~ /[^\s0-9.+-]/) {
            warn "TRACE: leaving validate_input on fail, must be number\n" if $::TRACE;
            $GlobalUi->display_error('er11d');
            $GlobalUi->change_focus_to_field_in_current_table($tag);
            return -1;
        }
    }

    warn "TRACE: leaving validate_input on success\n" if $::TRACE;
    return 0;
}

# returns boolean if field takes a focus for an editmode
sub allows_focus {

    my $self = shift;
    my $mode = shift;

    return 0 if defined( $self->{displayonly} );
    return 0 if defined( $self->{active_tabcol} );
    return 0 if $mode eq 'add' && defined( $self->{noentry} );
    return 0 if $mode eq 'update' && defined( $self->{noupdate} );

    return 1;
}

1;

