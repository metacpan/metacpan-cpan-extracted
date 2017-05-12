package CatalystX::Imports::Context::Config;

=head1 NAME

CatalystX::Imports::Context::Config - Import Configuration Constants

=cut

use warnings;
use strict;

=head1 BASE CLASSES

L<CatalystX::Imports::Context>

=cut

use base 'CatalystX::Imports::Context';

use Class::C3;
use Carp::Clan qw{ ^CatalystX::Imports(?:::|$) };

=head1 SYNOPSIS

  package MyApp::Controller::Foo;
  use base 'Catalyst::Controller';

  use CatalystX::Imports Config => [qw(bar baz)];

  __PACKAGE__->config(
      bar => 23,
      baz => 17,
  );

  sub bar_and_baz: Local {
      my ($self, $c) = @_;
      $c->response->body( bar + baz );   # now 40
  }

  1;

=head1 DESCRIPTION

This class provides exports for the L<CatalystX::Imports> module. It does
not, however, define exports in the usual sense. Instead, it will export
inline accessors to your local controller configuration.

This library does not accept any tags. If you try to pass some anyway, for
example C<:all>, an error will be raised. Naturally, this module will not
export anything by default.

=head2 Aliasing

To avoid symbol name conflicts, you can pass a hash reference with
"configuration name"/"alias to export" pairs, like this:

  use CatalystX::Imports
      Config => { model => 'model_name' };

Often you won't need to alias all of them, but just a few. Fortunately, you
can mix them:

  use CatalystX::Imports
      Config => ['model_order', { model => 'model_name' }];

=cut

=head1 METHODS

=head2 context_export_into

This overrides the original in L<CatalystX::Imports::Context> to raise
an error when tags are used. It also contains some internal convenience
transformations for aliasing.

=cut

sub context_export_into {
    my ($class, $target, @exports) = @_;

    # individualise aliasing hash refs
    @exports =
        map {   if (ref $_ eq 'HASH') {
                    my $hr = $_;
                    map { +{ $_ => $hr->{ $_ } } } keys %$hr;
                }
                else {
                    $_;
                }
            } @exports;

    # we don't accept tags
    croak __PACKAGE__ . ' does not accept tag specifications'
        if grep { /^:/ } @exports;

    # export cleaned symbols
    return $class->next::method($target, @exports);
}

=head2 get_export

This too overrides its original in L<CatalystX::Imports::Context>. It
will return export information for returning the configuration value.

=cut

sub get_export {
    my ($class, $export) = @_;
    my ($config, $name);

    # eventual aliasing
    if (ref $export eq 'HASH') {
        ($config, $name) = %$export;
    }
    else {
        ($config, $name) = ( ($export) x 2 );
    }

    # export with empty prototype, returning a config key from the
    # controller configuration
    return {
        name      => $name,
        code      => sub { $_[1]->{ $config } },
        prototype => '',
    };
}

=head1 DIAGNOSTICS

=head2 CatalystX::Imports::Context::Config does not accept tag specifications

You tried to import symbols by specifying a tag, like C<:all>, to the import
arguments of this library. However, this module doesn't respond to tags, and
therefore fails to accept them generally.

To solve this problem, specify the configuration values you want to export
explicitly.

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
