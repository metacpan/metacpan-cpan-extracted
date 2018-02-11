#!/usr/bin/env perl

# This demo application shows usage of the Dancer::Plugin::SPID module.
# See config.yml for its configuration.

use Dancer2;
use Dancer2::Plugin::SPID;

# We don't need to configure any custom route for SPID. See index.tt and user.tt
# for how to include the SPID button and the logout link.
get '/' => sub {
    # If we have an active SPID session, display a page with user attributes,
    # otherwise show a generic login page containing the SPID button.
    if (spid_session) {
        template 'user';
    } else {
        template 'index';
    }
};

# That's it. Seriously, that's all you need.
# Below you'll see how to customize the behavior further by configuring one or
# more hooks that the SPID plugin will call.

# This hook is called when the login endpoint is called and the AuthnRequest
# is about to be crafted.
hook 'plugin.SPID.before_login' => sub {
    # ...
};

# This hook is called after the SPID session was successfully initiated.
hook 'plugin.SPID.after_login' => sub {
    info "User " . spid_session->nameid . " logged in";
    
    # Here you might want to create the user in your local database or do more
    # things for initializing the session. Make sure everything you do here is
    # idempotent.
    
    # Log assertion as required by the SPID rules.
    # Warning: in order to comply with rules, this should be logged in a more
    # permanent way than regular Dancer logs, so you'd better use a database
    # or a dedicated log file.
    info "SPID Assertion: " . spid_session->assertion_xml;
};

# This hook is called when the logout endpoint is called and the LogoutRequest
# is about to be crafted.
hook 'plugin.SPID.before_logout' => sub {
    debug "User " . spid_session->nameid . " is about to logout";
};

# This hook is called when a SPID session is terminated (this might be triggered
# also when user initiated logout from another Service Provider or directly
# within the Identity Provider, thus without calling our logout endpoint and
# the 'before_logout' hook).
hook 'plugin.SPID.after_logout' => sub {
    my $success = shift;  # 'success' or 'partial'
    debug "User " . spid_session->nameid . " logged out";
};

dance;

__END__
