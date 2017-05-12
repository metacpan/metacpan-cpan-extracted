package CatalystX::ComponentsFromConfig::ViewAdaptor;
$CatalystX::ComponentsFromConfig::ViewAdaptor::VERSION = '1.006';
{
  $CatalystX::ComponentsFromConfig::ViewAdaptor::DIST = 'CatalystX-ComponentsFromConfig';
}
use Moose;

# ABSTRACT: trait-aware adaptor for Views


extends 'Catalyst::View';

with 'CatalystX::ComponentsFromConfig::Role::AdaptorRole'
    => { component_type => 'view' };

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::ComponentsFromConfig::ViewAdaptor - trait-aware adaptor for Views

=head1 VERSION

version 1.006

=head1 SYNOPSIS

In your application:

  package My::App;
  use Catalyst qw(
      ConfigLoader
      +CatalystX::ComponentsFromConfig::ViewPlugin
  );

In your config:

   <View::MyClass>
    class My::Class
    <args>
      some  param
    </args>
    <traits>
      +My::Special::Role
    </traits>
   </View::MyClass>

Now, C<< $c->view('MyClass') >> will contain an object built just like:

  my $obj = My::Class->new({some=>'param'});
  apply_all_roles($obj,'My::Special::Role');

=head1 DESCRIPTION

This plugin, built on
L<CatalystX::ComponentsFromConfig::Role::AdaptorRole>, adapts
arbitrary classes to Catalyst views, and can also apply roles to them
as specified in the configuration.

=head1 AUTHORS

=over 4

=item *

Tomas Doran (t0m) <bobtfish@bobtfish.net>

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
