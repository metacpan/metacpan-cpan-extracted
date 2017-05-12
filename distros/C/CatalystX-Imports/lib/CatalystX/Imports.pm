package CatalystX::Imports;

=head1 NAME

CatalystX::Imports - Shortcut functions for L<Catalyst> controllers

=cut

use warnings;
use strict;

use vars qw(
    $VERSION
    $STORE_CONTROLLER $STORE_CONTEXT $STORE_ARGUMENTS
    $ACTION_WRAPPER_VAR
);

use Class::MOP;
use Carp::Clan        qw{ ^CatalystX::Imports(?:::|$) };
use Filter::EOF;
use Sub::Name 'subname';

=head1 VERSION

0.04

=cut

$VERSION = '0.05';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  package MyApp::Controller::User;
  use base 'Catalyst::Controller';

  use CatalystX::Imports
      Context => { Default => [qw( :all )],
                   Config  => [{model => 'model_name'}, 'template'] },
      Vars    => { Stash   => [qw( $user $user_rs $template )],
                   Session => [qw( @shown_users )],
                   Flash   => [qw( $message )] };

  sub list: Chained {
      $user_rs = model(model_name)->search_rs;
  }

  sub load: Chained PathPart('') CaptureArgs(1) {
      $user = model(model_name)->find($args[0]);
  }

  sub view: Chained('load') {
      push @shown_users, $user->id;
      $template = template;
  }

  sub edit: Chained('load') {
      if (validate_params(request->params)) {
          $user->update(request->params);
          $message = "user updated";
      }
  }

  1;

=head1 DESCRIPTION

This module is B<not> stable yet. Features may change.

This module exports commonly used functionality and shortcuts to
L<Catalyst>s own feature set into your controller. Currently, these
groups of exports are available:

=head2 Context Exports

See also L<CatalystX::Imports::Context>. This will export functions
into your namespace that will allow you to access common methods and
values easier. As an example see the uses of
L<stash|CatalystX::Imports::Context::Default/stash>,
L<model|CatalystX::Imports::Context::Default/model> and
L<args|CatalystX::Imports::Context::Default/args> in the L</SYNOPSIS>.

You can ask for these imports by specifying a C<Context> argument on
the C<use> line:

  use CatalystX::Imports Context => ...

The C<Config> library is a special case that has no predefined
exports, but allows you to import accessors to your local controller
configuration.

=head2 Variable Exports

See also L<CatalystX::Imports::Vars>. With this module, you can import
the C<$self>, C<$ctx> and C<@args> variables as if you'd have done

  my ($self, $ctx, @args) = @_;

in one of your actions. It also allows you to import variables bound to
values in the stash, flash or session stores, like shown in the
L</SYNOPSIS>.

You can use this functionality via the C<Vars> argument on the C<use>
line:

  use CatalystX::Imports Vars => ...

=cut

# names of the localized stores in the controllers
$STORE_CONTROLLER = 'CATALYSTX_IMPORTS_STORE_CONTROLLER';
$STORE_CONTEXT    = 'CATALYSTX_IMPORTS_STORE_CONTEXT';
$STORE_ARGUMENTS  = 'CATALYSTX_IMPORTS_STORE_ARGUMENTS';

# where the wrappers for action calls will be sitting
$ACTION_WRAPPER_VAR = 'CATALYSTX_IMPORTS_ACTION_WRAPPERS';

=head1 METHODS

=cut

=head2 import

This is a method used by all subclasses. When called, it fetches the
caller as target (the C<use>ing class) and passes it to the
C<export_into> method that must be implemented by a C<use>able class.

It also makes sure that L</install_action_wrap_into> is called after
the initial runtime of your controller.

=cut

sub import {
    my ($class, @args) = @_;

    # the class that 'use'd us
    my $caller = scalar caller;

    # call install_action_wrap_into after package runtime
    Filter::EOF->on_eof_call( sub {
        my $eof = shift;
        $$eof = "; ${class}->install_action_wrap_into('${caller}'); 1;";
    });

    # call current export mechanism
    return $class->export_into($caller, @args);
}

=head2 register_action_wrap_in

Takes a code reference and a target and registers the reference to
be a wrapper for action code. As an example, without any functionality:

  CatalystX::Imports->register_action_wrap_in($class, sub {
      my $code     = shift;
      my @wrappers = @{ shift(@_) };

      # ... put your code here ...

      if (my $wrapper = shift @wrappers) {
          return $wrapper->($code, [@wrappers], @_);
      }
      else {
          return $code->(@_);
      }
  });

=cut

sub register_action_wrap_in {
    my ($class, $target, $code) = @_;
    no strict 'refs';
    no warnings 'once';
    push @{ "${target}::${ACTION_WRAPPER_VAR}" }, $code;
    return 1;
}

=head2 install_action_wrap_into

This module needs a few parts of data to provide it's functionality.
Namely, the current controller and context object, as well as the
arguments to the last called action. To get to these, it will simply
wrap all action code in your controller. This is what this function
does, essentially.

=cut

sub install_action_wrap_into {
    my ($class, $target) = @_;

    # get all action methods of the target class (not inherited actions)
    my $meta = Class::MOP::class_of($target);
    my @actions = $meta->get_method_with_attributes_list;

    # replace every action code with a wrapper
    for my $action (@actions) {
        # the wrapper fetches controller, context and args and stores
        # them for other parts of the CX:I module
        $meta->add_around_method_modifier($action->name => sub {
            my $next = shift;
            my ($self, $c, @args) = @_;

            # fetch registered action call wrappers
            my @wrappers = do {
                no strict 'refs';
                @{ "${target}::${ACTION_WRAPPER_VAR}" };
            };

            # defines where the needed object will be stored
            my %mapping = (
                CONTROLLER => $self,
                CONTEXT    => $c,
                ARGUMENTS  => \@args,
            );

            # store the objects
            {   no strict 'refs';
                ${ "${target}::CATALYSTX_IMPORTS_STORE_${_}" }
                  = $mapping{ $_ }
                    for keys %mapping;
            }

            # call original code with original arguments
            unless (@wrappers) {
                return $next->(@_);
            }

            # delegate to wrapper
            else {
                my $wrapper = shift @wrappers;
                return $wrapper->($next, [@wrappers], @_);
            }
        });
    }

    return 1;
}

=head2 export_into

Tells every specified exporter class (C<Context>, etc.) to export
themselves and passes their respective arguments.

=cut

sub export_into {
    my ($class, $target, @args) = @_;

    # we need exporter => options pairs
    croak 'CatalystX::Imports expects a key/value list as argument'
        if @args % 2;
    my %exporters = @args;

    # walk the exporters list and let every one export itself
    # to the target class
    for my $exporter (keys %exporters) {
        my $exporter_class = __PACKAGE__ . "::$exporter";
        Class::MOP::load_class($exporter_class);
        $exporter_class->export_into($target, $exporters{ $exporter });
    }

    return 1;
}

=head2 resolve_component

Some functionality will allow you to prefix used components with a
configurable string. They will use this method to find a component
according to the current configuration.

=cut

sub resolve_component {
    my ($class, $controller, $c, $type, $name, $args) = @_;

    # just use the name if nothing is configured at all
    my $config = $controller->config->{component_prefix};

    # a hashref means per-type configuration
    if (ref($config) eq 'HASH') {
        $config = exists($config->{ $type })  ? $config->{ $type }
                : exists($config->{-default}) ? $config->{-default}
                : return $name;
    }

    # if the result of the above is not an arrayref, make it one
    # for convenience reasons
    unless (ref($config) eq 'ARRAY') {
        $config = [$config];
    }

    # try to find a component under that prefix and return it if found
    for my $prefix (@$config) {
        my $comp_name = join('::', grep { $_ } $prefix, $name);
        my $comp = $c->$type($comp_name, @{ $args || [] });
        return $comp if defined($comp);
    }

    # nothing found
    return;
}

=head1 DIAGNOSTICS

See also L<CatalystX::Imports::Context/DIAGNOSTICS> and
L<CatalystX::Imports::Vars/DIAGNOSTICS> for further messages.

=head2 CatalystX::Imports expects a key/value list as argument

The use line expects a set of key/value pairs as arguments, but you gave
it a list with an odd number of elements.

=head1 SEE ALSO

L<Catalyst>,
L<CatalystX::Imports::Context>,
L<CatalystX::Imports::Vars>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
