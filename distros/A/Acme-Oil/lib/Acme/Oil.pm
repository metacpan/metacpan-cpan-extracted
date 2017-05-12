package Acme::Oil;
##############################################################################

use strict;
use warnings;
use warnings::register;
use Carp;
use vars qw($VERSION);

my $Level = 100; # remainder

$VERSION= 0.1;
##############################################################################

sub can (;\[$@%]){ #  UNIVERSAL::can is overloaded!

	return $Level unless(@_ > 0);

	return 0      if(!$Level); # oil can is empty!

	if( is_this_burning($_[0]) ){
		ignition($_[0]);
		$Level = 0;
	}
	else{
		soak( $_[0] );
		--$Level;
	}

	$Level;
}


sub wipe (\[$@%]) {
	if(ref($_[0]) eq 'SCALAR'){
		untie ${$_[0]};
	}
	elsif(ref($_[0]) eq 'ARRAY'){
		untie @{$_[0]};
	}
	elsif(ref($_[0]) eq 'HASH'){
		untie %{$_[0]};
	}
	else{
		croak "Sorry, not support it.";
	}
}


sub soak {
	if(ref($_[0]) eq 'SCALAR'){
		require Acme::Oil::ed::Scalar;
		tie ${$_[0]}, 'Acme::Oil::ed::Scalar', ${$_[0]};
	}
	elsif(ref($_[0]) eq 'ARRAY'){
		#croak "Sorry, not yet implemented.";
		require Acme::Oil::ed::Array;
		tie @{$_[0]}, 'Acme::Oil::ed::Array', @{$_[0]};
	}
	elsif(ref($_[0]) eq 'HASH'){
		croak "Sorry, not yet implemented.";
		#tie ${$_[0]}, 'Acme::Oil::ed::HASH', ${$_[0]};
	}
	else{
		croak "Sorry, not support it.";
	}
}


sub is_this_burning {
	my $ref = shift || return 0;

	if(ref($ref) eq 'SCALAR'){
		return _is_burning($$ref);
	}
	elsif(ref($ref) eq 'ARRAY'){
		for my $value (@$ref){
			if(_is_burning($value)){ return 1; }
		}
		return 0;
	}
}


sub _is_burning {
	my $value = shift;
	return 0 unless(defined $value);
	return 1 if $value =~ /fire/i;
}


sub ignition {

	carp "Don't bring the fire close!  ...Bom!"
	  if(warnings::enabled('Acme::Oil'));

	if(ref($_[0]) eq 'SCALAR'){
		require Acme::Oil::Ashed::Scalar;
		tie ${$_[0]}, 'Acme::Oil::Ashed::Scalar';
	}
	elsif(ref($_[0]) eq 'ARRAY'){
		require Acme::Oil::Ashed::Array;
		tie @{$_[0]}, 'Acme::Oil::Ashed::Array';
	}
}

##############################################################################
1;
__END__

=pod

=head1 NAME

Acme::Oil - Oil is slippery and combustible. 

=head1 SYNOPSIS

 use Acme::Oil;
 
 my $var = 'thing';
 
 Acme::Oil::can($var); #  this is oily.
 
 print $var;   # it is not likely to be able to take it out by slipping.
 
 $var = 'eel'; # it is not likely to be able to put in by slipping.
 
 $var = 'fire'; # No! Don't bring the fire!  ...Bom!
 
 print $var; # ashed.
 
 
 my $var2 = 'Firefox'; # burning.
 
 Acme::Oil::can($var); # silly!  ...Bom!

 Acme::Oil::can(); # doesn't remain any longer.



=head1 DESCRIPTION

There are two educational effects of this module.
First, if the variable is soaked in oil, it becomes slippery.
Second, it is dangerous to bring the fire close to the oil.
Please remembere these points, enjoy your Perl life!


=head1 FUNCTIONS

=over 4

=item Acme::Oil::can

It takes a scalar or an array or a hash(not yet supported).
If no argument, returns amount of the remainder.

=item Acme::Oil::wipe

It takes a scalar or an array or a hash(not yet supported)
and wiped oil off.

=back

=head1 WARNING

 use warnings 'ACME::Oil';

 no warnings 'ACME::Oil';

=head1 TODO

should support HASH.

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

Tie

=cut
