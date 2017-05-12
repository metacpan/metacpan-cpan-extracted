package Bolts::Bag;
$Bolts::Bag::VERSION = '0.143171';
# ABSTRACT: Helper for creating bags containing artifacts

use Moose;

use Carp;
use Moose::Util::MetaRole;
use Moose::Util::TypeConstraints;
use Safe::Isa;
use Scalar::Util qw( blessed reftype );


sub start_bag {
    my ($class, %params) = @_;

    my $package        = $params{package};
    my $meta_locator   = $params{meta_locator};
    my $such_that_each = $params{such_that_each};

    my $meta;
    my %options = (superclasses => [ 'Moose::Object' ]);
    if (defined $package) {
        $meta = Moose::Util::find_meta($package);
        if (defined $meta) {
            return $meta;
        }

        $meta = Moose::Meta::Class->create($package, %options);
    }
    else {
        $meta = Moose::Meta::Class->create_anon_class(%options);
    }

    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $meta,
        roles => [ 'Bolts::Role::SelfLocator' ],
    );

    $meta = Moose::Util::MetaRole::apply_metaroles(
        for             => $meta,
        class_metaroles => {
            class => [ 
                'Bolts::Meta::Class::Trait::Locator',
                'Bolts::Meta::Class::Trait::Bag',
            ],
        },
    );

    if ($such_that_each) {
        my $such_that = $class->_expand_such_that($such_that_each);
        if (defined $such_that->{does}) {
            $meta->such_that_does($such_that->{does});
        }
        if (defined $such_that->{isa}) {
            $meta->such_that_isa($such_that->{isa});
        }
    }

    if ($meta_locator) {
        $meta->locator($meta_locator);
    }

    Carp::cluck("bad meta @{[$meta->name]}") unless $meta->can('locator');

    return $meta;
}

sub _expand_such_that {
    my ($class, $such_that) = @_;

    $such_that //= {};
    my %expanded_such_that;

    if (defined $such_that->{isa}) {
        $expanded_such_that{isa} = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint($such_that->{isa});
    }

    if (defined $such_that->{does}) {
        $expanded_such_that{does} = Moose::Util::TypeConstraints::find_or_create_does_type_constraint($such_that->{does});
    }

    return \%expanded_such_that;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Bag - Helper for creating bags containing artifacts

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    my $meta = Bolts::Bag->start_bag(
        package => 'MyApp::Holder',
    );

    # In case the definition already ran...
    unless ($meta->is_finished_bag) {
        $meta->add_artifact(logger => Bolts::Artifact->new(
            name      => 'logger',
            blueprint => $meta->locator->acquire('blueprint', 'factory', {
                class => 'MyApp::Logger',
            },
            infer => 'acquisition',
            scope => $meta->locator->acquire('scope', 'singleton'),
        ));

        $meta->add_artifact(log_file => "var/messages.log");

        $meta->add_artifact(config => sub {
            return YAML::LoadFile("etc/config.yml");
        });

        $meta->finish_bag;
    }

    my $bag = $meta->name->new;

=head1 DESCRIPTION

This is a helper for creating bag objects. Technically, any object may be treated as a bag. However, this is the way Bolts creates bags through the sugar API in L<Bolts> and some other internals. The primary benefit to creating this way is access to the bag meta locator during construction so you can use the standard blueprints, injectors, scopes, etc. in the standard way.

=head1 METHODS

=head2 start_bag

    my $meta = Bolts::Bag->start_bag(
        package        => 'MyApp::Bag',
        meta_locator   => Bolts::Meta::Locator->new,
        such_that_each => {
            does => 'MyApp::Role',
            isa  => 'MyApp::Thing',
        },
    );

This returns a L<Class::MOP::Class> object representing the bag you want to define. The returned meta class will be created new if it does not yet exist. If it does already exist (as determined by L<Moose::Util/find_meta>, the existing class will be returned.

It is good practice to always check to see if the definition of the bag has already been finished before continuing, which allows the definition code to be run more than once:

    if ($meta->is_finished_bag) {
        # some ->add_artifact calls here...
        
        $meta->finish_bag;
    }

You can then use the meta class to get an instance like so:

    my $bag = $meta->name->new(%params);

After getting the meta class returned from this class method, the remainder of the methods you need are found in L<Bolts::Meta::Class::Trait::Bag> and L<Bolts::Meta::Class::Trait::Locator>, which the returned object implement.

This class method takes the following parameters:

=over

=item C<package>

This is the package name to give the class within the Perl interpreter. If not given, the name will be anonymously chosen by L<Moose>. It will also never return a finished class.

=item C<meta_locator>

You may pass this in to customize the meta locator object to use with your class. This is L<Bolts::Meta::Locator> by default.

=item C<such_that_each>

This is used to limit the types of artifacts allowed within the bag. This is a hash that may contain one or both of these keys:

=over

=item C<does>

This names a L<Moose::Role> that all artifacts returned from this bag must implement.

=item C<isa>

This names a Moose type constraint that all artifacts returned from this bag must match.

=back

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
