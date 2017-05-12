package CatalystX::ComponentsFromConfig::ModelPlugin;
$CatalystX::ComponentsFromConfig::ModelPlugin::VERSION = '1.006';
{
  $CatalystX::ComponentsFromConfig::ModelPlugin::DIST = 'CatalystX-ComponentsFromConfig';
}
use Moose::Role;

# ABSTRACT: plugin to create Models from configuration


with 'CatalystX::ComponentsFromConfig::Role::PluginRole'
    => { component_type => 'model' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::ComponentsFromConfig::ModelPlugin - plugin to create Models from configuration

=head1 VERSION

version 1.006

=head1 SYNOPSIS

In your application:

  package My::App;
  use Catalyst qw(
      ConfigLoader
      +CatalystX::ComponentsFromConfig::ModelPlugin
  );

In your config:

   <Model::MyClass>
    class My::Class
    <args>
      some  param
    </args>
    <traits>
      +My::Special::Role
    </traits>
   </Model::MyClass>

Now, C<< $c->model('MyClass') >> will contain an object built just like:

  my $obj = My::Class->new({some=>'param'});
  apply_all_roles($obj,'My::Special::Role');

=head1 DESCRIPTION

This plugin, built on
L<CatalystX::ComponentsFromConfig::Role::PluginRole>, allows you to
create model components at application setup time, just by specifying
them in the configuration.

=head1 GLOBAL CONFIGURATION

  <models_from_config>
   base_class My::ModelAdaptor
  </models_from_config>

The default C<base_class> is
C<CatalystX::ComponentsFromConfig::ModelAdaptor>, but you can specify
whatever adaptor you want. Of course, you have to make sure that the
model-specific configuration block is in the format that your adaptor
expects.

A useful example is when you want to use L<Catalyst::Model::DBIC::Schema>:

 <Model::DB>
  base_class Catalyst::Model::DBIC::Schema
  schema_class My::Schema
  <connect_info>
   dsn dbi:SQLite:dbname=/tmp/whatever.db
  </connect_info>
 </Model::DB>

Note that, since we're not using
L<CatalystX::ComponentsFromConfig::ModelAdaptor>, the way you pass the
various parameters is different than what is shown at the top.

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
