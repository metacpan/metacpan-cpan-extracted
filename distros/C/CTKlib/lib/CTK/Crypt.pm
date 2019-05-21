package CTK::Crypt; # $Id: Crypt.pm 250 2019-05-09 12:09:57Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Crypt - Cryptography frontend module

=head1 VERSION

Version 1.72

=head1 SYNOPSIS

    use CTK::Util qw/gpg_init gpg_encrypt gpg_decrypt/;

    my $gpg_instance = gpg_init(
        -gpgbin     => "/usr/bin/gpg",
        -gpghome    => "/gpg/homedir",
        -gpgconf    => "/gpg/homedir/gpg.conf",
        -gpgopts    => ["verbose", "yes"],
        -publickey  => "/path/to/public.key",
        -privatekey => "/path/to/private.key",
        -password   => "passphrase", # Key password
        -recipient  => "anonymous@example.com", # Email, user id, keyid, or keygrip
    ) or die("Can't create crypter");

    gpg_encrypt(
        -infile => "MyDocument.txt",
        -outfile=> "MyDocument.txt.asc",
        -armor  => "yes",
    ) or die( $CTK::Crypt::ERROR );

    gpg_decrypt(
        -infile => "MyDocument.txt.asc",
        -outfile=> "MyDocument.txt",
    ) or die( $CTK::Crypt::ERROR );

    tcd_encrypt( "file.txt", "file.tcd" )
        or die( $CTK::Crypt::ERROR );

    tcd_decrypt( "file.tcd", "file.txt" )
        or die( $CTK::Crypt::ERROR );

=head1 DESCRIPTION

Cryptography frontend module

=over 8

=item B<gpg_init>

    my $gpg_instance = gpg_init(
        -gpgbin     => "/usr/bin/gpg",
        -gpghome    => "/gpg/homedir",
        -gpgconf    => "/gpg/homedir/gpg.conf",
        -gpgopts    => ["verbose", "yes"],
        -publickey  => "/path/to/public.key",
        -privatekey => "/path/to/private.key",
        -password   => "passphrase", # Key password
        -recipient  => "anonymous@example.com", # Email, user id, keyid, or keygrip
    ) or die("Can't create crypter");

Initialize GPG instance

See L<CTK::Crypt::GPG>

=item B<gpg_decrypt>

    $gpg_instance->decrypt(
        -infile => "MyDocument.txt.asc",
        -outfile=> "MyDocument.txt",
    ) or die( $CTK::Crypt::ERROR );

GPG (PGP) Decrypting the files

See L<CTK::Crypt::GPG>

=item B<gpg_encrypt>

    $gpg_instance->encrypt(
        -infile => "MyDocument.txt",
        -outfile=> "MyDocument.txt.asc",
        -armor  => "yes",
    ) or die( $CTK::Crypt::ERROR );

GPG (PGP) Encrypting the files

See L<CTK::Crypt::GPG>

=item B<tcd_decrypt>

    tcd_decrypt( "file.tcd", "file.txt" )
        or die( $CTK::Crypt::ERROR );

TCD04 Decrypting files

=item B<tcd_encrypt>

    tcd_encrypt( "file.txt", "file.tcd" )
        or die( $CTK::Crypt::ERROR );

TCD04 Encrypting files

=back

=head1 TAGS

=over 8

=item B<:all>

Will be exported all functions

=item B<:tcd04>

Will be exported following functions:

    tcd_encrypt, tcd_decrypt

=item B<:gpg>

Will be exported following functions:

    gpg_init, gpg_encrypt, gpg_decrypt

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK::Crypt::GPG>, L<CTK::Crypt::TCD04>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::Crypt::GPG>, L<CTK::Crypt::TCD04>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION @EXPORT_OK %EXPORT_TAGS $ERROR/;
$VERSION = '1.72';

use base qw/Exporter/;

use IO::File;
use CTK::Crypt::GPG;
use CTK::Crypt::TCD04;

use constant BUFFER_SIZE => 32 * 1024; # 32kB

@EXPORT_OK = (qw/
        gpg_init gpg_encrypt gpg_decrypt
        tcd_encrypt tcd_decrypt
    /);

%EXPORT_TAGS = (
        tcd04 => [qw/tcd_encrypt tcd_decrypt/],
        gpg   => [qw/gpg_init gpg_encrypt gpg_decrypt/],
        all   => [@EXPORT_OK],
    );

my $GPG_INSTANCE;

sub gpg_init {
    return $GPG_INSTANCE = CTK::Crypt::GPG->new(@_);
}
sub gpg_encrypt {
    $ERROR = "";
    my $st = $GPG_INSTANCE->encrypt(@_);
    $ERROR = $GPG_INSTANCE->error unless $st;
    return $st;
}
sub gpg_decrypt {
    $ERROR = "";
    my $st = $GPG_INSTANCE->decrypt(@_);
    $ERROR = $GPG_INSTANCE->error unless $st;
    return $st;
}
sub tcd_encrypt {
    my $filein = shift;
    my $fileout = shift;
    unless (defined($filein) && length($filein) && -e $filein) {
        $ERROR = sprintf("File not found \"%s\"", $filein // "");
        return 0;
    }
    unless (defined($fileout) && length($fileout)) {
        $ERROR = "Incorrect target file";
        return 0;
    }
    $ERROR = "";

    my $infh = IO::File->new($filein, "r") or do {
        $ERROR = sprintf("Can't open file \"%s\": %s", $filein, $!);
        return 0;
    };
    $infh->binmode() or do {
        $ERROR = sprintf("Can't switch to binmode file \"%s\": %s", $filein, $!);
        return 0;
    };
    my $outfh = IO::File->new($fileout, "w") or do {
        $ERROR = sprintf("Can't open file \"%s\": %s", $fileout, $!);
        return 0;
    };
    $outfh->binmode() or do {
        $ERROR = sprintf("Can't switch to binmode file \"%s\": %s", $fileout, $!);
        return 0;
    };

    my $tcd = new CTK::Crypt::TCD04;
    my $buf;
    while ( $infh->read ( $buf, BUFFER_SIZE/2 ) ) {
        $outfh->write($tcd->encrypt($buf), BUFFER_SIZE) or do {
            $ERROR = sprintf("Can't write file \"%s\": %s", $fileout, $!);
            return 0;
        };
    }

    $outfh->close or do {
        $ERROR = sprintf("Can't close file \"%s\": %s", $fileout, $!);
        return 0;
    };
    $infh->close or do {
        $ERROR = sprintf("Can't close file \"%s\": %s", $filein, $!);
        return 0;
    };
    return 1;
}
sub tcd_decrypt {
    my $filein = shift;
    my $fileout = shift;
    unless (defined($filein) && length($filein) && -e $filein) {
        $ERROR = sprintf("File not found \"%s\"", $filein // "");
        return 0;
    }
    unless (defined($fileout) && length($fileout)) {
        $ERROR = "Incorrect target file";
        return 0;
    }
    $ERROR = "";

    my $infh = IO::File->new($filein, "r") or do {
        $ERROR = sprintf("Can't open file \"%s\": %s", $filein, $!);
        return 0;
    };
    $infh->binmode() or do {
        $ERROR = sprintf("Can't switch to binmode file \"%s\": %s", $filein, $!);
        return 0;
    };
    my $outfh = IO::File->new($fileout, "w") or do {
        $ERROR = sprintf("Can't open file \"%s\": %s", $fileout, $!);
        return 0;
    };
    $outfh->binmode() or do {
        $ERROR = sprintf("Can't switch to binmode file \"%s\": %s", $fileout, $!);
        return 0;
    };

    my $tcd = new CTK::Crypt::TCD04;
    my $buf;
    while ( $infh->read ( $buf, BUFFER_SIZE ) ) {
        $outfh->write($tcd->decrypt($buf), BUFFER_SIZE/2) or do {
            $ERROR = sprintf("Can't write file \"%s\": %s", $fileout, $!);
            return 0;
        };
    }

    $outfh->close or do {
        $ERROR = sprintf("Can't close file \"%s\": %s", $fileout, $!);
        return 0;
    };
    $infh->close or do {
        $ERROR = sprintf("Can't close file \"%s\": %s", $filein, $!);
        return 0;
    };
    return 1;
}

1;

__END__

