[% INCLUDE perl/pod.pl sub => 'AUTOLOAD', vars => ' ' -%]

sub AUTOLOAD {

	# localise the $AUTOLOAD variable
	local $AUTOLOAD;

	# ignore the method if it is the DESTROY method
	return if $AUTOLOAD =~ /DESTROY$/;

	# make sure that this is being called as a method
	croak( "AUTOLOAD(): This function is not being called by a ref: $AUTOLOAD( ".join (', ', @_)." )\n" ) unless ref $_[0];

	# get the object
	my $self = shift;

	# get the function name sans package name
	my ($method) = $AUTOLOAD =~ /::([^:]+)$/;

}
