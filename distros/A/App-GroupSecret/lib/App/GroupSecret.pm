package App::GroupSecret;
# ABSTRACT: A simple tool for maintaining a shared group secret


use warnings;
use strict;

our $VERSION = '0.304'; # VERSION

use App::GroupSecret::Crypt qw(generate_secure_random_bytes read_openssh_key_fingerprint);
use App::GroupSecret::File;
use Getopt::Long 2.38 qw(GetOptionsFromArray);
use MIME::Base64;
use Pod::Usage;
use namespace::clean;


sub new {
    my $class = shift;
    return bless {}, $class;
}


sub main {
    my $self = shift;
    my @args = @_;

    my $filepath    = '';
    my $help        = 0;
    my $man         = 0;
    my $version     = 0;
    my $private_key = '';

    # Parse options using pass_through so that we can pick out the global
    # options, wherever they are in the arg list, and leave the rest to be
    # parsed by each individual command.
    Getopt::Long::Configure('pass_through');
    GetOptionsFromArray(
        \@args,
        'file|f=s'          => \$filepath,
        'help|h|?'          => \$help,
        'manual|man'        => \$man,
        'private-key|k=s'   => \$private_key,
        'version|v'         => \$version,
    ) or pod2usage(2);
    Getopt::Long::Configure('default');

    pod2usage(-exitval => 1, -verbose => 99, -sections => [qw(SYNOPSIS OPTIONS COMMANDS)]) if $help;
    pod2usage(-verbose => 2) if $man;
    return print "groupsecret ${VERSION}\n" if $version;

    $self->{private_key} = $private_key if $private_key;
    $self->{filepath}    = $filepath    if $filepath;

    my %commands = (
        add_key         => 'add_key',
        add_keys        => 'add_key',
        change_secret   => 'set_secret',
        delete_key      => 'delete_key',
        delete_keys     => 'delete_key',
        list_keys       => 'list_keys',
        print           => 'print_secret',
        print_secret    => 'print_secret',
        remove_key      => 'delete_key',
        remove_keys     => 'delete_key',
        set_secret      => 'set_secret',
        show_secret     => 'print_secret',
        update_secret   => 'set_secret',
    );

    unshift @args, 'print' if !@args || $args[0] =~ /^-/;

    my $command = shift @args;
    my $lookup = $command;
    $lookup =~ s/-/_/g;
    my $method = '_action_' . ($commands{$lookup} || '');

    if (!$self->can($method)) {
        warn "Unknown command: $command\n";
        pod2usage(2);
    }

    $self->$method(@args);
}


sub filepath {
    shift->{filepath} ||= $ENV{GROUPSECRET_KEYFILE} || 'groupsecret.yml';
}


sub file {
    my $self = shift;
    return $self->{file} ||= App::GroupSecret::File->new($self->filepath);
}


sub private_key {
    shift->{private_key} ||= $ENV{GROUPSECRET_PRIVATE_KEY} || "$ENV{HOME}/.ssh/id_rsa";
}

sub _action_print_secret {
    my $self = shift;

    my $decrypt = 1;
    GetOptionsFromArray(
        \@_,
        'decrypt!' => \$decrypt,
    ) or pod2usage(2);

    my $file = $self->file;
    my $filepath = $file->filepath;
    die "No keyfile '$filepath' exists -- use the \`add-key' command to create one.\n"
        unless -e $filepath && !-d $filepath;
    die "No secret in keyfile '$filepath' exists -- use the \`set-secret' command to set one.\n"
        if !$file->secret;

    if ($decrypt) {
        my $private_key = $self->private_key;
        my $secret      = $file->decrypt_secret(private_key => $private_key) or die "No secret.\n";
        print $secret;
    }
    else {
        print $file->secret;
    }
}

sub _action_set_secret {
    my $self = shift;

    my $keep_passphrase = 0;
    GetOptionsFromArray(
        \@_,
        'keep-passphrase!' => \$keep_passphrase,
    ) or pod2usage(2);

    my $secret_spec = shift;
    if (!$secret_spec) {
        warn "You must specify a secret to set.\n";
        pod2usage(2);
    }

    my $passphrase;
    my $secret;

    if ($secret_spec =~ /^rand:(\d+)$/i) {
        my $rand = encode_base64(generate_secure_random_bytes($1), '');
        $secret = \$rand;
    }
    elsif ($secret_spec eq '-') {
        my $in = do { local $/; <STDIN> };
        $secret = \$in;
    }
    elsif ($secret_spec =~ /^file:(.*)$/i) {
        $secret = $1;
    }
    else {
        $secret = $secret_spec;
    }

    my $file = $self->file;

    if ($keep_passphrase) {
        my $private_key = $self->private_key;
        $passphrase = $file->decrypt_secret_passphrase($private_key);
        $file->encrypt_secret($secret, $passphrase);
    }
    else {
        $passphrase = generate_secure_random_bytes(32);
        $file->encrypt_secret($secret, $passphrase);
        $file->encrypt_secret_passphrase($passphrase);
    }

    $file->save;
}

sub _action_add_key {
    my $self = shift;

    my $embed   = 0;
    my $update  = 0;
    GetOptionsFromArray(
        \@_,
        'embed'     => \$embed,
        'update|u'  => \$update,
    ) or pod2usage(2);

    my $file = $self->file;
    my $keys = $file->keys;

    my $opts = {embed => $embed};

    for my $public_key (@_) {
        my $info = read_openssh_key_fingerprint($public_key);

        if ($keys->{$info->{fingerprint}} && !$update) {
            my $formatted_key = $file->format_key($info);
            print "SKIP\t$formatted_key\n";
            next;
        }

        if ($file->secret && !$opts->{passphrase}) {
            my $private_key = $self->private_key;
            my $passphrase  = $file->decrypt_secret_passphrase($private_key);
            $opts->{passphrase} = $passphrase;
        }

        local $opts->{fingerprint_info} = $info;
        my ($fingerprint, $key) = $file->add_key($public_key, $opts);

        local $key->{fingerprint} = $fingerprint;
        my $formatted_key = $file->format_key($key);
        print "ADD\t$formatted_key\n";
    }

    $file->save;
}

sub _action_delete_key {
    my $self = shift;

    my $file = $self->file;

    for my $fingerprint (@_) {
        if ($fingerprint =~ s/^(?:MD5|SHA1|SHA256)://) {
            $fingerprint =~ s/://g;
        }
        else {
            my $info = read_openssh_key_fingerprint($fingerprint);
            $fingerprint = $info->{fingerprint};
        }

        my $key = $file->keys->{$fingerprint};
        $file->delete_key($fingerprint) if $key;

        local $key->{fingerprint} = $fingerprint;
        my $formatted_key = $file->format_key($key);
        print "DELETE\t$formatted_key\n";
    }

    $file->save;
}

sub _action_list_keys {
    my $self = shift;

    my $file = $self->file;
    my $keys = $file->keys;

    while (my ($fingerprint, $key) = each %$keys) {
        local $key->{fingerprint} = $fingerprint;
        my $formatted_key = $file->format_key($key);
        print "$formatted_key\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GroupSecret - A simple tool for maintaining a shared group secret

=head1 VERSION

version 0.304

=head1 DESCRIPTION

This module is part of the command-line interface for managing keyfiles.

See L<groupsecret> for documentation.

=head1 METHODS

=head2 new

    $script = App::GroupSecret->new;

Construct a new script object.

=head2 main

    $script->main(@ARGV);

Run a command with the given command-line arguments.

=head2 filepath

    $filepath = $script->filepath;

Get the path to the keyfile.

=head2 file

    $file = $script->file;

Get the L<App::GroupSecret::File> instance for the keyfile.

=head2 private_key

    $filepath = $script->private_key;

Get the path to a private key used to decrypt the keyfile.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/groupsecret/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Charles McGarvey.

This is free software, licensed under:

  The MIT (X11) License

=cut
