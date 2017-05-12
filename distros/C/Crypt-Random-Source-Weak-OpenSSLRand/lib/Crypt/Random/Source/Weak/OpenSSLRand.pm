#!/usr/bin/perl

package Crypt::Random::Source::Weak::OpenSSLRand;
use Squirrel;

use OpenSSL::Rand qw(randbytes);

use namespace::clean -except => [qw(meta)];

extends qw(
	Crypt::Random::Source::Weak
	Crypt::Random::Source::Base
);

our $VERSION = "0.01";

sub available { 1 }

sub rank { 200 } # not too shabby if you can get it installed

sub get {
	my ( $self, $n ) = @_;
	randbytes($n);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Crypt::Random::Source::Weak::OpenSSLRand - Use L<OpenSSL::Rand> as a
L<Crypt::Random::Source>

=head1 SYNOPSIS

	use Crypt::Random::Source::Weak::OpenSSLRand;

	my $source = Crypt::Random::Source::Weak::OpenSSLRand->new;

	my $ten_bytes = $source->get(10);

=head1 DESCRIPTION

This module is a L<Crypt::Random::Source> plugin that provides L<OpenSSL::Rand>
support.

=head1 METHODS

Calls C<randbytes>.

=head1 SEE ALSO

L<Crypt::Random::Source>, L<OpenSSL>, L<OpenSSL::Rand>

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
