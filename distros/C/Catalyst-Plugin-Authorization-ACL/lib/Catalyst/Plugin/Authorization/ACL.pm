package Catalyst::Plugin::Authorization::ACL;
BEGIN {
  $Catalyst::Plugin::Authorization::ACL::AUTHORITY = 'cpan:RKITOVER';
}
$Catalyst::Plugin::Authorization::ACL::VERSION = '0.16';
use namespace::autoclean;
use Moose;
use mro 'c3';
with 'Catalyst::ClassData';
use Scalar::Util ();
use Catalyst::Plugin::Authorization::ACL::Engine qw/$DENIED $ALLOWED/;

# TODO
# refactor forcibly_allow_access so that the guts are cleaner

__PACKAGE__->mk_classdata("_acl_engine");

my $FORCE_ALLOW = bless {}, __PACKAGE__ . "::Exception";

sub execute {
    my ( $c, $class, $action ) = @_;

    if (    Scalar::Util::blessed($action)
        and $action->name ne "access_denied"
        and $action->name ne "ACL error rethrower" )
    {
        eval { $c->_acl_engine->check_action_rules( $c, $action ) };

        if ( my $err = $@ ) {
            my $force_allow = $c->acl_access_denied( $class, $action, $err );
            return unless $force_allow;
        }
        else {
            $c->acl_access_allowed( $class, $action );
        }

    }

    $c->maybe::next::method( $class, $action );
}

sub acl_allow_root_internals {
    my ( $app, $cmp ) = @_;

    foreach my $action ( qw/begin auto end/ ) {
        $app->allow_access("/$action") if $app->get_action($action, "/");
    }
}

sub setup_actions {
    my $app = shift;
    my $ret = $app->maybe::next::method(@_);

    $app->_acl_engine(
        Catalyst::Plugin::Authorization::ACL::Engine->new($app) );

    if ( my $config = $app->config->{acl} ) {
        foreach my $action ( qw/allow deny/ ) {
            my $method = "${action}_access";
            if ( my $paths = $config->{$action} ) {
                $app->$method( $_ ) for @$paths;
            }

            my $cond = ( $action eq "allow" ? "if" : "unless" );
            $method .= "_$cond";

            if ( my $args = $config->{"${action}_$cond"} ) {
                my ( $cond, @paths ) = @$args;
                $app->$method( $cond, $_ ) for @paths;
            }
        }
    }

    $ret;
}

sub deny_access_unless {
    my $c = shift;
    $c->_acl_engine->add_deny(@_);
}

sub deny_access_unless_any {
    my ($c, $path, $roles) = @_;

    $c->deny_access_unless($path, sub {
        my ($c, $action) = @_;

        return $c->check_any_user_role(@$roles);
    });
}

sub deny_access {
    my $c = shift;
    $c->deny_access_unless( @_, undef );
}

sub allow_access_if {
    my $c = shift;
    $c->_acl_engine->add_allow(@_);
}

sub allow_access_if_any {
    my ($c, $path, $roles) = @_;

    $c->allow_access_if($path, sub {
        my ($c, $action) = @_;

        return $c->check_any_user_role(@$roles);
    });
}

sub allow_access {
    my $c = shift;
    $c->allow_access_if( @_, 1 );
}

sub acl_add_rule {
    my $c = shift;
    $c->_acl_engine->add_rule(@_);
}

sub acl_access_denied {
    my ( $c, $class, $action, $err ) = @_;

    my $namespace = $action->namespace;

    if ( my $handler =
        ( $c->get_actions( "access_denied", $namespace ) )[-1] )
    {
        local $c->{_acl_forcibly_allowed} = undef;

        (my $path = $handler->reverse) =~ s!^/?!/!;

        eval { $c->detach( $path, [$action, $err] ) };

        return 1 if $c->{_acl_forcibly_allowed};

        die $@ || $Catalyst::DETACH;
    }
    else {
        $c->execute(
            $class,
            bless(
                {
                    code => sub { die $err },
                    name => "ACL error rethrower",
                },
                "Catalyst::Action"
            ),
        );

        return;
    }
}

sub forcibly_allow_access {
    my $c = shift;
    $c->{_acl_forcibly_allowed} = 1;
    die $Catalyst::DETACH;
}

sub acl_access_allowed {

}

__PACKAGE__->meta->make_immutable;
__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authorization::ACL - ACL support for Catalyst applications.

=head1 SYNOPSIS

        use Catalyst qw/
                Authentication
                Authorization::Roles
                Authorization::ACL
        /;

        __PACKAGE__->setup;

        __PACKAGE__->deny_access_unless(
                "/foo/bar",
                [qw/nice_role/],
        );

        __PACKAGE__->allow_access_if(
                "/foo/bar/gorch",
                sub { return $boolean },
        );

=head1 DESCRIPTION

This module provides Access Control List style path protection, with arbitrary
rules for L<Catalyst> applications. It operates only on the L<Catalyst>
private namespace, at least at the moment.

The two hierarchies of actions and controllers in L<Catalyst> are:

=over 4

=item Private Namespace

Every action has its own private path. This path reflects the Perl namespaces
the actions were born in, and the namespaces of their controllers.

=item External Namespace

Some actions are also directly accessible from the outside, via a URL.

The private and external paths will be the same, if you are using Local actions. Alternatively you can use C<Path>, C<Regex>, or C<Global> to specify a different external path for your action.

=back

The ACL module currently only knows to exploit the private namespace. In the
future extensions may be made to support external namespaces as well.

Various types of rules are supported, see the list under L</RULES>.

When a path is visited, rules are tested one after the other, with the most
exact rule fitting the path first, and continuing up the path. Testing
continues until a rule explcitly allows or denies access.

=head1 METHODS

=head2 allow_access_if

Arguments: $path, $rule

Check the rule condition and allow access to the actions under C<$path> if
the rule returns true.

This is normally useful to allow acces only to a specific part of a tree whose
parent has a C<deny_access_unless> clause attached to it.

If the rule test returns false access is not denied or allowed. Instead
the next rule in the chain will be checked - in this sense the combinatory
behavior of these rules is like logical B<OR>.

=head2 allow_access_if_any

Arguments: $path, \@roles

Same as above for any role in the list.

=head2 deny_access_unless

Arguments: $path, $rule

Check the rule condition and disallow access if the rule returns false.

This is normally useful to restrict access to any portion of the application
unless a certain condition can be met.

If the rule test returns true access is not allowed or denied. Instead the
next rule in the chain will be checked - in this sense the combinatory
behavior of these rules is like logical B<AND>.

=head2 deny_access_unless_any

Arguments: $path, \@roles

Same as above for any role in the list.

=head2 allow_access

=head2 deny_access

Arguments: $path

Unconditionally allow or deny access to a path.

=head2 acl_add_rule

Arguments: $path, $rule, [ $filter ]

Manually add a rule to all the actions under C<$path> using the more flexible
(but more verbose) method:

    __PACKAGE__->acl_add_rule(
        "/foo",
        sub { ... }, # see FLEXIBLE RULES below
        sub {
            my $action = shift;
            # return a true value if you want to apply the rule to this action
            # called for all the actions under "/foo"
        }
    };

In this case the rule must be a sub reference (or method name) to be invoked on
$c.

The default filter will skip all actions starting with an underscore, namely
C<_DISPATCH>, C<_AUTO>, etc (but not C<auto>, C<begin>, et al).

=head2 acl_access_denied

Arguments: $c, $class, $action, $err

=head2 acl_access_allowed

Arguments: $c, $class, $action

The default event handlers for access denied or allowed conditions. See below
on handling access violations.

=head2 acl_allow_root_internals

Adds rules that permit access to the root controller (YourApp.pm) C<auto>,
C<begin> and C<end> unconditionally.

=head1 EXTENDED METHODS

=head2 execute

The hook for rule evaluation

=head2 setup_actions

=head1 RULE EVALUATION

When a rule is attached to an action the "distance" from the path it was
specified in is recorded. The closer the path is to the rule, the earlier it
will be checked.

Any rule can either explicitly deny or explicitly allow access to a particular
action. If a rule does not explicitly allow or permit access, the next rule is
checked, until the list of rules is finished. If no rule has determined a
policy, access to the path will be permitted.

=head1 PATHS

To apply a rule to an action or group of actions you must supply a path.

This path is what you should see dumped at the beginning of the L<Catalyst>
server's debug output.

For example, for the C<foo> action defined at the root level of your
application, specify C</foo>. Under the C<Moose> controller (e.g.
C<MyApp::C::Moose>, the action C<bar> will be C</moose/bar>).

The "distance" a path has from an action that is contained in it is the the
difference in the number of slashes between the path of the action, and the
path to which the rule was applied.

=head1 RULES

=head2 Easy Rules

There are several kinds of rules you can create without using the complex
interface described in L</FLEXIBLE RULES>.

The easy rules are all predicate list oriented. C<allow_access_if> will
explicitly allow access if the predicate is true, and C<deny_access_unless>
will explicitly disallow if the predicate is false.

=over 4

=item Role Lists

  __PACAKGE__->deny_access_unless_any( "/foo/bar", [qw/admin moose_trainer/] );

When the role is evaluated the L<Catalyst::Plugin::Authorization::Roles> will
be used to check whether the currently logged in user has the specified roles.

If L</allow_access_if_any> is used, the presence of B<any> of the roles in
the list will immediately permit access, and if L</deny_access_unless_any> is
used, the lack of B<all> of the roles will immediately deny access.

Similarly, if C<allow_access_if> is used, the presence of B<all> the roles will
immediately permit access, and if C<deny_access_unless> is used, the lack of
B<any> of the roles will immediately deny access.

When specifying a role list without the
L<Catalyst::Plugin::Authorization::Roles> plugin loaded the ACL engine will
throw an error.

=item Predicate Code Reference / Method Name

The code reference or method is invoked with the context and the action
objects. The boolean return value will determine the behavior of the rule.

    __PACKAGE__->allow_access_if( "/gorch", sub { ... } );
    __PACKAGE__->deny_access_unless( "/moose", "method_name" );

When specifying a method name the rule engine ensures that it can be invoked
using L<UNIVERSAL/can>.

=item Constant

You can use C<undef>, C<0> and C<''> to use as a constant false predicate, or
C<1> to use as a constant true predicate.

=back

=head2 Flexible Rules

These rules are the most annoying to write but provide the most flexibility.

All access control is performed using exceptions -
C<$Catalyst::Plugin::Authorization::ACL::Engine::DENIED>, and
C<$Catalyst::Plugin::Authorization::ACL::Engine::ALLOWED> (these can be
imported from the engine module).

If no rule decides to explicitly allow or deny access, access will be
permitted.

Here is a rule that will always break out of rule processing by either
explicitly allowing or denying access based on how much mojo the current
user has:

    __PACKAGE__->acl_add_rule(
        "/foo",
        sub {
            my ( $c, $action ) = @_;

            if ( $c->user->mojo > 50 ) {
                die $ALLOWED;
            } else {
                die $DENIED;
            }
        }
    );

=head1 HANDLING DENIAL

There are two plugin methods that can be called when a rule makes a decision
about an action:

=over 4

=item acl_access_allowed

A no-op

=item acl_access_denied

Looks for a private action named C<access_denied> from the denied action's
controller and outwards (much like C<auto>), and if none is found throws an
access denied exception.

=item forcibly_allow_access

Within an C<access_denied> action this will immediately cause the blocked
action to be executed anyway.

=back

This means that you have several alternatives:

=head2 Provide an C<access_denied> action

    package MyApp::Controller::Foo;

    sub access_denied : Private {
        my ( $self, $c, $action ) = @_;

        ...
        $c->forcibly_allow_access
            if $you->mean_it eq "really";
    }

If you call C<forcibly_allow_access> then the blocked action will be
immediately unblocked. Otherwise the execution of the action will cease, and
return to it's caller or end.

=head2 Cleanup in C<end>

    sub end : Private {
        my ( $self, $c ) = @_;

        if ( $c->error and $c->error->[-1] eq "access denied" ) {
            $c->error(0); # clear the error

            # access denied
        } else {
            # normal end
        }
    }

=head2 Override the plugin event handler methods

    package MyApp;

    sub acl_access_allowed {
        my ( $c, $class, $action ) = @_;
        ...
    }

    sub acl_access_denied {
        my ( $c, $class, $action, $err ) = @_;
        ...
    }

C<$class> is the controller class the C<$action> object was going to be
executed in, and C<$err> is the exception cought during rule evaluation, if
any (access is denied if a rule raises an exception).

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Catalyst::Plugin::Authorization::Roles>,
L<http://catalyst.perl.org/calendar/2005/24>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 CONTRIBUTORS

castaway: Jess Robinson

caelum: Rafael Kitover E<lt>rkitover@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 - 2009
the Catalyst::Plugin::Authorization::ACL L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
