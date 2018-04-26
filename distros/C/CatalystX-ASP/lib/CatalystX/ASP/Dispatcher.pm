package CatalystX::ASP::Dispatcher;

use Moose;
use Moose::Util::TypeConstraints;
use Catalyst::Action;

extends 'Catalyst::DispatchType';

use Catalyst::Utils;
use Text::SimpleTable;

=head1 NAME

CatalystX::ASP::Dispatcher - Catalyst DispatchType to match .asp requests

=head1 SYNOPSIS

  package MyApp;

  after 'setup_dispatcher' => sub {
    push @{$shift->dispatcher->preload_dispatch_types}, '+CatalystX::ASP::Dispatcher';
  };

  __PACKAGE__->config('CatalystX::ASP' => {
    Dispatcher => {
      match_pattern => '\.asp$'
    }
  });

=head1 DESCRIPTION

This DispatchType will match any requests ending with .asp.

=cut

has 'default_action' => (
    is      => 'ro',
    isa     => 'Catalyst::Action',
    default => sub {
        return Catalyst::Action->new(
            name => 'asp',
            code => sub {
                my ( $self, $c, @args ) = @_;
                $c->forward( $c->view( 'ASP' ), \@args );
            },
            reverse    => '.asp',
            namespace  => '',
            class      => 'CatalystX::ASP::Controller',
            attributes => [qw(ASP)],
        );
    },
);

has '_config' => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => '_has_config',
);

coerce 'Regexp'
    => from 'Str'
    => via {qr/$_/i};

has 'match_pattern' => (
    is      => 'rw',
    isa     => 'Regexp',
    coerce  => 1,
    default => sub {qr/\.asp$/i},
);

has '_registered_actions' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    traits  => [qw(Hash)],
    handles => {
        _register_action => 'set',
    },
);

=head1 METHODS

=over

=item $self->list($c)

Debug output for ASP dispatch points

=cut

sub list {
    my ( $self, $c ) = @_;
    my $avail_width = Catalyst::Utils::term_width() - 9;
    my $col1_width  = ( $avail_width * .50 ) < 35 ? 35 : int( $avail_width * .50 );
    my $col2_width  = $avail_width - $col1_width;
    my $asp         = Text::SimpleTable->new(
        [ $col1_width, 'Path' ], [ $col2_width, 'Private' ]
    );
    $self->_init_config( $c->config->{'CatalystX::ASP'}{Dispatcher} );
    $asp->row( $self->match_pattern, '/asp' );

    $c->log->debug( "Loaded ASP actions:\n" . $asp->draw . "\n" );
}

=item $self->match($c, $path)

Checks if request path ends with .asp, and if file exists. Then creates custom
action to forward to ASP View.

=cut

sub match {
    my ( $self, $c, $path ) = @_;

    $self->_init_config( $c->config->{'CatalystX::ASP'}{Dispatcher} );
    my $match_pattern = $self->match_pattern;
    if ( $c->req->path =~ m/$match_pattern/ && -f $c->path_to( 'root', $c->req->path ) ) {
        $c->req->action( $path );
        $c->req->match( $path );
        $c->action( $self->default_action );
        $c->namespace( $self->default_action->namespace );
        return 1;
    }

    return 0;
}

=item $self->register( $c, $action )

Registers the generated action

=cut

sub register {
    my ( $self, $c, $action ) = @_;

    return $self->_register_action( $action->name => 1 ) if $action->attributes->{ASP};
}

=item $self->uri_for_action($action, $captures)

Get a URI part for an action

=cut

sub uri_for_action {
    my ( $self, $c, $action, $captures ) = @_;

    return $action->private_path;
}

sub _init_config {
    my ( $self, $config ) = @_;
    return if $self->_has_config;
    $self->_config( $config || {} );
    $self->$_( $config->{$_} ) for ( keys %$config );
}

__PACKAGE__->meta->make_immutable;

=back

=head1 SEE ALSO

=over

=item * L<CatalystX::ASP::Role>

=item * L<CatalystX::ASP::View>

=back
