package CatalystX::Component::Traits;
{
  $CatalystX::Component::Traits::VERSION = '0.19';
}

use namespace::autoclean;
use Moose::Role;
use Carp;
use List::MoreUtils qw/firstidx any uniq/;
use Scalar::Util 'reftype';
use Class::Load qw/ load_first_existing_class /;
with 'MooseX::Traits::Pluggable' => { -excludes => ['_find_trait'] };

=head1 NAME

CatalystX::Component::Traits - Automatic Trait Loading and Resolution for Catalyst Components

=cut

our $AUTHORITY = 'id:RKITOVER';

=head1 SYNOPSIS

    package Catalyst::Model::SomeModel;
    with 'CatalystX::Component::Traits';

    package MyApp::Model::MyModel;
    use parent 'Catalyst::Model::SomeModel';

    package MyApp;

    __PACKAGE__->config('Model::MyModel' => {
        traits => ['SearchedForTrait', '+Fully::Qualified::Trait']
    });

=head1 DESCRIPTION

Adds a L<Catalyst::Component/COMPONENT> method to your L<Catalyst> component
base class that reads the optional C<traits> parameter from app and component
config and instantiates the component subclass with those traits using
L<MooseX::Traits/new_with_traits> from L<MooseX::Traits::Pluggable>.

=head1 TRAIT SEARCH

Trait names qualified with a C<+> are taken to be full package names.

Unqualified names are searched for, using the algorithm described below.

=head2 EXAMPLE

Suppose your inheritance hierarchy is:

    MyApp::Model::MyModel
    Catalyst::Model::CatModel
    Catalyst::Model
    Catalyst::Component
    Moose::Object

The configuration is:

    traits => ['Foo']

The package search order for C<Foo> will be:

    MyApp::TraitFor::Model::CatModel::Foo
    Catalyst::TraitFor::Model::CatModel::Foo

=head2 A MORE PATHOLOGICAL EXAMPLE

For:

    My::App::Controller::AController
    CatalystX::Something::ControllerBase::SomeController
    Catalyst::Controller
    Catalyst::Model
    Catalyst::Component
    Moose::Object

With:

    traits => ['Foo']

Search order for C<Foo> will be:

    My::App::TraitFor::Controller::SomeController::Foo
    CatalystX::Something::TraitFor::Controller::SomeController::Foo

The C<Base> after (M|V|C) is automatically removed.

=head1 TRAIT MERGING

Traits from component class config and app config are automatically merged if
you set the C<_trait_merge> attribute default, e.g.:

    has '+_trait_merge' => (default => 1);

You can remove component class config traits by prefixing their names with a
C<-> in the app config traits.

For example:

    package Catalyst::Model::Foo;
    has '+_trait_merge' => (default => 1);
    __PACKAGE__->config->{traits} = [qw/Foo Bar/];

    package MyApp;
    __PACKAGE__->config->{'Model::Foo'}{traits} = [qw/-Foo Baz/];

Will load the traits:

    Bar Baz

=cut

# override MX::Traits attribute
has '_trait_namespace' => (
    init_arg => undef,
    isa      => 'Str',
    (Moose->VERSION >= 0.84 ) ? (is => 'bare') : (),
    default  => '+Trait',
);

has '_trait_merge' => (
    init_arg => undef,
    isa      => 'Str',
    (Moose->VERSION >= 0.84 ) ? (is => 'bare') : (),
    default  => 0,
);

sub COMPONENT {
    my ($class, $app, $args) = @_;

    my %class_config = %{ $class->config };
    my %app_config   = %$args;

    my $traits = $class->_merge_traits(
        delete $class_config{traits},
        delete $app_config{traits},
    );

    $args = $class->merge_config_hashes(\%class_config, \%app_config);

    if ($traits) {
        return $class->new_with_traits($app, {
            traits => $traits,
            %$args
        });
    }

    return $class->new($app, $args);
}

sub _merge_traits {
    my $class        = shift;
    my $left_traits  = shift || [];
    my $right_traits = shift || [];

    my $should_merge =
        eval { $class->meta->find_attribute_by_name('_trait_merge')->default };
    $should_merge = $should_merge->()
        if ref($should_merge) && reftype($should_merge) eq 'CODE';

    my @right_traits = ref($right_traits) ? @$right_traits : $right_traits;
    my @left_traits  = ref($left_traits)  ? @$left_traits  : $left_traits;
    unless ($should_merge) {
        return @right_traits ? \@right_traits : \@left_traits;
    }

    my @to_remove = map { /^-(.*)/ ? $1 : () } @left_traits, @right_traits;
    @left_traits  = grep !/^-/, @left_traits;
    @right_traits = grep !/^-/, @right_traits;

    my @traits = grep {
        my $trait = $_;
        not any { $trait eq $_ } @to_remove;
    } (@left_traits, @right_traits);

    return [ uniq @traits ];
}

sub _find_trait {
    my ($class, $base, $name) = @_;

    load_first_existing_class($class->_trait_search_order($base, $name));
}

sub _trait_search_order {
    my ($class, $base, $name) = @_;

    my @search_ns = $class->meta->class_precedence_list;

    my $MVCC = qr/(?:Model|View|Controller|Component)/;

    my $possible_parent_idx =
        (firstidx { /^CatalystX?::/ } @search_ns[1 ..  $#search_ns]) + 1;

    my ($parent, $parent_idx, $parent_name, $parent_name_partial);

    for my $try_parent ($possible_parent_idx, 0) {
        $parent_idx = $try_parent;
        $parent     = $search_ns[$parent_idx];

        ($parent_name, $parent_name_partial) =
            $parent =~ /($MVCC(?:Base)? (?: ::)? (.*))/x;

        last if $parent_name_partial; # otherwise root level component
    }

    (my $resolved_parent_name = $parent_name) =~ s/($MVCC)Base\b/$1/;

    my ($parent_part) = $parent =~ /($MVCC) (?:Base)? (?: ::)?/x;

    my @res;

    for my $ns (@search_ns[0 .. $parent_idx]) {
        my $find_part = $parent_part;

        my ($part) = $ns =~ /^(.+?)::$parent_part/;
        push @res, "${part}::${base}For::${resolved_parent_name}::$name";
    }

    @res;
}

# we'll come back to this later...
#    for my $ns (@search_ns[($parent_idx+1) .. $#search_ns]) {
#       my ($part, $rest) = split /::/, $ns, 2;
#
#       # no non-core crap in the Moose:: namespace
#       $part = 'MooseX' if $part eq 'Moose';
#
#       push @res, "${part}::${base}For::${rest}::$name";
#    }
#
#    @res;
#}

=head1 AUTHOR

Rafael Kitover, C<< <rkitover@cpan.org> >>

=head1 CONTRIBUTORS

Tomas Doran, C<< <bobtfish@bobtfish.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalystx-component-traits
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-Component-Traits>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Matt S. Trout and Tomas Doran helped me with the current design.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014, Rafael Kitover

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__; # End of CatalystX::Component::Traits
