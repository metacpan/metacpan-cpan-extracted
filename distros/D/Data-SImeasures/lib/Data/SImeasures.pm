package Data::SImeasures;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';

=head1 NAME

Data::SImeasures - The checks if something is a SI measure or not.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Data::SImeasures;

    my $sim = Data::SImeasures->new;
    ...

It is worth noting that some measures are present more than
once as that is more than one common form. These are listed
below.

    amp
    ampere

    meter
    metre

    Celsius
    degree Celsius

This module does have issues dealing with ohm and Celsius as
when it comes to the symbol as depending on the source, it
may be represented differently. This will be fixed eventually.

=head1 METHODS

=head2 new

This initilizes the object.

    my $sim=Data::SImeasures->new;

=cut

sub new{

	my $self={
		perror=>undef,
		error=>undef,
		errorString=>'',
	};
	bless $self;

	$self->{measures}={
		'amp'=>'A',
		'ampere'=>'A',
		'metre'=>'m',
		'meter'=>'m',
		'gram'=>'g',
		'second'=>'s',
		'kelvin'=>'K',
		'mole'=>'mol',
		'candela'=>'cd',
		'hertz'=>'Hz',
		'radian'=>'rad',
		'steradian'=>'sr',
		'newton'=>'N',
		'pascal'=>'Pa',
		'joule'=>'J',
		'watt'=>'W',
		'coulomb'=>'C',
		'volt'=>'V',
		'farad'=>'F',
		'ohm'=>'ERROR',
		'siemens'=>'S',
		'weber'=>'Wb',
		'tesla'=>'T',
		'henry'=>'H',
		'degree Celsius'=>'ERROR',
		'Celsius'=>'ERROR',
		'lumen'=>'lm',
		'lux'=>'lx',
		'becquere'=>'Bq',
		'gray'=>'Gy',
		'sievert'=>'Sv',
		'katal'=>'kat',
	};

	return $self;
}

=head2 getSymbol

This returns the symbol for the specified measure.

If if it ohm or Celsius, undef is returned.

    my $symbol=$self->getSymbol( $symbol );
    if ( $sim->error ){
        warn('Failed to match the specified measure');
    }else{
        if ( ! defined( $symbol ) ){
            warn( $measure.' is does not have a supported symbol' );
        }else{
            print "The symbol for ".$measure." is ".$symbol."\n";
        }
    }

=cut

sub getSymbol{
	my $self=$_[0];
	my $measure=$_[1];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	if ( ! defined( $measure ) ){
		$self->{error}=1;
		$self->{errorString}='No measure specified';
		$self->warn;
		return undef;
	}

	if ( ! $self->match( $measure ) ){
		$self->{error}=2;
		$self->{errorString}='';
		$self->warn;
		return undef;
	}

	my $symbol=$self->{measures}{$measure};
	if ( $symbol eq 'ERROR' ){
		return undef;
	}

	return $symbol;
}

=head2 match

This matches measures.

This only matches the name, not the symbol.

If ends in an s, plural, and does not match
siemens or Celsius, the end s is removed.

'1' is returned on it being matched and '0'
if it is not.

As long as an measure is defined, it wont error.

    if ( $sim->match( $measure ) ){
        print "It is a valid measure.\n";
    }

=cut

sub match{
	my $self=$_[0];
	my $measure=$_[1];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	if ( ! defined( $measure ) ){
		$self->{error}=1;
		$self->{errorString}='No measure specified';
		$self->warn;
		return undef;
	}

	#remove the end S if it is plural
	if ( 
		( $measure=~/s$/ ) &&
		( $measure!~/siemens$/ ) &&
		( $measure!~/Celsius$/ )
		){
		$measure=~s/s$//;
	}

	if ( defined( $self->{measures}{$measure} ) ){
		return 1;
	}

	return 0;
}

=head2 matchAll

This matches either the symbol or the name of the measure.

    if ( $sim->matchAll( $measure ) ){
        print "It is a valid measure.\n";
    }

=cut

sub matchAll{
	my $self=$_[0];
	my $measure=$_[1];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	if ( ! defined( $measure ) ){
		$self->{error}=1;
		$self->{errorString}='No symbol specified';
		$self->warn;
		return undef;
	}

	if ( $self->match( $measure ) ){
		return 1;
	}

	if ( $self->matchSymbol( $measure ) ){
		return 1;
	}

	return undef;
}

=head2 matchSymbol

This matches measure symbols.

'1' is returned on it being matched and '0'
if it is not.

As long as an measure is defined, it wont error.

This currently does not match ohm or Celsius given
how problematic matching can be. This is planned
to be fixed in later versions.

    if ( $sim->matchSymbol( $measure ) ){
        print "It is a valid measure.\n";
    }

=cut

sub matchSymbol{
	my $self=$_[0];
	my $measure=$_[1];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	if ( ! defined( $measure ) ){
		$self->{error}=1;
		$self->{errorString}='No symbol specified';
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{keys}});
	my $int=0;
	while( defined( $keys[$int] ) ){
		if (
			( $self->{measures}{ $keys[$int] } ne 'ERROR' ) &&
			( $self->{measures}{ $keys[$int] } eq $measure )
			){
			return 1;
		}

		$int++;
	}

	return 0;
}

=head1 ERROR CODES

This module is a Error::Helper ojbect so errors can be checked for
in the usual fashion.

=head2 1

No measure specified.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-simeasures at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SImeasures>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::SImeasures


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-SImeasures>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-SImeasures>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-SImeasures>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-SImeasures/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::SImeasures
