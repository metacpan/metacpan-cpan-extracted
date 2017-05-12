package DBICx::Backend::Move;

use 5.010;
use strict;
use warnings;
use Moo;
use Module::Load 'load';
use DBICx::Deploy;

our $VERSION = 1.00010;

sub deploy
{
        my ( $self, $schema, $dsn, @args ) = @_;
        load $schema;
        DBICx::Deploy->deploy($schema, $dsn, @args);
        return;
}


sub transfer_data
{
        my ( $self, $from, $to, $opt ) = @_;

        my $schema   = $opt->{schema};
        my $verbose  = $opt->{verbose} || 0;
        my $rawmode  = $opt->{rawmode};

 SOURCE:
        foreach my $source_name ($from->sources) {
                print STDERR "Transfer: $source_name => " if $verbose;
                my $source_rs = $from->resultset($source_name);

                if (ref $source_rs->result_source eq 'DBIx::Class::ResultSource::View') {
                        say STDERR "$source_name is a view. Skipped." if $verbose;
                        next SOURCE;
                }

                while (my $row = $source_rs->next) {
                        my %source_row;
                        print STDERR "." if $verbose >= 2;
                        %source_row = $rawmode ? $row->get_columns : $row->get_inflated_columns;
                        my $new_row;
                        if ($rawmode) {
                                $new_row = $to->resultset($source_name)->new({});
                                $new_row->set_columns(\%source_row);
                        } else {
                                $new_row = $to->resultset($source_name)->new(\%source_row);
                        }
                        $new_row->insert;
                }
                print STDERR "done.\n" if $verbose;
        }
        return;
}

1;
