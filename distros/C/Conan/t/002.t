use lib 'lib';
use Test::More tests => 1;

use_ok( 'Conan::Configure::Xen' );


__END__
my $config = Conan::Configure::Xen->new(
	basedir => '/tmp/',
	name => 'oma06',
	settings => {
	#	ip => '1.2.3.5',
	},
	generators => {
		# ip => sub {
		# 	my $self = shift;
		# 	my $output = '';
		# 	$output .= "# I'm the IP generator\n";
		# 	$output .= "ip = '" . $self->{settings}->{ip} . "'" . "\n"
		# 		if( $self->{settings}->{ip} );
		# 	return $output;
		# }
	},
);

$config->parse();

print $config->generate();

