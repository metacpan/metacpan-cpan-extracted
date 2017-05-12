package Data::Encrypted;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $VAR1);

require Exporter;

require Crypt::RSA;
require Crypt::RSA::Key::Public::SSH;
require Crypt::RSA::Key::Private::SSH;

require Term::ReadPassword;
require File::HomeDir;
require Storable;
require Fcntl;

use Carp;

$VERSION = '0.07';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(encrypted encrypt finish finished);

my $RESET = 0;
my ($FILE, $FH);
my ($PK, $SK, $PW);

sub import {

    @_ = _get_args(@_);

    # let Exporter finish it's work:
    Data::Encrypted->export_to_level(1, @_);
}

sub _get_args {

    for (my $i = 0 ; $i < @_ ; $i++) {
	if ($_[$i] =~ m/-?reset/oi) {
	    $RESET = 1;
	    splice(@_, $i--, 1);
	} elsif ($_[$i] =~ m/-?file/oi) {
	    $FILE = $_[$i+1];
	    splice(@_, $i--, 2);
	    _get_filehandle();
	} elsif ($_[$i] =~ m/-?fh/oi) {
	    $FH = $_[$i+1];
	    splice(@_, $i--, 2);
	} elsif ($_[$i] =~ m/-?pk/oi) {
	    $PK = $_[$i+1];
	    splice(@_, $i--, 2);
	} elsif ($_[$i] =~ m/-?sk/oi) {
	    $SK = $_[$i+1];
	    splice(@_, $i--, 2);
	} elsif ($_[$i] =~ m/-?pw/oi) {
	    $PW = $_[$i+1];
	    splice(@_, $i--, 2);
	}
    }

    return @_;
}

sub new {

    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {}, $class;

    _get_args(@_);

    unless (defined $FH) {
	_get_filehandle()
    }

    $self->{_public} = ref $PK ? $PK : new Crypt::RSA::Key::Public::SSH
	Filename => $PK || (File::HomeDir::home() . '/.ssh/identity.pub');
    $self->{_private} = ref $SK ? $SK : new Crypt::RSA::Key::Private::SSH
	(Filename => $SK || (File::HomeDir::home() . '/.ssh/identity'),
	 Password => $PW );

    $self->{_rsa} = new Crypt::RSA;

    return $self;
}

sub _get_filehandle {

    if ($FILE =~ m/^~([^\/]*)\//o) {
	my $user = $1;
	my $path;
	if ($user) {
	    $path = File::HomeDir::home($user);
	} else {
	    $path = File::HomeDir::home();
	}
	unless ($path) {
	    croak "No home directory for user: $user\n";
	}
	$FILE =~ s/^~$user/$path/;
    }

    sysopen(FH, $FILE, Fcntl::O_RDWR() | Fcntl::O_CREAT() )
	or croak "Can't open $FILE: $!";
    flock(FH, Fcntl::LOCK_EX())
	or croak "Can't flock file: $!";
    $FH = \*FH;
}

sub encrypted {

    my $self = shift;
    my $arg = shift;

    unless (ref $self) {
	my $newself = Data::Encrypted->new(defined $arg ? $arg : (), @_);
	($self, $arg) = ($newself, $self);
    }

    unless ($arg) {
	croak "Must supply argument to encrypted!";
    }

    unless (exists $self->{_data}) {
	$self->{_data} = '';
	while (<$FH>) {
	    $self->{_data} .= $_;
	}
	
	$self->{_data} =~ s/\s*$//os;

	if ($self->{_data}) {
	    $self->{_data} = $self->{_rsa}->decrypt(Cyphertext => $self->{_data},
						    Key => $self->{_private},
						    Armour => 1
					           );
	    $self->{_data} = Storable::thaw($self->{_data});
	} else {
	    $self->{_data} = {};
        }
    }

    if ($RESET || ! exists $self->{_data}->{$arg}) {
	$self->{_data}->{$arg} =
	    Term::ReadPassword::read_password(ref($self) .
					      " value for '$arg' not found," .
					      " please enter: ", 0, 1, 1);
    }
    return $self->{_data}->{$arg};
}
    
*encrypt = \&encrypted;

sub finished {

    if ($FH) {
	flock($FH, Fcntl::LOCK_UN());
	close($FH);
	undef $FH;
    }
}

*finish = \&finished;

sub DESTROY {

    my $self = shift;

    if ($self && ($FH || $FILE)) {
	unless ($FH) {
	    sysopen(FH, $FILE, Fcntl::O_RDWR() | Fcntl::O_CREAT())
		or croak "Can't open $FILE: $!";
	    flock(FH, Fcntl::LOCK_EX())
		or croak "Can't flock file: $!";
	    $FH = \*FH;
	}
	seek($FH, 0, 0);
	unless ($RESET) {
	    # need to rebuild our cryptosystem, ugh.
	    $self->{_public} = ref $PK ? $PK : new Crypt::RSA::Key::Public::SSH
		Filename => $PK || (File::HomeDir::home() . '/.ssh/identity.pub');
	    $self->{_private} = ref $SK ? $SK : new Crypt::RSA::Key::Private::SSH
		(Filename => $SK || (File::HomeDir::home() . '/.ssh/identity'),
		 Password => $PW );
	    $self->{_rsa} = new Crypt::RSA;
	    $self->{_data} = Storable::freeze($self->{_data});
	    $self->{_data} = $self->{_rsa}->encrypt(Message => $self->{_data},
						    Key => $self->{_public},
						    Armour => 1
					         );
	    print $FH $self->{_data};
	}
	delete $self->{_data};
    }

    unless (exists $INC{'Inline/Files.pm'} || ! $FILE) {
	flock($FH, Fcntl::LOCK_UN());
	close($FH);
	undef $FH;
    }

}

1;

__END__

=head1 NAME

Data::Encrypted - Transparently store encrypted data via RSA

=head1 SYNOPSIS

  # functional interface:
  use Data::Encrypted file => "./.$0-encrypted-data", qw(encrypted);

  # note: 'login' and 'password' are not *really* the login and
  # password values, only the desired prompt!
  my $login = encrypted('login');
  my $password = encrypted('password');

  # script continues, connecting to some secure resource (database,
  # website, etc).

  __END__

  # alternative, OO interface:
  use Data::Encrypted;

  my $enc = new Data::Encrypted file => "./.$0-encrypted-data";
  my $login = $enc->encrypted('login');
  my $password = $enc->encrypted('password');
  $enc->finished(); # close and release lock on storage file

  # script continues, connecting to some secure resource (database,
  # website, etc).

  __END__

  [ then, back at the command line: ]

  % myscript.pl
  Data::Encrypted value for 'login' not found, please enter: *****
  Data::Encrypted value for 'password' not found, please enter: ********
  [ script merrily continues ... ]

  % myscript.pl
  [ script merrily continues, no prompting this time ... ]

=head1 DESCRIPTION

Often when dealing with external resources (database engines, ftp,
telnet, websites, etc), your Perl script must supply a password, or
other sensitive data, to the other system.  This requires you to
either continually prompt the user for the data, or to store the
information (in plaintext) within your script.  You'd rather not have
to remember the connection details to all your different resources, so
you'd like to store the data somewhere.  And if you share your script
with anyone (as any good open-source developer would), you'd rather
not have your password or other sensitive information floating around.

Data::Encrypted attempts to fill this small void with a simple, yet
functional solution to this common predicament.  It works by prompting
you (via Term::ReadPassword) once for each required value, but only
does so the first time you run your script; thereafter, the data is
stored encrypted in a secondary file.  Subsequent executions of your
script use the encrypted data directly, if possible; otherwise it
again prompts for the data.  Currently, Data::Encrypted achieves
encryption via an RSA public-key cryptosystem implemented by
Crypt::RSA, using (by default) your own SSH1 public and private keys.

=head1 RSA Authentication

Data::Encrypted uses RSA authentication to encrypt and decrypt its
data.  It achieves this by reading the user's public and private RSA
keys.  By default, Data::Encrypted assumes these files are stored in
the .ssh subdirectory of their home directory (found using
File::HomeDir), but you can provide alternative key files yourself,
either by supplying alternative key filenames, or by building
Crypt::RSA::Key's yourself:


  use Data::Encrypted
  use Crypt::RSA::Key;

  my $public  = new Crypt::RSA::Key::Public::SSH
                   Filename => '~/.ssh/identity.pub';
  # my private key includes a passphrase!
  my $private = new Crypt::RSA::Key::Private::SSH
                   Filename => '~/.ssh/identity',
                   Password => q(These are the times that try men's souls);

  my $d = new Data::Encrypted (FILE => "~/.secret", PK => $public, SK => $private);
  my $password = $d->encrypted('password');

Or, more directly via the functional interface:

  use Data::Encrypted (FILE => './secret',
                       PK => '~/.ssh/identity.pub',
                       SK => '~/.ssh/identity',
                       PW => q(These are the times that try men's souls)
                      ), qw(encrypted);

  my $password = encrypted('password');


=head1 SSH1 vs. SSH2 and other public-key considerations

Data::Encrypted utilizes the facilities made available by Crypt::RSA,
and so is limited only by Crypt::RSA's ability to read and utilize
various public key formats.  Currently that means that only SSH
version 1 keys are usable.  Furthermore, keys which have been
themselves encrypted via use of a 'passphrase' are currently unusable
by Data::Encrypted -- future versions may overcome this limitation.

=head1 Encrypted Data Storage via Inline::Files

You may provide Data::Encrypted with a filename or already opened
filehandle for encrypted data storage; alternatively you may use
"virtual files" at the end of your script for encrypted data storage
via Inline::Files:

  use Inline::Files;
  use Data::Encrypted;

  open(ENCRYPT, '+<');

  my $enc = new Data::Encrypted fh => \*ENCRYPT;
  my $password = $enc->encrypted('password');

Then, Data::Encrypted will read/write it's data from the special
__ENCRYPT__ virtual file (see L<Inline::Files> for more information
and a better description of virtual files).  This way everything stays
contained within your script; no external storage file is necessary.
If you send the script to someone else, and they try to run it, the
RSA authentication will fail, but they will simply be prompted for the
values as you were when you first ran the script.  When they enter the
values the __ENCRYPT__ virtual file will be rewritten, and they may
continue to use the script.  In this way Data::Encrypted could be
though of as a "personalization" utility, ensuring that the encrypted
data can only be utilized by one person.

=head1 Resetting Encrypted Values

If, after the initial execution and value specification, you need to
reset or clear the stored values once so that you may specify new
ones, you can invoke your script like so:

  perl -MData::Encrypted=reset myscript.pl

Of course you could always just delete the already-encrypted data from
storage.

Alternatively, simply add the 'reset' imperative to your use
statement:

  use Data::Encrypted file => './secret', qw(encrypted reset);

This would force the user to enter the required data on every
invocation (which might be useful for yourself while you tried to
rememeber just what that lost database password was ...); even though
the encrypted data is available, it will be stored anew upon each
invocation.

=head1 Storage File Locking Issues

Data::Encrypted opens the storage file immediately upon specification
(via the use statement, or new object creation), and locks it for
exclusive use (or blocks until such a lock can be obtained).  It holds
this lock until the object is destroyed, or the script ends.  If you
wish the file to be closed and the lock to be released (so that other
scripts may use the file while your program continues running), you
should either undefine the encryption object you created, or call
finish() if using the functional interface:

# OO interface example:

my $enc = new Data::Encrypted file => "~/.sharedsecrets";
# ... use $enc->encrypted to retrieve encrypted data
undef $enc; # done using $enc, release the file lock
# ... continue running program

__END__

# functional interface example:

use Data::Encrypted qw(encrypted finish), file => "~/.sharedsecrets";
# ... use encrypted() to retrieve encrypted data
finish(); # done getting encrypted data, release the file lock
# ... continue running program

=head1 Real Life Examples

example #1 - a DBI session, utilizing virtual file storage:

  use DBI;
  use Inline::Files;
  use Data::Encrypted;

  open(ENCRYPT, '+<') or die $!;
  my $encryptor = new Data::Encrypted FH => \*ENCRYPT';

  my $dbh = DBI->connect('dbi:mysql:mydatabase',
                         $encryptor->encrypted('user name'),
                         $encryptor->encrypted('db password'),
                         { RaiseError => 1, AutoCommit => 1}
                        );
  [.. continue using $dbh ...]

example #2 - an FTP session, with 'reset' (will *always* prompt for
data until 'reset' is removed from use statement):

  use Net::FTP;
  use Data::Encrypted FILE => './.ftplogin', qw(encrypted reset);

  my $ftp = new Net::FTP 'ftp.somewhere.com';
  $ftp->login(encrypted('ftp user'),
              encrypted('ftp password'));
  $ftp->cwd('/pub');
  [... continue using $ftp ...]

example #3 - a POP3 email client session with keys in unguessable places:

  use Mail::POP3Client;
  use Crypt::RSA::Key;
  use Data::Encrypted;

  my $public = new Crypt::RSA::Key::Public::SSH
                 Filename => '~/.ssh/mykeys/public';

  my $public = new Crypt::RSA::Key::Private::SSH
                 Filename => '~/.ssh/mykeys/private'
                 Password => 'The Only Good Computer Is A Dead Computer';

  my $encryptor = new Data::Encrypted ( FILE => './.pop3email',
                                        SK   => $private,
                                        PK   => $public
                                      );

  my $pop3 = new Mail::POP3Client
               ( USER     => $encryptor->encrypted('user'),
                 PASSWORD => $encryptor->encrypted('password'),
                 HOST     => $encryptor->encrypted('host')
               );

example #4 - build a script to send to Bob that allows him to ftp
files from you, without passing along your connection information in
clear text; note that you yourself won't be able to actually use the
script without entering the data each time.  Also note that Bob could
easily read the encrypted information, so it is not secure from him.
It is only secure from prying third-parties.

  use Data::Encrypted;
  use Net::FTP;
  use Inline::Files;

  open(ENCRYPT, "+<") or die $!;
  my $encryptor = new Data::Encrypted FH => \*ENCRYPT,
                                      PK => '~/pubkeys/bob.pub';
  my $ftp = new Net::FTP "ftp.mysite.org";
  $ftp->login($encryptor->encrypted('user'),
              $encryptor->encrypted('password'));
  $ftp->cwd($encryptor->encrypted(q{Bob's directory}));
  $ftp->get($encryptor->encrypted(q{What Bob gets to download}));
  $ftp->quit();

=head1 BUGS/TODO

Inline::Files won't (yet) allow one package (i.e. Data::Encrypted) to
work with virtual files in another package (i.e. main); as a result,
you have to feed your virtual storage file to Data::Encrypted
manually.  Not so much a bug as an interface drawback.

Our usage of Inline::Files-generated filehandles is a bit noisy -
especially when first using "empty" virtual files (a known bug in
Inline::Files).  Damian Conway has said he'd think about trying to fix
it someday.

This idea could be extended to the Tie::EncryptedHash or other
Crypt::CBC-employing methodology, but would lose the fundamental
advantage of not requiring any clear text password or passphrase to
remain associated with the script.  Perhaps people wouldn't mind
typing one "universal" password or passphrase to get at their saved,
encrypted data ... ?

When Data::Encrypted prompts for unknown data, it could ask the user
to repeat their data entry for validation, to cut down on the
possibility of typos.

Currently the data is keyed via the prompt - hence if you use the same
prompt twice, the second piece of data will overwrite the first.

The data could be made to be "application-specific", so that the same
encrypted data storage file could be used for multiple applications
(without overwriting each other's data).  This could be as simple as
adding an additional dimenion to the hash, keying on $0 ...

When someone calls finish(), we close everything up ... but when
encrypted() is called, we don't ever check whether we've already
called finish, so this behavior is, uhmm, undefined I guess.

=head1 COPYRIGHT

Copyright (c) 2001 Aaron J Mackey. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Aaron J Mackey, amackey@virginia.edu

=head1 ORIGINAL IDEA

William R. Pearson, wrp@virginia.edu

=head1 SEE ALSO

Crypt::RSA, Inline::Files, Term::ReadPassword, File::HomeDir, perl(1).

=cut
