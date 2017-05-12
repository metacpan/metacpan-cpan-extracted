package MyApp::Data::Manager;
use namespace::autoclean;
use Moose;

extends 'Data::Manager';

use MyApp::Data::Visitor;

has _input => ( is => 'ro', isa => 'HashRef', init_arg => 'input' );

has actions => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

sub apply {
    my ($self) = @_;
    foreach my $scope ( keys %{ $self->verifiers } ) {
        my $results = $self->verify( $scope, $self->_input );
        return $self->actions->{$scope}->($results) if $results->success;
    }
    return;
}

sub errors {
    my $self = shift;
    my %errors;
    for my $msg ( @{ $self->messages->messages || [] } ) {
        $errors{ $msg->subject } = 'invalid'
          if $msg->msgid =~ /invalid/g;
        $errors{ $msg->subject } = 'missing'
          if $msg->msgid =~ /missing/g;
    }
    return unless scalar keys %errors;
    return \%errors;
}

around success => sub {
    my $orig = shift;
    my $self = shift;
    return !!( $self->$orig(@_) && scalar keys %{ $self->results } );
};

1;
