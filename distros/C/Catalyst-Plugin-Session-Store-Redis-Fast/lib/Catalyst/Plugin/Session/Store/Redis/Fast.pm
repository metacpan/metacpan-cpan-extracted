package Catalyst::Plugin::Session::Store::Redis::Fast;

our $VERSION = '1.001'; # VERSION

use warnings;
use strict;

use base qw/
    Class::Data::Inheritable
    Catalyst::Plugin::Session::Store
/;
use MRO::Compat;
use MIME::Base64 qw(encode_base64 decode_base64);
use Storable qw/nfreeze thaw/;
use Try::Tiny;
use Redis::Fast;

__PACKAGE__->mk_classdata(qw/_redis_connection/);

sub get_session_data {
    my ($c, $key) = @_;

    $c->_verify_redis_connection;

    if(my ($sid) = $key =~ /^expires:(.*)/) {
        $c->log->debug("Getting expires key for $sid");
        return $c->_redis_connection->get($key);
    } else {
        $c->log->debug("Getting $key");
        my $data = $c->_redis_connection->get($key);
        if(defined($data)) {
            return thaw( decode_base64($data) )
        }
    }

    return;
}

sub store_session_data {
    my ($c, $key, $data) = @_;

    $c->_verify_redis_connection;

    my $time = int($c->session_expires - time);
    if($time == 0) {
        $c->log->warn("skipping $key already expired at " . $c->session_expires );
    } else {
        if(my ($sid) = $key =~ /^expires:(.*)/) {
            $c->log->debug("Setting expires key for '$sid: $data' expiry seconds ($time)");
            $c->_redis_connection->setex($key, $time, $data);
        } else {
            $c->log->debug("Setting key '$key' with expiry seconds ($time)");
            $c->_redis_connection->setex($key, $time, encode_base64(nfreeze($data)));
        }
    }
    return;
}

sub delete_session_data {
    my ($c, $key) = @_;

    $c->_verify_redis_connection;

    $c->log->debug("Deleting: $key");
    $c->_redis_connection->del($key);

    return;
}

sub delete_expired_sessions {
    # my ($c) = @_;
    #redis will delete
}

sub setup_session {
    my ($c) = @_;

    $c->maybe::next::method(@_);
}

sub _verify_redis_connection {
    my ($c) = @_;

    my $cfg = $c->_session_plugin_config;
    $cfg->{server} //= '127.0.0.1:6379';

    try {
        $c->_redis_connection->ping;
    } catch {
        $c->_redis_connection(Redis::Fast->new( %$cfg ));
        if (defined $cfg->{select_db}) {
            $c->_redis_connection->select($cfg->{select_db});
        }
    };
}


1; # End of Catalyst::Plugin::Session::Store::Redis::Fast


=pod
 
=encoding UTF-8
 
=head1 NAME

    Catalyst::Plugin::Session::Store::Redis::Fast - Catalyst session store Redis Fast Plugin
    works with redis 2.0.0 and above
    Redis::Fast is 50% faster than Redis.pm

=head1 VERSION

Version 1.000

=head1 SYNOPSIS
 
    use Catalyst qw/
        Session
        Session::Store::Redis::Fast
        Session::State::Foo
    /;
     
    MyApp->config->{Plugin::Session} = {
        server       => '127.0.0.1:6379',   # Defaults to $ENV{REDIS_SERVER} or 127.0.0.1:6379
        sock         => '/path/to/socket',  #(optional) use unix socket
        reconnect    => 60,                 #(optional) Enable auto-reconnect
        every        => 500_000,            #(optional) Try to reconnect every 500ms up to 60 seconds until success
        encoding     => undef,              #(optional) Disable the automatic utf8 encoding => much more performance
        password     => 'TEST',             #(optional) default undef
        select_db    => 4,                  #(optional) will use the redis db default 0
    };
 
    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved
 
=head1 method

=head2 server (optional) either server or sock

    # Defaults to $ENV{REDIS_SERVER} or 127.0.0.1:6379
    MyApp->config->{Plugin::Session} = {
        server => '127.0.0.1:6379',
    }

=head2 sock (optional)

   # use unix socket
    MyApp->config->{Plugin::Session} = {
        sock    => '/path/to/socket',
    }

=head2 reconnect & every (optional)

    ## Enable auto-reconnect
    ## Try to reconnect every 500ms up to 60 seconds until success
    ## Die if you can't after that

    MyApp->config->{Plugin::Session} = {
        server    => '127.0.0.1:6379',
        reconnect => 60,
        every     => 500_000,
    }

=head2  name (optional)

     ## Set the connection name (requires Redis 2.6.9)

    MyApp->config->{Plugin::Session} = {
        server => '127.0.0.1:6379',
        name    => 'TEST',
    }

=head2  encoding (optional)

    ## Disable the automatic utf8 encoding => much more performance
    ## !!!! This will be the default after redis version 2.000

    MyApp->config->{Plugin::Session} = {
        server => '127.0.0.1:6379',
        enci    => 'TEST',
    }

=head2  password (optional)

    ## Sets the connection password

    MyApp->config->{Plugin::Session} = {
        server      => '127.0.0.1:6379',
         encoding   => undef
    }

=head2  select_db (optional)

    ## Selects db to be used for connection

    MyApp->config->{Plugin::Session} = {
        server      => '127.0.0.1:6379',
        select_db   => 3
    }

=head2 refer Redis::Fast for more connection method support

       no_auto_connect_on_new => 1,
       server => '127.0.0.1:6379',
       write_timeout => 0.2,
       read_timeout => 0.2,
       cnx_timeout => 0.2,


=head1 AUTHOR

Sushrut Pajai, C<< <spajai at cpan.org> >>

=head1 BUGS


Please report any bugs or feature requests to 

C<bug-catalyst-plugin-session-store-redis-fast at rt.cpan.org>, or through

the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Session-Store-Redis-Fast>.  

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=cut

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Session::Store::Redis::Fast


You can also look for information at:

=over 6

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Session-Store-Redis-Fast>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Session-Store-Redis-Fast>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Catalyst-Plugin-Session-Store-Redis-Fast>

=item * Search CPAN

L<https://metacpan.org/release/Catalyst-Plugin-Session-Store-Redis-Fast>

=item * github source code

L<https://github.com/spajai/Catalyst-Plugin-Session-Store-Redis-Fast>


=item * pull request

L<https://github.com/spajai/Catalyst-Plugin-Session-Store-Redis-Fast/pulls>


=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2021 by Sushrut Pajai

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language itself.

=cut