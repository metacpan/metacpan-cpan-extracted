

use strict;
use warnings;

package Context::Singleton::Frame;

our $VERSION = v1.0.1;

use List::Util;
use Scalar::Util;

use Context::Singleton::Frame::DB;
use Context::Singleton::Exception::Invalid;
use Context::Singleton::Exception::Deduced;
use Context::Singleton::Exception::Nondeducible;
use Context::Singleton::Frame::Promise;
use Context::Singleton::Frame::Promise::Builder;
use Context::Singleton::Frame::Promise::Rule;

use overload (
    '""' => sub { ref ($_[0]) . '[' . $_[0]->{depth} . ']' },
    fallback => 1,
);

sub new {
    my ($class, %proclaim) = @_;
    my $self = {
        promises    => {},
        depth       => 0,
        db          => $class->default_db_instance,
    };

    if (ref $class) {
        $self->{root}   = $class->{root};
        $self->{parent} = $class;
        $self->{db}     = $class->{db};
        $self->{depth}  = $class->{depth} + 1;

        $class = ref $class;
    }

    unless ($self->{root}) {
        $self->{root} = $self;
        Scalar::Util::weaken $self->{root};
    }

    $self = bless $self, $class;

    $self->proclaim (%proclaim);

    return $self;
}

sub depth {
    $_[0]->{depth};
}

sub parent {
    $_[0]->{parent};
}

sub default_db_class {
    'Context::Singleton::Frame::DB';
}

sub default_db_instance {
    $_[0]->default_db_class->instance;
}

sub db {
    $_[0]->{db};
}

sub debug {
    my ($self, @message) = @_;

    my $sub = (caller(1))[3];
    $sub =~ s/^.*://;

    use feature 'say';
    say "# [${\ $self->depth}] $sub ${\ join ' ', @message }";
}

sub _build_builder_promise_for {
    my ($self, $builder) = @_;

    my $promise = $self->_class_builder_promise->new (
        depth   => $self->depth,
        builder => $builder,
    );

    my %optional = $builder->default;
    my %required = map +($_ => 1), $builder->required;
    delete @required{ keys %optional };

    $promise->add_dependencies (
        map $self->_search_promise_for ($_), keys %required
    );

    $promise->set_deducible (0) unless keys %required;

    $promise->listen ($self->_search_promise_for ($_))
        for keys %optional;

    $promise;
}

sub _build_rule_promise_for {
    my ($self, $rule) = @_;

    $self->{promises}{$rule} // do {
        my $promise = $self->{promises}{$rule} = $self->_class_rule_promise->new (
            depth => $self->depth,
            rule => $rule,
        );

        $promise->add_dependencies ($self->parent->_search_promise_for ($rule))
            if $self->parent;

        for my $builder ($self->db->find_builder_for ($rule)) {
            $promise->add_dependencies (
                $self->_build_builder_promise_for ($builder)
            );
        }

        $promise;
    };
}

sub _class_builder_promise {
    'Context::Singleton::Frame::Promise::Builder';
}

sub _class_rule_promise {
    'Context::Singleton::Frame::Promise::Rule';
}

sub _deduce_rule {
    my ($self, $rule) = @_;

    my $promise = $self->_search_promise_for( $rule );
    return $promise->value if $promise->is_deduced;

    my $builder_promise = $promise->deducible_builder;
    return $builder_promise->value if $builder_promise->is_deduced;

    my $builder = $builder_promise->builder;
    my %deduced = $builder->default;

    for my $dependency ($builder->required) {
        # dependencies with default values may not be deducible
        # relying on promises to detect deducible values
        next unless $self->is_deducible( $dependency );

        $deduced{$dependency} = $self->deduce ($dependency);
    }

    $builder->build (\%deduced);
}

sub _execute_triggers {
    my ($self, $rule, $value) = @_;

    $_->($value) for $self->db->find_trigger_for ($rule);
}

sub _find_promise_for {
    my ($self, $rule) = @_;

    $self->{promises}{$rule};
}

sub _frame_by_depth {
    my ($self, $depth) = @_;

    return if $depth < 0;

    my $distance = $self->depth - $depth;
    return if $distance < 0;

    my $found = $self;

    $found = $found->parent
        while $distance-- > 0;

    $found;
}

sub _root_frame {
    $_[0]->{root};
}

sub _search_promise_for {
    my ($self, $rule) = @_;

    $self->_find_promise_for ($rule)
        // $self->_build_rule_promise_for ($rule)
        ;
}

sub _set_promise_value {
    my ($self, $promise, $value) = @_;

    $promise->set_value ($value, $self->depth);
    $self->_execute_triggers ($promise->rule, $value);

    $value;
}

sub _throw_deduced {
    my ($self, $rule) = @_;

    throw Context::Singleton::Exception::Deduced ($rule);
}

sub _throw_nondeducible {
    my ($self, $rule) = @_;

    throw Context::Singleton::Exception::Nondeducible ($rule);
}

sub contrive {
    my ($self, $rule, @how) = @_;

    $self->db->contrive ($rule, @how);
}

sub deduce {
    my ($self, $rule, @proclaim) = @_;

    $self = $self->new (@proclaim) if @proclaim;

    $self->_throw_nondeducible ($rule)
        unless $self->try_deduce ($rule);

    $self->_find_promise_for ($rule)->value;
}

sub is_deduced {
    my ($self, $rule) = @_;

    return unless my $promise = $self->_find_promise_for ($rule);
    return $promise->is_deduced;
}

sub is_deducible {
    my ($self, $rule) = @_;

    return unless my $promise = $self->_search_promise_for ($rule);
    return $promise->is_deducible;
}

sub proclaim {
    my ($self, @proclaim) = @_;

    return unless @proclaim;

    my $retval;
    while (@proclaim) {
        my $key = shift @proclaim;
        my $value = shift @proclaim;

        my $promise = $self->_find_promise_for ($key)
            // $self->_build_rule_promise_for ($key)
            ;

        $self->_throw_deduced ($key)
            if $promise->is_deduced;

        $retval = $self->_set_promise_value ($promise, $value);
    }

    $retval;
}

sub try_deduce {
    my ($self, $rule) = @_;

    my $promise = $self->_search_promise_for ($rule);
    return unless $promise->is_deducible;

    my $value = $self
        ->_frame_by_depth ($promise->deduced_in_depth)
        ->_deduce_rule ($promise->rule);
        ;

    $promise->set_value ($value, $promise->deduced_in_depth);

    1;
}

1;

__END__

