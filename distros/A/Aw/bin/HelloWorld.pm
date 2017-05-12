package HelloWorld;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.2';
}


sub new
{
my $class = shift;
my $self  = {};

	bless $self, $class;

}


sub speak
{
	print "Hello World\n";
}


sub store
{
my $self = shift;
	
	$self->{data} = shift;
}


sub showData
{
my $self = shift;

	print $self->{data}, "\n";
}


sub run
{
my $self = shift;

	$self->speak;
	$self->showData;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

HelloWorld - A Dummy Class for Aw:: Demonstrations.

=head1 SYNOPSIS

require HelloWorld;

my $world = new HelloWorld;


=head1 DESCRIPTION

The HelloWorld module is required by the demo_adapter.pl and demo_client.pl
demonstration scripts.  It serves no practical purpose.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
