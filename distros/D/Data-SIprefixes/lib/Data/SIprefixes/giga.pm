package Data::SIprefixes::giga;

use strict;
use warnings;
use bignum;
use base 'Error::Helper';

=head1 NAME

Data::SIprefixes::giga - This provides giga matching for Data::SIprefixes.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

    use Data::SIprefixes::giga;
    
    my $prefix=Data::SIprefixes::giga->new;

    my $origMeasure='megameter';
     
    my $measure=$prefix->longMatch( $origMeasure );
    my $long;
    if ( $prefix->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }elseif( ! defined( $measure ) ){
    
        $measure=$prefix->shortMatch( $origMeasure );
    
    }else{
        $long=1;
    }

=head1 METHODS

=head2 new

This initiates the object.

    my $prefix=$Data::SIprefixes::giga->new;

=cut

sub new {
	my $string=$_[1];

	my $self={
		perror=>undef,
		error=>undef,
		errorString=>'',
		fromBase=>1000,
		toBase=>1000,
	};
	bless $self;
	
	$self->{fromBase} **= -3;
	$self->{toBase} **= 3;

	return $self;
}

=head2 fromBase

Returns the number needed to to multiple it by to get from the unprefixed
measure to the prefixed measure.

    my $fromBase=$prefix->fromBase;

=cut

sub fromBase{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	return $self->fromBase;
}

=head2 longMatch

Matches long SI prefixed measures.

A match returns the measure with out the SI prefix, which will be ''
if no measure is specified.

    my $measure=$prefix->longMatch( $origMeasure );
    if ( $prefix->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub longMatch{
	my $self=$_[0];
	my $measure=$_[1];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	if ( ! defined( $measure ) ){
		$self->{error}=1;
		$self->{errorString}='No measure defined';
		$self->warn;
		return undef;
	}

	if ( $measure=~/^giga/ ){
		my $origMeasure=$measure;
		$measure=~s/^giga//g;

		if ( $measure =~ /^ / ){
			$self->{error}=2;
			$self->{errorString}='Space found after prefix, /^giga/, in "'.$origMeasure.'"' ;
			$self->warn;
			return undef;
		}

		return $measure;
	}

	return undef;
}

=head2 shortMatch

Matches short SI prefixed measures.

A match returns the measure with out the SI prefix, which will be ''
if no measure is specified.

    my $measure=$prefix->longMatch( $origMeasure );
    if ( $prefix->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub shortMatch{
    my $self=$_[0];
    my $measure=$_[1];

    if ( ! $self->errorblank ){
        $self->warnString('Failed to blank the previous error');
    }

    if ( ! defined( $measure ) ){
        $self->{error}=1;
        $self->{errorString}='No measure defined';
        $self->warn;
        return undef;
    }

	#avoid possible collisions
	if ( $measure eq 'Gy' ){
		return $measure
	}

    if ( $measure=~/^G/ ){
        my $origMeasure=$measure;
        $measure=~s/^G//;

        if ( $measure =~ /^ / ){
            $self->{error}=2;
            $self->{errorString}='Space found after prefix, /^G/, in "'.$origMeasure.'"' ;
            $self->warn;
            return undef;
        }

        return $measure;
    }

    return undef;
}

=head2 symbol

This returns the symbol for the prefix.

    my $symbol=$prefix->symbol;

=cut

sub symbol{
	return 'G';
}

=head2 toBase

Returns the number needed to to multiple it by to get from the prefixed measure
number to the unprefixed measure.

    my $toBase=$prefix->toBase;

=cut

sub toBase{
    my $self=$_[0];

    if ( ! $self->errorblank ){
        $self->warnString('Failed to blank the previous error');
    }

    return $self->toBase;
}

=head1 ERROR CODES

=head2 1

Nothing passed for a measure.

=head2 2

Space found after prefix.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-siprefixes at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SIprefixes>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::SIprefixes::giga


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-SIprefixes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-SIprefixes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-SIprefixes>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-SIprefixes/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::SIprefixes::giga
