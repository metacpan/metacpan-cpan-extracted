package Authen::Htpasswd::User;
use strict;
use base 'Class::Accessor::Fast';
use Carp;
use Authen::Htpasswd;
use Authen::Htpasswd::Util;

use overload '""' => \&to_line, bool => sub { 1 }, fallback => 1;

__PACKAGE__->mk_accessors(qw/ file encrypt_hash check_hashes /);

=head1 NAME

Authen::Htpasswd::User - represents a user line in a .htpasswd file

=head1 SYNOPSIS

    my $user = Authen::Htpasswd::User->new($username, $password[, @extra_info], \%options);
    my $user = $pwfile->lookup_user($username); # from Authen::Htpasswd object
    
    if ($user->check_password($password)) { ... }
    if ($user->hashed_password eq $foo) { ... }
    
    # these are written immediately if the user was looked up from an Authen::Htpasswd object
    $user->username('bill');
    $user->password('bar');
    $user->hashed_password('tIYAwma5mxexA');
    $user->extra_info('root', 'joe@site.com', 'Joe Sysadmin');
    $user->set(username => 'bill', password => 'foo'); # set several at once
    
    print $user->to_line, "\n";
 
=head1 METHODS

=head2 new

    my $userobj = Authen::Htpasswd::User->new($username, $password[, @extra_info], \%options);

Creates a user object. You may also specify the arguments and options together in a hash: 
C<< { username => $foo, password => $bar, extra_info => [$email, $name], ... } >>.

=over 4

=item encrypt_hash

=item check_hashes

See L<Authen::Htpasswd>.

=item hashed_password

Explicitly sets the value of the hashed password, rather than generating it with C<password>.

=back

=cut

sub new {
    my $class = shift;
    croak "not enough arguments" if @_ < 2;
    
    my $self = ref $_[-1] eq 'HASH' ? pop @_ : {};
    $self->{encrypt_hash} ||= 'crypt';
    $self->{check_hashes} ||= [ Authen::Htpasswd::Util::supported_hashes() ];
    $self->{autocommit} = 1;

    $self->{username} = $_[0];
    $self->{hashed_password} ||= htpasswd_encrypt($self->{encrypt_hash}, $_[1]) if defined $_[1];
    $self->{extra_info} = [ @_[2..$#_] ] if defined $_[2];

    bless $self, $class;
}

=head2 check_password

    $userobj->check_password($password,\@check_hashes);

Returns whether the password matches. C<check_hashes> is the same as for Authen::Htpasswd.

=cut

sub check_password {
    my ($self,$password,$hashes) = @_;
    $hashes ||= $self->check_hashes;
    foreach my $hash (@$hashes) {
        return 1 if $self->hashed_password eq htpasswd_encrypt($hash, $password, $self->hashed_password);
    }
    return 0;
}

=head2 username

=head2 hashed_password

=head2 extra_info(@fields)

Get and set the fields of the user line. These methods, as well as C<password> and C<set> below, write 
any changes immediately if the user was lookup up from an Authen::Htpasswd object. If the username is
changed, the old entry is I<not> preserved.

=cut

sub username {
    my $self = shift;
    if (@_) {
        $self->{old_username} = $self->{username} if $self->{username} ne $_[0];
        $self->{username} = shift;
        $self->_update if $self->{autocommit};        
    }
    return $self->{username};
}

sub hashed_password {
    my $self = shift;
    if (@_) {
        $self->{hashed_password} = shift;
        $self->_update if $self->{autocommit};        
    }
    return $self->{hashed_password};
}

sub extra_info {
    my $self = shift;
    if (@_) {
        $self->{extra_info} = [ @_ ];
        $self->_update if $self->{autocommit};        
    }
    return $self->{extra_info};
}

=head2 password
    
    $userobj->password($newpass);

Encrypts a new password. Dies if C<$newpass> is not provided.

=cut

sub password {
    my ($self,$password) = @_;
    croak "you must provide a new password" unless defined $password;
    $self->hashed_password( htpasswd_encrypt($self->encrypt_hash, $password) );
}

=head2 set

    $userobj->set(item => $value, ...);

Sets any of the four preceding values at once. Only writes the file once if it is going to be written.

=cut

sub set {
    my ($self,%attr) = @_;
    $self->{autocommit} = 0;
    while (my ($key,$value) = each %attr) {
        croak "don't know how to set $key" unless $self->can($key);
        $self->$key(ref $value eq 'ARRAY' ? @$value : $value);
    }    
    $self->_update;        
    $self->{autocommit} = 1;
}

=head2 to_line

    $userobj->to_line;

Returns a line for the user, suitable for printing to a C<.htpasswd> file. There is no newline at the end.

=cut

sub to_line {
    my $self = shift;
    return join(':', $self->username, $self->hashed_password,
        defined $self->extra_info ? @{$self->extra_info} : ());
}

sub _update {
    my $self = shift;
    if ($self->file) {
        if (defined $self->{old_username}) {
            $self->file->delete_user($self->{old_username});
            delete $self->{old_username};            
        }
        $self->file->update_user($self);
    }
}

=head1 AUTHOR

David Kamholz C<dkamholz@cpan.org>

Yuval Kogman

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2005 - 2007 the aforementioned authors.
    
    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut

1;
