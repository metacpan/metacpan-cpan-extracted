package Crypt::SimpleGPG;

=head1 NAME

Crypt::SimpleGPG - easy encryption and decryption using GPG

=head1 SYNOPSIS

=head2 Encrypting

    my $gpg = Crypt::SimpleGPG->new(home_dir = '/home/user/.gnupg');
    $gpg->import_key('/path/to/public/key');
    my $ciphertext = $gpg->encrypt($plaintext, $recipient);

=head2 Decrypting

    my $gpg = Crypt::SimpleGPG->new(home_dir = '/home/user/.gnupg');
    $gpg->import_key('/path/to/private/key');
    my $plaintext = $gpg->decrypt($ciphertext, $passphrase);

=head1 NOTES

C<home_dir> will default to C</var/tmp/gnupg> if not specified in the constructor. You probably don't want this, but it might be okay
if you're only using public keys.

C<temp_dir> will be used to store temporary files when decrypting using a passphrase.

=head1 COPYRIGHT

Copyright (c) 2010 Corey Cossentino

You may distribute under the terms of either the GNU General Public License or the Artistic License, as specified in the Perl README file.

=cut

use strict;
use warnings;

use IPC::Run;
use File::Temp qw(tempfile);
use Carp;

our $VERSION = "0.3";

my @options = qw( --batch --yes --armor --trust-model always --quiet --no-secmem-warning --no-permission-warning --no-tty --no-greeting );

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    $self = bless {}, $class;

    $self->__populate(@_);
    return $self;
}

sub __populate {
    my $self = shift;
    my %args = @_;

    $self->{home_dir} = $args{home_dir} || "/var/tmp/gnupg";
    $self->{gpg_path} = $args{gpg_path} || "/usr/bin/gpg";
    $self->{temp_dir} = $args{temp_dir} || "/var/tmp";
    $self->{debug} = $args{debug} || 0;

    if(not -d $self->{home_dir}) {
        mkdir($self->{home_dir})
            or confess "$self->{home_dir} is not a valid home directory";
    }

    if(not -e $self->{gpg_path}) {
        confess "$self->{gpg_path} does not exist";
    }

    if(not -x $self->{gpg_path}) {
        confess "$self->{gpg_path} is not executable";
    }

    if(not -w $self->{home_dir}) {
        confess "$self->{home_dir} is not writeable";
    }

    if(not -d $self->{temp_dir}) {
        confess "$self->{temp_dir} is not a valid directory";
    }

    if(not -w $self->{temp_dir}) {
        confess "$self->{temp_dir} is not writeable";
    }
}

sub import_key {
    my $self = shift;
    my $key_fn = shift;

    $self->__run(cmd_args => [ "--import", $key_fn ]);
}

sub encrypt {
    my $self = shift;
    my $plaintext = shift;
    my $recipient = shift;

    confess "No recipient." if not $recipient;

    my $ciphertext = $self->__run(cmd_args => [ "--output", "-", "--recipient", $recipient, "--encrypt", "-" ], stdin => $plaintext);
    return $ciphertext;
}

sub decrypt {
    my $self = shift;
    my $ciphertext = shift;
    my $passphrase = shift;
    
    my ($encfile_fh, $encfile_fn);

    my $args = [];
    if($passphrase) {
        ($encfile_fh, $encfile_fn) = tempfile("gpg_file_XXXXXXXXX", DIR => $self->{temp_dir});
        print $encfile_fh $ciphertext;
        close $encfile_fh;

        my $plaintext = $self->__run(cmd_args => [ "--passphrase-fd", "0", "--output", "-", $encfile_fn ], stdin => $passphrase);
        unlink $encfile_fn;

        return $plaintext;
    }
    else {
        my $plaintext = $self->__run(cmd_args => [ "-" ], stdin => $ciphertext);
        return $plaintext;
    }
}

sub __run {
    my ($self, %args) = @_;

    my ($stdin, $stdout, $stderr);
    my @cmd = ( $self->{gpg_path}, @options, "--homedir", $self->{home_dir}, @{$args{cmd_args}} );

    my $harness = IPC::Run::start( \@cmd, \$stdin, \$stdout, \$stderr, IPC::Run::timeout(10) );
    if($args{stdin}) {
        $stdin .= $args{stdin};
    }

    $harness->pump();
    $harness->finish();

    print STDERR $stderr if $self->{debug};
    return wantarray ? ($stdout, $stderr) : $stdout;
}

1;
