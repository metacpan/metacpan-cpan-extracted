#!/usr/bin/perl -w

# a simple but useful DBR browse utility.

use strict;
use warnings;

use DBR;
use DBR::Util::Logger;

use Data::Dumper;

my $conffile = shift @ARGV or die "I need a path to a DBR conf file!\n";
my $confdb   = shift @ARGV || 'dbrconf';

my $logger = new DBR::Util::Logger(-logpath => '/tmp/dbr_browser.log', -logLevel => 'warn');
my $dbr    = new DBR(
		     -logger => $logger,
		     -conf   => $conffile,
		    );

my $dbrh = $dbr->connect($confdb) or die "No config found for confdb $confdb";

if (my $schema_id = &get_schema) {
      while (1) {
            my $table_id = &get_table( $schema_id ) or last;
            &render( $table_id );
      }
}
print "\nbye!\n";

# ------------------------------------------------------------

sub render {
      my $table_id = shift;

      my $fields = $dbrh->select(
                                 -table  => 'dbr_fields',
                                 -fields => 'field_id name data_type is_pkey trans_id',
                                 -where  => { table_id => [ 'd', $table_id ] },
                                )
        or return;

      my $type_defs = DBR::Config::Field->list_datatypes or die;
      my %type_lookup; map { $type_lookup{$_->{id}} = $_ } @{$type_defs};

      my $trans_defs = DBR::Config::Trans->list_translators or die 'Failed to get translator list';
      my %trans_lookup; map {$trans_lookup{$_->{id}} = $_}  @$trans_defs;

      my $targets = $dbrh->select(
                                  -table  => 'dbr_relationships',
                                  -fields => 'from_field_id to_name to_table_id',
                                  -where  => { from_table_id => [ 'd', $table_id ] },
                                 ) or die;
      my $targeted_bys = $dbrh->select(
                                       -table  => 'dbr_relationships',
                                       -fields => 'from_table_id from_field_id to_name',
                                       -where  => { to_table_id => [ 'd', $table_id ] },
                                      ) or die;
      my @table_ids = grep { $_ } map { $_->{to_table_id}, $_->{from_table_id} } @{$targets}, @{$targeted_bys};
      my $tables = $dbrh->select(
                                 -table  => 'dbr_tables',
                                 -fields => 'table_id name',
                                 -where  => { table_id => [ 'd in', $table_id, @table_ids ] },
                                ) or die;
      my %table_lookup = map { $_->{table_id} => $_ } @{$tables};
      my @field_ids = map { $_->{from_field_id} } @{$targeted_bys};
      my $tfields = [];
      if (@field_ids) {
            $tfields = $dbrh->select(
                                     -table  => 'dbr_fields',
                                     -fields => 'field_id name',
                                     -where  => { field_id => [ 'd in', @field_ids ] },
                                    ) or die;
      }
      my %field_lookup = map { $_->{field_id} => $_ } @{$tfields};

      # create Table object, call relations() and then build lookups for fields.

      my @rows = ();
      foreach my $field (@{$fields}) {
            my ($target) = grep { $field->{field_id} == $_->{from_field_id} } @{$targets};
            push @rows, {
                         field  => $field->{name},
                         type   => $type_lookup{$field->{data_type}}->{handle},
                         trans  => $field->{trans_id} ? $trans_lookup{$field->{trans_id}}->{name} : $field->{is_pkey} ? '--PKEY--' : '',
                         target => $target ? $table_lookup{$target->{to_table_id}}->{name} : '',
                        };
      }

      # output info
      print uc( $table_lookup{$table_id}->{name} ) . "\n";
      &grid( \@rows, qw( field type trans target ) );
      if (@{$targeted_bys}) {
            my @rows = ();
            foreach my $t (@{$targeted_bys}) {
                  push @rows, {
                               'reverse name' => $t->{to_name},
                               'table.field'  => $table_lookup{$t->{from_table_id}}->{name}.'.'.$field_lookup{$t->{from_field_id}}->{name},
                              };
            }
            print "TARGETED BY:\n";
            &grid( \@rows, 'table.field', 'reverse name' );
      }
}

sub grid {
      my $rows = shift;  # data rows
      my @fields = @_;   # column keys order
      my %max = ();
      foreach my $row ({ map { $_ => $_ } @fields }, @{$rows}) {
            foreach my $field (@fields) {
                  my $len = defined $row->{$field} ? length( $row->{$field} ) : 0;
                  $max{$field} = $len if $len && $len > ($max{$field}||=0);
            }
      }
      my $box = '+-' . join( '-+-', map { '-' x $max{$_} } @fields ) . '-+';
      print "$box\n";
      print '| ' . join( ' | ', map { sprintf( '%'.$max{$_}.'s', $_ ) } @fields ) . " |\n";
      print "$box\n";
      foreach my $row (@{$rows}) {
            my @vals = ();
            foreach my $field (@fields) {
                  my $val = $row->{$field};
                  push @vals, defined $val ? sprintf( '%'.$max{$field}.'s', $val ) : '';
            }
            print '| ' . join( ' | ', @vals ) . " |\n";
      }
      print "$box\n";
}

sub get_table {
      my $schema_id = shift;

      while (1) {
            print "\nTABLE> ";
            chomp( my $filter = <STDIN> );
            last if $filter eq 'q';

            if (!length($filter) || $filter =~ m!\D!) {
                  my %where = ();
                  $where{name} = [ 'like', '%' . $filter . '%' ] if $filter;
                  my $tables = $dbrh->select(
                                             -table  => 'dbr_tables',
                                             -fields => 'table_id schema_id name',
                                             -where  => {
                                                         schema_id => ['d', $schema_id ],
                                                         %where
                                                        },
                                );
                  die "query error!\n" unless defined $tables;

                  if (!$tables || scalar( @{$tables} ) == 0) {
                        print "\nno matching tables found\n";
                  }

                  my $table;
                  if (@{$tables} > 1) {
                        foreach my $table (@{$tables}) {
                              printf "%3d) %s\n", $table->{table_id}, $table->{name};
                        }
                  }
                  else {
                        return $tables->[0]->{table_id};
                  }
            }
            else {
                  return $filter;
            }
      }

      return 0;
}

sub get_schema {
      my $schemas = $dbrh->select(
                                  -table => 'dbr_schemas',
                                  -fields => 'schema_id handle display_name',
                                 )
        or die('Schemas fetch failed');

      print "\nSelect a schema:\n0) Quit\n";
      foreach my $schema (@{$schemas}) {
            print "$schema->{schema_id}) $schema->{display_name}\n";
      }

      print "SCHEMA> ";
      chomp( my $pick = <STDIN> );
      my ($schema) = grep { $pick == $_->{schema_id} } @{$schemas} if $pick && $pick ne 'q';

      return $schema ? $schema->{schema_id} : 0;
}

1;
