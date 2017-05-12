package Bot::Cobalt::Core::ContextMeta::Auth;
$Bot::Cobalt::Core::ContextMeta::Auth::VERSION = '0.021003';
use strictures 2;
use Carp;

use Bot::Cobalt::Common ':types';


use Moo;
extends 'Bot::Cobalt::Core::ContextMeta';


around add => sub {
  my ($orig, $self) = splice @_, 0, 2;
  ## auth->add(
  ##   Context  => $context,
  ##   Username => $username,
  ##   Host     => $host,
  ##   Level    => $level,
  ##   Flags    => $flags,
  ##   Alias    => $plugin_alias
  ## )
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  
  for my $required (qw/context nickname username host level/) {
    unless (defined $args{$required}) {
      carp "add() missing mandatory opt $required";
      return
    }
  }
  
  $args{alias} = scalar caller unless defined $args{alias};
  $args{flags} = {}            unless defined $args{flags};
  
  my $meta = {
    Alias => $args{alias},
    Username => $args{username},
    Host  => $args{host},
    Level => $args{level},
    Flags => $args{flags},
  };

  $self->$orig($args{context}, $args{nickname}, $meta)
};

sub level {
  my ($self, $context, $nickname) = @_;

  return 0
    unless defined $context
    and defined $nickname
    and exists $self->_list->{$context}
    and ref $self->_list->{$context}->{$nickname};
  
  $self->_list->{$context}->{$nickname}->{Level} // 0
}

sub set_flag {
  my ($self, $context, $nickname, $flag) = @_;

  return
    unless defined $context
    and defined $nickname
    and $flag
    and exists $self->_list->{$context} 
    and exists $self->_list->{$context}->{$nickname};
  
  $self->_list->{$context}->{$nickname}->{Flags}->{$flag} = 1
}

sub drop_flag {
  my ($self, $context, $nickname, $flag) = @_;

  return
    unless defined $context 
    and defined $nickname 
    and $flag
    and exists $self->_list->{$context} 
    and exists $self->_list->{$context}->{$nickname};

  delete $self->_list->{$context}->{$nickname}->{Flags}->{$flag}
}

sub has_flag {
  my ($self, $context, $nickname, $flag) = @_;

  return
    unless defined $context 
    and defined $nickname 
    and $flag
    and exists $self->_list->{$context} 
    and exists $self->_list->{$context}->{$nickname};

  $self->_list->{$context}->{$nickname}->{Flags}->{$flag}
}

sub flags {
  my ($self, $context, $nickname) = @_;

  return +{} unless exists $self->_list->{$context}
         and ref $self->_list->{$context}->{$nickname}
         and ref $self->_list->{$context}->{$nickname}->{Flags}
         and reftype $self->_list->{$context}->{$nickname}->{Flags} eq 'HASH';

  $self->_list->{$context}->{$nickname}->{Flags}
}

{ no warnings 'once'; *user = *username }
sub username {
  my ($self, $context, $nickname) = @_;
  
  return
    unless defined $context
    and defined $nickname
    and exists $self->_list->{$context}
    and ref $self->_list->{$context}->{$nickname};

  $self->_list->{$context}->{$nickname}->{Username}
}

sub host {
  my ($self, $context, $nickname) = @_;
  
  return
    unless defined $context 
    and defined $nickname
    and exists $self->_list->{$context}
    and ref $self->_list->{$context}->{$nickname};

  $self->_list->{$context}->{$nickname}->{Host}
}

sub alias {
  my ($self, $context, $nickname) = @_;

  return
    unless defined $context 
    and defined $nickname
    and exists $self->_list->{$context}
    and ref $self->_list->{$context}->{$nickname};

  $self->_list->{$context}->{$nickname}->{Alias}
}

sub move {
  my ($self, $context, $old, $new) = @_;
  ## User changed nicks, f.ex
  
  return unless exists $self->_list->{$context}->{$old};
  
  $self->_list->{$context}->{$new}
    = delete $self->_list->{$context}->{$old}
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Core::ContextMeta::Auth - Auth list management

=head1 SYNOPSIS

  my $auth_lev = $core->auth->level($context, $nickname);
  my $auth_usr = $core->auth->username($context, $nickname);

See below for a complete description of available methods.

=head1 DESCRIPTION

A ContextMeta subclass providing context-specific authorization state 
information.

This is used by plugins to manage or retrieve authorized user details.

=head2 add

  ->add(
    Alias    => $alias,
    Context  => $context,
    Nickname => $nickname,
    Username => $username,
    Host     => $host,
    Level    => $lev,
    Flags    => \%flags,
  );

Add a newly-authorized user.

Alias should generally be the result of a Core C<get_plugin_alias> 
method call.

=head2 level

  ->level($context, $nickname)

Return recognized level for specified nickname, or 0 for unknown 
nicknames.

=head2 username

  ->username($context, $nickname)

Return authorized username for a specified nickname, or empty list for 
unknown.

=head2 host

  ->host($context, $nickname)

Return recognized hostname for a specified nickname, or empty list for 
unknown.

=head2 flags

  ->flags($context, $nickname)

Return flags HASH for a specified nickname, or empty hashref for 
unknown.

=head2 has_flag

  ->has_flag($context, $nickname, $flag)

Return boolean value indicating whether a flag is named flag is enabled.

=head2 set_flag

  ->set_flag($context, $nickname, $flag)

Turn a named flag on for the specified nickname.

=head2 drop_flag

  ->drop_flag($context, $nickname, $flag)

Remove a named flag from the specified nickname.

=head2 move

  ->move($context, $old, $new)

Move an authorized state, such as when a user changes nicknames.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
