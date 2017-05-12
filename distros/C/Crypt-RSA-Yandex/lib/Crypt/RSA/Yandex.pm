package Crypt::RSA::Yandex;

use 5.008000;
use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(ya_encrypt);
our @EXPORT = ( );

our $VERSION = '0.06';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub ya_encrypt {
    my ($pub_key,$text) = @_;
    my $cc = __PACKAGE__->new;
    $cc->import_public_key($pub_key);
    return $cc->encrypt($text);
}

1;

=head1 NAME

Crypt::RSA::Yandex - Perl binding to modified RSA library (yamrsa) for encrypting Yandex auth token

=head1 SYNOPSIS

    use Crypt::RSA::Yandex;

    my $crypter = Crypt::RSA::Yandex->new;
    $crypter->import_public_key($pubkey);

    my $encrypted = $crypter->encrypt($text);
    
    # or 
    use Crypt::RSA::Yandex 'ya_encrypt';
    my $encrypted = ya_encrypt($pubkey,$text);

=head1 DESCRIPTION

=head2 FUNCTIONAL INTERFACE

None by default.

=over 4

=item $encrypted_text = ya_encrypt($key, $text)

=back

=head2 OOP INTERFACE

=over 4

=item $crypter = Crypt::RSA::Yandex->new()

=item $self->import_public_key($key)

=item $encrypted_text = $self->encrypt($text)

=back

=head1 SEE ALSO

http://api.yandex.ru/fotki/doc/overview/authorization-token.xml

=head1 AUTHOR

Vladimir Timofeev, E<lt>vovkasm@gmail.comE<gt>

Mons Anderson, E<lt>mons@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by Rambler

=cut
