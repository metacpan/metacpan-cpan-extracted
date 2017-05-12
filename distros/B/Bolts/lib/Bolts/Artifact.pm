package Bolts::Artifact;
$Bolts::Artifact::VERSION = '0.143171';
# ABSTRACT: Tools for resolving an artifact value

use Moose;

with 'Bolts::Role::Artifact';

use Bolts::Util qw( locator_for meta_locator_for );
use Carp ();
use List::MoreUtils qw( all );
use Moose::Util::TypeConstraints;
use Safe::Isa;
use Scalar::Util qw( weaken reftype );


has init_locator => (
    is          => 'ro',
    does        => 'Bolts::Role::Locator',
    weak_ref    => 1,
);

with 'Bolts::Role::Initializer';


has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has blueprint => (
    is          => 'ro',
    does        => 'Bolts::Blueprint',
    required    => 1,
    traits      => [ 'Bolts::Initializer' ],
);


has scope => (
    is          => 'ro',
    does        => 'Bolts::Scope',
    required    => 1,
    traits      => [ 'Bolts::Initializer' ],
);


has infer => (
    is          => 'ro',
    isa         => enum([qw( none options acquisition )]),
    required    => 1,
    default     => 'none',
);


has inference_done => (
    reader      => 'is_inference_done',
    writer      => 'inference_is_done',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
    init_arg    => undef,
);


subtype 'Bolts::Injector::List',
     as 'ArrayRef',
  where { all { $_->$_does('Bolts::Injector') } @$_ };

has injectors => (
    is          => 'ro',
    isa         => 'Bolts::Injector::List',
    required    => 1,
    traits      => [ 'Array', 'Bolts::Initializer' ],
    handles     => {
        all_injectors => 'elements',
        add_injector  => 'push',
    },
    default     => sub { [] },
);


has does => (
    accessor    => 'does_type',
    isa         => 'Moose::Meta::TypeConstraint',
);


has isa => (
    accessor    => 'isa_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

no Moose::Util::TypeConstraints;


sub infer_injectors {
    my ($self, $bag) = @_;

    # use Data::Dumper;
    # warn Dumper($self);
    # $self->inference_is_done(1);

    # Use inferences to collect the list of injectors
    if ($self->infer ne 'none') {
        my $loc      = locator_for($bag);
        my $meta_loc = meta_locator_for($bag);

        my $inference_type = $self->infer;

        my $inferences = $meta_loc->acquire_all('inference');
        my %injectors = map { $_->key => $_ } $self->all_injectors;

        my @inferred_parameters;
        for my $inference (@$inferences) {
            push @inferred_parameters, 
                $inference->infer($self->blueprint);
        }

        # use Data::Dumper;
        # warn 'INFERRED: ', Dumper(\@inferred_parameters);

        PARAMETER: for my $inferred (@inferred_parameters) {
            my $key = $inferred->{key};

            next PARAMETER if defined $injectors{ $key };

            my %params = %$inferred;
            my $required = delete $params{required};
            my $via      = delete $params{inject_via};

            my $blueprint;
            if ($inference_type eq 'options') {
                $blueprint = $meta_loc->acquire('blueprint', 'given', { 
                    required => $required,
                });
            }
            else {
                $blueprint = $meta_loc->acquire('blueprint', 'acquired', {
                    locator => $loc,
                    path    => [ $key ],
                });
            }

            $params{blueprint} = $blueprint;

            my $injector = $meta_loc->acquire(@$via, \%params);
            unless (defined $injector) {
                Carp::carp(qq[Unable to acquire an injector for "$via".]);
                next PARAMETER;
            }
                
            $self->add_injector($injector);
        }
    }
}


sub such_that {
    my ($self, $such_that) = @_;

    # TODO Should probably do something special if on of the must_* are already
    # set. Maybe make sure the new things are compatible with the old? Maybe
    # setup a type union? Maybe croak? Maybe just carp? I don't know.

    $self->does_type($such_that->{does}) if defined $such_that->{does};
    $self->isa_type($such_that->{isa})   if defined $such_that->{isa};
}

# sub init_meta {
#     my ($self, $meta, $name) = @_;
# 
#     $self->blueprint->init_meta($meta, $name);
#     $self->scope->init_meta($meta, $name);
# 
#     # Add the actual artifact factory method
#     $meta->add_method($name => sub { $self });
# 
#     # # Add the actual artifact factory method
#     # $meta->add_method($name => sub {
#     #     my ($bag, %params) = @_;
#     #     return $self->get($bag, %params);
#     # });
# }


sub get {
    my ($self, $bag, %input_params) = @_;

    $self->infer_injectors($bag) unless $self->is_inference_done;

    my $name      = $self->name;
    my $blueprint = $self->blueprint;
    my $scope     = $self->scope;

    my $artifact;

    # Load the artifact from the scope unless the blueprint implies scope
    $artifact = $scope->get($bag, $name)
        unless $blueprint->implied_scope;

    # The scope does not have it, so load it again from blueprints
    if (not defined $artifact) {

        my @bp_params;
        for my $injector ($self->all_injectors) {
            $injector->pre_inject($bag, \%input_params, \@bp_params);
        }

        $artifact = $blueprint->get($bag, $name, @bp_params);

        for my $injector ($self->all_injectors) {
            $injector->post_inject($bag, \%input_params, $artifact);
        }

        # Carp::croak("unable to build artifact $name from blueprint")
        #     unless defined $artifact;

        # Add the item into the scope for possible reuse from cache
        $scope->put($bag, $name, $artifact)
            unless $blueprint->implied_scope;
    }

    # TODO This would be a much more helpful check to apply ahead of time in
    # cases where we can. Possibly some sort of such_that check on the
    # blueprints to be handled when such checks can be sensibly handled
    # ahead of time.

    my $isa  = $self->isa_type;
    my $does = $self->does_type;

    my $msg;
       $msg   = $isa->validate($artifact)  if defined $isa;
       $msg //= $does->validate($artifact) if defined $does;

    Carp::croak(qq[Constructed artifact named "$name" has the wrong type: $msg]) if $msg;

    return $artifact;
}

# sub inline_get {
#     my $blueprint_inline = $self->blueprint->inline_get;
#     my $scope_inline     = $self->scope->inline_scope;
# 
#     return q[
#         my ($self, $bag, %params) = @_;
#         my $artifact;
# 
#         ].$scope_inline.q[
# 
#         if (not defined $artifact) {
#             ].$blueprint_inline.q[
#         }
# 
#         return $artifact;
#     ];
# }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Artifact - Tools for resolving an artifact value

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        meta_locator => $meta,
        name         => 'key',
        blueprint    => [ 'blueprint', 'factory', {
            class => 'MyApp::Thing',
        } ],
        scope        => [ 'scope', 'singleton' ],
        infer        => 'acquisition',
        parameters   => {
            foo => [ 'blueprint', 'given', {
                isa => 'Str',
            } ],
            bar => value 42,
        },
    );

=head1 DESCRIPTION

This is the primary implementation of L<Bolts::Role::Artifact> with all the features described in L<Bolts>, including blueprint, scope, inferrence, injection, etc.

=head1 ROLES

=over

=item *

L<Bolts::Role::Artifact>

=item *

L<Bolts::Role::Initializer>

=back

=head1 ATTRIBUTES

=head2 init_locator

If provided with a references to the meta-locator for the bag to which the artifact is going to be attached, the L</blueprint>, L</scope>, and L</injectors> attributes may be given as initializers rather than as objects.

=head2 name

B<Required.> This sets the name of the artifact that is being created. This is passed through as part of scope resolution (L<Bolts::Scope>) and blueprint construction (L<Bolts::Blueprint>).

=head2 blueprint

B<Required.> This sets the L<Bolts::Blueprint> used to construct the artifact.

Instead of passing the blueprint object in directly, you can provide an initializer in an array reference, similar to what you would pass to C<acquire> to get the blueprint from the meta-locator, e.g.:

  blueprint => bolts_init('blueprint', 'acquire', {
      path => [ 'foo' ],
  }),

If so, you must provide an L</init_locator>.

=head2 scope

B<Required.> This sets the L<Bolts::Scope> used to manage the object's lifecycle.

Instead of passing the scope object in directly, you can provide an initializer in an array reference, similar to what you would pass to C<acquire> to get the scope from the meta-locator, e.g.:

  scope => bolts_init('scope', 'singleton'),

If so, you must provide a L</init_locator>.

=head2 infer

This is a setting that tells the artifact what kind of inferrence to perform when inferring injectors from the blueprint. This may e set to one of the following:

=over

=item none

B<Default.> When this is set, no inferrence is performed. The injectors will be defined according to L</dependencies> only.

=item options

This tells the artifact to infer the injection using the parameters passed to the call to L<Bolts::Role::Locator/acquire>. When the object is acquired and resolved, the caller will need to pass through any options needed for building the object.

=item acquisition

This tells the artifact to infer the injection using automatically acquired artifacts. The acquisition will happen from the bag containing the artifact with paths matching the name of the parameter.

B<Caution:> The way this work is likely to be customizeable in the future and the default behavior may differ.

=back

=head2 inference_done

This is an internal setting, which has a reader method named C<is_inference_done> and a writer named C<inference_is_done>. Do not use the writer directly unless you know what you are doing. You cannot set this attribute during construction.

Normally, this is a true value after the automatic inference of injectors has been completed and false before.

=head2 injectors

This is an array of L<Bolts::Injector>s, which are used to inject values into or after the construction process. Anything set here will take precedent over inferrence.

Instead of passing the array of injector objects in directly, you can provide an array of initializers, each as an array reference, similar to what you would pass to C<acquire> for each to get each injector from the meta-locator, e.g.:

  injector => [
      bolts_init('injector', 'parameter_name', {
          key       => 'foo',
          blueprint => bolts_init('blueprint', 'literal', {
              value => 42,
          }),
      }),
  ]

If so, you must provide a L</init_locator>.

=head2 does

This is used to control the role the artifact constructed must impement. Usually, this is not set directly, but set by the bag instead as an additional control on bag contents.

=head2 isa

This is used to control the type of the constructed artifact. Usually, this is not set directly, but set by the bag instead as an additional control on bag contents.

=head1 METHODS

=head2 infer_injectors

This performs the inference of L</injectors> based upon the L</infer> setting. This is called automatically when the artifact is resolved.

=head2 such_that

This is a helper for setting L</does> and L</isa>. The bag that contains the artifact normally calls this to enforce type constriants on the artifact.

=head2 get

This is called during the resolution phase of L<Bolts::Role::Locator> to either retrieve the object from the L</scope> or construct a new object according to the L</blueprint>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
