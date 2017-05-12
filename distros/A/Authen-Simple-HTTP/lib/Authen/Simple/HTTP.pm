package Authen::Simple::HTTP;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use LWP::UserAgent;
use Params::Validate qw[];

our $VERSION = 0.2;

__PACKAGE__->options({
    url => {
        type     => Params::Validate::SCALAR,
        optional => 0
    },
    agent => {
        type     => Params::Validate::OBJECT,
        isa      => 'LWP::UserAgent',
        default  => LWP::UserAgent->new(
            cookie_jar => {},
            keep_alive => 1,
            timeout    => 30
        ),
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    # This implementation is very hackish, however I could not find a cleaner
    # way to implement this without forking a lot of code from LWP::UserAgent.
    # Please let me know if you have any ideas of improvements.

    my $override = sprintf '%s::get_basic_credentials', ref $self->agent;
    my $response = undef;
    my $url      = $self->url;

    # First make sure we receive a challenge

    {
        no strict   'refs';
        no warnings 'redefine';

        local *$override = sub {
            return ( undef, undef );
        };

        $response = $self->agent->head($url);
    }

    if ( my $warning = $response->header('Client-Warning') ) {

        $self->log->error( qq/Received a client warning: '$warning'./ )
          if $self->log;

        return 0;
    }

    if ( $response->code != 401 ) {

        $self->log->error( qq/Server did not return a authentication challenge for '$url'./ )
          if $self->log;

        return 0;
    }

    # We have a challenge, issue a new request with credentials.

    {
        no strict   'refs';
        no warnings 'redefine';

        local *$override = sub {
            return ( $username, $password );
        };

        $response = $self->agent->head($url);
    }

    if ( $response->code == 401 ) {

        $self->log->debug( qq/Failed to authenticate user '$username' using url '$url'. Reason: 'Invalid credentials'/ )
          if $self->log;

        return 0;
    }

    if ( $response->is_error ) {

        my $code    = $response->code;
        my $message = $response->message;

        $self->log->error( qq/Failed to authenticate user '$username' using url '$url'. Reason: '$code $message'/ )
          if $self->log;

        return 0;
    }

    $self->log->debug( qq/Successfully authenticated user '$username' using url '$url'./ )
      if $self->log;

    return 1;
}

1;

__END__

=head1 NAME

Authen::Simple::HTTP - Simple HTTP authentication

=head1 SYNOPSIS

    use Authen::Simple::HTTP;
    
    my $http = Authen::Simple::HTTP->new( 
        url => 'http://www.host.com/protected'
    );
    
    if ( $http->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::HTTP

    PerlSetVar AuthenSimpleHTTP_url "http://www.host.com/protected"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::HTTP
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>    

=head1 DESCRIPTION

Authenticate against an HTTP server.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * url

Url to authenticate against. Required.

    url => 'http://www.host.com/protected'

=item * agent

Any object that is a subclass of L<LWP::UserAgent>.

    agent => LWP::UserAgent->new;

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::HTTP')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<LWP::UserAgent>.

L<LWPx::ParanoidAgent>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
