package CatalystX::ASP::Role;

use Moose::Role;

=head1 NAME

CatalystX::ASP::Role - Catalyst Role to plug-in the ASP View

=head1 SYNOPSIS

  package MyApp;

  use Moose;
  use Catalyst;
  extends 'Catalyst';

  with 'CatalystX::ASP::Role';

=head1 DESCRIPTION

Compose this role in your main application class. This will inject the ASP View
as View component in your app called 'ASP', accessible via
C<< $c->view('ASP') >>. It will also add a C<DispatchType> which will direct all
requests with C<.asp> extension to the View.

=head1 METHODS

=over

=item before 'setup_components'

Inject C<CatalystX::ASP::View> component as a View for your app

=cut

# Inject our View
before 'setup_components' => sub {
    my $class = shift;

    $class->inject_components(
        'View::ASP' => {
            from_component => 'CatalystX::ASP::View',
            }
    );

};

# Load ASP object and Global objects during setup
after 'setup_components' => sub {
    my $class = shift;

    my $asp = CatalystX::ASP->new(
        %{ $class->config->{'CatalystX::ASP'} },
        c               => $class,
        _setup_finished => 0,
    );
    $class->view( 'ASP' )->asp( $asp );
};

# Keep own copy of setup_finished
before 'setup_finalize' => sub {
    my ( $class ) = @_;

    my $asp = $class->view( 'ASP' )->asp;
    $asp->cleanup;
    $asp->_setup_finished( 1 );
};

=item after 'setup_dispatcher'

Load C<CatalystX::ASP::Dispatcher> as a C<DispatchType> for your app

=cut

# Register our DispatchType
after 'setup_dispatcher' => sub {
    my $c = shift;

    # Add our dispatcher
    push @{ $c->dispatcher->preload_dispatch_types }, '+CatalystX::ASP::Dispatcher';
};

no Moose::Role;

1;

=back

=head1 SEE ALSO

=over

=item * L<CatalystX::ASP::View>

=item * L<CatalystX::ASP::Dispatcher>

=back
