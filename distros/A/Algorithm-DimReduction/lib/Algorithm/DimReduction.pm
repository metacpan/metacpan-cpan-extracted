package Algorithm::DimReduction;

use strict;
use warnings;
use Algorithm::DimReduction::Result;
use File::Temp;
use File::Copy;
use Storable qw( nstore retrieve );
use base qw( Class::Accessor::Fast );

our $VERSION = '0.00001';

sub analyze {
    my $self      = shift;
    my $matrix    = shift;
    my $matrix_fh = $self->_output_temp_matrix($matrix);
    my ( $svd_file, $eigens ) = $self->_do_svd($matrix_fh);
    my $result = Algorithm::DimReduction::Result->new(
        svd_file => $svd_file,
        eigens   => $eigens,
    );
    return $result;
}

sub reduce {
    my $self      = shift;
    my $result    = shift;
    my $reduce_to = shift;

    my $svd_file = $result->{svd_file};

    my $octave_cmd = <<"    END";
        echo "\
            load('$svd_file');
            num = $reduce_to;
            s_sqrt = sqrt(s);
            max = size(u)(1,:);
            reduced_matrix = u([1:max],[1:num]) * s_sqrt([1:num],[1:num]);
            save $svd_file *;
        " | octave -q
    END
    system($octave_cmd);
    my $reduced_matrix = $self->_pickup_matrix($svd_file);
    return $reduced_matrix;
}

sub save_analyzed {
    my $self     = shift;
    my $result   = shift;
    my $save_dir = shift;

    $save_dir ||= $ENV{PWD} . '/RESULT';
    $save_dir =~ s/\/$//;
    unless ( -e $save_dir ) {
        system("mkdir -p $save_dir");
    }
    copy( $result->{svd_file}, $save_dir . '/svd.oct' );
    $result->{svd_file} = $save_dir . '/svd.oct';
    nstore( $result, $save_dir . '/result.bin' );
}

sub load_analyzed {
    my $self          = shift;
    my $save_dir_name = shift;
    my $result        = retrieve( $save_dir_name . '/result.bin' );
    return $result;
}

sub _output_temp_matrix {
    my $self   = shift;
    my $matrix = shift;

    my %args = (
        TEMPLATE => 'matrix_XXXX',
        SUFFIX   => '.mat',
    );
    my $matrix_fh = File::Temp->new(%args);
    for my $i ( 0 .. @$matrix - 1 ) {
        for my $j ( 0 .. @{ $matrix->[0] } - 1 ) {
            print $matrix_fh $matrix->[$i]->[$j], "\t";
        }
        print $matrix_fh "\n";
    }
    return $matrix_fh;
}

sub _do_svd {
    my $self      = shift;
    my $matrix_fh = shift;

    my $matrix_file = $matrix_fh->filename;
    my %args        = (
        TEMPLATE => 'svd_XXXX',
        SUFFIX   => '.oct',
    );
    my $svd_fh   = File::Temp->new(%args);
    my $svd_file = $svd_fh->filename;

    my $octarve_cmd = <<"    END";
        echo "\
            matrix = load $matrix_file;
            [u, s, v] = svd(matrix);
            for i=1:size(diag(s))(1:1)
                info(i) = sum(diag(s)([1:i],:))/sum(diag(s));
                printf('%g,', info(i));
            end
            save $svd_file *;
        " | octave -q
    END

    my @desc_order_eigens = split( ',', `$octarve_cmd` );

    if ( $self->{save_svd_file} ) {
        copy( $svd_file, $self->{save_svd_file} );
    }
    $self->{svd_fh} = $svd_fh;
    return ( $svd_file, \@desc_order_eigens );
}

sub _pickup_matrix {
    my $self     = shift;
    my $svd_file = shift;
    my $reduced_matrix;
    open( OCT, $svd_file );
  LABEL:
    while (<OCT>) {
        if ( $_ =~ /# name: reduced_matrix/ ) {
            my $type    = <OCT>;
            my $rows    = <OCT>;
            my $columns = <OCT>;
            while (<OCT>) {
                last LABEL if ( $_ =~ /#/ );
                chomp $_;
                my @cols = split( ' ', $_ );
                shift @cols if $cols[0] eq '';
                push( @$reduced_matrix, \@cols );
            }
        }
    }
    close(OCT);
    return $reduced_matrix;
}

1;
__END__

=head1 NAME

Algorithm::DimReduction - Dimension Reduction tool that relies on 'Octave'

=head1 SYNOPSIS

  use Algorithm::DimReduction;

  my $matrix = [
    [ 1, 2, 3, 4, 5],
    [ 6, 7, 8, 9,10],
    [11,12,13,14,15],
  ];

  my $reductor = Algorithm::DimReduction->new;

  # matrix has been analyzed beforehand
  my $result   = $reductor->analyze( $matrix );
  print Dumper $result->contribution_rate;

  # save and load
  $reductor->save_analyzed($result);
  my $result = $reductor->load_analyzed('save_dir');

  # reduce it
  my $reduce_to = 3;
  my $reduced_matrix = $reductor->reduce( $result, $reduce_to );

=head1 DESCRIPTION

Algorithm::DimReduction does Dimension Reduction with Singular value decomposition (SVD).

It relies on svd command of 'Octave'.

=head1 METHODS

=head2 analyze( $matrix )

=head2 reduce( $result_of_analyze, $reduce_to )

=head2 save_analyzed( $result_of_analyze, $save_dir )

=head2 load_analyzed( $save_dir )

=head1 AUTHOR

Takeshi Miki E<lt>t.miki@nttr.co.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
