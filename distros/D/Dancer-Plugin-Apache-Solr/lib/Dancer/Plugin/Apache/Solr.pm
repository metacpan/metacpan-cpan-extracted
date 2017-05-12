package Dancer::Plugin::Apache::Solr;

our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use utf8;
use Dancer::Plugin;
use Apache::Solr;

my $servers = {};

sub solr {
  my ($self, $name) = plugin_args(@_);
  my $cfg = plugin_setting;

  if (not defined $name) {
    if (keys %$cfg == 1) {
      ($name) = keys %$cfg;
    } elsif (keys %$cfg) {
      $name = "default";
    } else {
      die "No Solr servers are configured";
    }
  }

  return $servers->{$name} if $servers->{$name};

  my $options = $cfg->{$name} or die "The server $name is not configured";

  if ( my $alias = $options->{alias} ) {
    $options = $cfg->{$alias}
      or die "The server alias $alias does not exist in the config";
    return $servers->{$alias} if $servers->{$alias};
  }

  my $server_info =
    $options->{server_info}
    //
    {
      map { $_, $options->{$_} } qw(
        autocommit
        core
        format
        server
        server_version
      )
    }
  ;

  my $server;

  $server = Apache::Solr->new(%$server_info);

  return $servers->{$name} = $server;
};

register solr => \&solr;

register_plugin for_versions => [ 1, 2 ];

# ABSTRACT: Apache::Solr interface for Dancer applications


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::Apache::Solr - Apache::Solr interface for Dancer applications

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Dancer;
  use Dancer::Plugin::Apache::Solr qw(solr);

  get '/search' => sub {
    my $results = solr('default')->select(q => param 'q');

    # If you are accessing the 'default' schema, then you can just do:
    my $results = solr->select(q => param 'q');

    template search_results => {
      results => do_something_clever_with ($results)
    };
  };

  dance;

=head1 DESCRIPTION

This plugin makes it very easy to create L<Dancer> applications that interface
with the Apache Solr search engine.

It automatically exports the keyword C<solr> which returns an L<Apache::Solr> object.

You just need to configure your connection information.

For performance, Apache::Solr objects are cached in memory and are lazy loaded the first time they are accessed.

=head1 CONFIGURATION

Configuration can be done in your L<Dancer> config file.

=head2 Simple example

Here is a simple example. It defines one Solr server named C<default>:

    plugins:
      Apache-Solr:
        default:
          server: http://solr.example.com/search/

=head2 Multiple servers

In this example, there are 2 servers configured named C<default> and C<accessories>:

  plugins:
    Apache-Solr:
      default:
        server: http://solr.example.com/productSearch/
      accessories:
        server: http://solr.example.com/accessorySearch/

Each server configured must at least have a C<server> option set.

If you only have one server configured, or one of them is named
C<default>, you can call C<solr> without an argument to get the only
or C<default> server, respectively.

=head2 server_info

Alternatively, you may also declare your server information inside a hash named C<server_info>:

  plugins:
    Apache-Solr:
      default:
        server_info:
          server: http://solr.example.com/productSearch/
          format => JSON
          server_version: 4.5

=head2 alias

Aliases allow you to reference the same underlying server with multiple names.

For example:

  plugins:
    Apache-Solr:
      default:
          server: http://solr.example.com/productSearch/
      products:
        alias: default

Now you can access the default schema with C<solr()>, C<solr('default')>,
or C<solr('products')>.

=head1 FUNCTIONS

=head2 solr

    my $results = solr->select( q => $searchString );

The C<solr> keyword returns a L<Apache::Solr> object ready for you to use.

If you have configured only one server, then you can simply call C<solr> with no arguments.

If you have configured multiple server, you can still call C<solr> with no arguments if there is a server named C<default> in the configuration.

With no argument, the C<default> server is returned.

Otherwise, you B<must> provide C<solr()> with the name of the server:

    my $user = solr('accessories')->select( ... );

=head1 AUTHORS AND CONTRIBUTORS

This module is based on L<Dancer::Plugin::DBIC>, as at 22 October 2014 and adapted for and adapted for L<Apache::Solr> by Daniel Perrett.

The following had authored L<Dancer::Plugin::DBIC> at this time:

=over 4

=item *

Al Newkirk <awncorp@cpan.org>

=item *

Naveed Massjouni <naveed@vt.edu>

=back

The following had made contributions to L<Dancer::Plugin::DBIC> at this time:

=over 4

=item *

Alexis Sukrieh <sukria@sukria.net>

=item *

Dagfinn Ilmari Mannsåker <L<https://github.com/ilmari>>

=item *

David Precious <davidp@preshweb.co.uk>

=item *

Fabrice Gabolde <L<https://github.com/fgabolde>>

=item *

Franck Cuny <franck@lumberjaph.net>

=item *

Steven Humphrey <L<https://github.com/shumphrey>>

=item *

Yanick Champoux <L<https://github.com/yanick>>

=back

=head1 AUTHORS

=over 4

=item *

Daniel Perrett <dp13@sanger.ac.uk>

=item *

Al Newkirk <awncorp@cpan.org>

=item *

Naveed Massjouni <naveed@vt.edu>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
