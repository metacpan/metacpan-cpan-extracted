package Dancer2::Plugin::DBIx::Class;
use Modern::Perl;
our $VERSION = '1.1001'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: syntactic sugar for DBIx::Class in Dancer2, optionally with DBIx::Class::Schema::ResultSetNames
use Carp;
use Class::C3::Componentised;
use Dancer2::Plugin::DBIx::Class::ExportBuilder;
use Dancer2::Plugin 0.154000;

my $_schemas = {};

sub BUILD {
   my ($self) = @_;
   my $config = $self->config;
   my $call_rs = sub { shift->schema->resultset(@_) };
   @{ $self->keywords }{'rs'}        = $call_rs;
   @{ $self->keywords }{'rset'}      = $call_rs;
   @{ $self->keywords }{'resultset'} = $call_rs;
   @{ $self->keywords }{'schema'}    = sub { shift->schema(@_) };
   if ( defined $config->{default} ) {
      if ( !$config->{default}->{alias} ) {
         my $export_builder = Dancer2::Plugin::DBIx::Class::ExportBuilder->new(
            map { $_ => $config->{default}->{$_} }
            qw(schema_class dsn user password export_prefix) );
         my %new_keywords = $export_builder->exports;
         foreach my $dsl_keyword ( keys %{ Dancer2::Core::DSL->dsl_keywords } ) {
            delete $new_keywords{$dsl_keyword};
         }
         @{ $self->keywords }{ keys %new_keywords } = values %new_keywords;
      }
   }
   foreach my $schema ( keys %$config ) {
      next if $schema eq 'default';
      next if $config->{$schema}->{alias};
      my $export_builder = Dancer2::Plugin::DBIx::Class::ExportBuilder->new(
         map { $_ => $config->{$schema}->{$_} }
         qw(schema_class dsn user password export_prefix) );
      my %new_keywords = $export_builder->exports;
      foreach my $dsl_keyword ( keys %{ Dancer2::Core::DSL->dsl_keywords } ) {
         delete $new_keywords{$dsl_keyword};
      }
      foreach my $new_keyword ( keys %new_keywords ) {
         next if defined $self->keywords->{$new_keyword};
         $self->keywords->{$new_keyword} = $new_keywords{$new_keyword};
      }
   }
}

sub schema {
   my ( $self, $name, $schema_cfg ) = @_;

   my $cfg = $self->config;

   if ( not defined $name ) {
      my @names = keys %{$cfg}
          or croak('No schemas are configured');

      # Either pick the only one in the config or the default
      $name = @names == 1 ? $names[0] : 'default';
   }

   my $options = $cfg->{$name}
       or croak "The schema $name is not configured";

   if ($schema_cfg) {
      return $self->_create_schema( $name, $schema_cfg );
   }

   return $_schemas->{$name} if $_schemas->{$name};

   if ( my $alias = $options->{alias} ) {
      $options = $cfg->{$alias}
          or croak "The schema alias $alias does not exist in the config";
      return $_schemas->{$alias} if $_schemas->{$alias};
   }

   my $schema = $self->_create_schema( $name, $options );
   return $_schemas->{$name} = $schema;
}

sub _create_schema {
   my ( $self, $name, $options ) = @_;
   my @conn_info =
       $options->{connect_info}
       ? @{ $options->{connect_info} }
       : @$options{qw(dsn user password options)};
   if ( exists $options->{pass} ) {
      warn 'The pass option is deprecated. Use password instead.';
      $conn_info[2] = $options->{pass};
   }

   my $schema;
   if ( my $schema_class = $options->{schema_class} ) {
      $schema_class =~ s/-/::/g;
      eval { Class::C3::Componentised->ensure_class_loaded( $options->{schema_class} ); 1; }
          or croak 'Schema class ' . $options->{schema_class} . ' unable to load';
      if ( my $replicated = $options->{replicated} ) {
         $schema = $schema_class->clone;
         my %storage_options;
         my @params = qw( balancer_type balancer_args pool_type pool_args );
         for my $p (@params) {
            my $value = $replicated->{$p};
            $storage_options{$p} = $value if defined $value;
         }
         $schema->storage_type( [ '::DBI::Replicated', \%storage_options ] );
         $schema->connection(@conn_info);
         $schema->storage->connect_replicants( @{ $replicated->{replicants} } );
      } else {
         $schema = $schema_class->connect(@conn_info);
      }
   } else {
      my $dbic_loader = 'DBIx::Class::Schema::Loader';
      eval { Class::C3::Componentised->ensure_class_loaded($dbic_loader) }
          or croak "You must provide a schema_class option or install $dbic_loader.";
      $dbic_loader->naming( $options->{schema_loader_naming} || 'v7' );
      $schema = DBIx::Class::Schema::Loader->connect(@conn_info);
   }

   return $schema;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::DBIx::Class - syntactic sugar for DBIx::Class in Dancer2, optionally with DBIx::Class::Schema::ResultSetNames

=head1 VERSION

version 1.1001

=head1 SYNOPSIS

    # In your Dancer2 app, without DBIx::Class::Schema::ResultSetNames
    # (but why would you?)
       my $results = resultset('Human')->search( { . . .} );
    #
    # or, with DBIx::Class::Schema::ResultSetNames
       my $results = humans->search( { . . . } );
       my $single_person = human($human_id);

=head1 DESCRIPTION

Dancer2::Plugin::DBIx::Class adds convenience keywords to the DSL for L<Dancer2>, in order to make
database calls more semantically-friendly. This module is intended to be a forklift-upgrade for
L<Dancer2::Plugin::DBIC> enabling the user to deploy this plugin on already-running Dancer2 apps,
then add L<DBIx::Class::Schema::ResultSetNames> to new code.

=head1 CONFIGURATION

The configuration for this plugin can go in your config.yml, or in your environment:

    plugins:
      DBIx::Class:
        default:
          dsn: dbi:SQLite:dbname=my.db    # Just about any DBI-compatible DSN goes here
          schema_class: MyApp::Schema
          export_prefix: 'db'             # Optional, unless a table name (singular or plural)
                                          # is also a DSL keyword.
        second:                           # You can use multiple schemas!
          dsn: dbi:Pg:dbname=foo
          schema_class: Foo::Schema
          user: bob
          password: secret
          options:
            RaiseError: 1
            PrintError: 1
        third:
          alias: 'default'                # Yep, aliases work too.

=head1 YOU HAVE BEEN WARNED

The "optional" C<export_prefix> configuration adds the given prefix to the ResultSet names, if you
are using L<DBIx::Class::Schema::ResultSetNames>. You don't need to include an underscore at the 
end, you get that for free. It is wise to do this, if you have table names whose singular or plural
terms collide with L<Dancer2::Core::DSL> keywords, or those added by other plugins. In the event
that your term collides with a L<Dancer2::Core::DSL> keyword, it will not be added to this plugin,
and the functionality of the DSL keyword will take precedence.

=head1 FUNCTIONS

=head2 schema

This keyword returns the related L<DBIx::Class::Schema> object, ready for use.  Given without parameters,
it will return the 'default' schema, or the first one that was created, or the only one, if there is
only one.

=head2 resultset, rset, rs

These three keywords are syntactically identical, and, given a name of a L<DBIx::Class::ResultSet>
object, will return the resultset, ready for searching, or any other method you can use on a ResultSet:

    my $cars = rs('Car')->search({ . . .});

If you specify these without a C<schema> call before it, it will assume the default schema, as above.

=head1 NAMED RESULT SETS

L<DBIx::Class::Schema::ResultSetNames> adds both singular and plural method accessors for all resultsets.

So, instead of this:

    my $result_set = resultset('Author')->search({...});

you may choose to this:

    my $result_set = authors->search({...});

And instead of this:

    my $result = resultset('Author')->find($id);

you may choose to this:

    my $result = author($id)

The usual caveats apply to C<find()> returning multiple records; that behavior is deprecated, so if you
try to do something like:

    my $result = author( { first_name => 'John'} );

...odds are things will blow up in your face a lot.  Using a unique key in C<find()> is important.

=head1 BUT THAT'S NOT ALL!

If you combine this module, L<DBIx::Class::Schema::ResultSetNames>, and L<DBIx::Class::Helper::ResultSet::Shortcut>,
you can do some really fabulous, easy-to-read things in a L<Dancer2> route, like:

   # find all the books for an author, give me an array of
   #    their books as Row objects, with the editions prefetched.
   #
   my @books = author($id)->books->prefetch('edition')->all 
   
   # send a JSON-encoded list of hashrefs of authors with first names
   #    that start with 'John' and their works to your front-end framework
   #    (Some, like DevExtreme, do not cope well with the objects.)
   #
   send_as JSON => [ authors->like( 'first_name', 'John%')->prefetch('books')->hri->all ];

There are many really snazzy things to be found in L<DBIx::Class::Helpers>. Many of them can make
your code much more readable. Definitely worth a look-see.

Remember: your code has two developers: you, and you six months from now.

Remember also: You should write your code like the next developer to work on it is
a psychopath who knows where you live. 

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::ResultSet>

=item *

L<DBIx::Class::Schema::ResultSetNames>

=item *

L<DBIx::Class::Schema>

=back

=head1 CREDIT WHERE CREDIT IS DUE

Practically all of this code is the work of L<Matt S Trout (mst)|https://metacpan.org/author/MSTROUT>.
I just tidied things up and wrote documentation.

=head1 SOURCE

L<https://gitlab.com/geekruthie/Dancer2-Plugin-DBIx-Class>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dancer2-Plugin-DBIx-Classs>

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
