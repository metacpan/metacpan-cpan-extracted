package Syntax::Feature::CatalystAction;

use 5.008008;
use strict;
use warnings FATAL =>'all';

our $VERSION = '0.01';

use CatalystX::Syntax::Action ();
use B::Hooks::EndOfScope;
use Carp ();
use namespace::clean;

$Carp::Internal{ +__PACKAGE__ }++;

sub install {
  my ($class, %args) = @_;
  my $target = $args{into};
  my $name = $args{options}{ -as } || 'action';
  my $invocant = $args{options}{ -invocant } || '$self';

  CatalystX::Syntax::Action->import(
    into => $target,
    name => $name,
    invocant => $invocant,
  );

  on_scope_end {
    namespace::clean->clean_subroutines($target, $name);
  };

  return 1;
}

1;

=head1 NAME

Syntax::Feature::CatalystAction - Provide an action keyword to Catalyst Controllers

=head1 SYNOPSIS

    package MyApp::Web::Controller::Foo;

    use Moose;
    use namespace::autoclean;
    use syntax 'catalyst_action';

    extends 'Catalyst::Controller';

    action my_action($arg) : Path('my_special_action') Args(1)
    {
      $ctx->response->body('Look ma, no "my ($self, $ctx, $arg) = @_;"
    }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This module is a L<syntax> compatible wrapper for L<CatalystX::Syntax::Action>.
Please see that module for documentation and examples.  The main reason you 
might wish to use this instead is that it makes it easier to install multiple
syntax extensions at once.  For example:

    package MyApp::Web::Controller::Foo;

    use Moose;
    use syntax qw(method function catalyst_action);

    extends 'Catalyst::Controller';

    action my_action: Action { ... }

    method my_method {
      ...
      return function($arg1, $arg2) { ... };
    }

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<Catalyst>, L<Syntax::Feature::Method>, L<syntax>, L<Devel::Declare>

=head1 COPYRIGHT & LICENSE

Copyright 2011, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
