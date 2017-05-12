package Class::DI::Resource::YAML;
use strict;
use warnings;
use YAML qw(LoadFile);
use base qw(Class::DI::Resource);

sub new{
	my $class = shift;
	my $file_path = shift;
	my $self  = $class->SUPER::new;
	$self->load_resource($file_path);
	return $self;
}

sub load_resource{
	my $self = shift;
	my $file_path = shift;
	my $conf = LoadFile($file_path);
	foreach my $conf ( @{$conf->{injections}}){
			$self->{_resource}->{$conf->{name}} = $conf;
	}
}

1;
