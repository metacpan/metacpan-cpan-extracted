use strict;
use warnings;
package Data::InputMonster::Util::Catalyst 0.006;
# ABSTRACT: InputMonster sources for common Catalyst sources

#pod =head1 DESCRIPTION
#pod
#pod This module exports a bunch of routines to make it easy to use
#pod Data::InputMonster with Catalyst.  Each method, below, is also available as an
#pod exported subroutine, through the magic of Sub::Exporter.
#pod
#pod These sources will expect to receive the Catalyst object (C<$c>) as the
#pod C<$input> argument to the monster's C<consume> method.
#pod
#pod =cut

use Carp ();
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
  exports => {
    form_param    => curry_method,
    body_param    => curry_method,
    query_param   => curry_method,
    session_entry => curry_method,
  }
};

#pod =method form_param
#pod
#pod   my $source = form_param($field_name);
#pod
#pod This source will look for form parameters (with C<< $c->req->params >>) with
#pod the given field name.
#pod
#pod =cut

sub form_param {
  my ($self, $field_name) = @_;
  sub {
    my $field_name = defined $field_name ? $field_name : $_[2]{field_name};
    return $_[1]->req->params->{ $field_name };
  }
}

#pod =method body_param
#pod
#pod   my $source = body_param($field_name);
#pod
#pod This source will look for form parameters (with C<< $c->req->body_params >>)
#pod with the given field name.
#pod
#pod =cut

sub body_param {
  my ($self, $field_name) = @_;
  sub {
    my $field_name = defined $field_name ? $field_name : $_[2]{field_name};
    return $_[1]->req->body_params->{ $field_name };
  }
}

#pod =method query_param
#pod
#pod   my $source = query_param($field_name);
#pod
#pod This source will look for form parameters (with C<< $c->req->query_params >>)
#pod with the given field name.
#pod
#pod =cut

sub query_param {
  my ($self, $field_name) = @_;
  sub {
    my $field_name = defined $field_name ? $field_name : $_[2]{field_name};
    return $_[1]->req->query_params->{ $field_name };
  }
}

#pod =method session_entry
#pod
#pod   my $source = session_entry($locator);
#pod
#pod This source will look for an entry in the session for the given locator, using
#pod the C<dig> utility from L<Data::InputMonster::Util>.
#pod
#pod =cut

sub session_entry {
  my ($self, $locator) = @_;

  require Data::InputMonster::Util;
  my $digger = Data::InputMonster::Util->dig($locator);

  return sub {
    my ($monster, $input, $arg) = @_;
    $monster->$digger($input->session, $arg);
  };
}

q{$C IS FOR CATALSYT, THAT'S GOOD ENOUGH FOR ME};

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::InputMonster::Util::Catalyst - InputMonster sources for common Catalyst sources

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This module exports a bunch of routines to make it easy to use
Data::InputMonster with Catalyst.  Each method, below, is also available as an
exported subroutine, through the magic of Sub::Exporter.

These sources will expect to receive the Catalyst object (C<$c>) as the
C<$input> argument to the monster's C<consume> method.

=head1 PERL VERSION SUPPORT

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)

=head1 METHODS

=head2 form_param

  my $source = form_param($field_name);

This source will look for form parameters (with C<< $c->req->params >>) with
the given field name.

=head2 body_param

  my $source = body_param($field_name);

This source will look for form parameters (with C<< $c->req->body_params >>)
with the given field name.

=head2 query_param

  my $source = query_param($field_name);

This source will look for form parameters (with C<< $c->req->query_params >>)
with the given field name.

=head2 session_entry

  my $source = session_entry($locator);

This source will look for an entry in the session for the given locator, using
the C<dig> utility from L<Data::InputMonster::Util>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
