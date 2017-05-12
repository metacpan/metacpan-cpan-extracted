package Data::SIprefixes;

use strict;
use warnings;
use bignum;
use base 'Error::Helper';
use Module::List qw(list_modules);
use Data::SImeasures;

=head1 NAME

Data::SIprefixes - This helps with working with numbers with SI prefixed measures.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Data::SIprefixes;
    
    my $sim=Data::SIprefixes->new('3 grams');

    print 'Number: '.$sip->numberGet.
        "\nprefix: ".$sip->prefixGet.
        "\nmeasure: ".$sip->measureGet.
        "\nsymbol: ".$sip->symbolGet.
        "\nuse symbol: ".$sip->symbolUse.
        "\nstring: ".$sip->string."\n";

While new can properly parse some prefix/measure combos,
the ones below are set statically as they can cause confusion.

    amp
    ampere
    coulomb
    farad
    Gy
    henry
    kat
    katal
    kelvin
    m
    metre
    meter
    mol
    mole
    newton
    Pa
    pascal
    T

Because of this, while it is possible of matching other symbols
with out a measure, the ones listed below can't be.

    m
    T

=head1 METHODS

=head2 new

This initiates the object.

One argument is required and that is
the string.

    my $sip->new('3 kilometer');
    if ( $sip->error ){
        warn('error:'.$sip->error.': '.$sip->errorString);
    }

=cut

sub new{
	my $string=$_[1];

	my $self={
		perror=>undef,
		error=>undef,
		errorString=>'',
		long=>undef,
		measure=>'',
		number=>undef,
		original=>$string,
		prefixes=>{},
		prefix=>'',
	};
	bless $self;

	#loads all the prefixes, this is done dynamically for future expandability
	my @prefixes=keys(list_modules('Data::SIprefixes::', { list_modules => 1 } ));
	my $int=0;
	while ( defined( $prefixes[$int] ) ){
		my $prefix;
		my $toeval='use '.$prefixes[$int].'; $prefix='.$prefixes[$int].'->new;';
		eval( $toeval );

		if ( ! defined( $prefix ) ) {
			$self->{perror}=1;
			$self->{error}=1;
			$self->{errorString}='Failed to one of the prefix modules, "'.
				$prefixes[$int].'". It was returned as undefined';
			$self->warn;			
			return $self;
		}

		if ( $prefix->error ){
			$self->{perror}=1;
			$self->{error}=1;
			$self->{errorString}=$prefixes[$int].'->new errored. error="'.$prefix->error.
				'" errorString="'.$prefix->errorString.'"';
			$self->warn;
			return $self;
		}

		$prefixes[$int]=~s/^Data\:\:SIprefixes\:\://;

		$self->{prefixes}{$prefixes[$int]}=$prefix;
		
		$int++;
	}
	

	#remove any beginning or trailling white space
	$string=~s/^[ \t]*//g;
	$string=~s/[ \t]*$//g;

	#make sure it begins with a number
	if (
		( $string !~ /^[0123456789]+/ ) &&
		( $string !~ /^[012345789]*\.[0123456789]+/ ) &&
		( $string !~ /^\.[0123456789]+/ )
		){
		$self->{perror}=1;
		$self->{error}=2;
		$self->{errorString}='"'.$string.'" does not appear to start with a number';
		$self->warn;
		
		return $self;
	}

	#no prefix or unit so we can return after setting it
	if (
		( $string =~ /^[0123456789]+$/ ) ||
		( $string =~ /^[012345789]*\.[0123456789]+$/ ) ||
		( $string =~ /^\.[0123456789]+$/ )
		){
		$self->{number}=$string;
		$self->{prefix}='';
		
		return $self;
	}
	
	#gets the prefix and unit
	my $notnumeric=$string;
	$notnumeric=~s/^[0123456789.]+//;
	my $notnumericRemove=quotemeta( $notnumeric );
	$self->{number}=$string;
	$self->{number}=~s/^$notnumericRemove//;
	$notnumeric=~s/^[ \t]+//;

	#matches the long version first
	@prefixes=keys( @{ $self->{prefixes} } );
	$int=0;
	my $notMatched=1;
	while( 
		defined( $prefixes[$int] ) &&
		$notMatched
		){
		my $measure=$self->{prefixes}{ $prefixes[$int] }->longMatch( $notnumeric );
		if( defined( $measure ) ){
			my $self->{prefix}=$prefixes[$int];
			$self->{long}=1;
			$self->{measure}=$measure;
			$notMatched=0;
		}
		
		$int++;
	};

	#matches the short version first
	$int=0;
	while( 
		defined( $prefixes[$int] ) &&
		$notMatched
		){
		my $measure=$self->{prefixes}{ $prefixes[$int] }->shortMatch( $notnumeric );
		if( defined( $measure ) ){
			my $self->{prefix}=$prefixes[$int];
			$self->{measure}=$measure;
			$self->{long}=0;
			$notMatched=0;
		}
		
		$int++;
	};
	
	
	return $self;
}

=head2 measureGet

This returns the measure part.

This won't error as long as new did not.

If no measure was found, '' is returned.

    my $measure=$sip->measureSet('gram');

=cut

sub measureGet{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	return $self->{measure};
}

=head2 measureSet

This returns the measure part.

This sets the measure. This will accept ''
as a valid measure.

    $sip->measureSet( $measure );
    if ( $sip->error ){
        warn('error:'.$sip->error.': '.$sip->errorString);
    }

=cut

sub measureSet{
	my $self=$_[0];
	my $measure=$_[1];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	if ( ! defined( $measure ) ){
		$self->{error}=5;
		$self->{errorString}='No measure specified';
		$self->warn;
		return undef;
	}

	$self->{measure}=$measure;

	return 1;
}

=head2 numberGet

This returns the numeric part.

This won't error as long as new did not.

    my $error=$sip->numberGet;

=cut

sub numberGet{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	return $self->{number};
}

=head2 numberSet

This sets the numeric part.

This won't error as long as what you provide
a number.

    my $error=$sip->numberGet('4');

=cut

sub numberSet{
	my $self=$_[0];
	my $number=$_[1];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	if ( ! defined( $number ) ){
		$self->{error}=3;
		$self->{errorString}='No number specified';
		$self->warn;
		return undef;
	}

	#make sure it is a number
	if (
		( $number !~ /^[0123456789]+/ ) &&
		( $number !~ /^[012345789]*\.[0123456789]+/ ) &&
		( $number !~ /^\.[0123456789]+/ )
		){
		$self->{error}=2;
		$self->{errorString}='"'.$number.'" does not appear to be a number';
		$self->warn;
		
		return $self;
	}

	$self->{number}=$number;

	return '1';
}

=head2 prefixGet

This returns the current metric prefix.

As long as it new worked with out error,
then this will not error.

A return of '', means there is no current
prefix.

    my $prefix=$sip->prefixGet;

=cut

sub prefixGet{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	return $self->{prefix};
}

=head2 prefixSet

This sets the metric prefix and update
the number to reflect that change.

One argument is accepted and it is the new
prefix. A value of '' set it to no prefix.

If no prefix is specified, '' is used.

    $sip->prefixSet('kilo');

=cut

sub prefixSet{
	my $self=$_[0];
	my $prefix=$_[1];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	#default to base
	if ( ! defined( $prefix ) ){
		$prefix='';
	}

	#make sure it is a valid prefix
	if ( ! defined( $self->{prefixes}{$prefix} ) ){
		$self->{error}=4;
		$self->{errorString}='"'.$prefix.'" is not a recognized prefix';
		$self->warn;
		return undef;
	}

	#sets it back to the base for the current prefix
	my $toBase=$self->{prefixes}{ $self->{prefix} }->toBase;
	$self->{number} = $self->{number} * $toBase;

	#if we are going to base, exit here
	if ( $prefix eq '' ){
		$self->{prefix}=$prefix;
		return 1;
	}

	#go from the base for the new prefix
	my $fromBase=$self->{prefixes}{$prefix}->fromBase;
	$self->{number} = $self->{number} * $fromBase;

	$self->{prefix}=$prefix;

	return 1;
}

=head2 string

This returns a formatted string of the number, prefix/symbol, and measure.

This will not error as long as the module initialized with out error.

    my $string=$sip->string;

=cut

sub string{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	my $string=$self->{number}.' ';

	if ( $self->{long} ){
		$string=$string.$self->{prefix}.$self->{measure};
	}else{
		$string=$string.$self->symbolGet.$self->{measure};
	}

	return $string;
}

=head2 symbolGet

This returns the symbol for the prefix.

As long as it new worked with out error,
then this will not error.

A return of '', means there is no current
prefix and thus no symbol.

    my $symbol=$sip->getSymbol;

=cut

sub symbolGet{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	if ( $self->{prefix} eq '' ){
		return '';
	}

	return $self->{prefixes}{$self->{prefix}}->symbol;
}

=head2 symbolUse

Returns if the symbol should be used or not.

The returned value is boolean and this is based off
of how it is matched.

This will not error as long as the module has
initialized with out error.

    my $symbolUse=$sim->symbolUse;

=cut

sub symbolUse{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		$self->warnString('Failed to blank the previous error');
	}

	return $self->{long};
}

=head1 ERROR CODES

=head2 1

Failed to load one of the prefixes.

=head2 2

The string does not begin with a number.

=head2 3

No number specified.

=head2 4

No recognized prefix specified.

=head2 5

No measure specified.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-siprefixes at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SIprefixes>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::SIprefixes


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

1; # End of Data::SIprefixes
