package App::SeismicUnixGui::sunix::shell::xk;

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $constants    = L_SU_global_constants->new;
my $var          = $constants->var();
my $empty_string = $var->{_empty_string};

my $xk = {

	_process => '',

};

sub clear {

	$xk->{_process} = '';

}

=pod

kill processes
do it quietly -q
wait -wq

=cut

sub kill {

	my ($self) = @_;

	if ( $xk->{_process} ) {

		my $this = $xk->{_process};

		if ( $this eq 'ximage' || $this eq 'suximage' ) {

			system("killall ximage -wq");
		} elsif ( $this eq 'suxwigb' || $this eq 'xwigb' ) {

			# do it -wq uietly
			system("killall xwigb -wq");

		} elsif ( $this eq 'suxgraph' || $this eq 'xgraph' ) {
		} else {
			system("killall $xk->{_process} -wq");
		}
	} else {
		print("xk,kill,missing process\n");
	}
}

sub kill_process {

	my ($self) = @_;

	if ( defined $xk->{_process}
		&& $xk->{_process} ne $empty_string ) {
		system("killall $xk->{_process} -wq");
	} else {
		print("xk,kill,missing process\n");
	}
	return ();
}

sub kill_this {

	my ( $self, $process ) = @_;

	if ( defined $process
		&& $process ne $empty_string ) {

		my $this = $process;

		if ( $this eq 'ximage' || $this eq 'suximage' ) {

			system("killall ximage -wq");
			
		} elsif ( $this eq 'suxwigb' || $this eq 'xwigb' ) {

			# do it -wquietly
			system("killall xwigb -wq");

		} elsif ( $this eq 'suxgraph' || $this eq 'xgraph' ) {
			
			system("killall xgraph -wq");
			
		} else {
			system("killall $xk->{_process} -wq");
		}
	} else {
		print("xk,kill,missing process\n");
	}
}

sub set_process {

	my ( $self, $process ) = @_;

	if ( defined $process
		&& $process ne $empty_string ) {

		my $program_name = $process;
		$xk->{_process} = $program_name;

		return ();
	} else {
		print("xk,kill_this, missing process \n");
	}
}
1;
