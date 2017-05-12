use strict;
use warnings;

package Data::Couplet::Role::Plugin;
BEGIN {
  $Data::Couplet::Role::Plugin::AUTHORITY = 'cpan:KENTNL';
}
{
  $Data::Couplet::Role::Plugin::VERSION = '0.02004314';
}

# ABSTRACT: A Generalised Role for classes to extend Data::Couplet via aggregation.

use Moose::Role;
use namespace::autoclean;



no Moose::Role;
1;


__END__
=pod

=head1 NAME

Data::Couplet::Role::Plugin - A Generalised Role for classes to extend Data::Couplet via aggregation.

=head1 VERSION

version 0.02004314

=head1 SYNOPSIS

Currently this role is nothing special, it does nothing apart from let me know that a class
doesn't just have a special name. This could change later, but its bare bones for a start.

=head1 WRITING PLUGINS

  package Data::Couplet::Plugin::MyPluginName;

  use Moose::Role;

  with Data::Couplet::Role::Plugin;

  sub foo {

  }

=head1 USING PLUGINS

There are many other ways of doing it, but this way is the most recommended.

  package My::Package::DataCouplet;

  use Moose;

  extends 'Data::Couplet';

  with 'Data::Couplet::Plugin::MyPluginName';

  __PACKAGE__->meta->make_immutable;

  1;

Then later

  use aliased 'My::Package::DataCouplet' => 'DC';

  my $DC->new();

  ... etc ...

=head1 AUTHOR

Kent Fredric <kentnl at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

