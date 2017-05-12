package App::I18N::Config;
use warnings;
use strict;
use File::Spec;
use YAML::XS;

our $CONFIG;

sub configfile {
    return File::Spec->catfile( 'etc', 'po.yml' );
}

sub exists {
	return -e File::Spec->catfile( 'etc' , 'po.yml' );
}

sub read {
	my $class = shift;
	my $configfile = shift || $class->configfile;
	if( -e $configfile ) {
		return $CONFIG ||= YAML::XS::LoadFile($configfile);
	}
	return;
}

1;
