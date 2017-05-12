package Catalyst::Controller::ActionRole; # git description: v0.16-10-ge946d48
# ABSTRACT: (DEPRECATED) Apply roles to action instances
our $VERSION = '0.17';
use Moose;
use Class::Load qw(load_class load_first_existing_class);
use Catalyst::Utils;
use Moose::Meta::Class;
use String::RewritePrefix 0.004;
use MooseX::Types::Moose qw/ArrayRef Str RoleName/;
use List::Util qw(first);
use namespace::autoclean;

extends 'Catalyst::Controller';

#pod =head1 DEPRECATION NOTICE
#pod
#pod As of version C<5.90013>, L<Catalyst> has merged this functionality into the
#pod core L<Catalyst::Controller>.  You should no longer use it for new development
#pod and we recommend switching to the core controller as soon as practical.
#pod
#pod =head1 SYNOPSIS
#pod
#pod     package MyApp::Controller::Foo;
#pod
#pod     use Moose;
#pod     use namespace::autoclean;
#pod
#pod     BEGIN { extends 'Catalyst::Controller::ActionRole' }
#pod
#pod     sub bar : Local Does('Moo') { ... }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module allows one to apply L<Moose::Role>s to the C<Catalyst::Action>s for
#pod different controller methods.
#pod
#pod For that a C<Does> attribute is provided. That attribute takes an argument,
#pod that determines the role, which is going to be applied. If that argument is
#pod prefixed with C<+>, it is assumed to be the full name of the role. If it's
#pod prefixed with C<~>, the name of your application followed by
#pod C<::ActionRole::> is prepended. If it isn't prefixed with C<+> or C<~>,
#pod the role name will be searched for in C<@INC> according to the rules for
#pod L<role prefix searching|/ROLE PREFIX SEARCHING>.
#pod
#pod It's possible to apply roles to B<all> actions of a controller without
#pod specifying the C<Does> keyword in every action definition:
#pod
#pod     package MyApp::Controller::Bar
#pod
#pod     use Moose;
#pod     use namespace::autoclean;
#pod
#pod     BEGIN { extends 'Catalyst::Controller::ActionRole' }
#pod
#pod     __PACKAGE__->config(
#pod         action_roles => ['Foo', '~Bar'],
#pod     );
#pod
#pod     # Has Catalyst::ActionRole::Foo and MyApp::ActionRole::Bar applied.
#pod     #
#pod     # If MyApp::ActionRole::Foo exists and is loadable, it will take
#pod     # precedence over Catalyst::ActionRole::Foo.
#pod     #
#pod     # If MyApp::ActionRole::Bar exists and is loadable, it will be loaded,
#pod     # but even if it doesn't exist Catalyst::ActionRole::Bar will not be loaded.
#pod     sub moo : Local { ... }
#pod
#pod Additionally, roles can be applied to selected actions without specifying
#pod C<Does> using L<Catalyst::Controller/action> and configured with
#pod L<Catalyst::Controller/action_args>:
#pod
#pod     package MyApp::Controller::Baz;
#pod
#pod     use Moose;
#pod     use namespace::autoclean;
#pod
#pod     BEGIN { extends 'Catalyst::Controller::ActionRole' }
#pod
#pod     __PACKAGE__->config(
#pod         action_roles => [qw( Foo )],
#pod         action       => {
#pod             some_action    => { Does => [qw( ~Bar )] },
#pod             another_action => { Does => [qw( +MyActionRole::Baz )] },
#pod         },
#pod         action_args  => {
#pod             another_action => { customarg => 'arg1' },
#pod         }
#pod     );
#pod
#pod     # has Catalyst::ActionRole::Foo and MyApp::ActionRole::Bar applied
#pod     sub some_action : Local { ... }
#pod
#pod     # has Catalyst::ActionRole::Foo and MyActionRole::Baz applied
#pod     # and associated action class would get additional arguments passed
#pod     sub another_action : Local { ... }
#pod
#pod =head1 ROLE PREFIX SEARCHING
#pod
#pod Roles specified with no prefix are looked up under a set of role prefixes.  The
#pod first prefix is always C<MyApp::ActionRole::> (with C<MyApp> replaced as
#pod appropriate for your application); the following prefixes are taken from the
#pod C<_action_role_prefix> attribute.
#pod
#pod =attr _action_role_prefix
#pod
#pod This class attribute stores an array reference of role prefixes to search for
#pod role names in if they aren't prefixed with C<+> or C<~>. It defaults to
#pod C<[ 'Catalyst::ActionRole::' ]>.  See L</role prefix searching>.
#pod
#pod =cut

__PACKAGE__->mk_classdata(qw/_action_role_prefix/);
__PACKAGE__->_action_role_prefix([ 'Catalyst::ActionRole::' ]);

#pod =attr _action_roles
#pod
#pod This attribute stores an array reference of role names that will be applied to
#pod every action of this controller. It can be set by passing a C<action_roles>
#pod argument to the constructor. The same expansions as for C<Does> will be
#pod performed.
#pod
#pod =cut

has _action_role_args => (
    traits     => [qw(Array)],
    isa        => ArrayRef[Str],
    init_arg   => 'action_roles',
    default    => sub { [] },
    handles    => {
        _action_role_args => 'elements',
    },
);

has _action_roles => (
    traits     => [qw(Array)],
    isa        => ArrayRef[RoleName],
    init_arg   => undef,
    lazy_build => 1,
    handles    => {
        _action_roles => 'elements',
    },
);

sub _build__action_roles {
    my $self = shift;
    my @roles = $self->_expand_role_shortname($self->_action_role_args);
    load_class($_) for @roles;
    return \@roles;
}

#pod =for Pod::Coverage BUILD
#pod
#pod =cut

sub BUILD {
    my $self = shift;
    # force this to run at object creation time
    $self->_action_roles;
}

around create_action => sub {
    my ($orig, $self, %args) = @_;

    return $self->$orig(%args)
        if $args{name} =~ /^_(DISPATCH|BEGIN|AUTO|ACTION|END)$/;

    my @roles = $self->gather_action_roles(%args);
    return $self->$orig(%args) unless @roles;

    load_class($_) for @roles;

    my $action_class = $self->_build_action_subclass(
        $self->action_class(%args), @roles,
    );

    my $action_args = $self->config->{action_args};
    my %extra_args = (
        %{ $action_args->{'*'}           || {} },
        %{ $action_args->{ $args{name} } || {} },
    );

    return $action_class->new({ %extra_args, %args });
};

#pod =method gather_action_roles(\%action_args)
#pod
#pod Gathers the list of roles to apply to an action with the given C<%action_args>.
#pod
#pod =cut

sub gather_action_roles {
    my ($self, %args) = @_;

    return (
        $self->_action_roles,
        @{ $args{attributes}->{Does} || [] },
    );
}
sub _build_action_subclass {
    my ($self, $action_class, @roles) = @_;

    my $meta = Moose::Meta::Class->initialize($action_class)->create_anon_class(
        superclasses => [$action_class],
        roles        => \@roles,
        cache        => 1,
    );
    $meta->add_method(meta => sub { $meta });

    return $meta->name;
}

sub _expand_role_shortname {
    my ($self, @shortnames) = @_;
    my $app = $self->_application;

    my $prefix = $self->can('_action_role_prefix')
        ? $self->_action_role_prefix
        : ['Catalyst::ActionRole::'];

    my @prefixes = (qq{${app}::ActionRole::}, @$prefix);

    return String::RewritePrefix->rewrite(
        {
            ''  => sub {
                my $loaded = load_first_existing_class(
                    map { "$_$_[0]" } @prefixes
                );
                return first { $loaded =~ /^$_/ }
                    sort { length $b <=> length $a } @prefixes;
            },
            '~' => $prefixes[0],
            '+' => '',
        },
        @shortnames,
    );
}

sub _parse_Does_attr {
    my ($self, $app, $name, $value) = @_;
    return Does => $self->_expand_role_shortname($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Controller::ActionRole - (DEPRECATED) Apply roles to action instances

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }

    sub bar : Local Does('Moo') { ... }

=head1 DESCRIPTION

This module allows one to apply L<Moose::Role>s to the C<Catalyst::Action>s for
different controller methods.

For that a C<Does> attribute is provided. That attribute takes an argument,
that determines the role, which is going to be applied. If that argument is
prefixed with C<+>, it is assumed to be the full name of the role. If it's
prefixed with C<~>, the name of your application followed by
C<::ActionRole::> is prepended. If it isn't prefixed with C<+> or C<~>,
the role name will be searched for in C<@INC> according to the rules for
L<role prefix searching|/ROLE PREFIX SEARCHING>.

It's possible to apply roles to B<all> actions of a controller without
specifying the C<Does> keyword in every action definition:

    package MyApp::Controller::Bar

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }

    __PACKAGE__->config(
        action_roles => ['Foo', '~Bar'],
    );

    # Has Catalyst::ActionRole::Foo and MyApp::ActionRole::Bar applied.
    #
    # If MyApp::ActionRole::Foo exists and is loadable, it will take
    # precedence over Catalyst::ActionRole::Foo.
    #
    # If MyApp::ActionRole::Bar exists and is loadable, it will be loaded,
    # but even if it doesn't exist Catalyst::ActionRole::Bar will not be loaded.
    sub moo : Local { ... }

Additionally, roles can be applied to selected actions without specifying
C<Does> using L<Catalyst::Controller/action> and configured with
L<Catalyst::Controller/action_args>:

    package MyApp::Controller::Baz;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }

    __PACKAGE__->config(
        action_roles => [qw( Foo )],
        action       => {
            some_action    => { Does => [qw( ~Bar )] },
            another_action => { Does => [qw( +MyActionRole::Baz )] },
        },
        action_args  => {
            another_action => { customarg => 'arg1' },
        }
    );

    # has Catalyst::ActionRole::Foo and MyApp::ActionRole::Bar applied
    sub some_action : Local { ... }

    # has Catalyst::ActionRole::Foo and MyActionRole::Baz applied
    # and associated action class would get additional arguments passed
    sub another_action : Local { ... }

=head1 ATTRIBUTES

=head2 _action_role_prefix

This class attribute stores an array reference of role prefixes to search for
role names in if they aren't prefixed with C<+> or C<~>. It defaults to
C<[ 'Catalyst::ActionRole::' ]>.  See L</role prefix searching>.

=head2 _action_roles

This attribute stores an array reference of role names that will be applied to
every action of this controller. It can be set by passing a C<action_roles>
argument to the constructor. The same expansions as for C<Does> will be
performed.

=head1 METHODS

=head2 gather_action_roles(\%action_args)

Gathers the list of roles to apply to an action with the given C<%action_args>.

=head1 DEPRECATION NOTICE

As of version C<5.90013>, L<Catalyst> has merged this functionality into the
core L<Catalyst::Controller>.  You should no longer use it for new development
and we recommend switching to the core controller as soon as practical.

=head1 ROLE PREFIX SEARCHING

Roles specified with no prefix are looked up under a set of role prefixes.  The
first prefix is always C<MyApp::ActionRole::> (with C<MyApp> replaced as
appropriate for your application); the following prefixes are taken from the
C<_action_role_prefix> attribute.

=for Pod::Coverage BUILD

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Tomas Doran Hans Dieter Pearcey Alex J. G. Burzyński Jason Kohles William King NAKAGAWA Masaki Joenio Costa John Napiorkowski

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

Hans Dieter Pearcey <hdp@weftsoar.net>

=item *

Alex J. G. Burzyński <ajgb@ajgb.net>

=item *

Jason Kohles <email@jasonkohles.com>

=item *

William King <william.king@quentustech.com>

=item *

NAKAGAWA Masaki <masaki.nakagawa@gmail.com>

=item *

Joenio Costa <joenio@cpan.org>

=item *

John Napiorkowski <jjnapiork@cpan.org>

=back

=cut
