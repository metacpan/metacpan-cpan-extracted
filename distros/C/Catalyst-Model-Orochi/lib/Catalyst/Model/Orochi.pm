package Catalyst::Model::Orochi;
use Moose;
use Orochi;
use namespace::autoclean;

our $VERSION = '0.00002';
our $AUTHORITY = 'cpan:DMAKI';

extends 'Catalyst::Model';

has assembler => (
    is => 'ro',
    isa => 'Orochi',
    lazy_build => 1,
);

has classes => (
    is => 'ro',
    isa => 'ArrayRef',
    predicate => 'has_classes',
);

has injections => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_injections',
);

has namespaces => (
    is => 'ro',
    isa => 'ArrayRef',
    predicate => 'has_namespaces'
);

has prefix => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_prefix',
);

sub _build_assembler {
    my $self = shift;
    my %args;
    if ($self->has_prefix) {
        $args{prefix} = $self->prefix;
    }
    return Orochi->new(%args);
}

sub BUILD {
    my $self = shift;

    foreach my $component qw(injections classes namespaces) {
        my $predicate = "has_$component";
        my $setup     = "setup_$component";
        if ( $self->$predicate() ) {
            $self->$setup();
        }
    }

    return $self;
}

sub setup_injections {
    my $self = shift;
    my $assembler = $self->assembler;
    while ( my($name, $value) = each %{ $self->injections }) {
        if ( ! blessed $value ) {
            $value = Orochi::Injection::Literal->new(value => $value);
        }
        $assembler->inject($name, $value);
    }
}

sub setup_classes {
    my $self = shift;
    my $assembler = $self->assembler;
    foreach my $class ( @{ $self->classes } ) {
        $assembler->inject_class( $class );
    }
}

sub setup_namespaces {
    my $self = shift;
    my $assembler = $self->assembler;
    foreach my $namespace ( @{ $self->namespaces } ) {
        $assembler->inject_namespace( $namespace );
    }
    return $self;
}

sub get {
    my $self = shift;
    $self->assembler->get(@_);
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Catalyst::Model::Orochi - Catalyst-Orochi Integration

=head1 SYNOPSIS

    # in your  MyApp::Model::Orochi
    package MyApp::Model::Orochi;
    use Moose;
    use namespace::autoclean;

    extends 'Catalyst::Model::Orochi';

    __PACKAGE__->meta->make_immutable();

    1;

    # in your config (watch out for indentation, this is YAML)
    Model::Orochi:
        injections: # for literal values
            name01: value01 
        classes:
            - ClassName01
            - ClassName02
        namespaces:
            - Namespace01
            - Namespace02
    
    # in your Catalyst code:

    my $value = $c->model('Orochi')->get('registered/path');

=head1 DESCRIPTION

This model integrates Orochi DI container with Catalyst. The same caveats from Orochi apply.

=head1 CONFIGURATION KEYS

=over 4

=item B<injections>

A hashref of literal values. Same as inject_literal() or Orochi::Injection::Literal

=item B<classes>

A list of class names. These classes should be using MooseX::Orochi. If the class does not use, or have an ancestor that uses MooseX::Orochi, the class will be silently ignored

=item B<namespaces>

A list of namespaces. Any class files found under the namespace that uses MooseX::Orochi will be included.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut