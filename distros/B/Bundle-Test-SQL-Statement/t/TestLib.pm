package TestLib;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK);

use Exporter;
use File::Spec;
use Cwd;
use File::Path;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(test_dir prove_reqs show_reqs connect default_recommended);

my $test_dsn  = delete $ENV{DBI_DSN};
my $test_user = delete $ENV{DBI_USER};
my $test_pass = delete $ENV{DBI_PASS};

my $test_dir;
END { defined($test_dir) and rmtree $test_dir }

sub test_dir
{
    unless ( defined($test_dir) )
    {
        $test_dir = File::Spec->rel2abs( File::Spec->curdir() );
        $test_dir = File::Spec->catdir( $test_dir, "test_output_" . $$ );
        $test_dir = VMS::Filespec::unixify($test_dir) if ( $^O eq 'VMS' );
        rmtree $test_dir;
        mkpath $test_dir;
    }

    return $test_dir;
}

sub check_mod
{
    my ( $module, $version ) = @_;
    my $mod_path = $module;
    $mod_path =~ s|::|/|g;
    $mod_path .= '.pm';
    eval { require $mod_path };
    $@ and return ( 0, $@ );
    my $mod_ver = $module->VERSION();
    $version = eval $version;
    $mod_ver = eval $mod_ver;
    $@                   and return ( 0, $@ );
    $version <= $mod_ver and return ( 1, $mod_ver );
    return (
             0,
             sprintf(
                      "%s->VERSION() of %s doesn't satisfy requirement of %s",
                      $module, $mod_ver, $version
                    )
           );
}

my %defaultRecommended = (
                           'DBI'          => '1.616',
                           'DBD::File'    => '0.40',
                           'DBD::CSV'     => '0.30',
                           'DBD::DBM'     => '0.06',
#                           'DBD::AnyData' => '0.110',
                         );

sub default_recommended
{
    return %defaultRecommended;
}

sub prove_reqs
{
    my %requirements;
    my %recommends;

    {
        my %req = ( 'SQL::Statement' => '1.32', );
        my %missing;
        while ( my ( $m, $v ) = each %req )
        {
            my ( $ok, $msg ) = check_mod( $m, $v );
            $ok and $requirements{$m} = $msg;
            $ok or $missing{$m} = $msg;
        }

        if (%missing)
        {
            my $missingMsg =
                "YOU ARE MISSING REQUIRED MODULES: [ "
              . join( ", ", keys %missing ) . " ]:\n"
              . join( "\n", values(%missing) );

            if ( $INC{'Test/More.pm'} )
            {
                Test::More::BAIL_OUT $missingMsg;
            }
            else
            {
                print STDERR "\n\n$missingMsg\n\n";
                exit 0;
            }
        }
    }
    {
        my %req =
          $_[0]
          ? %{ $_[0] }
          : %defaultRecommended;
        while ( my ( $m, $v ) = each %req )
        {
            my ( $ok, $msg ) = check_mod( $m, $v );
##	    if ( !$ok and $INC{'Test/More.pm'} )
##	    {
##		Test::More::diag($msg);
##	    }
            $ok and $recommends{$m} = $msg;
        }
    }

    return ( \%requirements, \%recommends );
}

sub show_reqs
{
    my @proved_reqs = @_;

    if ( $INC{'Test/More.pm'} )
    {
        Test::More::diag("Using required:") if ( $proved_reqs[0] );
        Test::More::diag( "  $_: " . $proved_reqs[0]->{$_} ) for sort keys %{ $proved_reqs[0] };
        Test::More::diag("Using recommended:") if ( $proved_reqs[1] );
        Test::More::diag( "  $_: " . $proved_reqs[1]->{$_} ) for sort keys %{ $proved_reqs[1] };
    }
    else
    {
        print("# Using required:\n") if ( $proved_reqs[0] );
        print( "#   $_: " . $proved_reqs[0]->{$_} . "\n" ) for sort keys %{ $proved_reqs[0] };
        print("# Using recommended:\n") if ( $proved_reqs[1] );
        print( "#   $_: " . $proved_reqs[1]->{$_} . "\n" ) for sort keys %{ $proved_reqs[1] };
    }
}

sub connect
{
    my $type = shift;
    defined($type)
      and $type =~ m/^dbi:/i
      and return TestLib::DBD->new( $type, @_ );
    defined($type)
      and $type =~ s/^dbd::/dbi:/i
      and return TestLib::DBD->new( "$type:", @_ );
    return TestLib::Direct->new(@_);
}

package TestLib::Direct;

use Carp qw(croak);
use Params::Util qw(_ARRAY0 _ARRAY _HASH0 _HASH);
use Scalar::Util qw(blessed);

sub new
{
    my ( $class, $flags ) = @_;
    $flags ||= {};
    my $parser = SQL::Parser->new( 'ANSI', $flags );
    my %instance = (
                     parser => $parser,
                     cache  => {},
                   );
    my $self = bless( \%instance, $class );
    return $self;
}

sub parser
{
    return $_[0]->{parser};
}

sub command
{
    my $self = $_[0];
    return $self->{stmt}->command();
}

sub prepare
{
    my ( $self, $sql, $attrs ) = @_;
    my $stmt = SQL::Statement->new( $sql, $self->{parser} );
    $self->{stmt} = $stmt;
    $self->{stmt}->{errstr} or return $self;
    return;
}

sub execute
{
    my $self   = shift;
    my @params = @_;      # bind params
    my @args;
    $args[0] =
      defined( _HASH0( $params[0] ) ) && !blessed( $params[0] ) ? shift(@params) : $self->{cache};
    $args[1] = \@params;
    return $self->{stmt}->execute(@args);
}

sub do
{
    my ( $self, $sql, $attrs, @args ) = @_;
    return $self->prepare( $sql, $attrs )->execute(@args);
}

sub col_names
{
    my $self = $_[0];
    defined( $self->{stmt}->{NAME} )
      and defined( _ARRAY( $self->{stmt}->{NAME} ) )
      and return $self->{stmt}->{NAME};
    my @col_names = map { $_->{name} || $_->{value} } @{ $self->{stmt}->{column_defs} };
    return \@col_names;
}

sub all_cols
{
    my $self = $_[0];
    return $self->{stmt}->{all_cols};
}

sub tbl_names
{
    my $self = $_[0];
    my @tables = sort map { $_->name() } $self->{stmt}->tables();
    return \@tables;
}

sub columns
{
    my ( $self, @args ) = @_;
    return $self->{stmt}->columns(@args);
}

sub tables
{
    my ( $self, @args ) = @_;
    return $self->{stmt}->tables(@args);
}

sub row_values
{
    my ( $self, @args ) = @_;
    return $self->{stmt}->row_values(@args);
}

sub where_hash
{
    my $self = $_[0];
    return $self->{stmt}->where_hash();
}

sub where
{
    my $self = $_[0];
    return $self->{stmt}->where();
}

sub params
{
    my $self = $_[0];
    return $self->{stmt}->params();
}

sub limit
{
    my $self = $_[0];
    return $self->{stmt}->limit();
}

sub offset
{
    my $self = $_[0];
    return $self->{stmt}->offset();
}

sub order
{
    my ( $self, @args ) = @_;
    return $self->{stmt}->order(@args);
}

sub selectrow_array
{
    my $self = shift;
    $self->do(@_);
    my $result = $self->{stmt}->fetch_row();
    return wantarray ? @$result : $result->[0];
}

sub fetch_row
{
    my $self = $_[0];
    return $self->{stmt}->fetch_row();
}

sub fetch_rows
{
    my $self = $_[0];
    my $rc = $self->{stmt}->fetch_rows();
    return $rc;
}

# clone DBI function
sub fetchall_hashref
{
    my ( $self, $key_field ) = @_;

    my $i          = 0;
    my $names_hash = { map { $_ => $i++ } @{ $self->{stmt}->{NAME} } };
    my @key_fields = ( ref $key_field ) ? @$key_field : ($key_field);
    my @key_indexes;
    my $num_of_fields = $self->{stmt}->{'NUM_OF_FIELDS'};
    foreach (@key_fields)
    {
        my $index = $names_hash->{$_};    # perl index not column
        $index = $_ - 1
          if !defined $index && DBI::looks_like_number($_) && $_ >= 1 && $_ <= $num_of_fields;
        croak("Field '$_' does not exist (not one of @{[keys %$names_hash]})")
          unless defined $index;
        push @key_indexes, $index;
    }
    my $rows     = {};
    my $all_rows = $self->{stmt}->fetch_rows();
    my $NAME     = $self->{stmt}->{NAME};
    foreach my $row ( @{$all_rows} )
    {
        my $ref = $rows;
        $ref = $ref->{ $row->[$_] } ||= {} for @key_indexes;
        @{$ref}{@$NAME} = @$row;
    }
    return $rows;
}

sub rows
{
    return $_[0]->{stmt}->{NUM_OF_ROWS};
}

sub errstr
{
    defined( $_[0]->{stmt} ) and return $_[0]->{stmt}->errstr();
    return $_[0]->{parser}->errstr();
}

sub finish
{
    delete $_[0]->{stmt};
}

package TestLib::DBD;

sub new
{
    my ( $class, $dsn, $attrs ) = @_;
    $attrs ||= {};
    my $dbh = DBI->connect( $dsn, undef, undef, $attrs );
    my %instance = ( dbh => $dbh, );
    my $self = bless( \%instance, $class );
    return $self;
}

sub parser
{
    return $_[0]->{dbh}->{sql_parser_object};
}

sub command
{
    my $self = $_[0];
    return $self->{sth}->{sql_stmt}->command();
}

sub prepare
{
    my ( $self, $sql, $attr ) = @_;
    my $sth = $self->{dbh}->prepare( $sql, $attr );
    $self->{sth} = $sth and return $self;
    return;
}

sub execute
{
    my $self = shift;
    return $self->{sth}->execute(@_);
}

sub do
{
    my ( $self, $sql, $attrs, @args ) = @_;
    return $self->prepare( $sql, $attrs )->execute(@args);
}

sub selectrow_array
{
    my $self = shift;
    $self->do(@_);
    my $result = $self->{sth}->fetchrow_arrayref();
    return wantarray ? @$result : $result->[0];
}

sub col_names
{
    my $self = $_[0];
    return $self->{sth}->{NAME};
}

sub all_cols
{
    my $self = $_[0];
    return $self->{sth}->{sql_stmt}->{all_cols};
}

sub tbl_names
{
    my $self = $_[0];
    my @tables = sort map { $_->name() } $self->{sth}->{sql_stmt}->tables();
    return \@tables;
}

sub columns
{
    my ( $self, @args ) = @_;
    return $self->{sth}->{sql_stmt}->columns(@args);
}

sub tables
{
    my ( $self, @args ) = @_;
    return $self->{sth}->{sql_stmt}->tables(@args);
}

sub row_values
{
    my ( $self, @args ) = @_;
    return $self->{sth}->{sql_stmt}->row_values(@args);
}

sub where_hash
{
    my $self = $_[0];
    return $self->{sth}->{sql_stmt}->where_hash();
}

sub where
{
    my $self = $_[0];
    return $self->{sth}->{sql_stmt}->where();
}

sub params
{
    my $self = $_[0];
    return $self->{sth}->{sql_stmt}->params();
}

sub limit
{
    my $self = $_[0];
    return $self->{sth}->{sql_stmt}->limit();
}

sub offset
{
    my $self = $_[0];
    return $self->{sth}->{sql_stmt}->offset();
}

sub order
{
    my ( $self, @args ) = @_;
    return $self->{sth}->{sql_stmt}->order(@args);
}

sub fetch_row
{
    my $self = $_[0];
    return $self->{sth}->fetch();
}

sub fetch_rows
{
    my $self = $_[0];
    return $self->{sth}->fetchall_arrayref();
}

sub fetchall_hashref
{
    my $self = shift;
    return $self->{sth}->fetchall_hashref(@_);
}

sub rows
{
    return $_[0]->{sth}->rows();
}

sub errstr
{
    defined( $_[0]->{sth} ) and return $_[0]->{sth}->errstr();
    return $_[0]->{dbh}->errstr();
}

sub finish
{
    delete $_[0]->{sth};
}

1;
