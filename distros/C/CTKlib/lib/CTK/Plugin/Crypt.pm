package CTK::Plugin::Crypt;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::Crypt - Cryptography plugin

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK;
    my $ctk = new CTK(
            plugins => "crypt",
        );

    my $gpg_instance = $ctk->gpg_init(
        -gpgbin     => "/usr/bin/gpg",
        -gpghome    => "/gpg/homedir",
        -gpgconf    => "/gpg/homedir/gpg.conf",
        -gpgopts    => ["verbose", "yes"],
        -publickey  => "/path/to/public.key",
        -privatekey => "/path/to/private.key",
        -password   => "passphrase", # Key password
        -recipient  => "anonymous@example.com", # Email, user id, keyid, or keygrip
    ) or die("Can't create crypter");

    $ctk->gpg_encrypt(
        -infile => "MyDocument.txt",
        -outfile=> "MyDocument.txt.asc",
        -armor  => "yes",
    ) or die( $self->error );

    $ctk->gpg_decrypt(
        -infile => "MyDocument.txt.asc",
        -outfile=> "MyDocument.txt",
    ) or die( $self->error );

    $ctk->tcd_encrypt( "file.txt", "file.tcd" )
        or die( $self->error );

    $ctk->tcd_decrypt( "file.tcd", "file.txt" )
        or die( $self->error );

=head1 DESCRIPTION

Cryptography plugin

See L<http://www.gnupg.org> (GPG4Win - L<http://gpg4win.org>) for details

=head1 METHODS

=over 8

=item B<gpg_init>

    my $gpg_instance = $ctk->gpg_init(
        -gpgbin     => "/usr/bin/gpg",
        -gpghome    => "/gpg/homedir",
        -gpgconf    => "/gpg/homedir/gpg.conf",
        -gpgopts    => ["verbose", "yes"],
        -publickey  => "/path/to/public.key",
        -privatekey => "/path/to/private.key",
        -password   => "passphrase", # Key password
        -recipient  => "anonymous@example.com", # Email, user id, keyid, or keygrip
    ) or die("Can't create crypter");

Initialize GPG instance. NOTE! It is GLOBAL object!

For using self object please use L<CTK::Crypt::GPG> module

See L<CTK::Crypt::GPG>

=item B<gpg_decrypt>

    $ctk->gpg_decrypt(
        -infile => "MyDocument.txt.asc",
        -outfile=> "MyDocument.txt",
    ) or die( $self->error );

GPG (PGP) Decrypting the files

See L<CTK::Crypt::GPG>

=item B<gpg_encrypt>

    $ctk->gpg_encrypt(
        -infile => "MyDocument.txt",
        -outfile=> "MyDocument.txt.asc",
        -armor  => "yes",
    ) or die( $self->error );

GPG (PGP) Encrypting the files

See L<CTK::Crypt::GPG>

=item B<tcd_decrypt>

    $ctk->gpg_decrypt(
        -infile => "MyDocument.txt.asc",
        -outfile=> "MyDocument.txt",
    ) or die( $self->error );

TCD04 Decrypting the files

See L<CTK::Crypt::TCD04>

=item B<tcd_encrypt>

    $ctk->tcd_encrypt( "file.txt", "file.tcd" )
        or die( $self->error );

TCD04 Encrypting the files

See L<CTK::Crypt::TCD04>

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>, L<CTK::Crypt>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>, L<CTK::Crypt>, L<http://www.gnupg.org>, L<GPG4Win|http://gpg4win.org>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use base qw/CTK::Plugin/;

use CTK::Crypt ();

__PACKAGE__->register_method(
    method    => "gpg_init",
    callback  => sub {
    my $self = shift;
    return CTK::Crypt::gpg_init(@_);
});

__PACKAGE__->register_method(
    method    => "gpg_encrypt",
    callback  => sub {
    my $self = shift;
    my $status = CTK::Crypt::gpg_encrypt(@_);
    return $status if $status;
    $self->error($CTK::Crypt::ERROR);
    return 0;
});

__PACKAGE__->register_method(
    method    => "gpg_decrypt",
    callback  => sub {
    my $self = shift;
    my $status = CTK::Crypt::gpg_decrypt(@_);
    return $status if $status;
    $self->error($CTK::Crypt::ERROR);
    return 0;
});

__PACKAGE__->register_method(
    method    => "tcd_encrypt",
    callback  => sub {
    my $self = shift;
    my $status = CTK::Crypt::tcd_encrypt(@_);
    return $status if $status;
    $self->error($CTK::Crypt::ERROR);
    return 0;
});

__PACKAGE__->register_method(
    method    => "tcd_decrypt",
    callback  => sub {
    my $self = shift;
    my $status = CTK::Crypt::tcd_decrypt(@_);
    return $status if $status;
    $self->error($CTK::Crypt::ERROR);
    return 0;
});

1;

__END__
