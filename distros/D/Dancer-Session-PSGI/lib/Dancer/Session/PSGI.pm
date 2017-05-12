package Dancer::Session::PSGI;

# ABSTRACT: Let Plack::Middleware::Session handle Dancer's session

use strict;
use warnings;
our $VERSION = '0.01';

use Dancer::SharedData;
use base 'Dancer::Session::Abstract';

# session_name can't be set in config for this module
sub session_name {
    "plack_session";
}

sub create {
    return Dancer::Session::PSGI->new();
}

sub retrieve {
    my ($class, $id) = @_;
    my $session = Dancer::SharedData->request->{env}->{'psgix.session'};
    return Dancer::Session::PSGI->new(%$session);
}

sub flush {
    my $self = shift;
    my $session = Dancer::SharedData->request->{env}->{'psgix.session'};
    map {$session->{$_} = $self->{$_}} keys %$self;
    return $self;
}

sub destroy {
}

1;


__END__
=pod

=head1 NAME

Dancer::Session::PSGI - Let Plack::Middleware::Session handle Dancer's session

=head1 VERSION

version 0.01

=head1 SYNOPSIS

A basic psgi application

    use strict; use warnings;
    use Plack::Builder;

    my $app = sub {
        my $session = (shift)->{'psgix.session'};
        return [
            200,
            [ 'Content-Type' => 'text/plain' ],
            [ "Hello, you've been here for ", $session->{counter}++, "th time!" ],
        ];
    };

    builder { enable 'Session', store => 'File'; $app; };

In your app.psgi:

    builder {
        enable "Session", store => "File";
        sub { my $env = shift; my $request = Dancer::Request->new($env); Dancer->dance($request);};
    };

And a simple Dancer application:

   package session;
   use Dancer ':syntax';

    get '/' => sub {
        my $count = session("counter");
        session "counter" => ++$count;
        template 'index', {count => $count};
    };

Now, your two applications can share the same session informations.

=head1 DESCRIPTION

Dancer::Session::PSGI let you use C<Plack::Middleware::Session> as backend for your sessions.

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

