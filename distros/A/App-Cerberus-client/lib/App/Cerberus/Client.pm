package App::Cerberus::Client;
{
  $App::Cerberus::Client::VERSION = '0.08';
}

use strict;
use warnings;
use HTTP::Tiny();
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq );
use JSON();
use Carp;
use Any::URI::Escape;

our $JSON = JSON->new->utf8(1);

#===================================
sub new {
#===================================
    my ( $class, %conf ) = @_;
    my $servers = $conf{servers} || [];
    $servers = [$servers] unless ref $servers eq 'ARRAY';
    croak "No Cerebrus (servers) specified" unless @$servers;

    my $http = HTTP::Tiny->new( timeout => $conf{timeout} || 0.1 );
    bless {
        http    => $http,
        servers => [ shuffle uniq map { s{/?$}{/}; $_ } @$servers ]
    }, $class;
}

#===================================
sub request {
#===================================
    my $self   = shift;
    my %params = @_;
    my %failed;
    my $qs = '?' . join '&',
        map { uri_escape($_) . '=' . uri_escape( $params{$_} ) }
        keys %params;

    my $servers = $self->{servers};

    while (1) {
        my $server = shift @$servers;
        push @$servers, $server;
        last if $failed{$server}++;
        my $response = $self->{http}->get( $server . $qs );
        if ( $response->{success} ) {
            my $content = eval { $JSON->decode( $response->{content} ) }
                or warn "Decoding response from ($server): "
                . ( $@ || 'Unknown' ) . "\n"
                and next;
            return $content;
        }
        my $status = $response->{status};
        warn "Server $server: $status, $response->{reason}"
            . ( $status eq '599' ? ": " . $response->{content} : "\n" );
    }
    return {};
}

1;

# ABSTRACT: A multi-server client for speaking to App::Cerebrus


__END__
=pod

=head1 NAME

App::Cerberus::Client - A multi-server client for speaking to App::Cerebrus

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use App::Cerberus::Client;

    my $client = App::Cerberus::Client->new(
        servers => 'http://localhost:5000',
    );

    my $client = App::Cerberus::Client->new(
        servers => [
            'http://host1:5000',
            'http://host2:5000',
        ],
        timeout => 0.2
    );

    my $info = $client->request(
        ip => '80.1.2.3,
        ua => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
    );

=head1 DESCRIPTION

L<App::Cerberus::Client> is a simple HTTP client for talking to an
L<App::Cerberus> server.  If more than one server is specified, they will
be rotated in round robin fashion, and if any server fails, the next one will
be tried until one responds succesfully, or all servers have failed.

=head1 METHODS

=head2 new()

    $client = App::Cerberus::Client->new(
        servers => 'http://host1:5000',
     OR servers => [ 'http://host1:5000', 'http://host2:5000' ],

        timeout => 0.1,
    );

The C<servers> params accepts a single server or an array ref of servers.
The C<timeout> param is in seconds (defaults to 0.1 seconds).  Keep this low
as you don't want an overloaded L<App::Cerberus> server to become a bottleneck.

=head2 request()

    $info = $client->request(%params);

Sends a request to one of the configured servers, failing over to the next
server if there is any error.  If all servers fail, it returns an empty
hash-ref.

=head1 SEE ALSO

=over

=item L<App::Cerberus>

=item L<Dancer::Plugin::Cerberus>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

