#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::Key;
our $VERSION = '0.98';
use base qw(Class::Singleton);

my $pure_perl = 0;

if ($ENV{AUTOMATED_TESTING}) {

	#If this is a smoker, Crypt::Blowfish is required.
	use Crypt::Blowfish;

} else {

	eval ('use Crypt::Blowfish');
	if ($@) {
		eval ('use Crypt::Blowfish_PP');
		die "$@" if ($@);
		$pure_perl = 1;
	}

}

=pod

=head1 NAME

Apache::Wyrd::Services::Key - Apache-resident crypto key (Blowfish)

=head1 SYNOPSIS

	<Perl>
		use strict;
		use Apache::Wyrd::Services::Key;
		Apache::Wyrd::Services::Key->instance();
	</Perl>

=head1 DESCRIPTION

A subclass of the Singleton class, the key is created using the
C<instance> method, not the C<new> method.

Generates a random cryptographic key (for Blowfish) for use with an
C<Apache::Wyrd::Services::CodeRing> object.  Designed to be used at
server startup in order to keep the key in shared memory.  As the key is
never stored in a file and then changes on server restart, it cannot be
obtained trivially.  This makes it suitable for storing state
information on the browser without exposing the internals of your
program.  

If Blowfish is not available on your system, it will attempt Blowfish_PP
(pure perl) before failing to compile.

Fixed keys are also possible.  The instance method can also accept a
string as an argument to use in place of a randomly-generated key.

In development environments, with frequent server restarts, it is
advisable to use a fixed key to prevent your Form state and Login
Cookies from becoming unusable.

=head1 METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (void) C<instance> ([scalar])

Initialize the Key object.  If an optional key is supplied, the cypher
is initialized with that key.  If not, a random key is generated.

=cut

sub _new_instance {
	my ($class, $key) = @_;
	unless ($key) {
		for (my $i=0; $i<56; $i++) {
			#collect random chars, dropping null bytes in case of C
			#interfaces, i.e. DBM files and the like.
			$key .= chr(int(rand(255)) + 1);
		}
	}
	my $cypher = undef;
	if ($pure_perl) {
		$cypher = Crypt::Blowfish_PP->new($key);
	} else {
		$cypher = Crypt::Blowfish->new($key);
	}
	my $data = {
		key		=>	$key,
		cypher	=>	$cypher
	};
	bless $data, $class;
	return $data;
}

=pod

=item (void) C<key> ([scalar])

Return the key.

=cut

sub key {
	my $self = shift;
	return $self->{'key'};
}

=pod

=item (void) C<cypher> ([scalar])

Return the cypher, which will be a C<Crypt::Blowfish/_PP> object.

=cut

sub cypher {
	my $self = shift;
	return $self->{'cypher'};
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Unless a fixed key is used, any encrypted information is irretrievable
on server restart.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::CodeRing

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Auth

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;