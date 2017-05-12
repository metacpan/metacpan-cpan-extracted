package Data::YADV::Checker;

use strict;
use warnings;

use Try::Tiny;
use Data::YADV::CheckerASub;

sub new {
    my ($class, $structure, %args) = @_;

    bless {structure => $structure, %args}, $class;
}

sub structure { $_[0]->{structure} }
sub schema    { $_[0]->{schema} }

sub check {
    my $self = shift;
    my ($structure, $factory) = $self->_prepare_arguments(@_) or return;

    $factory->($structure)->verify();
}

sub check_value {
    my $self  = shift;
    my $cb    = pop;
    my $child = $self->_prepare_structure(@_) or return;

    $self->schema->build_checker('Data::YADV::CheckerASub', $cb => $child)
      ->verify();
}

sub check_defined {
    my $self = shift;
    my $structure = $self->_prepare_structure(@_) or return;

    if (not defined $structure->get_structure) {
        $self->error('element not defined', @_);
    }
}

sub check_each {
    my $self = shift;
    my ($node, $factory) = $self->_prepare_arguments(@_) or return;

    return $self->error($node->get_type . ' is not iterable',
        @{$node->get_path})
      unless $node->can('each');

    $node->each(
        sub {
            my ($node, $key) = @_;
            $factory->($node)->verify($key);
        }
    );
}

sub _get_child {
    my ($self, $structure, @path) = @_;

    my $child = try {
        $structure->get_child(@path);
    }
    catch {
        $self->_error_against_structure($structure, $_, @path);
    };

    $self->_error_against_structure($structure, 'element not found', @path) unless defined $child;

    $child;
}

sub _prepare_structure {
    my ($self, @elements) = @_;

    my $structure = $elements[0];
    if (ref $structure && $structure->can('get_child')) {
        shift @elements;
    } else {
        $structure = $self->structure;
    }

    $self->_get_child($structure, @elements);
}

sub _prepare_arguments {
    my ($self, @elements) = @_;
    my $schema = pop @elements;

    my $structure = $self->_prepare_structure(@elements) or return;
    my $checker_factory = $self->_checker_factory($schema);

    ($structure, $checker_factory);
}

sub _checker_factory {
    my ($self, $schema) = @_;

    if (ref $schema eq 'CODE') {
        return sub {
            $self->schema->build_checker('Data::YADV::CheckerASub', $schema,
                @_);
          }
    }

    return sub {
        my $module = $self->schema->schema_to_module($schema);
        $self->schema->build_checker($module, @_);
    };
}

sub error {
    my $self = shift;

    $self->_error_against_structure($self->structure, @_);
}

sub _error_against_structure {
    my ($self, $structure, $message, @path) = @_;

    my $prefix = $structure->get_path_string(@path);
    $prefix = '$structure' . ($prefix ? '->' : '') . $prefix;

    $self->{error_cb}->($prefix, $message);
}

1;
