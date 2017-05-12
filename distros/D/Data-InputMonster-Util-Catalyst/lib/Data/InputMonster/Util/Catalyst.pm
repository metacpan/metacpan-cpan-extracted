use strict;
use warnings;
package Data::InputMonster::Util::Catalyst;
{
  $Data::InputMonster::Util::Catalyst::VERSION = '0.005';
}
# ABSTRACT: InputMonster sources for common Catalyst sources


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


sub form_param {
  my ($self, $field_name) = @_;
  sub {
    my $field_name = defined $field_name ? $field_name : $_[2]{field_name};
    return $_[1]->req->params->{ $field_name };
  }
}


sub body_param {
  my ($self, $field_name) = @_;
  sub {
    my $field_name = defined $field_name ? $field_name : $_[2]{field_name};
    return $_[1]->req->body_params->{ $field_name };
  }
}


sub query_param {
  my ($self, $field_name) = @_;
  sub {
    my $field_name = defined $field_name ? $field_name : $_[2]{field_name};
    return $_[1]->req->query_params->{ $field_name };
  }
}


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

version 0.005

=head1 DESCRIPTION

This module exports a bunch of routines to make it easy to use
Data::InputMonster with Catalyst.  Each method, below, is also available as an
exported subroutine, through the magic of Sub::Exporter.

These sources will expect to receive the Catalyst object (C<$c>) as the
C<$input> argument to the monster's C<consume> method.

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

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
