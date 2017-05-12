#!/usr/bin/perl

package Crypt::Random::Source::Weak::openssl;
use Moose;

use File::Which qw(which);

use namespace::clean -except => [qw(meta)];

our $VERSION = "0.02";

sub available {
	which("openssl");
}

extends qw(
	Crypt::Random::Source::Weak
	Crypt::Random::Source::Base::Proc
);

has openssl => (
	is => "rw",
	default => sub { which("openssl") },
	trigger => sub { shift->clear_command },
);

has default_chunk_size => (
	is => "rw",
	default => 1 << 16,
	trigger => sub { shift->clear_command },
);

has 'command' => (
	isa => "ArrayRef",
	is  => "ro",
	lazy_build => 1,
	clearer => "clear_command",
);

sub _build_command {
	my $self = shift;
	return [$self->openssl, "rand", $self->default_chunk_size];
}

sub BUILD {
	my $self = shift;
	$self->set_default_command;
}

sub set_default_command {
	my $self = shift;

	$self->default_chunk_size(1 << 16) # about 1.5x the overhead of simply spawning openssl rand 0 on my computer
		unless $self->default_chunk_size;

	$self->command([qw(openssl rand), $self->default_chunk_size])
		unless defined $self->command;
}

sub _read_too_short {
	my ( $self, $buf, $got, $req ) = @_;

	$self->close; # will cause openssl to be respawned

	return $buf . $self->get( $req - $got );
}

__PACKAGE__

__END__

=pod

=head1 NAME

Crypt::Random::Source::Weak::openssl - Get random bytes from the OpenSSL
command line utility

=head1 SYNOPSIS

	use Crypt::Random::Source::Strong::openssl;

	my $source = Crypt::Random::Source::Weak::openssl->new

	my $bytes = $source->get(1024); # get 1kb of random bytes

=head1 DESCRIPTION

This is a B<weak> random byte source because C<openssl rand> is a PRNG.

This is a subclass of L<Crypt::Random::Source::Base::Proc>.

Due to the retarded nature of the F<rand> command line utility's interface, it
must repeatedly be invoked with C<default_chunk_size> as number of random bytes
to generate.

=head1 ATTRIBUTES

=over 4

=item default_chunk_size

The default number of bytes to generate per C<openssl rand> invocation.

Defaults to 64 kb, which is pretty large and balances well with the startup
time of C<openssl rand> for miniscule chunks.

If you will be needing a lot of random data, increasing this number to
something much larger would probably be beneficial.

=item openssl

The C<openssl> executable to invoke. Defaults to what L<File::Which> found for
C<openssl> (which means it must be in your C<PATH>).

=back

=head1 SEE ALSO

L<Crypt::Random::Source>

L<openssl(1)>, L<rand(1)>

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
