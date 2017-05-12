package CatalystX::Imports::Vars;

=head1 NAME

CatalystX::Imports::Vars - Import application variables

=cut

use warnings;
use strict;

=head1 BASE CLASSES

L<CatalystX::Imports>

=cut

use base 'CatalystX::Imports';

use Carp::Clan  qw{ ^CatalystX::Imports(?:::|$) };
use Data::Alias qw( alias deref );

=head1 SYNOPSIS

  package MyApp::Controller::Users;
  use base 'Catalyst::Controller';

  # use Vars => 1; for just $self, $ctx and @args
  use CatalystX::Imports
      Vars => { Stash   => [qw( $user $user_rs $template )],
                Session => [qw( $user_id )] };

  sub list: Local {
      $template = 'list.tt';
      $user_rs  = $ctx->model('User')->search;
  }

  sub view: Local {
      $template = 'view.tt';
      $user     = $ctx->model('User')->find($args[0]);
  }

  sub me: Local {
      $ctx->forward('view', [$user_id]);
  }

  1;

=head1 DESCRIPTION

This module allows you to bind various package vars in your controller
to specific places in the framework. By default, the variables C<$self>,
C<$ctx> and C<@args> are exported. They have the same value as if set
via

  my ($self, $ctx, @args) = @_;

in your action.

You can use a hash reference to specify what variables you want to bind
to their respective fields in the session, flash or stash, as
demonstrated in the L</SYNOPSIS>.

=cut

=head1 METHODS

=head2 export_into

Exports requested variables and intalls a wrapper to fill them with their
respective values if needed.

=cut

sub export_into {
    my ($class, $target, $args) = @_;

    # a simple '1' means only $self, $ctx and $args are requested
    if ($args and $args == 1) {
        $args = {};
    }

    # by now it should be a hash reference, or we got something wrong
    croak 'Either a 1 or a hash reference expected as argument for Vars'
        unless $args and ref $args eq 'HASH';

    # fetch session and
    my @session = @{ $args->{Session} || [] };
    my @stash   = @{ $args->{Stash}   || [] };
    my @flash   = @{ $args->{Flash}   || [] };

    # build map of symbol hash refs, containing method, type and
    # sym (name)
    my @sym =
        map { {method => $_->[0], type => $_->[2], sym => $_->[3]} }
        map { [@$_, $class->_destruct_var_name($_->[1])] }
        map { my $x = $_; map { [$x->[0], $_] } @{ $x->[1] } }
            [session => \@session], [stash => \@stash], [flash => \@flash];

    # export all symbols into the requesting namespace, include defaults
    $class->export_var_into($target, $class->_destruct_var_name($_))
        for @session, @stash, @flash, qw($self $ctx @args);

    # build and register our action wrapper
    $class->register_action_wrap_in($target, sub {
        my $code = shift;
        my @wrap = @{ shift(@_) };
        my ($self, $ctx, @args) = @_;

        # install default vars
        no strict 'refs';
        local *{ $target . '::self' } = \$self;
        local *{ $target . '::ctx'  } = \$ctx;
        local *{ $target . '::args' } = \@args;

        # localise symbols to this level
        local *{ "${target}::${_}" } for map { $_->{sym} } @sym;

        # scalar aliases
        alias ${ "${target}::" . $_->{sym} } =
            $ctx->can($_->{method})->($ctx)->{ $_->{sym} }
            for grep { $_->{type} eq 'scalar' } @sym;

        # hash aliases
        alias %{ "${target}::" . $_->{sym} } =
            %{ $ctx->can($_->{method})->($ctx)->{ $_->{sym} } ||= {} }
            for grep { $_->{type} eq 'hash' } @sym;

        # array aliases
        alias @{ "${target}::" . $_->{sym} } =
            @{ $ctx->can($_->{method})->($ctx)->{ $_->{sym} } ||= [] }
            for grep { $_->{type} eq 'array' } @sym;

        # there are other wrappers left
        if (my $w = shift @wrap) {
            return $w->($code, \@wrap, @_);
        }

        # we're the last wrapper
        else {
            return $code->(@_);
        }
    });

    return 1;
}

=head2 export_var_into

Installs a variable into a package.

=cut

sub export_var_into {
    my ($class, $target, $type, $name) = @_;
    my $target_name = "${target}::${name}";

    # initialise exported vars
    no strict 'refs';
    *$target_name =
        ( $type eq 'scalar' ? \$$target_name
        : $type eq 'array'  ? \@$target_name
        :                     \%$target_name );

    return 1;
}

=head2 _destruct_var_name

Takes a variable name and returns it's type (C<scalar>, C<array> or
C<hash>) and it's symbol parts.

=cut

sub _destruct_var_name {
    my ($class, $name) = @_;
    if ($name =~ /^([\@\%\$])(\S+)$/) {
        my ($sigil, $id) = ($1, $2);
        my %type = qw($ scalar % hash @ array);
        return ($type{ $sigil }, $id);
    }
    else {
        croak "Invalid identifier found: '$name'";
    }
}

=head1 DIAGNOSTICS

=head2 Invalid identifier found: 'foo'

You asked for the import of the var 'foo', but it is not a valid variable
identifier. E.g.: '@foo', '%foo' and '$foo' are valid, but '-foo', ':foo'
and 'foo' are not.

=head2 Either a 1 or a hash reference expected as argument for Vars

You can import just the default variables ($self, $ctx and @args) by
specifying a C<1> as a parameter ...

  use CatalystX::Imports Vars => 1;

... or you can give it a hash reference and tell it what you want
additionally ...

  use CatalystX::Imports Vars => { Stash => [qw($foo)] };

... but you specified something else as parameter.

=head1 SEE ALSO

L<Catalyst>,
L<CatalystX::Imports>,
L<CatalystX::Imports::Context>

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=cut


1;
