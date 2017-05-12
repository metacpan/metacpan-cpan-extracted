use strict;
use warnings;
package Data::Rx;
# ABSTRACT: perl implementation of Rx schema system
$Data::Rx::VERSION = '0.200007';
use Data::Rx::Util;
use Data::Rx::TypeBundle::Core;

#pod =head1 SYNOPSIS
#pod
#pod   my $rx = Data::Rx->new;
#pod
#pod   my $success = {
#pod     type     => '//rec',
#pod     required => {
#pod       location => '//str',
#pod       status   => { type => '//int', value => 201 },
#pod     },
#pod     optional => {
#pod       comments => {
#pod         type     => '//arr',
#pod         contents => '//str',
#pod       },
#pod     },
#pod   };
#pod
#pod   my $schema = $rx->make_schema($success);
#pod
#pod   my $reply = $json->decode( $agent->get($http_request) );
#pod
#pod   die "invalid reply" unless $schema->check($reply);
#pod
#pod =head1 COMPLEX CHECKS
#pod
#pod Note that a "schema" can be represented either as a name or as a definition.
#pod In the L</SYNOPSIS> above, note that we have both, '//str' and 
#pod C<{ type =E<gt> '//int', value =E<gt> 201 }>.  
#pod With the L<collection types|http://rx.codesimply.com/coretypes.html#collect>
#pod provided by Rx, you can validate many complex structures.  See L</learn_types>
#pod for how to teach your Rx schema object about the new types you create.
#pod
#pod When required, see L<Data::Rx::Manual::CustomTypes> for details on creating a
#pod custom type plugin as a Perl module.
#pod
#pod =head1 SCHEMA METHODS
#pod
#pod The objects returned by C<make_schema> should provide the methods detailed in
#pod this section.
#pod
#pod =head2 check
#pod
#pod   my $ok = $schema->check($input);
#pod
#pod This method just returns true if the input is valid under the given schema, and
#pod false otherwise.  For more information, see C<assert_valid>.
#pod
#pod =head2 assert_valid
#pod
#pod   $schema->assert_valid($input);
#pod
#pod This method will throw an exception if the input is not valid under the schema.
#pod The exception will be a L<Data::Rx::FailureSet>.  This has two important
#pod methods: C<stringify> and C<failures>.  The first provides a string form of the
#pod failure.  C<failures> returns a list of L<Data::Rx::Failure> objects.
#pod
#pod Failure objects have a few methods of note:
#pod
#pod   error_string - a human-friendly description of what went wrong
#pod   stringify    - a stringification of the error, data, and check string
#pod   error_types  - a list of types for the error; like tags
#pod
#pod   data_string  - a string describing where in the input the error occured
#pod   value        - the value found at the data path
#pod
#pod   check_string - a string describing which part of the schema found the error
#pod
#pod =head1 SEE ALSO
#pod
#pod L<http://rx.codesimply.com/>
#pod
#pod =cut

sub _expand_uri {
  my ($self, $str) = @_;
  return $str if $str =~ /\A\w+:/;

  if ($str =~ m{\A/(.*?)/(.+)\z}) {
    my ($prefix, $rest) = ($1, $2);
  
    my $lookup = $self->{prefix};
    Carp::croak "unknown prefix '$prefix' in type name '$str'"
      unless exists $lookup->{$prefix};

    return "$lookup->{$prefix}$rest";
  }

  Carp::croak "couldn't understand Rx type name '$str'";
}

#pod =method new
#pod
#pod   my $rx = Data::Rx->new(\%arg);
#pod
#pod This returns a new Data::Rx object.
#pod
#pod Valid arguments are:
#pod
#pod   prefix        - optional; a hashref of prefix pairs for type shorthand
#pod   type_plugins  - optional; an arrayref of type or type bundle plugins
#pod   no_core_types - optional; if true, core type bundle is not loaded
#pod   sort_keys     - optional; see the sort_keys section.
#pod
#pod The prefix hashref should look something like this:
#pod
#pod   {
#pod     'pobox'  => 'tag:pobox.com,1995:rx/core/',
#pod     'skynet' => 'tag:skynet.mil,1997-08-29:types/rx/',
#pod   }
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  $arg->{prefix} ||= {};

  my @plugins = @{ $arg->{type_plugins} || [] };
  unshift @plugins, $class->core_bundle unless $arg->{no_core_bundle};

  my $self = {
    prefix    => { },
    handler   => { },
    sort_keys => !!$arg->{sort_keys},
  };

  bless $self => $class;

  $self->register_type_plugin($_) for @plugins;

  $self->add_prefix($_ => $arg->{prefix}{ $_ }) for keys %{ $arg->{prefix} };

  return $self;
}

#pod =method make_schema
#pod
#pod   my $schema = $rx->make_schema($schema);
#pod
#pod This returns a new schema checker method for the given Rx input. This object
#pod will have C<check> and C<assert_valid> methods to test data with.
#pod
#pod =cut

sub make_schema {
  my ($self, $schema) = @_;

  $schema = { type => "$schema" } unless ref $schema;

  Carp::croak("no type name given") unless my $type = $schema->{type};

  my $type_uri = $self->_expand_uri($type);
  die "unknown type uri: $type_uri" unless exists $self->{handler}{$type_uri};

  my $handler = $self->{handler}{$type_uri};

  my $schema_arg = {%$schema};
  delete $schema_arg->{type};

  my $checker;

  if (ref $handler) {
    if (keys %$schema_arg) {
      Carp::croak("composed type does not take check arguments");
    }
    $checker = $self->make_schema($handler->{'schema'});
  } else {
    $checker = $handler->new_checker($schema_arg, $self, $type);
  }

  return $checker;
}

#pod =method register_type_plugin
#pod
#pod   $rx->register_type_plugin($type_or_bundle);
#pod
#pod Given a type plugin, this registers the plugin with the Data::Rx object.
#pod Bundles are expanded recursively and all their plugins are registered.
#pod
#pod Type plugins must have a C<type_uri> method and a C<new_checker> method.
#pod See L<Data::Rx::Manual::CustomTypes> for details.
#pod
#pod =cut

sub register_type_plugin {
  my ($self, $starting_plugin) = @_;

  my @plugins = ($starting_plugin);
  PLUGIN: while (my $plugin = shift @plugins) {
    if ($plugin->isa('Data::Rx::TypeBundle')) {
      my %pairs = $plugin->prefix_pairs;
      $self->add_prefix($_ => $pairs{ $_ }) for keys %pairs;

      unshift @plugins, $plugin->type_plugins;
    } else {
      my $uri = $plugin->type_uri;

      Carp::confess("a type plugin is already registered for $uri")
        if $self->{handler}{ $uri };
        
      $self->{handler}{ $uri } = $plugin;
    }
  }
}

#pod =method learn_type
#pod
#pod   $rx->learn_type($uri, $schema);
#pod
#pod This defines a new type as a schema composed of other types.
#pod
#pod For example:
#pod
#pod   $rx->learn_type('tag:www.example.com:rx/person',
#pod                   { type     => '//rec',
#pod                     required => {
#pod                       firstname => '//str',
#pod                       lastname  => '//str',
#pod                     },
#pod                     optional => {
#pod                       middlename => '//str',
#pod                     },
#pod                   },
#pod                  );
#pod
#pod =cut

sub learn_type {
  my ($self, $uri, $schema) = @_;

  Carp::confess("a type handler is already registered for $uri")
    if $self->{handler}{ $uri };

  die "invalid schema for '$uri': $@"
    unless eval { $self->make_schema($schema) };

  $self->{handler}{ $uri } = { schema => $schema };
}

#pod =method add_prefix
#pod
#pod   $rx->add_prefix($name => $prefix_string);
#pod
#pod For example:
#pod
#pod   $rx->add_prefix('.meta' => 'tag:codesimply.com,2008:rx/meta/');
#pod
#pod =cut

sub add_prefix {
  my ($self, $name, $base) = @_;

  Carp::confess("the prefix $name is already registered")
    if $self->{prefix}{ $name };

  $self->{prefix}{ $name } = $base;
}

#pod =method sort_keys
#pod
#pod   $rx->sort_keys(1);
#pod
#pod When sort_keys is enabled, causes Rx checkers for //rec and //map to
#pod sort the keys before validating.  This results in failures being
#pod produced in a consistent order.
#pod
#pod =cut

sub sort_keys {
  my $self = shift;

  $self->{sort_keys} = !!$_[0] if @_;

  return $self->{sort_keys};
}

sub core_bundle {
  return 'Data::Rx::TypeBundle::Core';
}

sub core_type_plugins { 
  my ($self) = @_;

  Carp::cluck("core_type_plugins deprecated; use Data::Rx::TypeBundle::Core");

  Data::Rx::TypeBundle::Core->type_plugins;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx - perl implementation of Rx schema system

=head1 VERSION

version 0.200007

=head1 SYNOPSIS

  my $rx = Data::Rx->new;

  my $success = {
    type     => '//rec',
    required => {
      location => '//str',
      status   => { type => '//int', value => 201 },
    },
    optional => {
      comments => {
        type     => '//arr',
        contents => '//str',
      },
    },
  };

  my $schema = $rx->make_schema($success);

  my $reply = $json->decode( $agent->get($http_request) );

  die "invalid reply" unless $schema->check($reply);

=head1 METHODS

=head2 new

  my $rx = Data::Rx->new(\%arg);

This returns a new Data::Rx object.

Valid arguments are:

  prefix        - optional; a hashref of prefix pairs for type shorthand
  type_plugins  - optional; an arrayref of type or type bundle plugins
  no_core_types - optional; if true, core type bundle is not loaded
  sort_keys     - optional; see the sort_keys section.

The prefix hashref should look something like this:

  {
    'pobox'  => 'tag:pobox.com,1995:rx/core/',
    'skynet' => 'tag:skynet.mil,1997-08-29:types/rx/',
  }

=head2 make_schema

  my $schema = $rx->make_schema($schema);

This returns a new schema checker method for the given Rx input. This object
will have C<check> and C<assert_valid> methods to test data with.

=head2 register_type_plugin

  $rx->register_type_plugin($type_or_bundle);

Given a type plugin, this registers the plugin with the Data::Rx object.
Bundles are expanded recursively and all their plugins are registered.

Type plugins must have a C<type_uri> method and a C<new_checker> method.
See L<Data::Rx::Manual::CustomTypes> for details.

=head2 learn_type

  $rx->learn_type($uri, $schema);

This defines a new type as a schema composed of other types.

For example:

  $rx->learn_type('tag:www.example.com:rx/person',
                  { type     => '//rec',
                    required => {
                      firstname => '//str',
                      lastname  => '//str',
                    },
                    optional => {
                      middlename => '//str',
                    },
                  },
                 );

=head2 add_prefix

  $rx->add_prefix($name => $prefix_string);

For example:

  $rx->add_prefix('.meta' => 'tag:codesimply.com,2008:rx/meta/');

=head2 sort_keys

  $rx->sort_keys(1);

When sort_keys is enabled, causes Rx checkers for //rec and //map to
sort the keys before validating.  This results in failures being
produced in a consistent order.

=head1 COMPLEX CHECKS

Note that a "schema" can be represented either as a name or as a definition.
In the L</SYNOPSIS> above, note that we have both, '//str' and 
C<{ type =E<gt> '//int', value =E<gt> 201 }>.  
With the L<collection types|http://rx.codesimply.com/coretypes.html#collect>
provided by Rx, you can validate many complex structures.  See L</learn_types>
for how to teach your Rx schema object about the new types you create.

When required, see L<Data::Rx::Manual::CustomTypes> for details on creating a
custom type plugin as a Perl module.

=head1 SCHEMA METHODS

The objects returned by C<make_schema> should provide the methods detailed in
this section.

=head2 check

  my $ok = $schema->check($input);

This method just returns true if the input is valid under the given schema, and
false otherwise.  For more information, see C<assert_valid>.

=head2 assert_valid

  $schema->assert_valid($input);

This method will throw an exception if the input is not valid under the schema.
The exception will be a L<Data::Rx::FailureSet>.  This has two important
methods: C<stringify> and C<failures>.  The first provides a string form of the
failure.  C<failures> returns a list of L<Data::Rx::Failure> objects.

Failure objects have a few methods of note:

  error_string - a human-friendly description of what went wrong
  stringify    - a stringification of the error, data, and check string
  error_types  - a list of types for the error; like tags

  data_string  - a string describing where in the input the error occured
  value        - the value found at the data path

  check_string - a string describing which part of the schema found the error

=head1 SEE ALSO

L<http://rx.codesimply.com/>

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Hakim Cassimally Ronald J Kimball

=over 4

=item *

Hakim Cassimally <hakim@mysociety.org>

=item *

Ronald J Kimball <rjk@tamias.net>

=item *

Ronald J Kimball <rkimball@pangeamedia.com>

=item *

Ronald J Kimball <rkimball@snapapp.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
