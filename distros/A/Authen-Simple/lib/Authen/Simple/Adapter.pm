package Authen::Simple::Adapter;

use strict;
use warnings;
use base qw[Class::Accessor::Fast Class::Data::Inheritable];

use Authen::Simple::Log      qw[];
use Authen::Simple::Password qw[];
use Carp                     qw[];
use Params::Validate         qw[];

__PACKAGE__->mk_classdata( _options => { } );
__PACKAGE__->mk_accessors( qw[ cache callback log ] );

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;

    my $params = Params::Validate::validate_with(
        params => \@_,
        spec   => $class->options,
        called => "$class\::new"
    );

    return $class->SUPER::new->init($params);
}

sub init {
    my ( $self, $params ) = @_;

    while ( my ( $method, $value ) = each( %{ $params } ) ) {
        $self->$method($value);
    }

    return $self;
}

sub authenticate {
    my $self  = shift;
    my $class = ref($self) || $self;

    my ( $username, $password ) = Params::Validate::validate_with(
        params => \@_,
        spec   => [
            {
                type => Params::Validate::SCALAR
            },
            {
                type => Params::Validate::SCALAR
            }
        ],
        called => "$class\::authenticate"
    );

    my $status;

    if ( $self->callback ) {

        $status = $self->callback->( \$username, \$password );

        if ( defined $status ) {

            my $boolean = $status ? 'true' : 'false';

            $self->log->debug( qq/Callback returned a $boolean value '$status' for user '$username'./ )
              if $self->log;

            return $status;
        }
    }

    if ( $self->cache ) {

        $status = $self->cache->get("$username:$password");

        if ( defined $status ) {

            $self->log->debug( qq/Successfully authenticated user '$username' from cache./ )
              if $self->log;

            return $status;
        }
    }

    $status = $self->check( $username, $password );

    if ( $self->cache && $status ) {

        $self->cache->set( "$username:$password" => $status );
        
        $self->log->debug( qq/Caching successful authentication status '$status' for user '$username'./ )
          if $self->log;
    }

    return $status;
}

sub check {
    Carp::croak( __PACKAGE__ . qq/->check is an abstract method/ );
}

sub check_password {
    my $self = shift;
    return Authen::Simple::Password->check(@_);
}

sub options {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if ( @_ ) {

        my ($options) = Params::Validate::validate_pos( @_, { type => Params::Validate::HASHREF } );

        if ( my @create = grep { ! $class->can($_) } keys %{ $options } ) {
            $class->mk_accessors(@create);
        }

        $options->{cache} ||= {
            type     => Params::Validate::OBJECT,
            can      => [ qw[get set] ],
            optional => 1
        };

        $options->{callback} ||= {
            type     => Params::Validate::CODEREF,
            optional => 1
        };

        $options->{log} ||= {
            type     => Params::Validate::OBJECT,
            can      => [ qw[debug info error warn] ],
            default  => Authen::Simple::Log->new,
            optional => 1
        };

        $class->_options($options);
    }

    return $class->_options;
}

1;

__END__

=head1 NAME

Authen::Simple::Adapter - Adapter class for implementations

=head1 SYNOPSIS

    package Authenticate::Simple::Larry;
    
    use strict;
    use base 'Authen::Simple::Adapter';
    
    __PACKAGE__->options({
        secret => {
            type     => Params::Validate::SCALAR,
            default  => 'wall',
            optional => 1
        }
    });
    
    sub check {
        my ( $self, $username, $password ) = @_;
        
        if ( $username eq 'larry' && $password eq $self->secret ) {
            
            $self->log->debug( qq/Successfully authenticated user '$username'./ )
              if $self->log;
            
            return 1;
        }
        
        $self->log->debug( qq/Failed to authenticate user '$username'. Reason: 'Invalid credentials'/ )
          if $self->log;
        
        return 0;
    }
    
    1;

=head1 DESCRIPTION

Adapter class for implementations.

=head1 METHODS

=over 4

=item * new ( %parameters )

If overloaded, this method should take a hash of parameters. The following 
options should be valid:

=over 8

=item * cache ( $ )

Any object that supports C<get>, C<set>. Only successful authentications are cached.

    cache => Cache::FastMmap->new

=item * callback ( \& )

A subref that gets called with two scalar references, username and password.

    callback = sub {
        my ( $username, $password ) = @_;
        
        if ( length($$password) < 6 ) {
            return 0; # abort, invalid credintials
        }
        
        if ( $$password eq 'secret' ) {
            return 1; # abort, successful authentication
        }
        
        return; # proceed;
    }
    
=item * log ( $ )

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple')
    log => $r->log
    log => $r->server->log

=back

=item * init ( \%parameters )

This method is called after construction. It should assign parameters and return 
the instance.

    sub init {
        my ( $self, $parameters ) = @_;
        
        # mock with parameters
        
        return $self->SUPER::init($parameters);
    }

=item * authenticate ( $username, $password )

End user method. Applies callback, checks cache and calls C<check> unless 
aborted by callback or a cache hit.

=item * check ( $username, $password )

Must be implemented in sublcass, should return true on success and false on failure.

=item * check_password( $password, $encrypted )

=item * options ( \%options )

Must be set in subclass, should be a valid L<Params::Validate> specification. 
Accessors for options will be created unless defined in sublcass.

    __PACKAGE__->options({
        host => {
            type     => Params::Validate::SCALAR,
            optional => 0
        },
        port => {
            type     => Params::Validate::SCALAR,
            default  => 80,
            optional => 1
        }
    });

=back

=head1 SEE ALSO

L<Authen::Simple>

L<Authen::Simple::Password>

L<Params::Validate>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
