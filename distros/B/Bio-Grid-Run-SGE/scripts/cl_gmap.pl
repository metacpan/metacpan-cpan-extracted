#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE;
use Bio::Grid::Run::SGE::Master;
use Data::Dumper;

my $GMAP_EXEC = "$ENV{HOME}/usr/bin/gmap";
run_job(
    {
        pre_task => sub {
            my ($c) = @_;

            $c->{extra}{gmapdb} = my_glob( $c->{extra}{gmapdb} );

            return Bio::Grid::Run::SGE::Master->new($c);
        },
        task => sub {
            my ( $c, $result_prefix, $in_file ) = @_;

            INFO("mapping $in_file");
            my $cmd =                 "$GMAP_EXEC -d $c->{extra}{genome} -D $c->{extra}{gmapdb} $c->{extra}{args} --format=gff3_gene $in_file >$result_prefix.gff3";
            INFO("running $cmd");
            my $success = my_sys_non_fatal($cmd);

            return $success;
        },
    }
);

1;

