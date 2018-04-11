#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester::Keypair;
$Authen::U2F::Tester::Keypair::VERSION = '0.03';
# ABSTRACT: Authen::U2F::Tester Keypair Object

use Moose;
use MooseX::AttributeShortcuts;
use MooseX::SingleArg;

use strictures 2;
use Crypt::PK::ECC;
use namespace::autoclean;



has keypair => (is => 'lazy', isa => 'Crypt::PK::ECC');



has [qw(public_key private_key)] => (is => 'lazy', isa => 'Value');

single_arg 'keypair';

sub _build_keypair {
    my $pk = Crypt::PK::ECC->new;

    $pk->generate_key('nistp256');

    return $pk;
}

sub _build_public_key {
    shift->keypair->export_key_raw('public');
}

sub _build_private_key {
    shift->keypair->export_key_raw('private');
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Authen::U2F::Tester::Keypair - Authen::U2F::Tester Keypair Object

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 my $keypair = Authen::U2F::Tester::Keypair->new;

 # private key in DER format
 my $private_key = $keypair->private_key;

 # public key in DER format
 my $public_key = $keypair->public_key;

 print $keypair->handle;

=head1 DESCRIPTION

This module manages L<Crypt::PK::ECC> keypairs for L<Authen::U2F::Tester>.

=head1 METHODS

=head2 new()

=head2 new($keypair)

Construct a new keypair object.  A L<Crypt::PK::ECC> object can be passed to
the constructor.  Otherwise a new keypair will be generated on demand.

=head2 keypair(): Crypt::PK::ECC

Gets the keypair for this object.  If a keypair was not passed to the
constructor, a new key will be generated.

=head2 public_key(): scalar

Get the public key (in C<DER> format) for this keypair.

=head2 private_key(): scalar

Get the private key (in C<DER> format) for this keypair.

=head1 SOURCE

The development version is on github at L<http://https://github.com/mschout/perl-authen-u2f-tester>
and may be cloned from L<git://https://github.com/mschout/perl-authen-u2f-tester.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/perl-authen-u2f-tester/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
