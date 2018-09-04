
use strict;
use warnings;

package Context::Singleton::Frame::Result;

our $VERSION = v1.0.4;

use Scalar::Util qw[];

sub new {
	my ($class, $resolver, $value) = @_;
	my $self = bless {
		resolver => $resolver,
		value    => $value,
	};

	die "Oops"
		unless $resolver->isa ('Context::Singleton::Frame');

	Scalar::Util::weaken ($self->{resolver});

	return $self;
}

sub resolver {
	$_[0]->{resolver};
}

sub value {
	$_[0]->{value};
}

1;

__END__

=head1 NAME

Context::Singleton::Frame::Result - store resolver result

=head1 DESCRIPTION

Package is for internal use of L<Context::Singleton::Frame>,
encapsulating multiple parameters into one object so I can have scalar context.

=cut
