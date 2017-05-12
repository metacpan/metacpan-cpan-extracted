package Apache::Kid;
use strict;
use vars qw(@ISA);
use Apache::SSI;
use Apache::Constants qw(:common OPT_EXECCGI);

@ISA = qw(Apache::SSI);
my $debug = 0;

sub ssi_images {
	my($self, $args) = @_;
	return &lastmod($args->{file} || $self->{_r}->filename);
}

sub echo_BOO { "BOO!" }

1;
