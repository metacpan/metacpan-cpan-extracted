
package Biblio::SICI::ItemSegment;
{
  $Biblio::SICI::ItemSegment::VERSION = '0.04';
}

# ABSTRACT: The item segment of a SICI

use strict;
use warnings;
use 5.010001;

use Moo;
use Sub::Quote;

use Business::ISSN;

use Biblio::SICI;
with 'Biblio::SICI::Role::ValidSegment', 'Biblio::SICI::Role::RecursiveLink';


has 'issn' => ( is => 'rw', trigger => 1, predicate => 1, clearer => 1, );

sub _trigger_issn {
	my ( $self, $newVal ) = @_;
	my @problems = ();

	if ( $newVal !~ m!\A[0-9X-]+\Z! ) {
		push @problems, 'contains invalid characters';
	}

	if ( $newVal !~ m!\A[0-9]{4}\-[0-9]{3}[0-9X]\Z! ) {
		push @problems, 'structural error';
	}

	unless (@problems) {
		if ( my $is = Business::ISSN->new($newVal) ) {
			unless ( $is->is_valid ) {
				push @problems, 'invalid issn';
			}
		}
	}

	if (@problems) {
		$self->log_problem_on( 'issn' => [@problems] );
	}
	else {
		$self->clear_problem_on('issn');
	}

	return;
} ## end sub _trigger_issn


has 'chronology' => ( is => 'rw', trigger => 1, predicate => 1, clearer => 1, );

sub _trigger_chronology {
	my ( $self, $newVal ) = @_;

	# TODO calendar schemes other than Gregorian may be used?!

	my @problems = ();

	# 1 YYYY
	# 2 YYYY/YYYY with second YYYY > first YYYY
	# 3 YYYYMM
	# 4 YYYYMM/MM with second MM > first MM
	# 5 YYYYMM/YYYYMM with second YYYY > first YYYY
	# 6 YYYYMMDD
	# 7 YYYYMMDD/DD with second DD > first DD
	# 8 YYYYMMDD/MMDD with second MM > first MM
	# 9 YYYYMMDD/YYYYMMDD with second YYYY > first YYYY

	my (%e) = ();

	if ( $newVal =~ /\A[0-9]{4}\Z/ ) {
		$e{'1Y'} = $newVal;
	}
	elsif ( $newVal =~ /\A([0-9]{4})\/([0-9]{4})\Z/ ) {
		$e{'1Y'} = $1;
		$e{'2Y'} = $2;

		unless ( $e{'2Y'} > $e{'1Y'} ) {
			push @problems, 'if specified, second year must be larger than first year';
		}
	}
	elsif ( $newVal =~ /\A([0-9]{4})([0-9]{2})\Z/ ) {
		$e{'1Y'} = $1;
		$e{'1M'} = $2;
	}
	elsif ( $newVal =~ /\A([0-9]{4})([0-9]{2})\/([0-9]{2})\Z/ ) {
		$e{'1Y'} = $1;
		$e{'1M'} = $2;
		$e{'2M'} = $3;

		unless ( $e{'2M'} > $e{'1M'} ) {
			push @problems, 'if specified, second month must be larger than first month';
		}
	}
	elsif ( $newVal =~ /\A([0-9]{4})([0-9]{2})\/([0-9]{4})([0-9]{2})\Z/ ) {
		$e{'1Y'} = $1;
		$e{'1M'} = $2;
		$e{'2Y'} = $3;
		$e{'2M'} = $4;

		unless ( $e{'2Y'} > $e{'1Y'} ) {
			push @problems, 'if specified, second year must be larger than first year';
		}
	}
	elsif ( $newVal =~ /\A([0-9]{4})([0-9]{2})([0-9]{2})\Z/ ) {
		$e{'1Y'} = $1;
		$e{'1M'} = $2;
		$e{'1D'} = $3;
	}
	elsif ( $newVal =~ /\A([0-9]{4})([0-9]{2})([0-9]{2})\/([0-9]{2})\Z/ ) {
		$e{'1Y'} = $1;
		$e{'1M'} = $2;
		$e{'1D'} = $3;
		$e{'2D'} = $4;

		unless ( $e{'2D'} > $e{'1D'} ) {
			push @problems, 'if specified, second day must be larger than first day';
		}
	}
	elsif ( $newVal =~ /\A([0-9]{4})([0-9]{2})([0-9]{2})\/([0-9]{2})([0-9]{2})\Z/ ) {
		$e{'1Y'} = $1;
		$e{'1M'} = $2;
		$e{'1D'} = $3;
		$e{'2M'} = $4;
		$e{'2D'} = $5;

		unless ( $e{'2M'} > $e{'1M'} ) {
			push @problems, 'if specified, second month must be larger than first month';
		}
	}
	elsif ( $newVal =~ /\A([0-9]{4})([0-9]{2})([0-9]{2})\/([0-9]{4})([0-9]{2})([0-9]{2})\Z/ ) {
		$e{'1Y'} = $1;
		$e{'1M'} = $2;
		$e{'1D'} = $3;
		$e{'2Y'} = $4;
		$e{'2M'} = $5;
		$e{'2D'} = $6;

		unless ( $e{'2Y'} > $e{'1Y'} ) {
			push @problems, 'if specified, second year must be larger than first year';
		}
	}
	else {
		$self->log_problem_on( 'chronology', ['illegal chronology structure'] );
		return;
	}

	# lets accept pub dates up to one year in the future
	# (relative to the date when this code is executed!)
	my (@time) = localtime(time);
	my $yr = $time[5] + 1900;
	my ( undef, undef, $decade, $year ) = split( '', $yr );
	if ( $year == 9 ) {
		$year = 0;
		$decade += 1;
	}
	else {
		$year += 1;
	}
	my $prevDecade = $decade - 1;

	for (qw( 2D 1D )) {
		if ( exists $e{$_} and $e{$_} !~ /\A(?:[012][0-9]|3[01])\Z/ ) {
			push @problems,
				  'illegal value for '
				. ( $_ eq '2D' ? 'second' : 'first' )
				. ' day: should be 01-31';
		}
	}
	for (qw( 2M 1M )) {
		if ( exists $e{$_} and $e{$_} !~ /\A(?:0[0-9]|1[012]|[23][1-4])\Z/ ) {
			push @problems,
				  'illegal value for '
				. ( $_ eq '2M' ? 'second' : 'first' )
				. ' month: should be 00-12, or 21-24, or 31-34';
		}
	}
	for (qw( 2Y 1Y )) {
		if ( exists $e{$_}
			and $e{$_} !~ /\A(?:1[0-9][0-9]{2}|20[0-$prevDecade][0-9]|20$decade[0-$year])\Z/o )
		{
			push @problems, 'illegal value for ' . ( $_ eq '2Y' ? 'second' : 'first' ) . ' year';
		}
	}

	if ( !@problems ) {
		$self->clear_problem_on('chronology');
	}
	else {
		$self->log_problem_on( 'chronology', \@problems );
	}

	return;
} ## end sub _trigger_chronology


has 'enumeration' => ( is => 'rw', predicate => 1, clearer => 1, trigger => 1, );

sub _trigger_enumeration {
	my ( $self, $newVal ) = @_;

	# clear partial values
	$self->clear_volume();
	$self->clear_problem_on('volume');
	$self->clear_issue();
	$self->clear_problem_on('issue');
	$self->clear_supplOrIdx();
	$self->clear_problem_on('supplOrIdx');

	if ( $newVal !~ /\A[0-9A-Z:]*[+*]?\Z/ ) {
		$self->log_problem_on( 'enumeration' => ['invalid characters used'] );
	}
	return;
}


has 'volume' => ( is => 'rw', predicate => 1, clearer => 1, trigger => 1, );

sub _trigger_volume {
	my ( $self, $newVal ) = @_;

	# clear aggregate value
	$self->clear_enumeration();
	$self->clear_problem_on('enumeration');

	my @problems = ();

	if ( $newVal !~ m!\A[A-Z0-9/]+\Z! ) {
		push @problems, 'contains invalid characters';
	}

	if ( $newVal !~ m!\A[A-Z0-9]+(?:/[A-Z0-9]+)?\Z! ) {
		push @problems, 'structural error';
	}

	if (@problems) {
		$self->log_problem_on( 'volume' => [@problems] );
	}
	else {
		$self->clear_problem_on('volume');
	}

	return;
} ## end sub _trigger_volume


has 'issue' => ( is => 'rw', predicate => 1, clearer => 1, trigger => 1, );

sub _trigger_issue {
	my ( $self, $newVal ) = @_;

	# clear aggregate value
	$self->clear_enumeration();
	$self->clear_problem_on('enumeration');

	my @problems = ();

	if ( $newVal !~ m!\A[A-Z0-9/]+\Z! ) {
		push @problems, 'contains invalid characters';
	}

	if ( $newVal !~ m!\A[A-Z0-9]+(?:/[A-Z0-9]+)?\Z! ) {
		push @problems, 'structural error';
	}

	if (@problems) {
		$self->log_problem_on( 'issue' => [@problems] );
	}
	else {
		$self->clear_problem_on('issue');
	}

	return;
} ## end sub _trigger_issue


has 'supplOrIdx' => ( is => 'rw', predicate => 1, clearer => 1, trigger => 1, );

sub _trigger_supplOrIdx {
	my ( $self, $newVal ) = @_;

	# clear aggregate value
	$self->clear_enumeration();
	$self->clear_problem_on('enumeration');

	my @problems = ();

	if ( length $newVal != 1 ) {
		push @problems, 'too many characters (allowed: 1)';
	}

	if ( $newVal ne '+' and $newVal ne '*' ) {
		push @problems, 'contains invalid characters';
	}

	if (@problems) {
		$self->log_problem_on( 'supplOrIdx' => [@problems] );
	}
	else {
		$self->clear_problem_on('supplOrIdx');
	}

	return;
} ## end sub _trigger_supplOrIdx


sub year {
	my $self = shift;

	return unless $self->has_chronology();

	my $c = $self->chronology;

	# 1 YYYY
	# 2 YYYY/YYYY with second YYYY > first YYYY
	# 3 YYYYMM
	# 4 YYYYMM/MM with second MM > first MM
	# 5 YYYYMM/YYYYMM with second YYYY > first YYYY
	# 6 YYYYMMDD
	# 7 YYYYMMDD/DD with second DD > first DD
	# 8 YYYYMMDD/MMDD with second MM > first MM
	# 9 YYYYMMDD/YYYYMMDD with second YYYY > first YYYY

	if ( $c =~ /\A[0-9]{4}\Z/ ) {
		return "$c";
	}
	elsif ( $c =~ /\A([0-9]{4})\/([0-9]{4})\Z/ ) {
		return ( "$1", "$2" );
	}
	elsif ( $c =~ /\A([0-9]{4})(?:[0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A([0-9]{4})(?:[0-9]{2})\/(?:[0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A([0-9]{4})(?:[0-9]{2})\/([0-9]{4})(?:[0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}
	elsif ( $c =~ /\A([0-9]{4})(?:[0-9]{2})(?:[0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A([0-9]{4})(?:[0-9]{2})(?:[0-9]{2})\/(?:[0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A([0-9]{4})(?:[0-9]{2})(?:[0-9]{2})\/(?:[0-9]{2})(?:[0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A([0-9]{4})(?:[0-9]{2})(?:[0-9]{2})\/([0-9]{4})(?:[0-9]{2})(?:[0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}

	return;
} ## end sub year


sub month {
	my $self = shift;

	return unless $self->has_chronology();

	my $c = $self->chronology;

	# 3 YYYYMM
	# 4 YYYYMM/MM with second MM > first MM
	# 5 YYYYMM/YYYYMM with second YYYY > first YYYY
	# 6 YYYYMMDD
	# 7 YYYYMMDD/DD with second DD > first DD
	# 8 YYYYMMDD/MMDD with second MM > first MM
	# 9 YYYYMMDD/YYYYMMDD with second YYYY > first YYYY

	if ( $c =~ /\A(?:[0-9]{4})([0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A(?:[0-9]{4})([0-9]{2})\/([0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}
	elsif ( $c =~ /\A(?:[0-9]{4})([0-9]{2})\/(?:[0-9]{4})([0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}
	elsif ( $c =~ /\A(?:[0-9]{4})([0-9]{2})(?:[0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A(?:[0-9]{4})([0-9]{2})(?:[0-9]{2})\/(?:[0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A(?:[0-9]{4})([0-9]{2})(?:[0-9]{2})\/([0-9]{2})(?:[0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}
	elsif ( $c =~ /\A(?:[0-9]{4})([0-9]{2})(?:[0-9]{2})\/(?:[0-9]{4})([0-9]{2})(?:[0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}

	return;
} ## end sub month


sub day {
	my $self = shift;

	return unless $self->has_chronology();

	my $c = $self->chronology;

	# 6 YYYYMMDD
	# 7 YYYYMMDD/DD with second DD > first DD
	# 8 YYYYMMDD/MMDD with second MM > first MM
	# 9 YYYYMMDD/YYYYMMDD with second YYYY > first YYYY

	if ( $c =~ /\A(?:[0-9]{4})(?:[0-9]{2})([0-9]{2})\Z/ ) {
		return "$1";
	}
	elsif ( $c =~ /\A(?:[0-9]{4})(?:[0-9]{2})([0-9]{2})\/([0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}
	elsif ( $c =~ /\A(?:[0-9]{4})(?:[0-9]{2})([0-9]{2})\/(?:[0-9]{2})([0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}
	elsif ( $c =~ /\A(?:[0-9]{4})(?:[0-9]{2})([0-9]{2})\/(?:[0-9]{4})(?:[0-9]{2})([0-9]{2})\Z/ ) {
		return ( "$1", "$2" );
	}

	return;
} ## end sub day


sub to_string {
	my $self = shift;

	my $str = '';

	if ( $self->has_issn() ) {
		$str = $self->issn();
	}

	if ( $self->has_chronology() ) {
		$str .= '(' . $self->chronology() . ')';
	}
	else {
		$str .= '()';
	}

	if ( $self->has_enumeration() ) {
		$str .= $self->enumeration();
	}
	else {
		if ( $self->has_volume() ) {
			$str .= $self->volume();
			if ( $self->has_issue() ) {
				$str .= ':' . $self->issue();
			}
		}
		if ( $self->has_supplOrIdx() ) {
			$str .= $self->supplOrIdx();
		}
	}

	return $str;
} ## end sub to_string


sub reset {
	my $self = shift;
	$self->clear_issn();
	$self->clear_problem_on('issn');
	$self->clear_chronology();
	$self->clear_problem_on('chronology');
	$self->clear_enumeration();
	$self->clear_problem_on('enumeration');
	$self->clear_volume();
	$self->clear_problem_on('volumne');
	$self->clear_issue();
	$self->clear_problem_on('issue');
	$self->clear_supplOrIdx();
	$self->clear_problem_on('supplOrIdx');
	return;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Biblio::SICI::ItemSegment - The item segment of a SICI

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  my $sici = Biblio::SICI->new();

  $sici->item->issn('2232-7651');

=head1 DESCRIPTION

I<Please note:> You are expected to not directly instantiate objects of this class!

The item segment of a SICI describes various aspects of the serial item referenced
by the SICI.
Unlike the contribution segment, which may be empty, the item segment is required!

=head1 ATTRIBUTES

For each attribute, clearer ("clear_") and predicate ("has_") methods
are provided.

=over 4

=item C<issn>

The ISSN of the serial.

=item C<chronology>

Identifies a specific date - usually the cover date - for an item
of a serial title.
Follows the format "YYYYMMDD" with only the applicable levels being
used.
For "MM", in addition to 01 to 12, the values 21 to 24 represent 
seasons (Spring, Summer, Fall, Winter) and the values 31 to 34 
represent the four quarters of a year.

=item C<enumeration>

Describes, which item of the serial is referenced.
The most common way of identifying an item is using a
combination of volume and issue numbers, which is why 
there are separate attributes for these kinds of data.

Please not that setting a value for C<enumeration> means
that any value present in the attributes C<volume>, 
C<issue> or C<supplOrIdx> gets removed!

=item C<volume>

The volume designation of the serial item.

Please note that setting a value for this attribute automatically 
clears the C<enumeration> attribute.

=item C<issue>

The issue designation of the serial item.

Please note that setting a value for this attribute automatically 
clears the C<enumeration> attribute.

=item C<supplOrIdx>

A one character code to describe if the SICI refers to either a 
supplement of the described item (represented as '+') or to an
index (represented as '*') which is published independently 
from a regular item.

(If you whish to refer to an index within an item please have
a look at the C<dpi> attribute of the control segment!) 

Please note that setting a value for this attribute automatically 
clears the C<enumeration> attribute.

=back

=head1 METHODS

=over 4

=item LIST C<year>()

Extracts the year info from the C<chronology> attribute.
Returns C<undef> if no chronology has been set.
May return either one or two values, depending on the given 
chronology. 
E.g.:

=over 4 

=item

if the chronology value is B<199624/199721> (an item
published Winter 1996 / Spring 1997) this method will return
C<(1996, 1997)>

=item

if the chronology value is B<20021201> (item published on
Dec. 1st, 2002) this method will return C<(2002)>

=back

=item LIST C<month>()

Extracts the month(s) from the chronology.
Returns C<undef> if no chronology has been set or no month info
is available from the chronology.
May return either one or two values, depending on the given 
chronology. Each value may be in the ranges 01 to 12, or 21 to 24, 
or 31 to 34; with 21 to 24 being the codes for the seasons Spring,
Summer, Fall, and Winter and 31 to 34 being the codes for the four
quarters of a year  (cf. the info on the C<chronology> attribute). 
E.g.:

=over 4 

=item

if the chronology value is B<199911/12> (an item
published November / December 1999) this method will return
C<(11, 12)>

=item

if the chronology value is B<20021201> (item published on
Dec. 1st, 2002) this method will return C<(12)>

=item

if the chronology value is B<200721/22> (an item 
published Spring / Summer 2007) this method will return 
C<(21, 22)>

=back

=item LIST C<day>()

Extracts the days(s) from the chronology.
Returns C<undef> if no chronology has been set or no day info
is available from the chronology.
May return either one or two values, depending on the given 
chronology. 
E.g.:

=over 4 

=item

if the chronology value is B<19991101/02> (an item
published November 1st / November 2nd 1999) this method will return
C<(01, 02)> (note the leading zeroes!); day spans are quite unlikely, 
but not prohibited

=item

if the chronology value is B<20021201> (item published on
Dec. 1st, 2002) this method will return C<(01)>

=back

=item STRING C<to_string>()

Returns a stringified representation of the data in the
item segment.

=item C<reset>()

Resets all attributes to their default values.

=item BOOL C<is_valid>()

Checks if the data for the control segment conforms
to the standard.

=back

=head1 SEE ALSO

L<Biblio::SICI::Role::ValidSegment>

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
