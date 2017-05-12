use strict;
use warnings;

package Catalyst::Plugin::Spark::Form;
BEGIN {
  $Catalyst::Plugin::Spark::Form::AUTHORITY = 'cpan:KENTNL';
}
{
  $Catalyst::Plugin::Spark::Form::VERSION = '0.01000002';
}

# ABSTRACT: A simple plug-in to make forms accessible quickly off the CTX.

use Moose::Role;
use namespace::autoclean;



sub form {
  my ( $ctx, $name, @args ) = @_;

  if ($name) {
    my @result = $ctx->_comp_search_prefixes( $name, qw/Form F/ );
    if ( ref $name ) {
      return map { $ctx->_filter_component( $_, @args ) } @result;
    }
    return $ctx->_filter_component( $result[0], @args );
  }

  return $ctx->component( $ctx->action->class );

}

no Moose::Role;



1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Spark::Form - A simple plug-in to make forms accessible quickly off the CTX.

=head1 VERSION

version 0.01000002

=head1 SYNOPSIS

  use Catalyst qw/ Spark::Form /;

  ...

  sub action {
    my ( $self, $ctx, @rest ) = @_;

    $ctx->form('bar') # loads My::Project::Form::Bar or My::Project::F::Bar

  }

=head1 METHODS

=head2 form

  $ctx->form( $formname )

=head1 CREDITS

Code thrown together by James Laver L<http://jameslaver.com>.

Code stolen from $c->controller.

=head1 DISCLAIMER

The code mightn't work, but its not my fault if it doesn't. Will gladly accept patches.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
