package Catalyst::Plugin::PluginLoader;

use strict;
use warnings; 
use MRO::Compat ();
use Catalyst::Utils ();
use Scalar::Util 'reftype';
use Moose::Util qw/find_meta apply_all_roles/;

use namespace::clean -except => 'meta';

our $VERSION = '0.04';

=head1 NAME

Catalyst::Plugin::PluginLoader - Load Catalyst Plugins from Config

=head1 SYNOPSIS

  <Plugin::PluginLoader>
      plugins Session
      plugins Session::Store::FastMmap
      plugins Session::State::Cookie
  </Plugin::PluginLoader>

  use Catalyst qw/ConfigLoader PluginLoader/;

=head1 DESCRIPTION

Allows you to load L<Catalyst> plugins from your app config file.

Plugin order is the same as if you put the plugins after PluginLoader in the
C<use Catalyst> line.

Roles will be loaded as well, however C<around 'setup'> will not work yet.

This is a B<COLOSSAL HACK>, use at your own risk.

Please report bugs at L<http://rt.cpan.org/>.

=cut

sub setup {
  my $class = shift;

  if (my $plugins = $class->config->{'Plugin::PluginLoader'}{plugins}) {
    my %old_plugins = %{ $class->_plugins };

    $plugins = [ $plugins ] unless ref $plugins;

    Catalyst::Exception->throw(
      'plugins must be an arrayref'
    ) if reftype $plugins ne 'ARRAY';

    $plugins = [ map {
        s/\A\+// ? $_ : "Catalyst::Plugin::$_"
    } grep { !exists $old_plugins{$_} } @$plugins ];

    my $isa = do { no strict 'refs'; \@{$class.'::ISA'}};

    my $isa_idx = 0;
    $isa_idx++ while $isa->[$isa_idx] ne __PACKAGE__;

    for my $plugin (@$plugins) {
      Catalyst::Utils::ensure_class_loaded($plugin);
      $class->_plugins->{$plugin} = 1;

      my $meta = find_meta($plugin);

      if ($meta && blessed $meta && $meta->isa('Moose::Meta::Role')) {
        apply_all_roles($class => $plugin);
      } else {
        splice @$isa, ++$isa_idx, 0, $plugin;
      }
    }

    unshift @$isa, shift @$isa; # necessary to tell perl that @ISA changed
    mro::invalidate_all_method_caches();

    if ($class->debug) {
      my @plugins = map { "$_  " . ( $_->VERSION || '' ) } @$plugins;

      if (@plugins) {
        my $t = Text::SimpleTable->new(74);
        $t->row($_) for @plugins;
        $class->log->debug( "Loaded plugins from config:\n" . $t->draw . "\n" );
      }
    }

    {
# ->next::method won't work anymore, we have to do it ourselves
      my @precedence_list = $class->meta->class_precedence_list;

      1 while shift @precedence_list ne __PACKAGE__;

      my $old_next_method = \&maybe::next::method;

      my $next_method = sub {
        if ((caller(1))[3] !~ /::setup\z/) {
          goto &$old_next_method;
        }

        my $code;
        while (my $next_class = shift @precedence_list) {
          $code = $next_class->can('setup');
          last if $code;
        }
        return unless $code;

        goto &$code;
      };

      no warnings 'redefine';
      local *next::method           = $next_method;
      local *maybe::next::method    = $next_method;

      return $class->next::method(@_);
    }
  } 

  return $class->next::method(@_);
}

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::ConfigLoader>,
L<Catalyst::Manual::ExtendingCatalyst>

=head1 TODO

Better tests.

=head1 AUTHOR

Ash Berlin, C<ash at cpan.org>

Rafael Kitover, C<rkitover at cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
# vim:sw=2 sts=2:
