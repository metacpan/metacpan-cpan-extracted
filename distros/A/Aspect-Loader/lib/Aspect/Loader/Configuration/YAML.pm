package Aspect::Loader::Configuration::YAML;
use strict;
use warnings;
use YAML qw(LoadFile);
use base qw(Aspect::Loader::Configuration);

sub new{
	my $class = shift;
	my $file_path = shift;
	my $self  = $class->SUPER::new;
	$self->load_configuration($file_path);
	return $self;
}

sub load_configuration{
	my $self = shift;
	my $file_path = shift;
	my $conf = LoadFile($file_path);
	foreach my $conf ( @{$conf->{aspects}}){
    push @{$self->{_configuration}},$conf;
	}
}

1;
