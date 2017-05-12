package Alien::NSS::ModuleBuild;

use parent 'Alien::Base::ModuleBuild';

# remove libnssckbi.dylib because at least on os-x it cannot be linked...
sub alien_generate_manual_pkgconfig {
  my $self = shift;

	my $ret = $self->SUPER::alien_generate_manual_pkgconfig(@_);
	$ret->{keywords}{Libs} =~ s/-lnssckbi ?//g;
	return $ret;
}

1;
