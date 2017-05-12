package Authen::Htpasswd;
use 5.005;
use strict;
use base 'Class::Accessor::Fast';
use Carp;
use IO::File;
use IO::LockedFile;
use Authen::Htpasswd::User;
use Scalar::Util qw(blessed);

use vars qw{$VERSION $SUFFIX};

$VERSION = '0.171';
$VERSION = eval $VERSION;
$SUFFIX = '.new';

__PACKAGE__->mk_accessors(qw/ file encrypt_hash check_hashes /);

=head1 NAME

Authen::Htpasswd - interface to read and modify Apache .htpasswd files

=head1 SYNOPSIS
    
    my $pwfile = Authen::Htpasswd->new('user.txt', { encrypt_hash => 'md5' });
    
    # authenticate a user (checks all hash methods by default)
    if ($pwfile->check_user_password('bob', 'foo')) { ... }
    
    # modify the file (writes immediately)
    $pwfile->update_user('bob', $password, $info);
    $pwfile->add_user('jim', $password);
    $pwfile->delete_user('jim');
    
    # get user objects tied to a file
    my $user = $pwfile->lookup_user('bob');
    if ($user->check_password('vroom', [qw/ md5 sha1 /])) { ... } # only use secure hashes
    $user->password('foo'); # writes to file
    $user->set(password => 'bar', extra_info => 'editor'); # change more than one thing at once
    
    # or manage the file yourself
    my $user = Authen::Htpasswd::User->new('bill', { hashed_password => 'iQ.IuWbUIhlPE' });
    my $user = Authen::Htpasswd::User->new('bill', 'bar', 'staff', { encrypt_hash => 'crypt' });
    print PASSWD $user->to_line, "\n";

=head1 DESCRIPTION

This module provides a convenient, object-oriented interface to Apache-style
F<.htpasswd> files.

It supports passwords encrypted via MD5, SHA1, and crypt, as well as plain
(cleartext) passwords.

Additional fields after username and password, if present, are accessible via
the C<extra_info> array.

=head1 METHODS

=head2 new

    my $pwfile = Authen::Htpasswd->new($filename, \%options);

Creates an object for a given F<.htpasswd> file. Options:

=over 4

=item encrypt_hash

How passwords should be encrypted if a user is added or changed. Valid values are C<md5>, C<sha1>, 
C<crypt>, and C<plain>. Default is C<crypt>.

=item check_hashes

An array of hash methods to try when checking a password. The methods will be tried in the order
given. Default is C<md5>, C<sha1>, C<crypt>, C<plain>.

=back

=cut

sub new {
    my $class = shift;
    my $self  = ref $_[-1] eq 'HASH' ? pop @_ : {};
    $self->{file} = $_[0] if $_[0];
    croak "no file specified" unless $self->{file};
    if (!-e $self->{file}) {
        open my $file, '>', $self->{file} or die $!;
        close $file or die $!;
    }
    
    $self->{encrypt_hash} ||= 'crypt';        
    $self->{check_hashes} ||= [ Authen::Htpasswd::Util::supported_hashes() ];
    unless ( defined $self->{write_locking} ) {
        if ( $^O eq 'MSWin32' or $^O eq 'cygwin' ) {
            $self->{write_locking} = 0;
        } else {
            $self->{write_locking} = 1;
        }
    }
    
    bless $self, $class;
}

=head2 lookup_user
    
    my $userobj = $pwfile->lookup_user($username);

Returns an L<Authen::Htpasswd::User> object for the given user in the password file.

=cut

sub lookup_user {
    my ($self,$search_username) = @_;
    
    my $file = IO::LockedFile->new($self->file, 'r') or die $!;
    while (defined(my $line = <$file>)) {
        chomp $line;
        my ($username,$hashed_password,@extra_info) = split /:/, $line;
        if ($username eq $search_username) {
            $file->close or die $!;
            return Authen::Htpasswd::User->new($username,undef,@extra_info, {
                    file            => $self, 
                    hashed_password => $hashed_password,
                    encrypt_hash    => $self->encrypt_hash, 
                    check_hashes    => $self->check_hashes 
                });
        }
    }
    $file->close or die $!;
    return undef;
}

=head2 all_users

    my @users = $pwfile->all_users;

=cut

sub all_users {
    my $self = shift;

    my @users;
    my $file = IO::LockedFile->new($self->file, 'r') or die $!;
    while (defined(my $line = <$file>)) {
        chomp $line;
        my ($username,$hashed_password,@extra_info) = split /:/, $line;
        push(@users, Authen::Htpasswd::User->new($username,undef,@extra_info, {
                file => $self, 
                hashed_password => $hashed_password,
                encrypt_hash => $self->encrypt_hash, 
                check_hashes => $self->check_hashes 
            }));
    }
    $file->close or die $!;
    return @users;
}

=head2 check_user_password

    $pwfile->check_user_password($username,$password);

Returns whether the password is valid. Shortcut for 
C<< $pwfile->lookup_user($username)->check_password($password) >>.

=cut

sub check_user_password {
    my ($self,$username,$password) = @_;
    my $user = $self->lookup_user($username);
    croak "could not find user $username" unless $user;
    return $user->check_password($password);
}

=head2 update_user
    
    $pwfile->update_user($userobj);
    $pwfile->update_user($username, $password[, @extra_info], \%options);

Modifies the entry for a user saves it to the file. If the user entry does not
exist, it is created. The options in the second form are passed to L<Authen::Htpasswd::User>.

=cut

sub update_user {
    my $self = shift;
    my $user = $self->_get_user(@_);
    my $username = $user->username;

    my ($old,$new) = $self->_start_rewrite;
    my $seen = 0;
    while (defined(my $line = <$old>)) {
        if ($line =~ /^\Q$username\E:/) {
            chomp $line;
            my (undef,undef,@extra_info) = split /:/, $line;
            $user->{extra_info} ||= [ @extra_info ] if scalar @extra_info;
            $self->_print( $new, $user->to_line . "\n" );
            $seen++;
        } else {
            $self->_print( $new, $line );
        }
    }
    $self->_print( $new, $user->to_line . "\n" ) unless $seen;
    $self->_finish_rewrite($old,$new);
}

=head2 add_user

    $pwfile->add_user($userobj);
    $pwfile->add_user($username, $password[, @extra_info], \%options);

Adds a user entry to the file. If the user entry already exists, an exception is raised.
The options in the second form are passed to L<Authen::Htpasswd::User>.

=cut

sub add_user {
    my $self = shift;
    my $user = $self->_get_user(@_);
    my $username = $user->username;

    my ($old,$new) = $self->_start_rewrite;
    while (defined(my $line = <$old>)) {
        if ($line =~ /^\Q$username\E:/) {
            $self->_abort_rewrite($old,$new);
            croak "user $username already exists in " . $self->file . "!";
        }
        $self->_print( $new, $line );
    }
    $self->_print( $new, $user->to_line . "\n" );
    $self->_finish_rewrite($old,$new);
}

=head2 delete_user

    $pwfile->delete_user($userobj);
    $pwfile->delete_user($username);

Removes a user entry from the file.

=cut

sub delete_user {
    my $self = shift;
    my $username = blessed($_[0]) && $_[0]->isa('Authen::Htpasswd::User') ? $_[0]->username : $_[0];

    my ($old,$new) = $self->_start_rewrite;
    while (defined(my $line = <$old>)) {
        next if $line =~ /^\Q$username\E:/;
        $self->_print( $new, $line );
    }
    $self->_finish_rewrite($old,$new);
}

sub _print {
    my ($self,$new,$string) = @_;
    if ( $self->{write_locking} ) {
        print $new $string;
    } else {
        $$new .= $string;
    }
}

sub _get_user {
    my $self = shift;
    return $_[0] if blessed($_[0]) && $_[0]->isa('Authen::Htpasswd::User');
    my $attr = ref $_[-1] eq 'HASH' ? pop @_ : {};
    $attr->{encrypt_hash} ||= $self->encrypt_hash;
    $attr->{check_hashes} ||= $self->check_hashes;
    return Authen::Htpasswd::User->new(@_, $attr);
}

sub _start_rewrite {
    my $self = shift;
    if ( $self->{write_locking} ) {
        my $old = IO::LockedFile->new($self->file, 'r+') or die $!;
        my $new = IO::File->new($self->file . $SUFFIX, 'w') or die $!;
        return ($old,$new);
    } else {
        my $old = IO::File->new( $self->file, 'r' ) or die $!;
        my $new = "";
        return ($old, \$new);
    }
}

sub _finish_rewrite {
    my ($self,$old,$new) = @_;
    if ( $self->{write_locking} ) {
        $new->close or die $!;
        rename $self->file . $SUFFIX, $self->file or die $!;
        $old->close or die $!;
    } else {
        $old->close or die $!;
        $old = IO::File->new( $self->file, 'w' ) or die $!;
        print $old $$new;
        $old->close or die $!;
    }
}

sub _abort_rewrite {
    my ($self,$old,$new) = @_;
    if ( $self->{write_locking} ) {
      $new->close;
      $old->close;
      unlink $self->file . $SUFFIX;
    } else {
      $old->close;
    }
}

=head1 AUTHOR

David Kamholz C<dkamholz@cpan.org>

Yuval Kogman

=head1 SEE ALSO

L<Apache::Htpasswd>.

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2005 - 2007 the aforementioned authors.
        
    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut

1;
