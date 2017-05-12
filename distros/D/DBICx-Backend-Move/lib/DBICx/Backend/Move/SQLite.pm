package DBICx::Backend::Move::SQLite;

use 5.010;
use strict;
use warnings;
use Moo;

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

        $self->transfer_data($from, $to, $opt);
        return 0;
}

1;
