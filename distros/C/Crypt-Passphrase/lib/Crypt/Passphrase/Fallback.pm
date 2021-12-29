package Crypt::Passphrase::Fallback;
$Crypt::Passphrase::Fallback::VERSION = '0.004';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Validator';

sub new {
	my ($class, %args) = @_;
	return bless {
		callback => $args{callback},
		acceptor => $args{acceptor} || sub { 1 },
	}, $class;
}

sub accepts_hash {
	my ($self, $hash) = @_;
	return $self->{acceptor}->($hash);
}

sub verify_password {
	my ($self, $password, $hash) = @_;
	return $self->{callback}->($password, $hash);
}

1;

#ABSTRACT: a fallback validator for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Fallback - a fallback validator for Crypt::Passphrase

=head1 VERSION

version 0.004

=head1 METHODS

=head2 new(%args)

This method takes two named arguments

=over 4

=item * callback

The C<verify_password> method will call this with the password and the hash, and return its return value.

=item * acceptor

This callback will decide if this object will take a hash. By default it accepts anything.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
