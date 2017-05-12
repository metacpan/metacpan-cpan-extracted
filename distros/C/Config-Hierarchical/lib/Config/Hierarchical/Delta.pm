
package Config::Hierarchical::Delta ;
use base Exporter ;

use strict;
use warnings ;

BEGIN 
{
use Exporter ();

use vars qw ($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.01' ;
@EXPORT_OK   = qw (GetConfigDelta GetConfigHierarchicalDelta DumpConfigHierarchicalDelta Get_NoIdentical_Filter);
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

use Carp ;
use Data::Compare ;
use Data::TreeDumper ;
use Sub::Install ;

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

=head1 NAME

 Config::Hierarchical::Delta - Comparator for hashes and Config::Hierarchical objects

=head1 SYNOPSIS

	# comparing hashes:
	
	use Config::Hierarchical ; 
	use Config::Hierarchical::Delta qw (GetConfigDelta GetConfigHierarchicalDelta DumpConfigHierarchicalDelta Get_NoIdentical_Filter) ; 
	
	my $delta = GetConfigDelta
				(
				{name   => {A => 1, COMMON => 0}},
				{name_2 => {B => 2, COMMON => 0}}
				) ;

$delta is a reference to the following hash:

	{
	'in \'name\' only'   => {'A' => 1},
	'in \'name_2\' only' => {'B' => 2},
	'identical'          => {'COMMON' => 0},
	},

	# comparing Config Hierarchical objects:
	
	my $config_0 = new Config::Hierarchical
				(
				NAME => 'config 0',
				INITIAL_VALUES  =>
					[
					{NAME => 'CC1', VALUE => '1'},
					{NAME => 'CC2', VALUE => '2'},
					] ,
				) ;
				
	my $config_1 = new Config::Hierarchical
				(
				NAME => 'config 1',
				CATEGORY_NAMES   => ['A', 'B',],
				DEFAULT_CATEGORY => 'A',
				
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'B', ALIAS => $config_0},
					
					{NAME => 'CC1', VALUE => '1'},
					{NAME => 'CC2', VALUE => '2'},
					{NAME => 'CC3', VALUE => '3'},
					] ,
				) ;
				
	$config_1->Set(NAME => 'CC1', VALUE => '1.1') ;
	
	my $config_2 = new Config::Hierarchical
				(
				NAME => 'config 2',
				
				CATEGORY_NAMES   => ['<A>', 'B',],
				DEFAULT_CATEGORY => 'A',
				INITIAL_VALUES   =>
					[
					{CATEGORY => 'B', ALIAS => $config_1},
					] ,
				) ;
	
	$config_2->Set(CATEGORY => 'A', NAME => 'CC1', VALUE => 'A', OVERRIDE => 1) ;
	$config_2->Set(CATEGORY => 'A', NAME => 'XYZ', VALUE => 'xyz') ;
	
	my $dump = DumpConfigHierarchicalDelta($config_2, $config_0) ;

$dump contains the following string:

	Delta between 'config 2' and 'config 0'':
	|- different 
	|  `- CC1 
	|     |- config 0 = 1 
	|     `- config 2 = A 
	|- identical 
	|  `- CC2 = 2 
	`- in 'config 2' only 
	   |- CC3 = 3 
	   `- XYZ = xyz 

=head1 DESCRIPTION

This module lets you compare hashes and Config::Hierarchical objects.

=head1 DOCUMENTATION


=head1 SUBROUTINES/METHODS

=cut

#-------------------------------------------------------------------------------

sub GetConfigDelta
{

=head2 GetConfigDelta

	my $delta = GetConfigDelta
				(
				{name   => {A => 1, COMMON => 0}},
				{name_2 => {B => 2, COMMON => 0}}
				) ;

B<GetConfigDelta> compares two hashes and returns a reference to a hash containing up to 4 elements.
It takes as argument two hash reference which contain a single element. The key is used as name for the hash
while the value is a reference to the hash to be compared.

Returned elements:

=over 2

=item * identical

Contains all the elements that are identical in both hashes as well as the value they have

=item * different

Contains the elements that are common in both hashes but with different values

=item * in 'lhs' only 

Contains the elements that exists in the first hash but not in the second hash .

=item * in 'rhs' only

Contains the elements that exists in the first hash but not in the second hash .

=back

=cut

my ($lhs,  $rhs) = @_ ;

die "GetConfigDelta: Error, wrong argument type on the left hand side, expected hash with a single element!\n" unless 'HASH' eq ref $lhs ;
die "GetConfigDelta: Error, wrong argument type on the right hand side, expected hash with a single element!\n" unless 'HASH' eq ref $rhs ;

die "GetConfigDelta: Error, only one element expected on left hand side\n" unless 1 == scalar(keys %{$lhs}) ;
die "GetConfigDelta: Error, only one element expected on right hand side\n" unless 1 == scalar(keys %{$rhs}) ;

my $lhs_name = (keys %{$lhs})[0] ;
my $rhs_name = (keys %{$rhs})[0] ;

die "GetConfigDelta: Error, expected a HASH as a config on the left hand side\n" unless 'HASH' eq ref $lhs->{$lhs_name} ;
die "GetConfigDelta: Error, expected a HASH as a config on the right hand side\n" unless 'HASH' eq ref $rhs->{$rhs_name} ;

# make lhs and rhs point to the configs
($lhs,  $rhs) = ($lhs->{$lhs_name}, $rhs->{$rhs_name}) ;

my %delta ;

for my $key( keys %{$lhs})
	{
	if(exists $rhs->{$key})
		{
		if(!Compare($rhs->{$key}, $lhs->{$key}))
			{
			$delta{different}{$key} = {$lhs_name => $lhs->{$key}, $rhs_name => $rhs->{$key}}
			}
		else
			{
			$delta{identical}{$key} = $lhs->{$key} ;
			}
		}
	else
		{
		$delta{"in '$lhs_name' only"}{$key} = $lhs->{$key} ;
		}
	}
	
for my $key( keys %{$rhs})
	{
	unless(exists $lhs->{$key})
		{
		$delta{"in '$rhs_name' only"}{$key} = $rhs->{$key} ;
		}
	}

return(\%delta) ;
}
  
#-------------------------------------------------------------------------------

sub GetConfigHierarchicalDelta
{

=head2 GetConfigHierarchicalDelta

	my $config_1 = new Config::Hierarchical(...) ;
	my $config_2 = new Config::Hierarchical(...) ;
	
	GetConfigHierarchicalDelta($config_1, $config_2) ;

Compares two B<Config::Hierarchical> objects and returns a reference to hash containing the delta between the 
objects. See L<GetConfigDeleta> for a description of the returned hash.

The name of the Config::Variable object is extracted from the objects.

=cut


my ($lhs,  $rhs) = @_ ;

die "GetConfigHierarchicalDelta: Error, expected a 'Config::Hierarchical' on the left hand side\n" unless 'Config::Hierarchical' eq ref $lhs ;
die "GetConfigHierarchicalDelta: Error, expected a 'Config::Hierarchical' on the right hand side\n" unless 'Config::Hierarchical' eq ref $rhs ;

my ($lhs_name) = $lhs->GetInformation() ;
my ($rhs_name) = $rhs->GetInformation() ;

my $lhs_hash_ref = $lhs->GetHashRef() ;
my $rhs_hash_ref = $rhs->GetHashRef() ;

return( GetConfigDelta({$lhs_name=> $lhs_hash_ref} ,{$rhs_name=> $rhs_hash_ref}) );
}

#-------------------------------------------------------------------------------

sub DumpConfigHierarchicalDelta
{

=head2 DumpConfigHierarchicalDelta

	my $config_1 = new Config::Hierarchical(...)
	my $config_2 = new Config::Hierarchical(...) ;
	
	print DumpConfigHierarchicalDelta($config_1, $config_2, QUOTE_VALUES => 1) ;
  

The first two arguments a L<Config::Hierarchical> objects, the rest of the arguments are passed
as is to L<Data::TreeDumper>.

This sub returns a string containing the dump of the delta. See L<Synopsis> for an output example.

=cut

my ($lhs,  $rhs, @other_arguments_to_data_treedumper) = @_ ;

die "GetConfigHierarchicalDelta: Error, expected a 'Config::Hierarchical' on the left hand side\n" unless 'Config::Hierarchical' eq ref $lhs ;
die "GetConfigHierarchicalDelta: Error, expected a 'Config::Hierarchical' on the right hand side\n" unless 'Config::Hierarchical' eq ref $rhs ;

my ($lhs_name) = $lhs->GetInformation() ;
my ($rhs_name) = $rhs->GetInformation() ;

return
	(
	DumpTree GetConfigHierarchicalDelta($lhs ,$rhs) ,
	"Delta between '$lhs_name' and '$rhs_name'':", 
	DISPLAY_ADDRESS => 0,
	@other_arguments_to_data_treedumper 
	) ;
}

#-------------------------------------------------------------------------------

sub Get_NoIdentical_Filter
{

=head2 Get_NoIdentical_Filter

Dumping a config delta with:

	print  DumpConfigHierarchicalDelta($config_2, $config_0) ;	

Gives:

	$expected_dump = <<EOD ;
	Delta between 'config 2' and 'config 0'':
	|- different 
	|  `- CC1 
	|     |- config 0 = 1 
	|     `- config 2 = A 
	|- identical 
	|  `- CC2 = 2 
	`- in 'config 2' only 
	   |- CC3 = 3 
	   `- XYZ = xyz 
  

if you do not want to display the configuration variables that are identical, use:

	print  DumpConfigHierarchicalDelta($config_2, $config_0, Get_NoIdentical_Filter()) ;

which gives:

	my $expected_dump = <<EOD ;
	Delta between 'config 2' and 'config 0'':
	|- different 
	|  `- CC1 
	|     |- config 0 = 1 
	|     `- config 2 = A 
	`- in 'config 2' only 
	   |- CC3 = 3 
	   `- XYZ = xyz 
	EOD

Returns a L<Data::TreeDumper> filter you can use to remove the 'identical' element from the delta hash.

=cut

return (LEVEL_FILTERS => {0 => sub {my $s = shift ; return('HASH', undef, grep {$_ ne 'identical'} keys %{$s})}}) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

Copyright 2006-2007 Khemir Nadim. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Hierarchical

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Hierarchical>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-config-hierarchical@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Hierarchical>

=back

=head1 SEE ALSO


=cut
