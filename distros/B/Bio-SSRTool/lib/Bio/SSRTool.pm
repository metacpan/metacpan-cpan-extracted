package Bio::SSRTool;

use 5.006;
use strict;
use warnings;
use vars qw( @ISA @EXPORT @EXPORT_OK );
use Carp qw( croak );
use IO::Scalar;

@ISA = qw( Exporter );
@EXPORT = qw( find_ssr );
@EXPORT_OK = qw( find_ssr );

our $VERSION = '0.04';

=head1 NAME

Bio::SSRTool - The great new Bio::SSRTool!

=head1 SYNOPSIS

Examines FASTA-formatted sequence data for simple sequence repeats (SSRs).

    use Bio::SSRTool;

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=cut

# ------------------------------------------------------------
sub find_ssr {

=head2 find_ssr

    my $ssr_tool = Bio::SSRTool->new();
    my @ssrs = $ssr_tool->find_ssr( $seq, { min_repeats => 10 } );

Or: 

    use Bio::SSRTool 'find_ssr';

    my @ssrs = find_ssr( $fh, { motif_length => 'trimer' } );

The "find_ssr" routine expects a sequence string in FASTA format 
(or a filehandle to read a FASTA file) and an optional hash-ref of 
arguments including:

=over 4

=item min_repeats

A positive integer

=item motif_length

A positive integer between 1 and 10.  Default is 4.

=back

=cut

    my $seq         = shift or return;
    my $args        = shift || {};
    my $motif_len   = $args->{'motif_length'} || 4;
    my $min_repeats = $args->{'min_repeats'}  || 5;

    unless ( 
        $motif_len =~ /^\d{1,2}$/ && $motif_len > 0 && $motif_len < 11
    ) {
        croak "Invalid motif length '$motif_len'";
    }

    #
    # Make sure it acts like a filehandle
    #
    if ( ref $seq ne 'GLOB' ) {
        if ( $seq !~ /\n$/ && -e $seq ) {
            my $tmp = $seq;
            open my $fh, '<', $tmp or die "Can't read '$tmp': $!\n";
            $seq = $fh;
        }
        else {
            my $tmp = $seq;
            $seq = IO::Scalar->new( \$tmp );
        }
    }

    my @ssrs;
    $/ = '>';
    while ( my $rec = <$seq> ) {
        chomp $rec;
        next unless $rec;
        my ( $titleline, $sequence ) = split /\n/, $rec, 2;
        next unless ( $sequence && $titleline );

        # the ID is the first whitespace-delimited item on titleline
        my ( $id ) = $titleline =~ /^(\S+)/;  
        $id          ||= 'INPUT';
        $sequence      =~ s/\s+//g; # concatenate multi-line sequence
        my $seqlength  = length $sequence;
        my $ssr_number = 1; # track multiple ssrs within a single sequence
        my %locations;      # track location of SSRs as detected

        # test each spec against sequence
        for my $len ( 1 .. $motif_len ) {
            my $re = qr/(([gatc]{$len})\2{$min_repeats,})/;

            while ( $sequence =~ m/$re/ig ) {
                my $ssr   = $1;
                my $motif = lc $2;

                # reject "aaaaaaaaa", "ggggggggggg", etc.
                next if _homopolymer( $motif, $len );
                my $ssrlength  = length( $ssr );        # SSR length
                my $repeats    = $ssrlength / $len;     # of rep units
                my $end        = pos( $sequence );      # where SSR ends
                pos($sequence) = $end - $len;           # see docs
                my $start      = $end - $ssrlength + 1; # SSR starts
                my $id_and_num = $id . "-" . $ssr_number++;

                # count SSR only once
                unless ( $locations{ $start }++ ) {
                    push @ssrs, {
                        sequence    => $id_and_num, 
                        motif       => $motif, 
                        num_repeats => $repeats,
                        start       => $start,      
                        end         => $end,   
                        seq_length  => $seqlength
                    };
                }
            }
        }
    }

    return @ssrs;
}

# ------------------------------------------------------------
sub _homopolymer {
    # returns 'true' if motif is repeat of single nucleotide
    my ( $motif, $motiflength ) = @_;
    my ( $reps ) = $motiflength - 1;
    return $motif =~ /([gatc])\1{$reps}/;
}

# ------------------------------------------------------------
=head1 AUTHOR

Ken Youens-Clark, C<< <kclark at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-ssrtool at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-SSRTool>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::SSRTool

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-SSRTool>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-SSRTool>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-SSRTool>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-SSRTool/>

=back

=head1 ACKNOWLEDGEMENTS

This was originally written in 1999 by Sam Cartinhour.  Thanks to Jim
Thomason for code review.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ken Youens-Clark.

This program is released under the following license: GPL

=cut

1;
