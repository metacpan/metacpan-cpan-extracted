package CTK::Crypt::GPG;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Crypt - GPG Crypt backend

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CTK::Crypt::GPG;

    my $gpg = CTK::Crypt::GPG->new(
        -gpgbin     => "/usr/bin/gpg",
        -gpghome    => "/gpg/homedir",
        -gpgconf    => "/gpg/homedir/gpg.conf",
        -gpgopts    => ["verbose", "yes"],
        -publickey  => "/path/to/public.key",
        -privatekey => "/path/to/private.key",
        -password   => "passphrase", # Key password
        -recipient  => "anonymous@example.com", # Email, user id, keyid, or keygrip
    ) or die("Can't create crypter");

    $gpg->encrypt(
        -infile => "MyDocument.txt",
        -outfile=> "MyDocument.txt.asc",
        -armor  => "yes",
    ) or die( $gpg->error );

    $gpg->decrypt(
        -infile => "MyDocument.txt.asc",
        -outfile=> "MyDocument.txt",
    ) or die( $gpg->error );

=head1 DESCRIPTION

GPG Crypt backend

See L<http://www.gnupg.org> (GPG4Win - L<http://gpg4win.org>) for details

For start working with this module You need create public and private GPG keys:

    gpg --full-gen-key

Example of interaction (test account):

    > Anonymous
    > anonymous@example.com
    > Password: test
    < 58E79B320D135DEE
    < ADF81A296AAC9503A6135F258E79B320D135DEE

For show list of available keys run:

    gpg -k
    gpg -K

For export keys run:

    gpg --export -a -o mypublic.key "anonymous@example.com"
    gpg --export-secret-keys --batch --pinentry-mode loopback --passphrase "test" -a -o myprivate.key "anonymous@example.com"

=head2 new

    my $gpg = CTK::Crypt::GPG->new(
        -gpgbin     => "/usr/bin/gpg",
        -gpghome    => "/gpg/homedir",
        -gpgconf    => "/gpg/homedir/gpg.conf",
        -gpgopts    => ["verbose", "yes"],
        -publickey  => "/path/to/public.key",
        -privatekey => "/path/to/private.key",
        -password   => "passphrase", # Key password
        -recipient  => "anonymous@example.com", # Email, user id, keyid, or keygrip
    ) or die("Can't create crypter");

=over 8

=item B<gpgbin>

GPG program

For example: "/usr/bin/gpg"

Default: gpg from PATH

=item B<gpghome>, B<homedir>

GPG homedir

For example: "/gpg/homedir"

Default: /tmp/gpgXXXXX

=item B<gpgconf>

Path to GPG config file (for options storing)

For example: "/gpg/homedir/gpg.conf"

Default: /tmp/gpgXXXXX/gpg.conf

=item B<gpgopts>, B<options>

GPG default options

For example: ["verbose", "yes"]

Default: ["verbose", "yes"],

=item B<publickey>, B<pubkey>, B<pubring>

Public key path

For example: "/path/to/public.key"

=item B<privatekey>, B<privkey>, B<privring>, B<seckey>, B<secring>

Private key path

For example: "/path/to/private.key"

=item B<password>, B<passphrase>, B<passw>, B<pass>

Private key password

For example: "passphrase"

=item B<recipient>, B<keyid>, B<id>, B<user>, B<keygrip>

Email, user id, keyid, or keygrip

For example: "anonymous@example.com",

=back

=head2 decrypt

    $gpg->decrypt(
        -infile => "MyDocument.txt.asc",
        -outfile=> "MyDocument.txt",
    ) or die( $gpg->error );

PGP file decrypting

=over 8

=item B<in>, B<filein>, B<filesrs>, B<infile>, B<src>

Source file (encrypted file)

=item B<out>, B<fileout>, B<filedst>, B<outfile>, B<dst>

Target file

=back

=head2 encrypt

    $gpg->encrypt(
        -infile => "MyDocument.txt",
        -outfile=> "MyDocument.txt.asc",
        -armor  => "yes",
    ) or die( $gpg->error );

PGP file encrypting

=over 8

=item B<in>, B<filein>, B<filesrs>, B<infile>, B<src>

Source file

=item B<out>, B<fileout>, B<filedst>, B<outfile>, B<dst>

Target file (encrypted file)

=item B<armor>, B<ascii>

Enable armor-mode (as text output): yes, on, 1, enable

For example: "yes"

Default: "no"

=back

=head2 error

    print $gpg->error;

Returns error string

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK::Util>, L<File::Temp>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::Util>, L<http://www.gnupg.org>, L<GPG4Win|http://gpg4win.org>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use Carp;
use CTK::Util qw(:API :FORMAT :UTIL :FILE );
use File::Temp qw();
use File::Spec;

use constant {
    # GPG (GNUPG)
    GPGBIN    => 'gpg',
    GPGCONF   => 'gpg.conf',
    GPGOPTS   => ["verbose", "yes"],
    GPGEXT    => ".asc",
};

sub new {
    my $class = shift;
    my ($gpgbin, $gpghome, $gpgconf, $gpgopts, $pubkey, $seckey, $pass, $recipient) =
    read_attributes([
        ['GPG','GPGBIN','BIN','CMD','COMMAND'],
        ['GPGHOME','GPGDIR','DIRGPG','HOMEGPG','HOMEDIR'],
        ['GPGCONF','CONFIG','CONF'],
        ['GPGOPTS','GPGOPTIONS','OPTIONS','OPTS'],
        ['PUBLIC','PUBLICKEY','PUP','PUBKEY','PUBRING'],
        ['PRIVATE','PRIV','PRIVATEKEY','SEC','SECKEY','SECRETKEY','PRIVKEY','PRIVRING','SECRING'],
        ['PASS','PASSWORD','PASSPHRASE','PASSW'],
        ['RECIPIENT','KEYID','ID','USER','KEYGRIP'],
    ], @_) if defined $_[0];
    $gpgbin ||= which(GPGBIN);
    my $tmpdir = File::Temp->newdir(TEMPLATE => 'gpgXXXXX', TMPDIR => 1) unless $gpghome;
    if ($gpghome) {
        preparedir($gpghome, 0700) or do {
            carp(sprintf("Can't prepare dir: %s", $gpghome));
            return undef;
        };
    } else {
        $gpghome = $tmpdir->dirname;
    }
    $gpgconf ||= File::Spec->catfile($gpghome, GPGCONF);
    $gpgopts ||= GPGOPTS;
    my @opts = ('# Do not edit this file');
    if (ref($gpgopts) eq 'ARRAY') { push @opts, @$gpgopts }
    else { push @opts, $gpgopts }
    fsave($gpgconf, join("\n", @opts)) or do {
        carp(sprintf("Can't save GPG conffile: %s", $gpgconf));
        return undef;
    };
    eval { chmod $gpgconf, 0600 };

    # Get version
    my @cmd = ();
    push(@cmd, $gpgbin, "--homedir", $gpghome, "--options", $gpgconf, "--version");
    my $err = "";
    my $out = execute( [@cmd], undef, \$err, 1 );
    my $version = $out && $out =~ /gpg.+?([0-9\.]+)\s*$/m ? $1 : 0;
    if ($version) {
        my $tv = pack("U*",split(/\./, $version));
        unless ($tv gt pack("U*", 2, 0)) {
            carp(sprintf("Incorrect GPG version v%vd. Require v2.0.0 and above", $tv));
            return undef;
        }
    }
    $out = "" if $version;

    # Import keys
    foreach my $key ($pubkey, $seckey) {
        next unless $key;
        next unless length($key);
        next unless -e $key;
        @cmd = ($gpgbin, "--homedir", $gpghome, "--options", $gpgconf);
        push @cmd, "--pinentry-mode", "loopback", "--passphrase", $pass if $pass && length($pass);
        push @cmd, "--import", $key;
        $out = execute( [@cmd], undef, \$err, 1 );
        unless ($recipient) {
            foreach my $t ($out, $err) {
                next unless $t;
                $recipient = $1 if $t =~ /key\s+([a-z0-9]+)\:/im;
                last if $recipient;
            }
        }
    }

    my $self = bless {
        gpgbin  => $gpgbin,
        homedir => $gpghome,
        tempdir => $tmpdir,
        gpgconf => $gpgconf,
        options => [@opts],
        cmd     => join(" ", @cmd),
        stdout  => $out,
        stderr  => $err,
        version => $version,
        pubkey  => $pubkey,
        seckey  => $seckey,
        password => $pass,
        recipient => $recipient,
        error => $recipient ? "" : "Incorrect recipient!",
    }, $class;
    return $self;
}

sub encrypt {
    my $self = shift;
    my ($inf, $outf, $armor) =
    read_attributes([
        ['IN','FILEIN','INPUT','FILESRC','SRC','INFILE'],
        ['OUT','FILEOUT','OUTPUT','FILEDST','DST','OUTFILE'],
        ['ARMOR','ASCII'],
    ], @_) if defined $_[0];
    $self->{error} = "";
    $armor = isTrueFlag($armor);
    my $recipient = $self->{recipient};
    return 0 unless $recipient;
    unless (defined($inf) && length($inf) && -e $inf) {
        $self->{error} = sprintf("File not found: %s", $inf // "");
        return 0;
    }
    $outf = sprintf("%s%s", $inf, GPGEXT) unless defined($outf) && length($outf);

    my @cmd = ($self->{gpgbin}, "--homedir", $self->{homedir}, "--options", $self->{gpgconf}, "--always-trust");
    push(@cmd, "-r", $recipient);
    push(@cmd, "-a") if $armor;
    push(@cmd, "-o", $outf);
    push(@cmd, "-e", $inf);
    $self->{cmd} = join(" ", @cmd);
    my $err = "";
    my $out = execute( [@cmd], undef, \$err, 1 );
    $self->{stdout} = $out // '';
    $self->{stderr} = $err // '';

    # Return
    return 1 if -e $outf;
    $self->{error} = sprintf("Can't encrypt file: %s\n%s", $outf, $err // "");
    return 0;
}
sub decrypt {
    my $self = shift;
    my ($inf, $outf) =
    read_attributes([
        ['IN','FILEIN','INPUT','FILESRC','SRC','INFILE'],
        ['OUT','FILEOUT','OUTPUT','FILEDST','DST','OUTFILE'],
    ], @_) if defined $_[0];
    $self->{error} = "";
    unless (defined($inf) && length($inf) && -e $inf) {
        $self->{error} = sprintf("File not found: %s", $inf // "");
        return 0;
    }
    unless (defined($outf) && length($outf)) {
        $self->{error} = "Incorrect output file";
        return 0;
    }

    my @cmd = ($self->{gpgbin}, "--homedir", $self->{homedir}, "--options", $self->{gpgconf}, "--always-trust");
    push(@cmd, "--pinentry-mode", "loopback", "--passphrase", $self->{password}) if $self->{password};
    push(@cmd, "-o", $outf);
    push(@cmd, "-d", $inf);
    $self->{cmd} = join(" ", @cmd);
    my $err = "";
    my $out = execute( [@cmd], undef, \$err, 1 );
    $self->{stdout} = $out // '';
    $self->{stderr} = $err // '';

    # Return
    return 1 if -e $outf;
    $self->{error} = sprintf("Can't decrypt file: %s\n%s", $outf, $err // "");
    return 0;
}
sub error {
    my $self = shift;
    return $self->{error} // '';
}


1;
__END__

List of keys:
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --list-keys
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --list-secret-keys

Delete all keyrings:
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --delete-secret-and-public-key 58E79B320D135DEE

Export keys to files:
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --export -a -o mypublic.key 58E79B320D135DEE
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --export-secret-keys -a -o myprivate.key 58E79B320D135DEE

Encrypting:
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --batch --import ./mypublic.key
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --batch --always-trust -r 58E79B320D135DEE -o README.asc -a -e README
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --batch --delete-keys 58E79B320D135DEE

Decrypting:
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --batch --pinentry-mode loopback --passphrase "test" --import ./myprivate.key
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --batch --always-trust --pinentry-mode loopback --passphrase "test" -o README.dec -d README.asc
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --batch --delete-secret-keys 58E79B320D135DEE

Password unset:
gpg --homedir /home/minus/mygpg --options /home/minus/mygpg/gpg.conf --edit-key 58E79B320D135DEE
