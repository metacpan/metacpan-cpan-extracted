package CGI::Wiki::Simple::Plugin;

use strict;

use CGI::Wiki;
use CGI::Wiki::Simple;
use Carp qw(croak);
use Digest::MD5 qw( md5_hex );

use vars qw($VERSION);

$VERSION = 0.09;

=head1 NAME

CGI::Wiki::Simple::Plugin - Base class for CGI::Wiki::Simple plugins.

=head1 DESCRIPTION

This is the base class for special interactive Wiki nodes where the content
is produced programmatically, like the LatestChanges page and the AllNodes
page. A plugin subclass implements
more or less the same methods as a CGI::Wiki::Store - a later refactoring
might convert all Plugin-subclasses to CGI::Wiki::Store subclasses or vice-versa.

=head1 SYNOPSIS

=for example begin

  package CGI::Wiki::Simple::Plugin::MyPlugin;
  use strict;
  use Carp qw(croak);
  use CGI::Wiki::Simple::Plugin( name => 'MyPlugin' );

  sub retrieve_node_data {
    my ($wiki) = shift;

    my %args = scalar @_ == 1 ? ( name => $_[0] ) : @_;
    croak "No valid node name supplied"
      unless $args{name};

    # $args{name} is the node name
    # $args{version} is the node version, if no version is passed, means current
    # ... now actually retrieve the content ...
    my @results = ("Hello world",0,"");

    my %data;
    @data{ qw( content version last_modified ) } = @results;
    $data{checksum} = md5_hex($data{content});
    return wantarray ? %data : $data{content};
  };

  # Alternatively, if your plugin can handle more than one node :
  package CGI::Wiki::Simple::Plugin::MyMultiNodePlugin;
  use strict;
  use CGI::Wiki::Simple::Plugin (); # No automatic import

  sub import {
    my ($module,@nodenames) = @_;
    CGI::Wiki::Simple::Plugin::register_nodes(module => $module, names => [@nodenames]);
  };

=for example end

=cut

sub import {
  my ($class,%args) = @_;
  my ($module) = caller;
  my %names;

  for (qw(name names)) {
    if (exists $args{$_}) {
      if (ref $args{$_}) {
        for (@{$args{$_}}) {
          $names{$_} = 1
        };
      } else {
        $names{$args{$_}} = 1;
      };
    };
  };

  register_nodes(module => $module, names => [sort keys %names]);
};

sub register_nodes {
  my (%args) = @_;
  my ($module) = $args{module};
  my (%names);

  for (qw(name names)) {
    if (exists $args{$_}) {
      if (ref $args{$_}) {
        for (@{$args{$_}}) {
          $names{$_} = 1
        };
      } else {
        $names{$args{$_}} = 1;
      };
    };
  };
  my @names = keys %names;
  croak "Need the node name as which to install $module"
    unless @names;

  # Install our callback to the plugin
  no strict 'refs';
  my $handler = $args{code} || \&{"${module}::retrieve_node"};

  for (@names) {
    $CGI::Wiki::Simple::magic_node{$_} = sub {
      my $wiki = shift;
      my %args = scalar @_ == 1 ? ( name => $_[0] ) : @_;
      $args{wiki} = $wiki;
      croak "No valid node name supplied" unless $args{name};
      my @results = $handler->( %args );
      @results = ("", 0, "") unless scalar @results;
      my %data;
      @data{ qw( content version last_modified ) } = @results;
      $data{checksum} = md5_hex($data{content});
      return wantarray ? %data : $data{content};
    };
  };
};

1;