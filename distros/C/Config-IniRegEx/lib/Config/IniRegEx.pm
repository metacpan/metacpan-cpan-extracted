package Config::IniRegEx;

use warnings;
use strict;

use Config::IniFiles;
our $VERSION = '0.01';

=head1 NAME

Config::IniRegEx - Ini workaround, regex search for parameters and sections.

=head1 SYNOPSIS

use Config::IniRegEx;

my $foo = Config::IniRegEx->New();

$foo->ValRegex('section_name', 'parameter_regex');

$foo->SectionExistsRegex('section_regex');

$foo->SectionRegex('section_regex');

$foo->ParameterRegex('section_regex');


=cut

########## functions intended for internal use should start with _ .


sub New {
	my	( $class )	= shift;

	# returns undef. When
	# 	1. Ini config does not exists
	# 	2. Ini config is not in form to process such as Wrong Format. ( depends on Config::IniFiles )
	my $nocase = $_[1];
	$nocase = 0 if ( not defined $_[1] );
	my $DataRef = _ParseAndPopulate($_[0],$nocase);
	return undef if ( not defined $DataRef );

	# Have the filename, options and data tied with the reference, so that it can be 
	# blessed for this class, and these can be accessed from the object of this class.
	my $objref = {
					'filename' => $_[0],
					'nocase'   => $nocase,
					'data'	   => $DataRef,
				};
	bless $objref,$class;
	return $objref;
}	# ----------  end of subroutine New  ----------


sub _ParseAndPopulate
{
	# Get filename from argument of this functions 
	my ($filename, $icase)  = @_;
	# To store the data available in a ini file.
 	my %ini;

	# Tie that filename into ini hash, it will store in a hash of hash form.
  	tie %ini, 'Config::IniFiles', ( -file => "$filename", -nocase => $icase );

	# If the filename given is not available
	if ( ! %ini ) {
		return undef;
	}
	# Returning the reference of a hash.
	return \%ini;
}

# Return undef, if there is no section with the given name.
# expected: Section should be text and parameter could be regex.
sub ValRegex
{
	my ( $Pack, $Section, $Parameter ) = @_;
	my  $countofmatch  = 0;
	my  %outhash ;
	undef %outhash;

	# Check whether the section exist first.
	if ( tied( %{$Pack->{'data'}})->SectionExists($Section) ) {
		# take the parameters available in that section.
		foreach ( keys %{$Pack->{'data'}->{$Section}} ) {
			# Check if the parameters are matching. 
			if ( $_ =~ /^$Parameter$/ ) {
				# If it matches, Store this into the output hash.
				$outhash{$_} = $Pack->{'data'}->{$Section}->{$_};
				# Have a matched count
				$countofmatch++;
			}
		}
	}

	# return's undef when
	# 	1. Section does not exist
	# 	2. Section exists, but no match for parameter.
	# else return's the matched set of parameter and its value as a hash.
	return %outhash;
}


#4. SectionRegex()
#
#4.1 returns the section names which matches to the supplied regex.
#4.2 If there is no argument, then call the default Sections function, and do the default action.
#4.3 nocase should be considered.

sub SectionRegex
{
	my ( $Pack, $Section ) = @_;
	my  $countofmatch =  0;
	my  @opsec;
	undef @opsec;

	if ( !$Section ) {
		#Section argument is not available
		return @opsec;
	}

	foreach ( tied( %{$Pack->{'data'}})->Sections() ) {
		if ( $_ =~ /^$Section$/ ) {
			push @opsec, $_;
			$countofmatch++;
		}
	}

	# return's undef when
	# 	1. section argument is not given
	# 	2. section does not matches.
	# else return's an array of matched sections	
	return @opsec;
}



#5. SectionExists ( regex )
#
#5.1 returns number of matches.
#        ZERO for no match.
sub SectionExistsRegex
{
	my ( $Pack, $Section ) = @_;
	my ( $countofmatch ) = ( 0 );

	if ( !$Section ) {
		#Section arguement is not available 
		return 0;
	}

	foreach ( tied( %{$Pack->{'data'}})->Sections() ) {
		if ( $_ =~ /^$Section$/ ) {
			$countofmatch++;
		}
	}

	# return's 0 when
	# 	1. When the section argument is not passed
	# 	2. when the section does not match
	# else return's number of match
	return $countofmatch;
}


#6. Parameters ( regex )
#
#6.1 argument is section regex,
#6.2 returns hash of hash, where the hash key is section name, and the nested hash key is parameter name.

sub ParameterRegex
{
	my ( $Pack , $Section) = @_;
	my %ophash;
	undef %ophash;

	if ( !$Section ) {
		#Section arguement is not available
		return %ophash;
	}

	# Get all the sections 
	foreach ( tied( %{$Pack->{'data'}})->Sections() ) {
		# Check for a match 
		if ( $_ =~ /^$Section$/ ) {
			$ophash{$_} = $Pack->{'data'}->{$_};
		}
	}

	# returns undef. When
	# 	1. section argument is not given
	# 	2. when the section does not match
	# else returns hash of hash, where the hash key is section name, and the nested hash key is parameter name.
	return %ophash;
}

sub post
{
	my ($pack) = shift;
	my $ref = {'a' => 'b'};
	$pack->{'hash'} = $ref;

	return;
}

sub AUTOLOAD 
{

	my ( $Pack ) = shift;
	my $program = our $AUTOLOAD ;
	$program =~ s/.*:://;
	######## what to do ????????????
	print	tied( %{$Pack->{'data'}})->$program;
}


=cut

=head1 DESCRIPTION

Config::IniRegEx is dependent on Config::IniFiles. Using that module it does the ini configuration
file parsing, with an addon facility of regex kind of search.

Each function explained below, searches for a different thing based up on the given regular expression.
And it is a exact regex match.

When a function of a Config::IniFiles is called then it will be called using the autoload functionality, 
i.e all the functions of the Config::IniFiles can be called with this object itself. ( creating an
object for Config::IniRegEx is enough, can access all the functions available at Config::IniFiles also. ).

This module aims out doing a regex search for Sections, and Parameters of the Ini configuration file.
It does the Perl regex matching, nothing external. So whoever knows the Perl basic regex can use this
feature.

=head1 FUNCTIONS

The following functions are available.

=head2 New
	
	New (filename,nocase)
	
	Returns a new configuration object (or "undef" if the configuration file has an error)
	my $object = Config::IniRegEx->New('config_filename', [nocase] );

	Arguments
		First argument is absolute path of the ini configuration file which you want 
		to manipulate.
		Second argument could be 0 or 1.
			0 to handle the config file in a case-sensitive manner
			1 to handle the config file in a case-insensitive manner
			By default, config files are case-sensitive.

	For Example
	
	my $object = Config::IniRegEx->New("sample.ini");

=head2 ValRegex
	
	%val_hash = $foo->ValRegex('section_name','parameter_regex');

	section_name - should be text, ( not a regular expression )
	parameter_regex - can be Perl regex

	return's undef when
	 	1. Section does not exist
	 	2. Section exists, but no match for parameter.
	else return's the matched set of parameter and its value as a hash.

	For Example

	%val_hash = $foo->ValRegex('sizes','size_._side');

	%val_hash will contain
		size_a_side => 100
		size_b_side => 55

=head2 SectionRegex

	@box_sections = $foo->SectionRegex('section_name_regex');


	section_name_regex - regex to match section name

	return's undef when
	 	1. section argument is not given
	 	2. section does not matches.
	else return's an array of matched section names.

	For Example

	@box_sections = $foo->SectionRegex("box_.*");

	@size_of_all_sides will contain
		( 'box_day_first', 'box_day_second','box_day_third' )


=head2 SectionExistsRegex


	$section_available = $foo->SectionExistsRegex('section_name_regex');

	section_name_regex - regex to match section name

	return's 0 when
		1. When the section argument is not passed
		2. when the section does not match
	else return's number of match

	For Example

	$section_available = $foo->SectionExistsRegex('box_.*');

	$section_available will contain
		3


=head2 ParameterRegex

	%matched_hash = $foo->ParameterRegex('section_name_regex');

	section_name_regex - regex to match section name

	returns undef. When
		1. section argument is not given
		2. when the section does not match
	else returns hash of hash, where the hash key is section name, and the nested hash key is parameter name.

	For Example

	%matched_hash = $foo->ParameterRegex("box_day_.*");

	%matched_hash will contain
	( 'box_day_first' => {
		'expected_from' => Tue,
		'expected_to' => Thu
		},

	  'box_day_second' => {
		'expected_from' => Mon,
		'expected_to' => Fri
		},

	  'box_day_third' => {
		'expected_from' => Mon,
		'expected_to' => Sat
		},
	)	



=head1 AUTHOR

Sasi, C<< <sasi.asterisk at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Sasi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Config::IniRegEx
