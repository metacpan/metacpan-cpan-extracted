package MyApp::Role::Verification;
use namespace::autoclean;
use Moose::Role;

use MyApp::Data::Manager;
use Data::Diver qw(Dive);

has verifiers => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    builder    => 'verifiers_specs'
);

has actions => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    builder    => 'action_specs'
);

requires 'verifiers_specs';
requires 'action_specs';

sub check {
    my ( $self, %args ) = @_;

    my $path  = delete $args{for};
    my $input = delete $args{with};

    my $verifier = Dive( $self->verifiers, split( /\./, $path ) );
    my $action   = Dive( $self->actions,   split( /\./, $path ) );

    return MyApp::Data::Manager->new(
        input     => $input,
        verifiers => { $path => $verifier },
        actions   => { $path => $action }
    );
}

sub execute {
    my ( $self, $c, %args ) = @_;

    my $dm     = $self->check(%args);
    my $result = $dm->apply;

    unless ( $dm->success ) {
        $c->stash->{rest} = { form_error => $dm->errors, error => 'form_error' };
        $c->res->code(400);
        $c->detach();
    }

    return wantarray ? ( $dm, $result ) : $result;
}

1;
