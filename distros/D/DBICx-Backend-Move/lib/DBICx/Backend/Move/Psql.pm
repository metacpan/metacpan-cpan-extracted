package DBICx::Backend::Move::Psql;

use 5.010;
use strict;
use warnings;
use Moo;
use Module::Load 'load';
use DBICx::Deploy;

extends 'DBICx::Backend::Move';

sub migrate
{
        my ( $self, $connect_from, $connect_to, $opt ) = @_;

        my $schema  = $opt->{schema};
        my $verbose = $opt->{verbose};
        my $logfile = $opt->{logfile};

        $self->deploy($schema, @$connect_to);

        my $from = $schema->connect(@$connect_from);
        my $to   = $schema->connect(@$connect_to);

        $to->txn_do(sub { $to->storage->dbh->do("SET CONSTRAINTS ALL DEFERRED"); $self->transfer_data($from, $to, $opt) });


        # Transfering data did not update autoincrement sequences so we need to do it manually
        foreach my $source_name ($to->sources) {
                my $column_infos = $to->resultset($source_name)->result_source->columns_info();
                foreach my $column ($to->resultset($source_name)->result_source->columns) {
                        if ($column_infos->{$column}->{is_auto_increment}) {

                                # get the real next value, which is current max+1
                                # If anyone else tries to update this number, it will fail.
                                # Probably ok since we just create this database.
                                my $value = $to->resultset($source_name)->get_column($column)->max;
                                $value += 1;

                                my $table_name = $to->source_registrations->{$source_name}->name;
                                $to->storage->dbh_do(
                                                     sub { my ($storage, $dbh) = @_;
                                                           my $sequence = $dbh->selectrow_array("select pg_get_serial_sequence('$table_name', '$column');");
                                                           $dbh->do("alter sequence $sequence restart with $value");
                                                   } );
                        }
                }

        }
        return 0;
}

1;
