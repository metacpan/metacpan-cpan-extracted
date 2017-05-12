package CatalystX::Imports::Context::Default;

=head1 NAME

CatalystX::Imports::Context::Default - Default Context Library

=cut

use warnings;
use strict;

=head1 BASE CLASSES

L<CatalystX::Imports::Context>

=cut

use base 'CatalystX::Imports::Context';

=head1 SYNOPSIS

  package MyApp::Controller::Foo;
  use base 'Catalyst::Controller';
  use CatalystX::Imports Context => ':all';

  sub foo: Local {
      stash( rs => model('Foo')->find(param('foo')) );
  }

  1;

=head1 DESCRIPTION

This package represents the default library of
L<Context|CatalystX::Imports::Context> exports.

=head2 Tags

There are some tags you can use to import groups of functions:

=over

=item C<:all>

Imports all registered exports in their real names. Aliases will not
be included in the export. You still have to specify them explicitly.

=item C<:intro>

All exports in the L</INTROSPECTION EXPORTS> section.

=item C<:mvc>

The C<L</model>>, C<L</view>> and C<L</controller>> exports.

=item C<:req>

Exports all functions in the L</REQUEST EXPORTS> section.

=item C<:param>

Contains the C<L</has_param>> and C<L</param>> exports.

=item C<:log>

Everything defined in the L</LOGGING AND DEBUGGING EXPORTS> section.

=item C<:debug>

The L</debug> and L</log_debug> exports.

=back

For more information on the import syntax, please consult
L<CatalystX::Imports::Context>.

=cut

# just for convenience, argument positions
my %Pos = (LIB => 0, SELF => 1, CTX => 2, A_ARGS => 3, ARGS => 4);

=head1 INTROSPECTION EXPORTS

=cut

=head2 action

The C<action> function is a shortcut to lookup action(chain) objects.
When called without arguments:

  my $current_action_object = action;

it will return the current action as stored in C<$c-E<gt>action>. You
can also specify the action of which you'd like to have the object. It
accepts simple action names (not starting with a slash) to return an
action relative to the current controller:

  my $action = action('list');

But it also allows you to pass an absolute action path:

  my $action = action('/foo/bar/edit');

=cut

__PACKAGE__->register_export(
    name => 'action',
    code => sub {
        my ($self, $c, $name) = @_[ @Pos{qw( SELF CTX ARGS )} ];
        return $c->action
            unless $name;
        return $c->dispatcher->get_action_by_path($name)
            if $name =~ m{^/};
        return $self->action_for($name);
    },
    tags => [qw( intro )],
);

=head2 model

=head2 view

=head2 controller

These three functions are shortcuts to the corresponding method on the
context object. Therefore, the expression

  my $person = model('DBIC::Person')->find(23);

will usually do the same as

  my $person = $c->model('DBIC::Person')->find(23);

Note, however, that these three exports are aware of the
L<component_prefix|CatalystX::Imports/component_prefix> configuration
setting.

=cut

for my $type (qw( model view controller )) {
    __PACKAGE__->register_export(
        name => $type,
        code => sub {
            my ($library, $self, $c, $a_args, $name, @args)
                = @_[ @Pos{qw( LIB SELF CTX A_ARGS )}, $Pos{ARGS} .. $#_ ];
#            my ($library, $self, $c, $a_args, $name) = @_;
            return $library->resolve_component($self, $c, $type, $name, \@args);
        },
        tags => [qw( intro mvc )],
    );
}

=head2 uri_for

See also L<Catalyst/$c-E<gt>uri_for>. Here is an example in combination
with L</action>:

  my $edit_uri = uri_for(action('edit'), 23);

=cut

__PACKAGE__->register_export(
    name => 'uri_for',
    code => sub {
        my ($c, @args) = @_[ $Pos{CTX}, $Pos{ARGS} .. $#_ ];
        return $c->uri_for(@args);
    },
    tags => [qw( intro )],
);

=head2 path_to

See also L<Catalyst/$c-E<gt>path_to>. This utility function builds a
path by your specification, starting at the application root:

  my $pdf_dir = path_to(qw( root data pdfs ));

=cut

__PACKAGE__->register_export(
    name => 'path_to',
    code => sub {
        my ($c, @args) = @_[ $Pos{CTX}, $Pos{ARGS} .. $#_ ];
        return $c->path_to(@args);
    },
    tags => [qw( intro )],
);

=head1 REQUEST EXPORTS

=cut

=head2 stash

See L<Catalyst/$c-E<gt>stash>, for which this function is a shortcut:

  stash(rs => $result_set); # stores the key 'rs' in the stash
  ...
  my $rs = stash->{rs};     # retrieves it again

=cut

__PACKAGE__->register_export(
    name => 'stash',
    code => sub {
        my ($c, @args) = @_[ $Pos{CTX}, $Pos{ARGS} .. $#_ ];
        return $c->stash(@args);
    },
    tags => [qw( req )],
);

=head2 arguments

Returns the last called action's passed arguments.

=cut

__PACKAGE__->register_export(
    name => 'arguments',
    code => sub { return $_[ $Pos{A_ARGS} ] },
    tags => [qw( req )],
);

=head2 request

Returns the current L<Catalyst::Request> object. You can also import
its L<alias|CatalystX::Imports::Context/ALIASES> C<req>.

  if (request->method eq 'POST') {
      ...
  }

=cut

__PACKAGE__->register_export(
    name  => 'request',
    code  => sub { $_[ $Pos{CTX} ]->request },
    alias => [qw( req )],
    tags  => [qw( req )],
);

=head2 response

Returns the current L<Catalyst::Response> object. You can also import
its L<alias|CatalystX::Imports::Context/ALIASES> C<res>.

  response->status(404);
  response->body('I misplaced that resource.');

=cut

__PACKAGE__->register_export(
    name  => 'response',
    code  => sub { $_[ $Pos{CTX} ]->response },
    alias => [qw( res )],
    tags  => [qw( req )],
);

=head2 captures

Returns the current requests captures.

=cut

__PACKAGE__->register_export(
    name  => 'captures',
    code  => sub { @{ $_[ $Pos{CTX} ]->request->captures } },
    alias => [qw( cap )],
    tags  => [qw( req )],
);

=head2 has_param

Boolean test if a query parameter was submitted with the request.

  sub search: Local {
      if (has_param('q')) {
          my $q = param('q');
          stash( result => model('Foo')->search({ bar => $q }) );
      }
  }

=cut

__PACKAGE__->register_export(
    name  => 'has_param',
    code  => sub {
        my ($c, $name) = @_[ @Pos{qw( CTX ARGS )} ];
        return exists $c->request->params->{ $name };
    },
    tags  => [qw( req param )],
);

=head2 param

The same as a call to the C<param> method on the current
L<Catalyst::Request> object.

=cut

__PACKAGE__->register_export(
    name  => 'param',
    code  => sub {
        my ($c, $name) = @_[ @Pos{qw( CTX ARGS )} ];
        return $c->request->param( $name );
    },
    tags  => [qw( req param )],
);

=head1 LOGGING AND DEBUGGING EXPORTS

=cut

=head2 debug

This function allows you to nest debugging code directly in your actions
and only execute it when debugging is turned on.

  debug { # runs only in debug mode
      my $foo = 'something';
      my @bar = (1 .. 10_000);
      warn "Doing $foo on $_" for @bar;
      log_debug('Done.');
  };

=cut

__PACKAGE__->register_export(
    name => 'debug',
    code => sub {
        my ($c, $code) = @_[ @Pos{qw( CTX ARGS )} ];
        return $code->() if $c->debug;
        return;
    },
    tags => [qw( log debug )],
    prototype => '&',
);

=head2 log_debug

Outputs content to the logging channel, B<but only> if the application is
in debug mode.

=cut

__PACKAGE__->register_export(
    name => 'log_debug',
    code => sub {
        my ($c, @args) = @_[ $Pos{CTX}, $Pos{ARGS} .. $#_ ];
        return $c->log->debug(@args) if $c->debug;
    },
    tags => [qw( log debug )],
);

=head2 log_info

=head2 log_warn

=head2 log_error

These functions log to the C<info>, C<warn> and C<error> channels.

=cut

for my $type (qw( info warn error )) {
    __PACKAGE__->register_export(
        name => "log_$type",
        code => sub {
            my ($c, @args) = @_[ $Pos{CTX}, $Pos{ARGS} .. $#_ ];
            return $c->log->$type(@args);
        },
        tags => [qw( log )],
    );
}

=head1 SEE ALSO

L<Catalyst>,
L<CatalystX::Imports::Context>,
L<CatalystX::Imports>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
