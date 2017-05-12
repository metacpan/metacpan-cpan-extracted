package BioX::Workflow::Command::Utils::Plugin;

use MooseX::App::Role;

#TODO make this into a general Plugin Loader

use Cwd qw(getcwd);
use Try::Tiny;

with 'MooseX::Object::Pluggable';

=head1 BioX::Workflow::Command::Utils::Plugin

Take care of all file operations

=cut

=head2 Attributes

=cut

=head3 plugins

Load plugins that are used both by the submitter and executor such as logging pluggins

=cut

option 'plugins' => (
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
    documentation => 'Load aplication plugins',
    cmd_split     => qr/,/,
    required      => 0,
);

option 'plugins_opts' => (
    is            => 'rw',
    isa           => 'HashRef',
    documentation => 'Options for application plugins',
    required      => 0,
);

=head2 Subroutines

=cut

=head3 gen_load_plugins

=cut

sub BUILD {}

after 'BUILD' => sub {
  my $self = shift;

  return unless $self->plugins;

  $self->app_load_plugins( $self->plugins );
  $self->parse_plugin_opts( $self->plugins_opts );
};

sub gen_load_plugins {
    my $self = shift;

    return unless $self->plugins;

    $self->app_load_plugins( $self->plugins );
    $self->parse_plugin_opts( $self->plugins_opts );
}

=head3 app_load_plugin

=cut

sub app_load_plugins {
    my $self    = shift;
    my $plugins = shift;

    return unless $plugins;

    foreach my $plugin ( @{$plugins} ) {
        try {
            $self->load_plugin($plugin);
        }
        catch {
            $self->app_log->warn("Could not load plugin $plugin!\n$_");
        }
    }

}

=head3 parse_plugin_opts

parse the opts from --plugin_opts

=cut

sub parse_plugin_opts {
    my $self     = shift;
    my $opt_href = shift;

    return unless $opt_href;
    while ( my ( $k, $v ) = each %{$opt_href} ) {
        $self->$k($v) if $self->can($k);
    }
}

sub unparse_plugin_opts {
    my $self     = shift;
    my $opt_href = shift;
    my $opt_opt  = shift;

    my $opt_str = "";

    return unless $opt_href;

    while ( my ( $k, $v ) = each %{$opt_href} ) {
        next unless $k;
        $v = "" unless $v;
        $opt_str .= "--$opt_opt" . "_opts " . $k . "=" . $v . " ";
    }

    return $opt_str;
}

1;
