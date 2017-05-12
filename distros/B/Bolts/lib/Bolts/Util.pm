package Bolts::Util;
$Bolts::Util::VERSION = '0.143171';
# ABSTRACT: Utilities helpful for use with Bolts

use Moose ();
use Moose::Exporter;

use Bolts::Locator;
use Moose::Util;
use Safe::Isa;
use Hash::Util::FieldHash 'fieldhash';

use Bolts::Meta::Initializer;

Moose::Exporter->setup_import_methods(
    as_is => [ qw( bolts_init locator_for meta_locator_for ) ],
);

fieldhash my %locator;
fieldhash my %meta_locator;


sub _injector {
    my ($meta, $where, $type, $key, $params) = @_;

    my %params;

    if ($params->$_can('does') and $params->$_does('Bolts::Blueprint')) {
        %params = { blueprint => $params };
    }
    else {
        %params = %$params;
    }

    Carp::croak("invalid blueprint in $where $key")
        unless $params{blueprint}->$_can('does')
           and $params{blueprint}->$_does('Bolts::Blueprint::Role::Injector');

    $params{isa}  = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint($params{isa})
        if defined $params{isa};
    $params{does} = Moose::Util::TypeConstraints::find_or_create_does_type_constraint($params{does})
        if defined $params{does};

    $params{key} = $key;

    return $meta->acquire('injector', $type, \%params);
}

# TODO This sugar requires special knowledge of the built-in blueprint
# types. It would be slick if this was not required. On the other hand, that
# sounds like very deep magic and that might just be taking the magic too far.
sub artifact {
    my $meta = shift;
    my $name = shift;

    # No arguments means it's acquired with given parameters
    my $blueprint_name;
    my %params;
    if (@_ == 0) {
        $blueprint_name = 'acquired';
        $params{path}   = [ "__auto_$name" ];
        $meta->add_attribute("__auto_$name" =>
            is       => 'ro',
            init_arg => $name,
        );
    }

    # One argument means it's a literal or an artifact object
    elsif (@_ == 1) {

        # If it is an artifact, just return it as is
        return { $name => $_[0] }
            if $_[0]->$_can('does') && $_[0]->$_does('Bolts::Role::Artifact');

        $blueprint_name = 'literal';
        $params{value} = $_[0];
    }

    # Otherwise, we gotta figure out what it is...
    else {
        %params = @_;

        # Is the service class named?
        if (defined $params{blueprint}) {
            $blueprint_name = delete $params{blueprint};
        }

        # Is it an acquired?
        elsif (defined $params{path} && $params{path}) {
            $blueprint_name = 'acquired';

            $params{path} = [ $params{path} ] unless ref $params{path} eq 'ARRAY';

            my @path = ('__top', @{ $params{path} });

            $params{path} = \@path;
        }

        # Is it a literal?
        elsif (exists $params{value}) {
            $blueprint_name = 'literal';
        }

        # Is it a factory blueprint?
        elsif (defined $params{class}) {
            $blueprint_name = 'factory';
        }

        # Is it a builder blueprint?
        elsif (defined $params{builder}) {
            $blueprint_name = 'built';
        }

        else {
            Carp::croak("unable to determine what kind of service $name is in ", $meta->name);
        }
    }

    my @injectors;
    if (defined $params{parameters}) {
        my $parameters = delete $params{parameters};

        if ($parameters->$_does('Bolts::Blueprint')) {
            push @injectors, _injector(
                $meta, 'parameters', 'parameter_position',
                '0', { blueprint => $parameters },
            );
        }
        elsif (ref $parameters eq 'HASH') {
            for my $key (keys %$parameters) {
                push @injectors, _injector(
                    $meta, 'parameters', 'parameter_name', 
                    $key, $parameters->{$key},
                );
            }
        }
        elsif (ref $parameters eq 'ARRAY') {
            my $key = 0;
            for my $params (@$parameters) {
                push @injectors, _injector(
                    $meta, 'parameters', 'parameter_position',
                    $key++, $params,
                );
            }
        }
        else {
            Carp::croak("parameters must be a blueprint, an array of blueprints, or a hash with blueprint values");
        }
    }

    if (defined $params{setters}) {
        my $setters = delete $params{setters};

        for my $key (keys %$setters) {
            push @injectors, _injector(
                $meta, 'setters', 'setter',
                $key, $setters->{$key},
            );
        }
    }

    if (defined $params{indexes}) {
        my $indexes = delete $params{indexes};

        while (my ($index, $def) = splice @$indexes, 0, 2) {
            if (!Scalar::Util::blessed($def) && Scalar::Util::reftype($def) eq 'HASH') {
                $def->{position} //= $index;
            }

            push @injectors, _injector(
                $meta, 'indexes', 'store_array',
                $index, $def,
            );
        }
    }

    if (defined $params{push}) {
        my $push = delete $params{push};

        my $i = 0;
        for my $def (@$push) {
            my $key = $def->{key} // $i;

            push @injectors, _injector(
                $meta, 'push', 'store_array',
                $key, $def,
            );

            $i++;
        }
    }

    if (defined $params{keys}) {
        my $keys = delete $params{keys};

        for my $key (keys %$keys) {
            push @injectors, _injector(
                $meta, 'keys', 'store_hash',
                $key, $keys->{$key},
            );
        }
    }

    # TODO Remember the service for introspection

    my $scope_name = delete $params{scope} // '_';
    my $infer      = delete $params{infer} // 'none';

    my $scope      = $meta->acquire('scope', $scope_name);

    my $blueprint  = $meta->acquire('blueprint', $blueprint_name, \%params);

    return { 
        $name => Bolts::Artifact->new(
            meta_locator => $meta,
            name         => $name,
            blueprint    => $blueprint,
            scope        => $scope,
            infer        => $infer,
            injectors    => \@injectors,
        ),
    };
}


sub locator_for {
    my ($bag) = @_;

    if ($bag->$_does('Bolts::Role::Locator')) {
        return $bag;
    }
    elsif (defined $locator{ $bag }) {
        return $locator{ $bag };
    }
    else {
        return $locator{ $bag } = Bolts::Locator->new($bag);
    }
}


sub meta_locator_for {
    my ($bag) = @_;

    my $meta = Moose::Util::find_meta($bag);
    if (defined $meta) {
        my $meta_meta = Moose::Util::find_meta($meta);
        if ($meta_meta->$_can('does_role') && $meta_meta->does_role('Bolts::Meta::Class::Trait::Locator')) {
            return $meta->locator;
        }
    }

    elsif (defined $meta_locator{ $bag }) {
        return $meta_locator{ $bag };
    }

    return $meta_locator{ $bag } = $Bolts::GLOBAL_FALLBACK_META_LOCATOR->new;
}


sub bolts_init { Bolts::Meta::Initializer->new(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Util - Utilities helpful for use with Bolts

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts::Util qw( bolts_init locator_for meta_locator_for );

    my $loc   = locator_for($bag);
    my $thing = $loc->acquire('path', 'to', 'thing');

    my $metaloc = meta_locator_for($bag);
    my $blueprint = $metaloc->acquire('blueprint', 'factory', {
        class  => 'MyApp::Thing',
        method => 'fetch',
    });

    # See Bolts::Role::Initializer for a better synopsis
    my $obj = MyApp::Thing->new(
        foo => bolts_init('path', 'to', 'foo'),
    );

=head1 DESCRIPTION

This provides some helpful utility methods for use with Bolts.

=head1 EXPORTED FUNCTIONS

=head2 artifact

    my %artifact = %{ artifact($bag, $name, %definition) };

    # For example:
    my %artifact = %{ artifact($bag, thing => ( class => 'MyApp::Thing' ) ) };

This contains the internal implementation for building L<Bolt::Artifact> objects used by the sugar methods in L<Bolts> and L<Bolts::Role>. See the documentation L<there|Bolts/artifact> for more details on how to call it.

The C<$bag> must be the metaclass or reference to which the artifact is being attached. The C<$name> is the name to give the artifact and teh C<%definition> is the remainder of the definition.

This function returns a hash with a single key, which is the name of the artifact. The value on that key is an object that implements L<Bolts::Role::Artifact>.

=head2 locator_for

    my $loc = locator_for($bag);

Given a bag, it will return a L<Bolts::Role::Locator> for acquiring artifacts from it. If the bag provides it's own locator, the bag will be returned. If it doesn't (e.g., if it's a hash or an array or just some other object that doesn't have a locator built-in), then a new locator will be built to locate within the bag and returned on the first call. Subsequent calls using the same reference will return the same locator object.

=head2 meta_locator_for

    my $metaloc = meta_locator_for($bag);

Attempts to find the meta locator for the bag. It returns a L<Bolts::Role::Locator> that is able to return artifacts used to manage a collection of bolts bags and artifacts. If the bag itself does not have such a locator associated with it, one is constructed using the L<Bolts/$Bolts::GLOBAL_FALLBACK_META_LOCATOR> class, which is L<Bolts::Meta::Locator> by default. After the first call, the object created the first time for each reference will be reused.

=head2 bolts_init

    my $init = bolts_init(@path, \%params);

This is shorthand for:

    my $init = Bolts::Meta::Initializer->new(@path, \%params);

This returns an initializer object that may be used with L<Bolts::Role::Initializer> to automatically initialize attributes from a built-in locator.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
