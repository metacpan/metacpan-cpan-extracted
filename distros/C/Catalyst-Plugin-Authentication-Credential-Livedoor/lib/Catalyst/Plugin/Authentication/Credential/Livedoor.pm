package Catalyst::Plugin::Authentication::Credential::Livedoor;

use strict;
use warnings;
our $VERSION = '0.03';

use NEXT;
use WebService::Livedoor::Auth;
use UNIVERSAL::require;

sub setup {
    my $c = shift;
    my $config = $c->config->{authentication}->{livedoor} || {};
    unless (exists $config->{ldauth_object}) {
        $config->{user_class} ||= 
            'Catalyst::Plugin::Authentication::User::Hash';
        $config->{user_class}->require;
        $config->{ldauth_object} = WebService::Livedoor::Auth->new({
            app_key => $config->{app_key},
            secret => $config->{secret},
        });
    }
    $c->NEXT::setup(@_);
}

sub authenticate_livedoor_url {
    my ($c, $query) = @_;
    $query ||= {};
    my %q;
    if ($c->config->{authentication}->{livedoor}->{get_livedoor_id}) {
        $q{perms} = 'id';
    }
    else {
        $q{perms} = 'userhash';
    }
    my $uri = $c->config->{authentication}->{livedoor}->{ldauth_object}->uri_to_login({%{$query}, %q});
}

sub authenticate_livedoor {
    my $c = shift;
    my $config = $c->config->{authentication}->{livedoor};
    my $auth = $config->{ldauth_object};
    if (my $res = $auth->validate_response($c->req)) {
        my $id = $res->userhash;
        if ($config->{get_livedoor_id}) {
            if (my $livedoor_id = $auth->get_livedoor_id($res)) {
                $id = $livedoor_id;
            } 
            else {
                $c->log->debug('failed to authenticate livedoor. Reason: %s', $auth->errstr)
                    if $c->debug;
                return;
            }
        }
        my $user = {
            userhash => $res->userhash,
            livedoor_id => $res->livedoor_id,
        };
        my $store = $config->{store} || $c->default_auth_store;
        if ($store and my $store_user = $store->get_user($id, $user)) {
            $c->set_authenticated($store_user);
        }
        else {
            $user = $config->{user_class}->new($user);
            $c->set_authenticated($user);
        }
        return 1;
    } 
    else {
        $c->log->debug('failed to authenticate livedoor. Reason: %s', $auth->errstr)
            if $c->debug;
        return;
    }
}


1;
__END__

=head1 NAME

Catalyst::Plugin::Authentication::Credential::Livedoor - livedoor Auth API for Catalyst.

=head1 SYNOPSIS

  use Catalyst qw(
      Authentication
      Authentication::Credential::Livedoor
      Session
      Session::Store::FastMmap
      Session::State::Cookie
  );

  MyApp->config(
     authentication => {
         livedoor => {
             app_key => '...',
             secret => '...',
             get_livedoor_id => 1,
         }
     }
  );
  
  sub login : Local {
      my( $self, $c ) = @_;
      $c->res->redirect( $c->authenticate_livedoor_url );
  }

  sub auth_callback : Local {
      my( $self, $c ) = @_;
      if ( $c->authenticate_livedoor ) {
          $c->res->redirect($c->uri_for('/'));
       }
       else {
          # login failed.
       }
  }



=head1 DESCRIPTION

Catalyst::Plugin::Authentication::Credential::Livedoor provides authentication via livedoor Auth API

=head1 AUTHOR

Tomohiro IKEBE E<lt>ikebe@shebang.jpE<gt>

=head1 SEE ALSO

http://auth.livedoor.com/

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
