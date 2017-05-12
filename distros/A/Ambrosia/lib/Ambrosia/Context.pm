package Ambrosia::Context;
use strict;
use warnings;

use Ambrosia::Assert;
use Ambrosia::error::Exceptions;
use Ambrosia::DataProvider;
use Ambrosia::QL;
use Ambrosia::Utils::Container;
use Ambrosia::Utils::Queue;

use Ambrosia::Event qw/on_start on_abort on_finish/;

use Ambrosia::Meta;

class sealed {
    extends => [qw/Exporter/],
    public  => [qw/repository mqueue response_type resource_type resource_id method proxy/],
    private => [qw/__error __cgi/],
};

our $VERSION = 0.010;

our @EXPORT = qw/Context/;

sub new : Private
{
}

{
    my $_CONTEXT;

    sub instance
    {
        unless ( $_CONTEXT )
        {
            my $package = shift;
            my %params = @_ == 1 ? %{$_[0]} : @_;
            assert {$params{engine_name}} 'Context must instance before first call "Context" or you not set "engine_name" in params.';
            #throw Ambrosia::error::Exception::BadUsage('Context must instance before first call "Context"') unless $params{engine_name};

            my ($engine_name,$engine_params) = @params{qw/engine_name engine_params/};
            delete @params{qw/engine_name engine_params/};
            my $cgi = Ambrosia::core::ClassFactory::create_object(
                    'Ambrosia::CommonGatewayInterface::' . $engine_name, $engine_params);

            $_CONTEXT = $package->SUPER::new(__cgi => $cgi, %params);
        }
        return $_CONTEXT;
    }

    sub destroy
    {
        undef $_CONTEXT;
    }

    sub Context
    {
        no warnings;
        return __PACKAGE__->instance();
    }
}

sub start_session
{
    my $self = shift;
    $self->repository = new Ambrosia::Utils::Container;
    $self->mqueue = new Ambrosia::Utils::Queue;
    $self->init_request_params;
    $self->publicEvent('on_start');
}

sub abort_session
{
    my $self = shift;
    $self->repository = undef;
    $self->mqueue = undef;
    $self->__cgi->abort();
    $self->publicEvent( on_abort => $self->error() );
}

sub finish_session
{
    my $self = shift;
    $self->repository = undef;
    $self->mqueue = undef;
    $self->__cgi->close();
    $self->publicEvent( 'on_finish' );
}

sub print_response_header
{
    print shift()->__cgi->output_data(@_);
}

sub redirect
{
    my $self = shift;
    $self->__cgi->SET_REDIRECT();
    $self->__cgi->output_data(@_);
}

#TODO!!
sub handler
{
    $_[0]->__cgi->handler();
}

sub is_complete
{
    $_[0]->__cgi->IS_COMPLETE;
}

sub param
{
    return shift()->__cgi->handler()->param(@_) || undef;
}

sub action
{
    my $self = shift;

    return $self->param('action') || '*' unless $self->resource_type;

    if ( $self->method eq 'GET' || $self->method eq 'HEAD' )
    {
        return (defined $self->resource_id ? '/get/' : '/list/') . $self->resource_type
    }
    elsif ( $self->method eq 'POST' || $self->method eq 'DELETE' )
    {
        return '/save/' . $self->resource_type;
    }
    else
    {
        throw Ambrosia::error::Exception::BadUsage 'Unknown http method: "' . ($self->method || 'undefined' ) . '"';
    }
}

sub init_request_params
{
    my $self = shift;
    my $scriptName = $ENV{SCRIPT_NAME} or return;
    my $uri = $ENV{REQUEST_URI};
    $uri =~ s/^$scriptName//;

    my ($response_type, $resource_type, $resource_id) = ( $uri =~ m{/?(?:(html|xml|json|atom|rss)/)?([^?\\\/]*)(?:/([^?\\\/]+)?)?} );

    $self->response_type = lc($response_type) || 'html';
    $self->resource_type = $resource_type;
    $self->resource_id = $resource_id;
    $self->method = $ENV{REQUEST_METHOD};
}

sub script_path
{
    return $ENV{SCRIPT_NAME} || $0;
}

sub host_name
{
    $ENV{HTTP_HOST} ? (split /:/, $ENV{HTTP_HOST}, 2)[0] : chomp(my $hn = `hostname`)
}

sub host_path
{
    my $self = shift;
    my $scriptName = shift;

    if ( $ENV{HTTP_HOST} )
    {
        return host_name() . ($ENV{SERVER_PORT} eq '80' ? '' : ':' . $ENV{SERVER_PORT});
    }
    else
    {
        return host_name();
    }
}

sub full_script_path
{
    my $self = shift;

    if ( $ENV{HTTP_HOST} )
    {
        return 'http://' . $ENV{HTTP_HOST} . $ENV{SCRIPT_NAME};
    }
    else
    {
        return script_path();
    }
}

sub data
{
    my $self = shift;

    my %r;
    tie %r, 'Ambrosia::Utils::Container', $self->repository;

    return {
            script     => $self->proxy || $self->full_script_path,
            repository => \%r,
        };
}

sub error
{
    my $self = shift;
    $self->__error = join( '; ', @_ ) if @_;
    return $self->__error;
}

sub backup_uri
{
    my $self = shift;
    $self->host_path . '?action=' . $self->action . '&' . join '&', map {$_ . '=' . $self->param($_) } grep {defined $_} @{$self->param()};
}

1;

__END__

=head1 NAME

Ambrosia::Context - a context of application.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::Context;

    instance Ambrosia::Context( proxy => $URI )
        ->on_start( sub {
                instance Ambrosia::Plugin::Session(storage => new Ambrosia::Plugin::Session::Cookie())
            } )
        ->on_abort( sub {session->destroy} )
        ->on_finish( sub {session->destroy} );


=head1 DESCRIPTION

C<Ambrosia::Context> is a context of application.

=head1 CONSTRUCTOR

=head2 instance

Creates an object of type of C<Ambrosia::Context>.

=head1 METHODS

=head2 destroy

Destroys a context. You must call this method when session finished.

=head2 Context

Returns global an object of type of C<Ambrosia::Context>.

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
