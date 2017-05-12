package Bolts::Inference::Moose;
$Bolts::Inference::Moose::VERSION = '0.143171';
# ABSTRACT: Inference engine for Moose classes

use Moose;

with 'Bolts::Inference';

use Class::Load ();
use Moose::Util ();


sub infer {
    my ($self, $blueprint) = @_;

    return unless $blueprint->isa('Bolts::Blueprint::Factory');

    my $class = $blueprint->class;
    Class::Load::load_class($class);

    my $meta = Moose::Util::find_meta($class);

    return unless defined $meta;

    my @parameters;
    ATTR: for my $attr ($meta->get_all_attributes) {
        my ($preferred_injector, $key);
        if (defined $attr->init_arg) {
            $preferred_injector = 'parameter_name';
            $key = $attr->init_arg;
        }
        elsif ($attr->has_write_method) {
            $preferred_injector = 'setter';
            $key = $attr->get_write_method;
        }
        else {
            next ATTR;
        }

        my $isa = $attr->type_constraint;
        push @parameters, {
            key        => $key,
            inject_via => [ 'injector', $preferred_injector ],
            (defined $isa ? (isa => $isa) : ()),
            required   => $attr->is_required,
        };
    }

    return @parameters;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Inference::Moose - Inference engine for Moose classes

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    package MyApp::Thing;
    use Moose;

    has id => ( is => 'ro' );
    has name => ( is => 'ro' );

    package MyApp::Settings;
    use Bolts;

    artifact thing => (
        class => 'MyApp::Thing',
        infer => 'options',
    );

    package MyApp;

    my $settings = MyApp::Settings->new;
    my $thing = $settings->acquire('thing', {
        id => 1,
        name => 'something',
    }); # works!

=head1 DESCRIPTION

Performs inferrence for L<Moose> object constructor injection on
L<Bolts::Blueprint::Factory>. That is, it is the way in which Bolts will
automatically guess how to build your Moose objects, provided you construct them
with L<Bolts::Blueprint::Factory> (see the L</SYNOPSIS> for an example).

This works by iterating through the attributes on the metaclass for the Moose
object set on the L<Bolts::Blueprint::Factory/class> of the blueprint. If the
attribute has an C<init_arg> set (which all do by default to a name matching the
attribute name), then the dependency will be passed to the constructor as a
parameter. If the C<init_arg> is undefined, but a setter is provided (i.e., you
use C<< isa => 'rw' >> or use C<< writer => 'set_attr' >> or C<< accessor =>
'attr' >> when setting up the attribute), the setter will be used for that
dependency instead. If neither a setter or an C<init_arg> is defined, then the
attribute will be skipped for injection.

=head1 ROLES

=over

=item *

L<Bolts::Inferrence>

=back

=head1 METHODS

=head2 infer

This implements the inferrence described in L</DESCRIPTION>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
