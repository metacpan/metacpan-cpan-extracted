package Dancer2::Plugin::Passphrase::Hashed;
use strict;
use warnings;
use MIME::Base64 qw(encode_base64);

# ABSTRACT: Passphrases and Passwords as objects for Dancer2

=head1 NAME

Dancer2::Plugin::Passphrase::Hashed - Helper package for Dancer2::Plugin::Passphrase.

=head1 METHODS

=head2 rfc2307()

=head2 scheme()

=head2 algorithm()

=head2 cost()

=head2 plaintext()

=head2 salt_raw()

=head2 hash_raw()

=head2 salt_hex()

=head2 hash_hex()

=head2 salt_base64()

=head2 hash_base64()

=head1 AUTHOR

Maintainer: Henk van Oers <hvoers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

sub new {
    my $class = shift;
    my @args  = @_;
    return bless { @args == 1 ? %{$args[0]} : @args }, $class;
}

sub rfc2307     { $_[0]->{'rfc2307'}   || undef        }
sub scheme      { $_[0]->{'scheme'}    || undef        }
sub algorithm   { $_[0]->{'algorithm'} || undef        }
sub cost        { $_[0]->{'cost'}      || undef        }
sub plaintext   { $_[0]->{'plaintext'} || undef        }
sub salt_raw    { $_[0]->{'salt'}      || undef        }
sub hash_raw    { $_[0]->{'hash'}      || undef        }
sub salt_hex    { unpack 'H*', $_[0]->{'salt'}         }
sub hash_hex    { unpack 'H*', $_[0]->{'hash'}         }
sub salt_base64 { encode_base64( $_[0]->{'salt'}, '' ) }
sub hash_base64 { encode_base64( $_[0]->{'hash'}, '' ) }

1;
