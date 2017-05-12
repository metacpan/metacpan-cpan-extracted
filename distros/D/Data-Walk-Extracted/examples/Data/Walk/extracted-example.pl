#!perl
package Data::Walk::MyRole;
use Moose::Role;
requires '_process_the_data';
use MooseX::Types::Moose qw(
        Str
		ArrayRef
		HashRef
    );
my $mangle_keys = {
    Hello_ref => 'primary_ref',
    World_ref => 'secondary_ref',
};

#########1 Public Method      3#########4#########5#########6#########7#########8

sub mangle_data{
	my ( $self, $passed_ref ) = @_;
	@$passed_ref{ 'before_method', 'after_method' } = 
		( '_mangle_data_before_method', '_mangle_data_after_method' );
	### Start recursive parsing
	$passed_ref = $self->_process_the_data( $passed_ref, $mangle_keys );
	### End recursive parsing with: $passed_ref
	return $passed_ref->{Hello_ref};
}

#########1 Private Methods    3#########4#########5#########6#########7#########8

### If you are at the string level merge the two references
sub _mangle_data_before_method{
	my ( $self, $passed_ref ) = @_;
	if( 
		is_Str( $passed_ref->{primary_ref} ) and 
		is_Str( $passed_ref->{secondary_ref} )		){
		$passed_ref->{primary_ref} .= " " . $passed_ref->{secondary_ref};
	}
	return $passed_ref;
}

### Strip the reference layers on the way out
sub _mangle_data_after_method{
	my ( $self, $passed_ref ) = @_;
	if( is_ArrayRef( $passed_ref->{primary_ref} ) ){
		$passed_ref->{primary_ref} = $passed_ref->{primary_ref}->[0];
	}elsif( is_HashRef( $passed_ref->{primary_ref} ) ){
		$passed_ref->{primary_ref} = $passed_ref->{primary_ref}->{level};
	}
	return $passed_ref;
}

package main;
use MooseX::ShortCut::BuildInstance qw( build_instance );
my 	$AT_ST = build_instance( 
		package			=> 'Greeting',
		superclasses	=> [ 'Data::Walk::Extracted' ],
		roles			=> [ 'Data::Walk::MyRole' ],
	);
print $AT_ST->mangle_data( {
		Hello_ref =>{ level =>[ { level =>[ 'Hello' ] } ] },
		World_ref =>{ level =>[ { level =>[ 'World' ] } ] },
	} ) . "\n";