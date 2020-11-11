NAME
----

CGI::Application::Plugin::Throttle - Rate-Limiting for CGI::Application

SYNOPSIS
--------

    use CGI::Application::Plugin::Throttle;
    
    
    # Your application
    sub setup {
        
      ...
      
      # Create a redis handle
      my $redis = Redis->new();
      
      # Configure throttling
      $self->throttle()->configure(
        redis     => $redis,
        prefix    => "REDIS:KEY:PREFIX",
        limit     => 100,
        period    => 60,
        exceeded  => "slow_down_champ"
      );
      
      ...
      
    }
    
    sub throttle_keys {
        my $self = shift;
        
        # do not throttle at all when returning `undef`
        return undef if %ENV{DEVELOPMENT};
        
        return (
            remote_addr => $ENV{REMOTE_ADDR},
            
            maybe
            pwd_recover => $self->_is_password_recovery
        );
    }
    
    sub throttle_spec {
        { pwd_recover => 1 } =>
        {  limit =>     5, period => 300, exceeded => 'stay_out' }
        
        { remote_addr => '127.0.0.1' }
        { limit => 10_000, period =>   1, exceeded => 'get_home' }
    }


DESCRIPTION
-----------

This module allows you to enforce a throttle on incoming requests to your
application, based upon the remote IP address, or other parameters.

This module stores a count of accesses in a Redis key-store, and once hits
exceed the specified threshold the user will be redirected to the run-mode
you've specified.


POTENTIAL ISSUES / CONCERNS
---------------------------
Users who share IP addresses, because they are behind a common-gateway for
example, will all suffer if the threshold is too low.  We attempt to mitigate
this by building the key using a combination of the remote IP address, and the
remote user-agent.

This module has added great flexibillity to change the parameters being used for
generating the redis key. It now also has the posibillity to select different
throttle rules specified by filters that need to match the parameters.


AUTHOR
------
Steve Kemp <steve@steve.org.uk>

CONTRIBUTORS
------------
Theo van Hoesel <tvanhoesel@perceptyx.com>

COPYRIGHT AND LICENSE
---------------------
Copyright (C) 2014 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under the
same terms as Perl itself.

