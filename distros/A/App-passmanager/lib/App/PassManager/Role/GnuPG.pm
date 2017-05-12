package App::PassManager::Role::GnuPG;
{
  $App::PassManager::Role::GnuPG::VERSION = '1.113580';
}

use Moose::Role;

use GnuPG::Interface;
use IO::Handle;
use IO::File;

has '_gnupg' => (
    is => 'ro',
    isa => 'GnuPG::Interface',
    reader => 'gnupg',
    lazy_build => 1,
);

# shared interface to local GnuPG process
sub _build__gnupg {
    my $gnupg = GnuPG::Interface->new();
    $gnupg->options->batch(1);
    return $gnupg;
}

sub decrypt_file {
    my ($self, $cryptfile, $passphrase) = @_;

    my ( $input, $output, $passphrase_fh ) = (
        IO::Handle->new(),
        IO::Handle->new(),
        IO::Handle->new(),
    );
    my $handles = GnuPG::Handles->new(
        passphrase => $passphrase_fh,
        stdin      => $input,
        stdout     => $output,
    );
    my $pid = $self->gnupg->decrypt( handles => $handles );

    # load the passphrase into memory-based filehandle
    print $passphrase_fh $passphrase;
    close $passphrase_fh;

    # load the crypted file from disk
    my $cipher_file = IO::File->new( $cryptfile );
    print $input $_ while <$cipher_file>;
    close $input;
    close $cipher_file;

    my @plaintext  = <$output>; # reading the output
    chomp @plaintext;

    # clean up...
    close $output;
    waitpid $pid, 0;  # clean up the finished GnuPG process

    return (wantarray ? @plaintext : $plaintext[0]);
}

sub encrypt_file {
    my ($self, $cryptfile, $passphrase, @plaintext) = @_;

    my ( $input, $output, $passphrase_fh ) = (
        IO::Handle->new(),
        IO::Handle->new(),
        IO::Handle->new(),
    );
    my $handles = GnuPG::Handles->new(
        passphrase => $passphrase_fh,
        stdin      => $input,
        stdout     => $output,
    );
    my $pid = $self->gnupg->encrypt_symmetrically( handles => $handles );

    # load the passphrase into memory-based filehandle
    print $passphrase_fh $passphrase;
    close $passphrase_fh;

    # slurp in the plaintext
    print $input (join '', @plaintext);
    close $input;

    # load the crypted file from disk
    my $cipher_file = IO::File->new( $cryptfile, '>' );
    print $cipher_file $_ while <$output>;

    # clean up...
    close $output;
    close $cipher_file;

    waitpid $pid, 0;  # clean up the finished GnuPG process
}

1;
