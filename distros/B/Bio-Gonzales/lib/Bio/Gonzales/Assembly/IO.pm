package Bio::Gonzales::Assembly::IO;

use warnings;
use strict;
use Carp;

use 5.010;

use File::Slurp qw/slurp/;
use List::MoreUtils qw/zip/;
use Bio::Gonzales::Seq::IO qw/fahash/;
use Bio::Gonzales::Matrix::IO qw(mslurp);

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(agpslurp agp2fasta);

our @AGP_COLUMN_NAMES = qw/
    object
    object_beg
    object_end
    part_number
    component_type
    component_id
    component_beg
    component_end
    orientation/;

sub INFO { say STDERR @_; }

sub agpslurp {
    my ($file) = @_;

    my @lines = slurp $file;

    my @agp;
    for my $l (@lines) {
        $l =~ s/\r\n/\n/;
        chomp $l;
        my @a = split /\t/, $l;

        #add last field in case somebody forgot to add it...
        push @a, '' if ( @a == 8 );

        #but if sth is really going wrong, break
        confess "error in agp file $file\n$l" unless ( @a == 9 );

        given ( $a[8] ) {
            when ('-') { $a[8] = -1 }
            when ('+') { $a[8] = 1 }
            default    { $a[8] = 0 }
        }

        push @agp, +{ zip @AGP_COLUMN_NAMES, @a };
    }

    return \@agp;
}

sub agp2fasta {
    my ( $agp, $seq, $out ) = @_;

    INFO("reading scf_seqs");
    my %scf_seqs = map { INFO("  $_"); ( fahash($_) ) } @$seq;

    INFO("reading agp data");
    my %agp_data;
    for my $agp_file (@$agp) {
        INFO("  $agp_file");
        my $data = agpslurp($agp_file);
        for my $e (@$data) {
            $agp_data{ $e->{object} } //= [];
            push @{ $agp_data{ $e->{object} } }, $e;

        }
    }

    INFO("processing agp data");
    while ( my ( $chr_id, $objs ) = each %agp_data ) {
        INFO("processing $chr_id");
        $objs = [ sort { $a->{part_number} <=> $b->{part_number} } @$objs ];

        open my $out_fh, '>', $out or confess "Can't open filehandle: $!";
        my $last_obj_end;
        say $out_fh ">$chr_id";
        for my $o (@$objs) {
            die "error" if ( $last_obj_end && ( $last_obj_end + 1 != $o->{object_beg} ) );
            given ( $o->{component_type} ) {
                when ('W') {
                    INFO( "processing scf " . $o->{component_id} );
                    unless ( exists( $scf_seqs{ $o->{component_id} } ) ) {
                        die "could not find " . Dumper $o;
                    }

                    print $out_fh $scf_seqs{ $o->{component_id} }
                        ->subseq( [ @{$o}{qw/component_beg component_end orientation/} ] )->seq;
                }
                when ('N') {

                    my $len = $o->{object_end} - $o->{object_beg} + 1;
                    INFO( "processing gap of length " . $len );
                    print $out_fh 'N' x $len
                }
                when ('U') {
                    INFO("processing gap of UNKNOWN length 100");
                    print $out_fh 'N' x 100

                }
                default { die "unknown component type" . Dumper $o }
            }
        }
        $out_fh->close;
    }

}

1;

__END__

=head1 NAME

Bio::Gonzales::Assembly::IO - assembly related stuff

=head1 SYNOPSIS

    use Bio::Gonzales::Assembly::IO qw(agpslurp);

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
