package AproJo;
use Mojo::Base 'Mojolicious';

use Data::Dumper;

our $VERSION = '0.015';

use File::Basename 'dirname';
use File::Spec;
use File::Spec::Functions qw'rel2abs catdir';
use File::ShareDir 'dist_dir';
use Cwd;

use Mojo::Home;

has db => sub {
  my $self         = shift;
  my $schema_class = $self->config->{db_schema}
    or die "Unknown DB Schema Class";
  eval "require $schema_class"
    or die "Could not load Schema Class ($schema_class), $@\n";

  my $db_connect = $self->config->{db_connect}
    or die "No DBI connection string provided";
  my @db_connect = ref $db_connect ? @$db_connect : ($db_connect);

  my $schema = $schema_class->connect(@db_connect)
    or die "Could not connect to $schema_class using $db_connect[0]";

  return $schema;
};

has app_debug => 0;

has home => sub {
  my $path = $ENV{MOJO_HOME} || getcwd;
  return Mojo::Home->new(File::Spec->rel2abs($path));
};

has config_file => sub {
  my $self = shift;
  return $ENV{APROJO_CONFIG} if $ENV{APROJO_CONFIG};

  return $self->home->rel_file('aprojo.conf');
};

sub startup {
  my $app = shift;

  $app->plugin(
    Config => {
      file    => $app->config_file,
      default => {
        'db_connect' => [
          'dbi:SQLite:dbname=' . $app->home->rel_file('aprojo.db'),
          undef,
          undef,
          {'sqlite_unicode' => 1}
        ],
        'db_schema' => 'AproJo::DB::Schema',
        'secret'    => '47110815'
      },
    }
  );

  {
    # use content from directories under share/files or using File::ShareDir
    my $lib_base = catdir(dirname(rel2abs(__FILE__)), '..', 'share','files');

    my $public = catdir($lib_base, 'public');
    $app->static->paths->[0] = -d $public ? $public : catdir(dist_dir('AproJo'), 'files','public');
    my $static_path = $app->static->paths->[0];
    #print STDERR '$static_path: ',$static_path,"\n";

    my $templates = catdir($lib_base, 'templates');
    $app->renderer->paths->[0] = -d $templates ? $templates : catdir(dist_dir('AproJo'), 'files', 'templates');
  }

  $app->plugin('I18N');
  $app->plugin('Mojolicious::Plugin::ServerInfo');
  $app->plugin('Mojolicious::Plugin::DBInfo');

  $app->plugin('Mojolicious::Plugin::Form');

  push @{$app->commands->namespaces}, 'AproJo::Command';

  #DEPRECATED: $app->secret( $app->config->{secret} );
  $app->secrets([$app->config->{secret}]);

  $app->helper(schema => sub { shift->app->db });

  $app->helper('home_page' => sub {'/'});

  $app->helper(
    'auth_fail' => sub {
      my $self = shift;
      my $message = shift || "Not Authorized";
      $self->flash(onload_message => $message);
      $self->redirect_to($self->home_page);
      return 0;
    }
  );

  $app->helper(
    'source_id' => sub {
      my ($self, $source) = @_;
      return undef unless $source;
      my @columns    = $self->schema->source($source)->columns;
      my $table_name = $self->schema->class($source)->table;
      my $source_id  = $table_name . '_id';
      return $source_id if (grep {/$source_id/} @columns);
      return $columns[0] if (scalar @columns);
    }
  );

  $app->helper(
    'get_user' => sub {
      my ($self, $name) = @_;
      unless ($name) {
        $name = $self->session->{username};
      }
      return undef unless $name;
      #say STDERR 'get_user: ', $name if $self->app->app_debug;
      return $self->schema->resultset('User')->single({name => $name});
    }
  );

  $app->helper(
    'has_role' => sub {
      my $self = shift;
      my $user_string = shift || '';
      my $role_string = shift || '';
      my $user = $self->get_user($user_string);
      return undef unless $user;
      my $role = $user->roles()->single({name => $role_string});
      #say STDERR 'has_role: ', $role->name if $self->app->app_debug;
      return ($role && $role->name eq $role_string);
    }
  );
  $app->helper(
    'is_admin' => sub {
      my ($self,$user) = @_;
      return $self->has_role($user,'admin');
    }
  );

  my $routes = $app->routes;

  $routes->get('/')->to('front#index');
  $routes->get('/front/*name')->to('front#page');
  $routes->post('/save')->to('front#save');
  $routes->post('/login')->to('user#login');
  $routes->any('/logout')->to('user#logout');

  my $if_admin = $routes->under(
    sub {
      my $self = shift;
      return $self->auth_fail unless $self->is_admin;
      return 1;
    }
  );

  $if_admin->post('/admin/save/:table')->to('admin#save');

  $if_admin->get('/admin/change/:table/:id')->to('admin#change');
  $if_admin->get('/admin/show/:table')->to('admin#show');

}

1;

__END__

=head1 NAME

AproJo - A time recording application based on Mojolicious

=begin html

<a href='https://travis-ci.org/wollmers/AproJo'><img src='https://travis-ci.org/wollmers/AproJo.png' alt="AproJo" /></a>
<a href='https://coveralls.io/r/wollmers/AproJo?branch=master'><img src='https://coveralls.io/repos/wollmers/AproJo/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/AproJo'><img src='http://cpants.cpanauthors.org/dist/AproJo.png' alt='Kwalitee Score' /></a>
<a href='http://badge.fury.io/pl/AproJo'><img src='https://badge.fury.io/pl/AproJo.svg' alt='CPAN version' height='18' /></a>

=end html

=head1 SYNOPSIS

 $ aprojo setup
 $ aprojo daemon

=head1 DESCRIPTION

L<AproJo> is a Perl web application.

=head1 STATUS

L<AproJo> is still in pre-Alpha state. It still misses essential features to be useful in production.

=head1 INSTALLATION

L<AproJo> uses well-tested and widely-used CPAN modules, so installation should be as simple as

    $ cpanm AproJo

when using L<App::cpanminus>. Of course you can use your favorite CPAN client or install manually by cloning the L</"SOURCE REPOSITORY">.

=head1 SETUP

=head2 Environment

Although most of L<AproJo> is controlled by a configuration file, a few properties must be set before that file can be read. These properties are controlled by the following environment variables.

=over

=item C<APROJO_HOME>

This is the directory where L<AproJo> expects additional files. These include the configuration file and log files. The default value is the current working directory (C<cwd>).

=item C<APROJO_CONFIG>

This is the full path to a configuration file. The default is a file named F<aprojo.conf> in the C<APROJO_HOME> path, however this file need not actually exist, defaults may be used instead. This file need not be written by hand, it may be generated by the C<aprojo config> command.

=back

=head2 The F<aprojo> command line application

L<AproJo> installs a command line application, C<aprojo>. It inherits from the L<mojo> command, but it provides extra functions specifically for use with AproJo.

=head3 config

 $ aprojo config [options]

This command writes a configuration file in your C<APROJO_HOME> path. It uses the preset defaults for all values, except that it prompts for a secret. This can be any string, however stronger is better. You do not need to memorize it or remember it. This secret protects the cookies employed by AproJo from being tampered with on the client side.

L<AproJo> does not need to be configured, however it is recommended to do so to set your application's secret.

The C<--force> option may be passed to overwrite any configuration file in the current working directory. The default is to die if such a configuration file is found.

=head3 setup

 $ aprojo setup

This step is required. Run C<aprojo setup> to setup a database. It will use the default DBI settings (SQLite) or whatever is setup in the C<APROJO_CONFIG> configuration file.

=head1 RUNNING THE APPLICATION

 $ aprojo daemon

After the database is has been setup, you can run C<aprojo daemon> to start the server.

You may also use L<morbo> (Mojolicious' development server) or L<hypnotoad> (Mojolicious' production server). You may even use any other server that Mojolicious supports, however for full functionality it must support websockets. When doing so you will need to know the full path to the C<aprojo> application. A useful recipe might be

 $ hypnotoad `which aprojo`

where you may replace C<hypnotoad> with your server of choice.

=head2 Logging

Logging in L<AproJo> is the same as in L<Mojolicious|Mojolicious::Lite/Logging>. Messages will be printed to C<STDERR> unless a directory named F<log> exists in the C<APROJO_HOME> path, in which case messages will be logged to a file in that directory.

=head1 TECHNOLOGIES USED

=over

=item *

L<Mojolicious|http://mojolicio.us> - a next generation web framework for the Perl programming language

=item *

L<DBIx::Class|http://www.dbix-class.org/> - an extensible and flexible Object/Relational Mapper written in Perl

=item *

L<Bootstrap|http://twitter.github.com/bootstrap> - the CSS/JS library from Twitter

=item *

L<jQuery|http://jquery.com/> - jQuery


=back

=head1 SEE ALSO

=over

=item *

L<Contenticious> - File-based Markdown website application

=back

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/AproJo>

=head1 AUTHOR

Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



      
