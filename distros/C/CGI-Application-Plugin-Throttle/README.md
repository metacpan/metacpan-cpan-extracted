NAME
    CGI::Application::Plugin::Throttle - Rate-Limiting for CGI::Application-based applications, using Redis for persistence.

SYNOPSIS

      use CGI::Application::Plugin::Throttle;


      # Your application
      sub setup {
        ...

        # Create a redis handle
        my $redis = Redis->new();

        # Configure throttling
        $self->throttle()->configure( redis => $redis,
                                      prefix => "REDIS:KEY:PREFIX",
                                      limit => 100,
                                      period => 60,
                                      exceeded => "slow_down_champ" );


DESCRIPTION
-----------

This module allows you to enforce a throttle on incoming requests to
your application, based upon the remote IP address.

This module stores a count of accesses in a Redis key-store, and once
hits from a particular source exceed the specified threshold the user
will be redirected to the run-mode you've specified.


POTENTIAL ISSUES / CONCERNS
---------------------------
Users who share IP addresses, because they are behind a common-gateway
for example, will all suffer if the threshold is too low. We attempt to
mitigate this by building the key using a combination of the remote IP
address, and the remote user-agent.

This module will apply to all run-modes, because it seems likely that
this is the most common case. If you have a preference for some modes to
be excluded please do contact the author.


AUTHOR
------
Steve Kemp <steve@steve.org.uk>

COPYRIGHT AND LICENSE
---------------------
Copyright (C) 2014 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

