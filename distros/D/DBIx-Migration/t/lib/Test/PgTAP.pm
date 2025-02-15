use strict;
use warnings;

package Test::PgTAP;

# our $VERSION = '0.001';

use parent qw( Test::Builder::Module );

use Test::Deep qw( bag deep_diag cmp_details );

our @EXPORT = qw( tables_are triggers_are );

# the idea how to inject a database handle was borrowed from
# https://metacpan.org/pod/Test::DatabaseRow
our $Dbh;

# https://pgtap.org/documentation.html#tables_are
sub tables_are {
  my ( $schema, $expected_tables, $test_name );
  my $first_arg = shift;
  if ( 'ARRAY' eq ref( $first_arg ) ) {
    $expected_tables = $first_arg;
    ( $test_name ) = @_;
  } else {
    $schema = $first_arg;
    ( $expected_tables, $test_name ) = @_;
  }

  my @got_tables;
  if ( defined $schema ) {
    my $sth = $Dbh->table_info( '%', defined $schema ? $schema : '%', '%', 'TABLE' );
    while ( my $row = $sth->fetchrow_hashref ) {
      push @got_tables, $row->{ TABLE_NAME };
    }
  } else {
    @got_tables = grep { not /\Apg_catalog\./ and not /\Ainformation_schema\./ } $Dbh->tables( '%', '%', '%', 'TABLE' );
  }

  my ( $ok, $stack ) = cmp_details( \@got_tables, bag( @$expected_tables ) );
  my $Test = __PACKAGE__->builder;
  unless ( defined $test_name ) {
    $test_name =
      defined $schema
      ? "Schema '$schema' should have the expected tables"
      : 'Non PostgreSQL schemas should have the expected tables';
  }
  unless ( $Test->ok( $ok, $test_name ) ) {
    my $diag = deep_diag( $stack );
    $Test->diag( $diag );
  }
}

# https://pgtap.org/documentation.html#triggers_are
sub triggers_are {
  my ( $schema, $table, $expected_triggers, $test_name );
  my $first_arg  = shift;
  my $second_arg = shift;
  if ( 'ARRAY' eq ref( $second_arg ) ) {
    $table             = $first_arg;
    $expected_triggers = $second_arg;
    ( $test_name ) = @_;
  } else {
    $schema = $first_arg;
    $table  = $second_arg;
    ( $expected_triggers, $test_name ) = @_;
  }

  my $sth;
  if ( defined $schema ) {
    $sth = $Dbh->prepare( <<'EOF' );
SELECT
  trigger_name
FROM
  information_schema.triggers
WHERE
  event_object_schema = ? AND event_object_table = ?
EOF
    $sth->execute( $schema, $table );
  } else {
    $sth = $Dbh->prepare( <<'EOF' );
SELECT
  event_object_schema || '.' || trigger_name
FROM
  information_schema.triggers
WHERE
  event_object_schema <> 'pg_catalog' AND event_object_schema <> 'information_schema' AND event_object_table = ?
EOF
    $sth->execute( $table );
  }
  my @got_triggers = map { @$_ } @{ $sth->fetchall_arrayref( [ 0 ] ) };

  my ( $ok, $stack ) = cmp_details( \@got_triggers, bag( @$expected_triggers ) );
  my $Test = __PACKAGE__->builder;
  unless ( defined $test_name ) {
    $test_name =
      defined $schema
      ? "Table '$table' in schema '$schema' should have the expected triggers"
      : "Table '$table' in non PostgreSQL schemas should have the expected triggers";
  }
  unless ( $Test->ok( $ok, $test_name ) ) {
    my $diag = deep_diag( $stack );
    $Test->diag( $diag );
  }
}

1;

__END__

=pod

=head1 NAME

Test::pgTAP - Test module that implements pgTAP in Perl

=head1 TEST FUNCTIONS

=head2 SCHEMA RELATED

=head3 C<tables_are()>

=head3 C<triggers_are()>

=head1 SEE ALSO

=over

=item * L<Using pgTAP|https://pgtap.org/documentation.html#usingpgtap>

=back

=cut
