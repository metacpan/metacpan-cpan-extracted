
package Config::Hierarchical::Tie::ReadOnly ;

use strict;
use warnings ;

BEGIN 
{
#~ use Exporter ();

use vars qw ($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.01' ;
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

use Carp ;
use base qw(Tie::Hash) ;

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

=head1 NAME

Config::Hierarchical::Tie::ReadOnly - Access Hierarchical configuration container through a read only hash

=head1 SYNOPSIS

  
	my $config = new Config::Hierarchical
				(
				NAME => 'config',
				
				CATEGORY_NAMES   => ['A', 'B'],
				DEFAULT_CATEGORY => 'B',
				
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'A', NAME => 'CC1', VALUE => '1'},
					{CATEGORY => 'B', NAME => 'CC2', VALUE => '2'},
					{CATEGORY => 'A', NAME => 'CC3', VALUE => '3'},
					{CATEGORY => 'B', NAME => 'CC4', VALUE => '4'},
					{CATEGORY => 'A', NAME => 'CC5', VALUE => '5'},
					] ,
				) ;
	
	my %hash ;
	tie %hash, 'Config::Hierarchical::Tie::ReadOnly' => $config ;
	
	my @keys = sort keys %hash ; # qw( CC1 CC2 CC3 CC4 CC5)
	print $hash{CC1} ; # print '1'
	
	$hash{CC1} = 2 ; # dies, hash is read only

=head1 DESCRIPTION

Creates a read only wrapper around a B<Config::Hierarchical> object. This let's you access the config
object as a hash. You can use B<{}> access which makes it easy to use the config in interpolated string.
You can also use B<keys> and B<each> on the tied config.

but you can't modify the variables, clear the config or delete any variable.

This is also class is also used to allow you to link a category to an existing Config::Hierarchical object. See
L<new> in <Config::Hierarchical>.

=head1 DOCUMENTATION

=head1 SUBROUTINES/METHODS

=cut

#-------------------------------------------------------------------------------

sub TIEHASH 
{
my ($class, @arguments) = @_ ;

=head2 TIEHASH

The method invoked by the command tie %hash, class name. Associates a new hash instance with the specified class. 

=cut

unless('Config::Hierarchical' eq ref $arguments[0])
	{
	croak "Argument must be a 'Config::Hierarchical' object!\n" ;
	}
	
my $self = {CONFIG => $arguments[0]} ;
bless($self, $class) ;

return($self) ;
}

#-------------------------------------------------------------------------------

sub STORE
{ ## no critic (RequireFinalReturn)
	
my ($this, $key, $value) = @_ ;

=head2 STORE

Dies as this tie is read only.

=cut

my (undef, $filename, $line) = caller() ;
$this->{CONFIG}{INTERACTION}{DIE}->("This hash is read only at '$filename:$line'!\n") ;
}

#-------------------------------------------------------------------------------

sub FETCH 
{

my ($this, $key) = @_ ;

=head2 FETCH

Retrieve the value associated with the configuration variable passed as argument

=cut

my (undef, $filename, $line) = caller() ;
return($this->{CONFIG}->Get(NAME => $key, FILE => $filename, LINE => $line)) ;
}

#-------------------------------------------------------------------------------

sub FIRSTKEY 
{

my ($this) = @_ ;

=head2 FIRSTKEY

Return the first key in the hash. Used internally by Perl.

=cut

$this->{KEYS} = [$this->{CONFIG}->GetKeys()] ;
$this->{KEY_INDEX} = 0 ;

return $this->{KEYS}[$this->{KEY_INDEX}] ;
}

#-------------------------------------------------------------------------------

sub NEXTKEY 
{

my ($this, $lastkey) = @_ ;

=head2 NEXTKEY

Return the next key in the hash. Used internally by Perl.

=cut

$this->{KEY_INDEX}++ ;
return $this->{KEYS}[$this->{KEY_INDEX}] ;
}

#-------------------------------------------------------------------------------

sub EXISTS 
{

my ($this, $key) = @_ ;

=head2 EXISTS

Verify that key exists within the tied Config::Hierarchical.

=cut

return($this->{CONFIG}->Exists(NAME => $key)) ;
}

#-------------------------------------------------------------------------------

sub DELETE 
{ ## no critic (RequireFinalReturn)

my ($this, $key) =  @_ ;

=head2 DELETE

Dies as this tie is read only.

=cut

my (undef, $filename, $line) = caller() ;
$this->{CONFIG}{INTERACTION}{DIE}->("This hash is read only at '$filename:$line'!\n") ;
}

#-------------------------------------------------------------------------------

sub CLEAR 
{ ## no critic (RequireFinalReturn)

my ($this) = @_ ;

=head2 CLEAR

Dies as this tie is read only.

=cut

my (undef, $filename, $line) = caller() ;
$this->{CONFIG}{INTERACTION}{DIE}->("This hash is read only at '$filename:$line'!\n") ;
}

#-------------------------------------------------------------------------------

sub SCALAR 
{

my ($this) = @_ ;

=head2 SCALAR

returns the number of elements in the tied Config::Hierarchical object.

=cut

return($this->{CONFIG}->GetKeys()) ;
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

Copyright 2007 Khemir Nadim. All rights reserved.

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
