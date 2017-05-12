# ABSTRACT: Dancer::Plugin::Authorize authentication via the Dancer configuration file!

package Dancer::Plugin::Authorize::Credentials::Config;
BEGIN {
  $Dancer::Plugin::Authorize::Credentials::Config::VERSION = '1.110720';
}

use strict;
use warnings;
use base qw/Dancer::Plugin::Authorize::Credentials/;


sub authorize {
    
    my ($self, $options, @arguments) = @_;
    my ($login, $password) = @arguments;
    
    my $settings = $Dancer::Plugin::Authorize::settings;
    
    if ($login) {
    
    # authorize a new account using supplied credentials
        
        my $accounts = $options->{accounts};
        
        unless ($password) {
            $self->errors('login and password are required');
            return 0;
        }
    
        if (defined $accounts->{$login}) {
            
            if (defined $accounts->{$login}->{password}) {
                
                if ($accounts->{$login}->{password} =~ /^$password$/) {
                    
                    my $session_data = {
                        id    => $login,
                        name  => $accounts->{$login}->{name} || ucfirst($login),
                        login => $login,
                        roles => [@{$accounts->{$login}->{roles}}],
                        error => []
                    };
                    return $self->credentials($session_data);
                    
                }
                else {
                    $self->errors('login and/or password is invalid');
                    return 0;
                }
                
            }
            else {
                $self->errors('attempting to access as inaccessible account');
                return 0;
            }
            
        }
        else {
            $self->errors('login and/or password is invalid');
            return 0;
        }
    
    }
    else {
        
    # check if current user session is authorized
        
        my $user = $self->credentials;
        if (($user->{id} || $user->{login}) && !@{$user->{error}}) {
            
            return $user;
            
        }
        else {
            $self->errors('you are not authorized', 'your session may have ended');
            return 0;
        }
        
    }
    
}

1;
__END__
=pod

=head1 NAME

Dancer::Plugin::Authorize::Credentials::Config - Dancer::Plugin::Authorize authentication via the Dancer configuration file!

=head1 VERSION

version 1.110720

=head1 SYNOPSIS

    # in your app code
    my $auth = auth($login, $password);
    if ($auth) {
        # login successful
    }
    
    # use your own encryption (if the user account password is encrypted)
    my $auth = auth($login, encrypt($password));
    if ($auth) {
        # login successful
    }

=head1 DESCRIPTION

Dancer::Plugin::Authorize::Credentials::Config uses your Dancer application
configuration file as the application's user management system.

=head1 METHODS

=head2 authorize

The authorize method (found in every authentication class) validates a user against
the defined datastore using the supplied arguments and configuration file options.

=head1 CONFIGURATION

    plugins:
      Authorize:
        credentials:
          class: Config
          options: 
            accounts:
              user01:
                name: Joe Schmoe
                password: foobar
                roles:
                  - guest
                  - user
              user02:
                name: Jacque Fock
                password: barbaz
                roles:
                  - admin

=head1 AUTHOR

  Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

