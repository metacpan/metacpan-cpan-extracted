package App::PasswordManager;

use strict;
use warnings;

use Crypt::PBKDF2;
use File::HomeDir;
use File::Spec;
use JSON;

our $VERSION = '1.0.0';

sub new {
    my ( $class, %args ) = @_;

    my $home_dir = File::HomeDir->my_home;
    my $file     = File::Spec->catfile( $home_dir, '.password_manager.json' );

    my $self = {
        pbkdf2     => Crypt::PBKDF2->new(
            hash_class => 'HMACSHA1',
            iterations => 10000,
            salt_len   => 10,
        ),
        data_file  => $args{file} || $file,
        salt       => 42,
        passwords  => {},
    };

    bless $self, $class;

    $self->_load_passwords();
    return $self;
}

sub add_password {
    my ( $self, $login, $password ) = @_;
    die "Login '$login' already exists!\n" if exists $self->{passwords}{$login};

    my $hashed_password = $self->{pbkdf2}->generate( $password, $self->{salt} );
    $self->{passwords}{$login} = {
        password => $hashed_password,
        salt     => $self->{salt},
    };
    $self->_save_passwords();
    return scalar keys %{ $self->{passwords} };
}

sub list_passwords {
    my ($self) = @_;
    return [ keys %{ $self->{passwords} } ];
}

sub remove_password {
    my ( $self, $login ) = @_;
    die "Login '$login' not found!\n" unless exists $self->{passwords}{$login};
    delete $self->{passwords}{$login};
    $self->_save_passwords();
    return 1;
}

sub edit_password {
    my ( $self, $login, $new_password ) = @_;
    die "Login '$login' not found!\n" unless exists $self->{passwords}{$login};

    my $hashed_password = $self->{pbkdf2}->generate( $new_password, $self->{salt} );
    $self->{passwords}{$login}{password} = $hashed_password;
    $self->{passwords}{$login}{salt}     = $self->{salt};
    $self->_save_passwords();
    return 1;
}

sub copy_to_clipboard {
    my ( $self, $login ) = @_;
    die "Login '$login' not found!\n" unless exists $self->{passwords}{$login};
    my $password = $self->{passwords}{$login}{password};
    open my $clip, '|-', 'xclip -selection clipboard'
      or die "Could not copy: $!";
    print $clip $password;
    close $clip;
    return 1;
}

sub _load_passwords {
    my ($self) = @_;
    if ( -e $self->{data_file} ) {
        open my $fh, '<', $self->{data_file} or die "Could not open file '$self->{data_file}': $!";
        local $/;
        my $json = <$fh>;
        close $fh;
        $self->{passwords} = decode_json($json) if $json;
    }
}

sub _save_passwords {
    my ($self) = @_;
    open my $fh, '>', $self->{data_file} or die "Could not open file '$self->{data_file}': $!";
    print $fh encode_json($self->{passwords});
    close $fh;
}

1;
__END__

=encoding utf-8

=head1 NAME

password_manager - Simple password manager for adding, listing, editing, deleting, and copying passwords to the clipboard.

=head1 SYNOPSIS

    password_manager [options]

=head1 DESCRIPTION

This script allows you to manage passwords in a simple way. Available operations include adding a new password, listing stored passwords, deleting an existing password, editing a password, and copying a password to the clipboard.

=head1 OPTIONS

=over 4

=item --add <login> <password>

Add a new password associated with the specified login.

Example:

    password_manager --add "my_login" "my_password"

=item --list

List all stored logins with their respective passwords.

Example:

    password_manager --list

=item --delete <login>

Delete the password associated with the specified login.

Example:

    password_manager --delete "my_login"

=item --edit <login> <new_password>

Edit the password associated with the specified login.

Example:

    password_manager --edit "my_login" "new_password"

=item --copy <login>

Copy the password associated with the specified login to the clipboard.

Example:

    password_manager --copy "my_login"

=item --help

Display this help message.

=back

=head1 EXAMPLES

Add a new password:

    password_manager --add "my_login" "my_password"

List all passwords:

    password_manager --list

Delete a password:

    password_manager --delete "my_login"

Edit a password:

    password_manager --edit "my_login" "new_password"

Copy a password to the clipboard:

    password_manager --copy "my_login"

=head1 ERRORS

If there is an error during any operation (such as adding, editing, or removing passwords), an error message will be displayed indicating the issue.

=head1 DEPENDENCIES

This script requires the L<Getopt::Long> module for command-line argument handling and the L<App::PasswordManager> module for password management operations.

=head1 AUTHOR

Luiz Felipe de Castro Vilas Boas <luizfelipecastrovb@gmail.com>

=head1 LICENSE

This module is released under the MIT License. See the LICENSE file for more details.

=cut
