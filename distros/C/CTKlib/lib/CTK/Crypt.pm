package CTK::Crypt; # $Id: Crypt.pm 193 2017-04-29 07:30:55Z minus $
use Moose::Role; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Crypt - Cryptography

=head1 VERSION

Version 1.71

=head1 SYNOPSIS

    $c->gpg_decript(
            -in      => CTK::catfile($DATADIR,'in','test.txt.asc'), # Source encripted-file
            -out     => CTK::catfile($DATADIR,'out','test.txt'),    # Destination decripted-file
            -gpghome => '', # RESERVED
            -certdir => '', # Certificate directory. Default: ./data/cert
            -pubkey  => '', # Public key file. Default: ./data/cert/public.key
            -privkey => '', # Private key file. Default: ./data/cert/private.key
            -pass    => '', # Passphrase
        );

=head1 DESCRIPTION

See L<http://www.gnupg.org> (GPG4Win - L<http://gpg4win.org>) for details

=head2 gpg_decript

    $c->gpg_decript(
            -in      => CTK::catfile($DATADIR,'in','test.txt.asc'), # Source encripted-file
            -out     => CTK::catfile($DATADIR,'out','test.txt'),    # Destination decripted-file
            -gpghome => '', # RESERVED
            -certdir => '', # Certificate directory. Default: ./data/cert
            -pubkey  => '', # Public key file. Default: ./data/cert/public.key
            -privkey => '', # Private key file. Default: ./data/cert/private.key
            -pass    => '', # Passphrase
        );

PGP Decrypting the files group

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use constant {
    # GPG (GNUPG)
    GPGBIN    => 'gpg',
    GPGHOME   => 'gpg',
    CERTDIR   => 'cert',
    PUBRING   => 'public.key',
    SECRING   => 'private.key',
};

use vars qw/$VERSION/;
$VERSION = '1.71';

use CTK::Util qw(:API :FORMAT :UTIL);

sub gpg_decript {
    # Дешифровка файла с помощью команды gpg
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($ifile, $ofile, $gpghome, $certdir, $pubkey, $seckey, $pass);
       ($ifile, $ofile, $gpghome, $certdir, $pubkey, $seckey, $pass) =
            read_attributes([
                ['IN','FILEIN','INPUT','FILESRC','SRC','INFILE'],
                ['OUT','FILEOUT','OUTPUT','FILEDST','DST','OUTFILE'],
                ['GPGHOME','GPGDIR','DIRGPG','HOMEGPG','GPG'],
                ['CERTDIR','DIRCERT','CERT','CERTS','CRT'],
                ['PUBLIC','PUBLICKEY','PUP','PUBKEY','PUBRING'],
                ['PRIVATE','PRIV','PRIVATEKEY','SEC','SECKEY','SECRET','SECRETKEY','PRIVKEY','PRIVRING','SECRING'],
                ['PASS','PASSWORD','PASSPHRASE'],
            ],@args) if defined $args[0];

    return 0 unless $ifile;
    return 0 unless $ofile;
    $gpghome ||= catfile($CTK::DATADIR,GPGHOME);
    $certdir ||= catfile($CTK::DATADIR,CERTDIR);
    $pubkey  ||= catfile($certdir,PUBRING);
    $seckey  ||= catfile($certdir,SECRING);
    $pass      = '' unless defined $pass;

    preparedir($gpghome) unless -e $gpghome;
    preparedir($certdir) unless -e $certdir;

    my @cmd = (GPGBIN);
    push @cmd, "--lock-multiple";
    push @cmd, "--compress-algo", 1;
    push @cmd, "--cipher-algo", "cast5";
    push @cmd, "--force-v3-sigs";
    push @cmd, "--yes";

    unless (CTK::WIN) {
        push @cmd, "--options", CTK::NULL;
        push @cmd, "--homedir", $certdir;
        push @cmd, "--keyring", $pubkey;
        push @cmd, "--secret-keyring",$seckey;
        push @cmd, "--passphrase", $pass if defined $pass;
    }

    push @cmd, "-t";
    push @cmd, "-o", $ofile;
    push @cmd, $ifile;
    push @cmd, CTK::ERR2OUT;

    my $rprresult = procexec(\@cmd);

    if (-e $ofile) {
        #CTK::debug("OK: File GnuPG decription to \"$ofile\"");
        return 1;
    } else {
        #CTK::debug("FAILED: File GnuPG decription to \"$ofile\"\n");
        #CTK::debug($rprresult);
        carp("FAILED: File GnuPG decription to \"$ofile\"\n$rprresult"); #unless CTK::debugmode();
        return 0;
    }
}

1;
__END__

Домашний каталог: /home/gpg

1. Проверяем, а не имеем ли мы уже установленный сертификат для расшифровки?

 gpg --options /dev/null --no-secmem-warning --homedir /home/gpg
     --keyring /home/gpg/pubring.gpg --secret-keyring /home/gpg/secring.gpg -k

2. Если НЕ имеем, то импортируем его:

 gpg --options /dev/null --no-secmem-warning --homedir /home/gpg
     --keyring /home/gpg/pubring.gpg --secret-keyring /home/gpg/secring.gpg --import /home/gpg/cyberplat.asc

3. Далее смотрим опять. Появился?

 gpg --options /dev/null --no-secmem-warning --homedir /home/gpg
     --keyring /home/gpg/pubring.gpg --secret-keyring /home/gpg/secring.gpg -k

4. Снимаем пароль!

 gpg --options /dev/null --no-secmem-warning --homedir /home/gpg
     --keyring /home/gpg/pubring.gpg --secret-keyring /home/gpg/secring.gpg --edit-key cyberplat

