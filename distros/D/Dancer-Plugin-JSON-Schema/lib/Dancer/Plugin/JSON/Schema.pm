package Dancer::Plugin::JSON::Schema;

our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use utf8;
use Dancer::Plugin;
use JSON ();
use JSON::Schema;
use JSON::Hyper;
use Dancer qw(:syntax);

my $schemas = {};

sub json_schema {
  my ($self, $name) = plugin_args(@_);
  my $cfg = plugin_setting;

  if (not defined $name) {
    if (keys %$cfg == 1) {
      ($name) = keys %$cfg;
    } elsif (keys %$cfg) {
      $name = "default";
    } else {
      die "No JSON Schemas are configured";
    }
  }

  return $schemas->{$name} if $schemas->{$name};

  my $options = $cfg->{$name} or die "The schema $name is not configured";

  if ( my $alias = $options->{alias} ) {
    $options = $cfg->{$alias}
      or die "The schema alias $alias does not exist in the config";
    return $schemas->{$alias} if $schemas->{$alias};
  }

  my $schema_info =
    $options->{schema_info}
    //
    {
      map { $_, $options->{$_} } qw(
        options
        schema
      )
    }
  ;

  unless ( ref $schema_info->{schema} ) {
    # get the file
    my $appdir = config->{appdir} // __FILE__ =~ s~(?:/blib)?/lib/Dancer/Plugin/JSON/Schema\.pm~~r;
    my $fn     = $appdir . '/' . $schema_info->{schema};
    open ( my $fh, '<', $fn ) or die ("Could not open schema file $fn for read");
    my $raw_json           = '';
    $raw_json             .= $_ while (<$fh>);
    my $parsed_json        = JSON::from_json($raw_json);
    JSON::Hyper->new->process_includes($parsed_json, '/', undef);
    $schema_info->{schema} = $parsed_json;
  }

  my $schema;

  $schema = JSON::Schema->new( $schema_info->{schema}, $schema_info->{options} // {} );

  return $schemas->{$name} = $schema;
};

register json_schema => \&json_schema;

register_plugin for_versions => [ 1, 2 ];

# ABSTRACT: JSON::Schema interface for Dancer applications


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::JSON::Schema - JSON::Schema interface for Dancer applications

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Dancer;
  use Dancer::Plugin::JSON::Schema qw(json_schema);

  post '/search' => sub {
    my $structure = param('q');
    my $result = json_schema('default')->validate($structure);

    # If you are accessing the 'default' schema, then you can just do:
    my $result = json_schema->validate($structure);

    ...
  };

  dance;

=head1 DESCRIPTION

This plugin makes it very easy to create L<Dancer> applications that interface
with JSON Schema.

It automatically exports the keyword C<json_schema> which returns an L<JSON::Schema> object.

You just need to configure where to get the schema from.

For performance, JSON::Schema objects are cached in memory and are lazy loaded the first time they are accessed.

=head1 CONFIGURATION

Configuration can be done in your L<Dancer> config file.

=head2 Simple example

Here is a simple example. It defines one schema named C<default>:

    plugins:
      'JSON::Schema':
        default:
          schema: schemas/item.json

=head2 Multiple schemas

In this example, there are 2 schemas configured named C<default> and C<accessories>:

  plugins:
    'JSON::Schema':
      default:
        schema: schemas/item.json
      user:
        schema: schemas/user.json

Each schema configured must at least have a C<schema> option set.

If you only have one schema configured, or one of them is named
C<default>, you can call C<json_schema> without an argument to get the only
or C<default> schema, respectively.

=head2 schema_info

Alternatively, you may also declare your schema information inside a hash named C<schema_info>:

  plugins:
    'JSON::Schema':
      default:
        schema_info:
          schema: schemas/item.json

=head2 alias

Aliases allow you to reference the same underlying schema with multiple names.

For example:

  plugins:
    'JSON::Schema':
      default:
        schemas/item.json
      products:
        alias: default

Now you can access the default schema with C<json_schema()>, C<json_schema('default')>,
or C<json_schema('products')>.

=head1 FUNCTIONS

=head2 json_schema

    my $result = json_schema->validate( $structure );

The C<json_schema> keyword returns a L<JSON::Schema> object ready for you to use.

If you have configured only one schema, then you can simply call C<json_schema> with no arguments.

If you have configured multiple schemas, you can still call C<json_schema> with no arguments if there is a schema named C<default> in the configuration.

With no argument, the C<default> schema is returned.

Otherwise, you B<must> provide C<json_schema()> with the name of the schema:

    my $user = json_schema('accessories')->select( ... );

=head1 AUTHORS AND CONTRIBUTORS

This module is based on L<Dancer::Plugin::DBIC>, as at 22 October 2014, and adapted for JSON::Schema by Daniel Perrett.

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
