package Chemistry::ESPT::Aprmcrd;

use base qw(Chemistry::ESPT::ESSfile);
use strict;
use warnings;

=head1 NAME

Chemistry::ESPT::Aprmcrd - AMBER prmcrd file object.

=head1 SYNOPSIS

    use Chemistry::ESPT::Aprmcrd;

    my $prmcrd = Chemistry::ESPT::Aprmcrd->new();

=head1 DESCRIPTION

This module provides methods to quickly access data contained in an AMBER prmcrd file.
AMBER prmcrd files can only be read currently.

=cut

our $VERSION = '0.02';

=begin comment

### Version History ###
 0.01	digest prmcrd files from Amber9
 0.02	moved to Chemistry::ESPT namespace

=end comment

=head1 ATTRIBUTES

All attributes are currently read-only and get populated by reading the assigned ESS file.  Attribute values are
accessible through the B<$Aprmcrd-E<gt>get()> method.

=over 15

=item  CARTCOORD

NATOMS x 3 matrix containing Cartesian coordinates

=back

=head1 METHODS

Method parameters denoted in [] are optional.

=over 15

=item B<$prmcrd-E<gt>new()>

Creates a new Aprmcrd object

=cut

## the object constructor **

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $prmcrd = Chemistry::ESPT::ESSfile->new();

	$prmcrd->{PROGRAM} = "AMBER";
	$prmcrd->{TYPE} = "prmcrd";

	# molecular info
	$prmcrd->{CARTCOORD} = [];		# Current cartesian coordinates

	bless($prmcrd, $class);
	return $prmcrd;
}


## methods ##

=item B<$prmcrd-E<gt>analyze(filename [spin])>

Analyze the spin results in file called filename.  Spin defaults to Alpha.

=cut

# set filename & spin then digest the file
sub analyze : method {
	my $prmcrd = shift;
	$prmcrd->prepare(@_);
	$prmcrd->_digest();
	return;
}


## subroutines ##

sub _digest {

my $prmcrd = shift;

# flags & counters
my $counter = 0;
my $Titleflag = 1;

# open filename for reading or display error
open(PRMCRDFILE,$prmcrd->{FILENAME}) || die "Could not read $prmcrd->{FILENAME}\n$!\n";

# grab everything which may be useful
while (<PRMCRDFILE>){
	# skip blank lines
	next if /^$/;

	# title; first line of text
	if ( $Titleflag == 1 && /^[\w\d\-\(\)]+/ ) {
		chomp($_);
		s/\s+$//;
		$prmcrd->{TITLE} = $_;
		$Titleflag = 0;
		next;
	}
	# number of atoms
	if ( $Titleflag == 0 && /^\s+(\d+)$/ ) {
		$prmcrd->{NATOMS} = $1;
		next;
	}
        # current cartesian coordinates
        # store in an N x 3 array for the time being
        # switch to PerlMol objects in the future
        if ( /^\s+((?:-*\d+\.\d+\s+){1,6})/ ) {
		my @carts = split /\s+/, $1;
                for (my $i=0; $i<scalar(@carts); $i++) {
                        push @{ $prmcrd->{CARTCOORD} [$counter] }, $carts[$i];
                        $counter++ if $#{$prmcrd->{CARTCOORD} [$counter]}  == 2;
                }
                next;
        }

}
}


1;
__END__

=back

=head1 VERSION

0.02

=head1 SEE ALSO

L<Chemistry::ESPT::ESSfile>, L<http://amber.scripps.edu>

=head1 AUTHOR

Dr. Jason L. Sonnenberg, E<lt>sonnenberg.11@osu.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Dr. Jason L. Sonnenberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. I would like to hear of any
suggestions for improvement.

=cut

