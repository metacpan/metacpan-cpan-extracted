package CatalystX::ComponentsFromConfig;
$CatalystX::ComponentsFromConfig::VERSION = '1.006';
{
  $CatalystX::ComponentsFromConfig::DIST = 'CatalystX-ComponentsFromConfig';
}

# ABSTRACT: create models / views at load time


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::ComponentsFromConfig - create models / views at load time

=head1 VERSION

version 1.006

=head1 DESCRIPTION

This distribution provides 2 Catalyst plugins
(L<CatalystX::ComponentsFromConfig::ModelPlugin> and
L<CatalystX::ComponentsFromConfig::ViewPlugin>) and 2 adaptor classes
(L<CatalystX::ComponentsFromConfig::ModelAdaptor> and
L<CatalystX::ComponentsFromConfig::ViewAdaptor>).

=head1 SYNOPSYS

In your application:

  use Catalyst qw(
      ConfigLoader
      +CatalystX::ComponentsFromConfig::ModelPlugin
  );

In your configuration:

  <Model::MyClass>
   class My::Class
   <args>
    some param
   </args>
  </Model::MyClass>

Now, C<< $c->model('MyClass') >> will contain an object built just like:

  My::Class->new({some=>'param'});

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
