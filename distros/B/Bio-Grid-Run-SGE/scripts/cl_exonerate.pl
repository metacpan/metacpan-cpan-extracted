#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE;
use Bio::Grid::Run::SGE::Master;
use Bio::Gonzales::Seq::IO qw/faiterate/;
use Data::Dumper;
use IO::Handle;

my $EXEC = "$ENV{HOME}/usr/precompiled/exonerate-2.2.0-x86_64/bin/exonerate";
run_job(
    {
        task => sub {
            my ( $c, $result_prefix, $query_seq, $target_seq ) = @_;

            open my $res_fh, '>>', $result_prefix or confess "Can't open filehandle: $!";
            {
                my $fai = faiterate($query_seq);
                while ( my $s = $fai->() ) {
                    print $res_fh "#Q: " . $s->id, "\n";
                }
            }
            {
                my $fai = faiterate($target_seq);
                while ( my $s = $fai->() ) {
                    print $res_fh "#T: " . $s->id, "\n";
                }
            }
            $res_fh->close;

            my @cmd = ( $EXEC, @{ $c->{args} }, '--query', $query_seq, '--target', $target_seq );
            INFO( "running ", join( " ", @cmd ) );

            my $success = my_sys_non_fatal( join( " ", @cmd, ">>$result_prefix" ) );

            return $success;
        },
    }
);

1;
