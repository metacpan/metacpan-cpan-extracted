package Clustericious;

use strict;
use warnings;
use 5.010;
use File::Spec;
use File::Glob qw( bsd_glob );
use File::Path qw( mkpath );

# ABSTRACT: (Deprecated) A framework for RESTful processing systems.
our $VERSION = '1.29'; # VERSION


sub _testing
{
  state $test = 0;
  my($class, $new) = @_;
  $test = $new if defined $new;
  $test;
}

sub _config_path
{
  grep { -d $_ }
    map { File::Spec->catdir(@$_) } 
    grep { defined $_->[0] }
    (
      [ $ENV{CLUSTERICIOUS_CONF_DIR} ],
      (!_testing) ? (
        [ bsd_glob('~'), 'etc' ],
        [ bsd_glob('~/.config/Perl/Clustericious') ],
        [ '', 'etc' ],
      ) : (),
    );
}

sub _slurp_pid ($)
{
  use autodie;
  my($fn) = @_;
  open my $fh, '<', $fn;
  my $pid = <$fh>;
  close $fh;
  chomp $pid;
  $pid;
}

sub _dist_dir
{
  state $dir;
  $dir //= do {
    require Path::Class::Dir;
    require File::ShareDir::Dist;
    Path::Class::Dir->new(
      File::ShareDir::Dist::dist_share('Clustericious') or die "unable to find share directory",
    );
  };
}

sub _generate_port
{
  require IO::Socket::INET;
  # this code is duplicated in Test::Clustericious::Command,
  # don't want to move it just FYI
  IO::Socket::INET->new(Listen => 5, LocalAddr => "127.0.0.1")->sockport
}

sub _my_dist_data
{
  my $dir = bsd_glob '~/.local/share/Perl/dist/Clustericious';
  mkpath $dir, 0, 0700;
  $dir;
}

sub _default_url
{
  my(undef, $app_name) = @_;
  require Path::Class::File;
  require JSON::MaybeXS;
  require Mojo::URL;
  my $file = Path::Class::File->new(_my_dist_data(), 'default_ports.json');

  $app_name =~ s{::}{-};
  
  my $data = -f $file ? JSON::MaybeXS::decode_json(scalar $file->slurp) : {};
  
  $data->{$app_name} // do {
    my $url = Mojo::URL->new('http://127.0.0.1');
    $url->port(__PACKAGE__->_generate_port);
    $url = $url->to_string;

    $data->{$app_name} = $url;
    $file->spew(JSON::MaybeXS::encode_json($data));

    $url;
  };
}

# Note sub _config_uncache also gets placed
# in this package, but it is defined in
# Clustericious::Config.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious - (Deprecated) A framework for RESTful processing systems.

=head1 VERSION

version 1.29

=head1 SYNOPSIS

Generate a new Clustericious application:

 % clustericious generate app MyApp

Basic application layout:

 package MyApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 sub startup
 {
   my($self) = @_;
   $self->SUPER::startup;
   # app startup
 }
 
 package MyApp::Routes;
 
 use Clustericious::RouteBuilder;
 
 # Mojolicious::Lite style routing
 get '/' => sub { shift->render(text => 'welcome to myapp') };

Basic testing for Clustericious application:

 use Test::Clustericious::Cluster;
 use Test::More tests => 4;
 
 # see Test::Clustericious::Cluster for more details
 # and examples.
 my $cluster = Test::Clustericious::Cluster->new;
 $cluster->create_cluster_ok('MyApp');    # 1
 
 my $url = $cluster->url;
 my $t   = $cluster->t;   # Test::Mojo object
 
 $t->get_ok("$url/")                      # 2
   ->status_is(200)                       # 3
   ->content_is('welcome to myapp');      # 4
 
 __DATA__
 
 @ etc/MyApp.conf
 ---
 url: <%= cluster->url %>

=head1 DESCRIPTION

B<NOTE>: This module has been deprecated, and may be removed on or after 31 December 2018.
Please see L<https://github.com/clustericious/Clustericious/issues/46>.

Clustericious is a web application framework designed to create HTTP/RESTful
web services that operate on a cluster, where each service does one thing 
and ideally does it well.  The design goal is to allow for easy deployment
of applications.  Clustericious is based on the L<Mojolicious> and borrows
some ideas from L<Mojolicious::Lite> (L<Clustericious::RouteBuilder> is 
based on L<Mojolicious::Lite> routing).

Two examples of Clustericious applications on CPAN are L<Yars> the archive
server and L<PlugAuth> the authentication server.

=head1 FEATURES

Here are some of the distinctive aspects of Clustericious :

=over 4

=item *

Simplified route builder based on L<Mojolicious::Lite> (see L<Clustericious::RouteBuilder>).

=item *

Provides a set of default routes (e.g. /status, /version, /api) for consistent
interaction with Clustericious services (see L<Clustericious::Plugin::CommonRoutes>).

=item *

Introspects the routes available and publishes the API as /api.

=item *

Automatically handle different formats (YAML or JSON) depending on request 
(see L<Clustericious::Plugin::AutodataHandler>).

=item *

Interfaces with L<Clustericious::Client> to allow easy creation of
clients.

=item *

Uses L<Clustericious::Config> for configuration.

=item *

Uses L<Clustericious::Log> for logging.

=item *

Integrates with L<Module::Build::Database> and L<Rose::Planter>
to provide a basic RESTful CRUD interface to a database.

=item *

Provides 'stop' and 'start' commands, and high-level configuration
facilities for a variety of deployment options.

=back

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
