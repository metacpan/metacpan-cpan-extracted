package Data::Util::Error;

use strict;
use warnings;
use Data::Util ();

sub import{
	my $class = shift;
	$class->fail_handler(scalar(caller) => @_) if @_;
}

my %FailHandler;
sub fail_handler :method{
	shift; # this class

	my $pkg = shift;
	my $h = $FailHandler{$pkg}; # old handler

	if(@_){ # set
		$FailHandler{$pkg} = Data::Util::code_ref(shift);
	}
	else{ # get
		require MRO::Compat if $] <  5.010_000;
		require mro         if $] >= 5.011_000;

		foreach my $p(@{mro::get_linear_isa($pkg)}){
			if(defined( $h = $FailHandler{$p} )){
				last;
			}
		}
	}


	return $h;
}

sub croak{
	require Carp;

	my $caller_pkg;
	my $i = 0;
	while( defined( $caller_pkg = caller $i) ){
		if($caller_pkg ne 'Data::Util'){
			last;
		}
		$i++;
	}

	my $fail_handler = __PACKAGE__->fail_handler($caller_pkg);

	local $Carp::CarpLevel = $Carp::CarpLevel + $i;
	die $fail_handler ? &{$fail_handler} : &Carp::longmess;
}
1;
__END__

=head1 NAME

Data::Util::Error - Deals with class-specific error handlers in Data::Util

=head1 SYNOPSIS

	package Foo;
	use Data::Util::Error sub{ Foo::InvalidArgument->throw_error(@_) };
	use Data::Util qw(:validate);

	sub f{
		my $x_ref = array_ref shift; # Foo::InvalidArgument is thrown if invalid
		# ...
	}

=head1 Functions

=over 4

=item Data::Util::Error->fail_handler()

=item Data::Util::Error->fail_handler($handler)

=item Data::Util::Error::croak(@args)

=back

=head1 SEE ALSO

L<Data::Util>.

=cut
