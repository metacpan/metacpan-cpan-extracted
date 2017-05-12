# $Id: Swiss.pm 34 2006-06-19 19:19:43Z giel $

#   Algorithm::Pair::Swiss.pm
#
#   Copyright (C) 2006 Gilion Goudsmit ggoudsmit@shebang.nl
#
#   This library is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself, either Perl version 5.8.5 or, at your
#   option, any later version of Perl 5 you may have available.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#   or FITNESS FOR A PARTICULAR PURPOSE.
#

=head1 NAME

Algorithm::Pair::Swiss - Generate unique pairings for tournaments

=head1 VERSION

This document describes Algorithm::Pair::Swiss version 0.14

=head1 SYNOPSIS

    use Algorithm::Pair::Swiss;

    my $pairer = Algorithm::Pair::Swiss->new;

    $pairer->parties(1,2,3,4);

    @round_1 = $pairer->pairs;

    $pairer->exclude(@round_1);

    @round_2 = $pairer->pairs;

=head1 DESCRIPTION

This module was created as an alternative for Algorithm::Pair::Best, which
probably offers more control over the pairings, in particular regarding
ensuring the highest overal quality of pairings. Algorithm::Pair::Swiss is
sort of dumb in this regard, but uses a slightly more intuitive interface
and an algorithm that should perform noticably faster. The module was
primarily designed based on the Swiss rounds system used for Magic: The
Gathering tournaments.

After creating an Algorithm::Pair::Swiss-E<gt>B<new> object, use the B<parties>
method to supply a list of parties (players or teams) to be paired. At any
time the B<exclude> method can be used to indicate which pairs shouldn't be
generated (probably because they've already been paired in an earlier round).        

The list of parties is sorted and the pairer tries to find a set of pairs that
respects the exclude list, and tries to pair the parties that appear first
in the sorted list with each other most aggresively.

To influence the sort order, use objects as parties and overload either the
B<cmp> or B<0+> operators in the object class to sort as desired.

Algorithm::Pair::Swiss-E<gt>B<pairs> explores the parties and returns the first
pairing solution which satisfies the excludes. Because it doesn't exhaustively
try all possible solutions, performance is generally pretty reasonable.

For a large number of parties, it is generally easy to find a non-excluded pair,
and for a smaller number of parties traversal of the possible pairs is done
reasonably fast.

This module uses the parties as keys in a hash, and uses the empty string ('')
as a special case in this same hash. For this reason, please observe the
following restrictions regarding your party values:

=over 1

=item - make sure it is defined (not undef)

=item - make sure it is defined when stringified

=item - make sure each is a non-empty string when stringified

=item - make sure each is unique when stringified

=back

All the restrictions on the stringifications are compatible with the perl's
default stringification of objects, and should be safe for any stringification
which returns a unique party-identifier (for instance a primary key from a
Class::DBI object).        

=cut


package Algorithm::Pair::Swiss;
use strict;
use warnings;
no warnings 'recursion';
require 5.001;

our $REVISION = sprintf(q{%d} => q{$Rev: 34 $} =~ /(\d+)/g);
our $VERSION = q(0.14);

use Carp;

######################################################
#
#       Public methods
#
#####################################################

=head1 METHODS

=over 4

=item my $pairer = B<Algorithm::Pair::Swiss-E<gt>new>( @parties )

A B<new> Algorithm::Pair::Swiss object is used to generate pairings.
Optionally @parties can be given when instantiating the object. This is
the same as using the B<parties> method described below.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->parties(@_) if @_;
    return $self;
}    

=item $pairer-E<gt>B<parties>( @parties )

Provides the pairer with a complete list of all individuals that can
be paired. If no parties are specified, it returns the sorted list
of all parties. This allows you to use this method to extract 'rankings'
if you happen to have implemented a B<cmp> operator overload in the
class your parties belong to.

=cut

sub parties {
    my $self = shift;
    return sort @{$self->{parties}} unless @_;
    $self->{parties} = [ @_ ];
    for my $i (@{$self->{parties}}) { 
        croak q{All parties must have a defined stringification}
            unless defined "$i";
        croak qq{All parties must have a unique stringification, but "$i" seems to be a duplicate}
            if exists $self->{exclude}->{"$i"};
        $self->{exclude}->{"$i"}={} 
    }
}

=item @pairs = $pairer-E<gt>B<pairs>

Returns the best pairings found as a list of arrayref's, each containing
one pair of parties.

=cut

sub pairs {    
    my $self = shift;
    my @pairs = _pairs([$self->parties],$self->{exclude});
    return @pairs;
}    

=item $pair-E<gt>B<exclude>( @pairs )

Excludes the given pairs from further pairing. The @pairs array
should consist of a list of references to arrays, each containing the two
parties of that pair. This means you can easily feed it the output of
a previous call to $pair-E<gt>B<pairs>. The selection given is added
to previously excluded pairs.

If there was an odd number of parties, the lowest ranked party will be
paired with 'undef', unless it has already been paired with 'undef'. In
that case, the second-lowest ranked party will get that pairing. Etcetera,
etcetera. 'Lowest-ranked' is defined as being last in the party-list after
sorting. In MTG terms, being paired with 'undef' would mean getting a bye
(and getting the full three points for that round as a consequence).

=cut

sub exclude {
    my $self = shift;
    for my $pair (@_) {
	my ($x,$y) = @$pair;
	    $self->{exclude}->{"$x"}->{$y?"$y":''} = 1 if $x;
	    $self->{exclude}->{"$y"}->{$x?"$x":''} = 1 if $y;
    }	
}    

=item $pair-E<gt>B<drop>( @parties )

Excludes the given parties from further pairing. The given parties will
be removed from the internal parties list and won't be returned by the
parties method anymore. This method is usually used when a participant
has decided to quit playing.

=cut

sub drop {
    my $self = shift;
    my %parties = map { ( "$_" => $_ ) } $self->parties;
    for my $party (@_) { delete $parties{"$party"} }
    $self->{parties} = [ values %parties ];
}

sub _pairs {
    my ($unpaired,$exclude) = @_;
    my @unpaired = @$unpaired;
    my $p1 = shift @unpaired;
    for my $p2 (@unpaired) {
    	next if exists $exclude->{"$p1"}->{"$p2"};	# already paired
       	next if exists $exclude->{"$p2"}->{"$p1"};	# already paired
    	return [$p1,$p2] if @unpaired==1;		    # last pair!
    	my @remaining = grep {"$_" ne "$p2"} @unpaired;	# this pair could work
    	my @pairs = _pairs(\@remaining,$exclude);	# so try to pair the rest
    	next unless @pairs;				            # no luck
    	return [$p1,$p2],@pairs;			        # yay! return the resultset
    }
    if(@unpaired % 2 == 0) {					            # single player left
        return if exists $exclude->{"$p1"}->{''};		# already had a bye before
	    return [$p1,undef] unless @unpaired; 		# return a bye
	    my @pairs = _pairs(\@unpaired,$exclude);
	    return unless @pairs;
	    return @pairs,[$p1,undef];
    }
    return;
}    

1;

__END__

=back

=head1 EXPORT

None by default.

=head1 BUGS AND LIMITATIONS

No bugs that I know of...

The module's performance will probably break down 
if you use 1000+ parties and 100+ rounds though...

=head1 REQUIREMENTS

Perl 5.6.0 or later (though it will probably work ok with earlier versions)

=head1 SEE ALSO

=over 1

=item o Algorithm::Pair::Best

The B<Algorithm::Pair::Best> module if you need more control
over your pairings.

=item o overload

For proper results you'll want to overload the B<cmp> and/or B<0+>
operators of the objects you're using as parties. This will allow
for the correct sort order, so higher-ranked parties are matched
better.

=back

=head1 ACKNOWLEDGEMENTS

Reid Augustin for by B<Algorithm::Pair::Best>

Elizabeth Mattijsen for giving me some pointers on getting this module CPAN-ready.

=head1 AUTHOR

Gilion Goudsmit, E<lt>ggoudsmit@shebang.nlE<gt>

I can also be found on http://www.perlmonks.org as Gilimanjaro. You can direct 
any questions concerning this module there as well.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Gilion Goudsmit

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

