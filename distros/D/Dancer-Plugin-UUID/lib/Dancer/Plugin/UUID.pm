package Dancer::Plugin::UUID;

#ABSTRACT: Maintain unique identifiers for each visitor of the application.


use strict;
use warnings;
use feature ':5.10';
use Dancer ':syntax';
use Dancer::Plugin;
use Digest::SHA1 'sha1_hex';
use Data::UUID;

# constants
my $uuid_cookie_name = 'dancer.uuid';
my $drop_test_name   = 'dancer.uuid.test';

hook 'before' => sub {

    # if Do Not Track, do nothing
    return if request->env->{'HTTP_DNT'};

    # if we have a UUID already, return
    my $uuid = cookies->{$uuid_cookie_name};
    return if defined $uuid;

    # no UUID cookie is found, do we have the 'test cookie'?
    if ( defined cookies->{$drop_test_name} ) {

        # check the value, to make sure that's our cookie
        my $expected = _build_test_cookie_value();

        # the test cookie has the expected value, we can drop our UUID cookie
        if ( $expected eq cookies->{$drop_test_name}->value ) {
            my $uuid_fact = Data::UUID->new;
            $uuid = $uuid_fact->create();
            cookie $uuid_cookie_name => $uuid_fact->to_string($uuid),
              expires                => "3 years";
        }
    }

    # drop the test cookie, for the session
    cookie $drop_test_name => _build_test_cookie_value();
};

register uuid => sub {
    return _uuid_value();
};

hook 'before_template_render' => sub {
    my $tokens = shift;
    $tokens->{'dancer.uuid'} = _uuid_value();
};

# private

sub _build_test_cookie_value {
    return sha1_hex( __FILE__ );
}

sub _uuid_value {
    if ( !request->env->{HTTP_DNT} ) {
        my $uuid = cookies->{$uuid_cookie_name};
        return $uuid->value if defined $uuid;
    }
    undef;
}

register_plugin;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::UUID - Maintain unique identifiers for each visitor of the application.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::UUID;
      
    get ‘/someroute’ => sub {
       my $uid = uuid;
    };

=head1 DESCRIPTION 

This plugin takes care of dropping a cookie with a unique user identifier on
each visitor of the web application. The ID follows the
L<UUID|http://en.wikipedia.org/wiki/Universally_unique_identifier> spec and is
generated randomly on the second visit of the user.

Identifiers are generated with L<Data::UUID>.

The very first visit is used to drop a I<test cookie> to see if the client
accepts cookies. If not, then no cookie will be droped and the UUID for that
client will be C<undef>.

This plugin is useful if you wish to track your users on your application. 

This plugin honors the I<Do not track> policy and won’t drop any cookie when
this option is enabled in the client’s browser.

=head1 KEYWORDS

The plugin exports the following keywords.

=head2 C<uuid>

Returns the value of the UUID for the current user. If the browser refuses
cookies, or has the Do Not Track setting enabled, returns undef.

The cookie droped will expire in 3 years (which is almost the end of time for a
device in the Internet world).

=head1 HOOKS

When the plugin is loaded, it declares a C<before> hook that will be responsible
for dropping the UUID cookie. As it's impossible to know if the browser accepts
cookies without droping a cookie first, a test cookie is used on the first
visit.

If on the second visit, the test cookie is sent back by the browser, with a
legitimate value, it is assumed that the browser accepts cookies. The real UUID
cookie is then droped.

That means that the very first visits of the users won't be tracked (all users
are identified as "undef" users on their first visit).

=head1 AUTHOR

Alexis Sukrieh <sukria@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
