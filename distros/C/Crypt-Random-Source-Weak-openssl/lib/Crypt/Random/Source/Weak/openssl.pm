package Crypt::Random::Source::Weak::openssl; # git description: v0.02-6-g14c3ddf
# ABSTRACT: Get random bytes from the OpenSSL command line utility

use Moo;

use File::Which qw(which);

use namespace::clean;

our $VERSION = '0.03';

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
	isa => sub { die "$_[0] must be an arrayref" unless ref $_[0] eq 'ARRAY' },
	is => 'lazy',
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

=encoding UTF-8

=head1 NAME

Crypt::Random::Source::Weak::openssl - Get random bytes from the OpenSSL command line utility

=head1 VERSION

version 0.03

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

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Crypt-Random-Source-Weak-openssl>
(or L<bug-Crypt-Random-Source-Weak-openssl@rt.cpan.org|mailto:bug-Crypt-Random-Source-Weak-openssl@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
