package Dancer2::Plugin::DBIC::Async;

$Dancer2::Plugin::DBIC::Async::VERSION   = '0.01';
$Dancer2::Plugin::DBIC::Async::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

use IO::Async::Loop;
use Dancer2::Plugin;
use DBIx::Class::Async;
use Module::Runtime qw(use_module);

=head1 NAME

Dancer2::Plugin::DBIC::Async - Asynchronous DBIx::Class::Async plugin for Dancer2

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  # In config.yml
  plugins:
    DBIC::Async:
      default:
        schema_class: MyApp::Schema
        dsn: "dbi:SQLite:dbname=myapp.db"
        user: ""
        password: ""
        options:
          sqlite_unicode: 1
        async:
          workers: 4

  # In your Dancer2 app
  use Dancer2::Plugin::DBIC::Async;

  get '/users' => sub {
      my $count = async_count('User')->get;
      return to_json({ count => $count });
  };

  get '/users/:id' => sub {
      my $user = async_find('User', route_parameters->get('id'))->get;
      return to_json($user);
  };

=head1 DESCRIPTION

This plugin provides asynchronous database access using L<DBIx::Class::Async>
in L<Dancer2> applications.

=cut

my %ASYNC;

plugin_keywords qw(
    async_db
    async_count
    async_find
    async_search
    async_create
    async_update
    async_delete
);

=head1 KEYWORDS

=head2 async_db

  my $async_db = async_db();
  my $async_db = async_db('connection_name');

Returns the DBIx::Class::Async object for direct method calls.

=cut

sub async_db :PluginKeyword {
    my ($plugin, $name) = @_;
    return _get_async($plugin, $name);
}

=head2 async_count

  my $count_future = async_count('User');
  my $count_future = async_count('User', 'connection_name');
  my $count = $count_future->get;

Returns a Future that resolves to the count of records.

=cut

sub async_count :PluginKeyword {
    my ($plugin, $source, $name) = @_;
    my $async = _get_async($plugin, $name);
    return $async->count($source);
}

=head2 async_find

  my $user_future = async_find('User', $id);
  my $user = $user_future->get;

Returns a Future that resolves to a single record.

=cut

sub async_find :PluginKeyword {
    my ($plugin, $source, $id, $name) = @_;
    my $async = _get_async($plugin, $name);
    return $async->find($source, $id);
}

=head2 async_search

  my $users_future = async_search('User', { active => 1 });
  my $users = $users_future->get;

Returns a Future that resolves to an arrayref of matching records.

=cut

sub async_search :PluginKeyword {
    my ($plugin, $source, $cond, $name) = @_;
    my $async = _get_async($plugin, $name);
    return $async->search($source, $cond);
}

=head2 async_create

  my $user_future = async_create('User', { name => 'John' });
  my $user = $user_future->get;

Returns a Future that resolves to the created record.

=cut

sub async_create :PluginKeyword {
    my ($plugin, $source, $data, $name) = @_;
    my $async = _get_async($plugin, $name);
    return $async->create($source, $data);
}

=head2 async_update

  my $result_future = async_update('User', $id, { name => 'Jane' });
  my $result = $result_future->get;

Returns a Future that resolves to the update result.

=cut

sub async_update :PluginKeyword {
    my ($plugin, $source, $id, $data, $name) = @_;
    my $async = _get_async($plugin, $name);
    return $async->update($source, $id, $data);
}

=head2 async_delete

  my $result_future = async_delete('User', $id);
  my $result = $result_future->get;

Returns a Future that resolves to the delete result.

=cut

sub async_delete :PluginKeyword {
    my ($plugin, $source, $id, $name) = @_;
    my $async = _get_async($plugin, $name);
    return $async->delete($source, $id);
}

#
#
# INTERNAL METHOD

sub _get_async {
    my ($plugin, $name) = @_;
    $name ||= 'default';

    return $ASYNC{$name} if $ASYNC{$name};

    my $app            = $plugin->app;
    my $plugins_config = $app->config->{plugins} || {};
    my $dbic_config    = $plugins_config->{'DBIC::Async'} || {};
    my $conf           = $dbic_config->{$name};

    die "No configuration for connection '$name'"
        unless $conf;

    my $schema_class = $conf->{schema_class}
        or die "schema_class required for connection '$name'";

    use_module($schema_class);

    my @connect_info = (
        $conf->{dsn}      || die("dsn required"),
        $conf->{user}     || '',
        $conf->{password} || '',
        $conf->{options}  || {},
    );

    my $loop       = IO::Async::Loop->new;
    my %async_opts = %{ $conf->{async} || {} };
    delete $async_opts{loop};

    my $async = DBIx::Class::Async->new(
        schema_class => $schema_class,
        connect_info => \@connect_info,
        loop         => $loop,  # Use our new loop
        %async_opts,
    );

    $ASYNC{$name} = $async;

    return $async;
}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Dancer2-Plugin-DBIC-Async>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Dancer2-Plugin-DBIC-Async/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::DBIC::Async

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Dancer2-Plugin-DBIC-Async/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-DBIC-Async>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Dancer2-Plugin-DBIC-Async/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Dancer2::Plugin::DBIC::Async
