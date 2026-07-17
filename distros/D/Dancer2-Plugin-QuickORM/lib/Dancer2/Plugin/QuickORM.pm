package Dancer2::Plugin::QuickORM 1.0000;
use strict;
use warnings;
use Dancer2::Core::DSL;
use Dancer2::Plugin;
use Carp qw/croak/;
use Lingua::EN::Inflect::Phrase;

our $AUTHORITY = 'cpan:GEEKRUTH';    # AUTHORITY

my $_orms = {};

plugin_keywords qw/orm/;

sub BUILD {
   my ($self)       = @_;
   my $config       = $self->config;
   my $new_keywords = {};
   foreach my $name ( keys %$config ) {
      my $orm_config = $config->{$name};
      my $class      = $orm_config->{class}
         or croak "ORM '$name' is missing 'class' in the configuration";
      $ENV{"QuickORM_${name}_name"} = $name;
      foreach my $key ( keys %$orm_config ) {
         $ENV{"QuickORM_${name}_$key"} = $orm_config->{$key};
      }
      ( my $class_file = "$class.pm" ) =~ s{::}{/}g;
      eval { require $class_file }
         or croak "Failed to load ORM class '$class': $@";
      my $orm = $class->orm($name);
      $_orms->{$name} = $orm;
      foreach my $table ( $orm->schema($name)->tables ) {
         my $table_name = $table->name;
         my $singular   = $self->_source_name_to_method_name($table_name);
         my $plural     = $self->_source_name_to_plural_name($table_name);

         # scalar/arrayref: fetch the single row by primary key.
         # Dancer2::Plugin always calls keyword subs as ($plugin, @args), so
         # the plugin instance itself is shifted off and discarded here.
         my $row_sub = sub {
            my ( undef, $id ) = @_;
            croak "'$table_name' requires a primary key value"
               unless defined $id;
            croak
               "'$table_name' expects a single primary key value, not a hashref of search conditions"
               if ref($id) eq 'HASH';
            return $orm->handle($table_name)->by_id($id);
         };

         # hashref: run it through SQL::Abstract as search conditions.
         # no argument: return every row.
         my $set_sub = sub {
            my ( undef, $where ) = @_;
            my $handle = $orm->handle($table_name);
            return $handle->all unless defined $where;
            croak "'$table_name' expects a hashref of search conditions"
               unless ref($where) eq 'HASH';
            return $handle->where($where)->all;
         };

         my @words;
         if ( $singular eq $plural ) {

            # words like "moose" only get one keyword, so it has to
            # tell a row lookup from a search by the shape of its argument.
            my $smart_sub = sub {
               my ( undef, $arg ) = @_;
               croak
                  "'$table_name' requires a primary key value or a hashref of search conditions"
                  unless defined $arg;
               return $orm->handle($table_name)->where($arg)->all
                  if ref($arg) eq 'HASH';
               croak "'$table_name' does not accept a reference of type '"
                  . ref($arg) . q/'/
                  if ref($arg) && ref($arg) ne 'ARRAY';
               return $orm->handle($table_name)->by_id($arg);
            };
            @words = ( [ $singular => $smart_sub ] );
         }
         else {
            @words = ( [ $singular => $row_sub ], [ $plural => $set_sub ] );
         }

         foreach my $pair (@words) {
            my ( $word, $sub ) = @$pair;
            if ( defined $new_keywords->{$word} ) {

               # it already exists, so let's make that one an error
               $new_keywords->{$word} = sub {
                  croak "$word is ambiguous; use <schema>_$word instead!";
               };
            }
            else {
               $new_keywords->{$word} = $sub;
            }
            $new_keywords->{"${name}_${word}"} = $sub;
         }
      }
   }
   foreach my $dsl_keyword ( keys %{ Dancer2::Core::DSL->dsl_keywords } ) {
      delete $new_keywords->{$dsl_keyword};
   }
   foreach my $new_keyword ( keys %$new_keywords ) {
      next if defined $self->keywords->{$new_keyword};
      $self->keywords->{$new_keyword} = $new_keywords->{$new_keyword};
   }
   return;
}

sub orm {
   my ( $self, $name ) = @_;
   $name //= 'default';
   if ( !$_orms->{$name} ) {
      croak "ORM '$name' is not defined in the configuration";
   }
   return $_orms->{$name};
}

sub _source_name_to_method_name {
   my ( $class, $source_name ) = @_;
   my $phrase       = $class->_source_name_to_phrase($source_name);
   my $singularised = Lingua::EN::Inflect::Phrase::to_S($phrase);
   return join '_', split q{ }, $singularised;
}

sub _source_name_to_phrase {
   my ( $class, $source_name ) = @_;
   return join q{ }, map {
      join( q{ }, map {lc} grep {length} split /([A-Z]{1}[^A-Z]*)/ )
   } split /::/, $source_name;
}

sub _source_name_to_plural_name {
   my ( $class, $source_name ) = @_;
   my $phrase     = $class->_source_name_to_phrase($source_name);
   my $pluralised = Lingua::EN::Inflect::Phrase::to_PL($phrase);
   return join '_', split q{ }, $pluralised;
}
1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::QuickORM - Adds QuickORM syntactic sugar to Dancer2

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

   package MyApp;
   use Dancer2;
   use Dancer2::Plugin::QuickORM;

   set plugins => {
      QuickORM => {
         default => {
            class => 'MyApp::ORM',
         },
      },
   };

   # 'widget' table -> singular/plural keywords widget()/widgets()
   get '/widget/:id' => sub {
      return widget( route_parameters->get('id') );
   };

   get '/widgets' => sub {
      return [ widgets( { color => 'blue' } ) ];
   };

   # get at the raw ORM connection directly
   get '/stats' => sub {
      return { row_count => orm()->handle('widget')->all };
   };

=head1 DESCRIPTION

C<Dancer2::Plugin::QuickORM> looks at the ORM(s) you've configured with L<DBIx::QuickORM>,
walks every table in their schema(s), and generates a Dancer2 keyword (i.e. an
importable function) for each one, so routes can query it without any
boilerplate.

For each configured ORM name (see L</CONFIGURATION AND ENVIRONMENT>), the
plugin's C<BUILD> step:

=over 4

=item 1.

Loads the configured C<class> and calls C<< $class->orm($name) >> to obtain
a connection.

=item 2.

Iterates C<< $orm->schema($name)->tables >> and, for each table, derives a
singular and a plural keyword name from the table name (splitting
C<StudlyCaps>/C<CamelCase> into words and singularising/pluralising with
L<Lingua::EN::Inflect::Phrase>).

=item 3.

Registers those keywords, plus schema-prefixed variants
(C<< <name>_<singular> >> and C<< <name>_<plural> >>), so a table is always
reachable unambiguously even if more than one configured ORM exposes a
table of the same name.

=back

=head2 Generated keywords

If a table's singular and plural forms differ (the common case, e.g.
C<widget>/C<widgets>), two keywords are generated:

=over 4

=item C<< singular($id) >>

Fetches the single row with that primary key. Croaks if called with no
argument, or with a hashref (which is a search, not a primary key).

=item C<< plural($where) >>

Runs a search. Called with no arguments, returns every row. Called with a
hashref, runs it as search conditions against the table. Croaks if given
anything other than a hashref.

=back

If a table's singular and plural forms are identical (e.g. C<moose>), a
single "smart" keyword is generated instead, which inspects the shape of
its argument to decide what you meant:

=over 4

=item * a hashref is treated as search conditions (like the plural form above);

=item * C<undef> (i.e. no argument) croaks, since there's no sensible default;

=item * anything else (a plain scalar, or an arrayref) is treated as a
primary key value and looked up like the singular form above;

=item * any other kind of reference (coderef, scalarref, etc.) croaks,
since it's neither a valid search nor a valid primary key.

=back

=head2 Keyword collisions

Two different kinds of collision are handled, and handled differently:

=over 4

=item Two configured ORMs derive the same bare keyword

The bare keyword (e.g. C<widget>) becomes ambiguous: calling it croaks,
telling you to use the schema-prefixed form (e.g. C<default_widget> or
C<second_widget>) instead. The schema-prefixed forms always work.

=item A derived keyword collides with an existing keyword

If the bare keyword name is already in use (either because it's a core
Dancer2 DSL keyword, e.g. C<session> or C<response_header>, or because
this plugin has already registered it itself - its own C<orm> keyword,
see below), the bare form is silently skipped so the existing keyword
keeps working. The schema-prefixed form is still registered and
reachable.

=back

=head1 SUBROUTINES/METHODS

=head2 orm

   orm();          # the connection configured as 'default'
   orm($name);     # the connection configured under $name

Returns the raw ORM connection object for the given configured name
(defaults to C<'default'> when no name is given). Croaks if C<$name> was
not configured.

This is the one keyword the plugin always registers itself (via
C<plugin_keywords>), regardless of what tables are configured; use it when
you need something the generated per-table keywords don't cover.

=head2 BUILD

Runs once when the plugin is instantiated. Reads the plugin configuration,
loads each configured ORM class, and generates the per-table keywords
described in L</DESCRIPTION>. Not intended to be called directly.

=head1 ATTRIBUTES

This plugin exposes no public attributes of its own. All of its behaviour
is driven by the C<plugins-E<gt>QuickORM> section of your Dancer2
configuration; see L</CONFIGURATION AND ENVIRONMENT>.

=head1 DIAGNOSTICS

=over 4

=item C<< ORM '%s' is missing 'class' in the configuration >>

A configured ORM name has no C<class> key. Every entry under
C<plugins-E<gt>QuickORM> must specify one.

=item C<< Failed to load ORM class '%s': %s >>

The configured C<class> could not be C<require>d; the underlying error is
appended.

=item C<< ORM '%s' is not defined in the configuration >>

C<orm($name)> was called with a name that wasn't configured.

=item C<< '%s' requires a primary key value >>

A singular (or smart) keyword was called with no argument.

=item C<< '%s' expects a single primary key value, not a hashref of search conditions >>

A singular keyword was called with a hashref; use the plural (search)
keyword instead.

=item C<< '%s' expects a hashref of search conditions >>

A plural keyword was called with a non-hashref, non-undef argument.

=item C<< '%s' requires a primary key value or a hashref of search conditions >>

A smart keyword (identical singular/plural table) was called with no
argument.

=item C<< '%s' does not accept a reference of type '%s' >>

A smart keyword was called with a reference that's neither a hashref
(search) nor usable as a primary key.

=item C<< %s is ambiguous; use <schema>_%s instead! >>

The bare keyword is generated by more than one configured ORM; call the
schema-prefixed form instead.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Configure one or more named ORMs under C<plugins-E<gt>QuickORM> in your
Dancer2 config:

   plugins:
     QuickORM:
       default:
         class: MyApp::ORM
         dsn: "dbi:Pg:dbname=myapp"
       reporting:
         class: MyApp::ORM
         dsn: "dbi:Pg:dbname=myapp_reporting"

Each key under C<QuickORM> is an ORM name (C<default> is used when
C<orm()> is called without an argument); each value is a hashref that must
contain a C<class>, plus whatever other keys your ORM class needs.

Every key/value pair in a given ORM's configuration (including C<class>
itself) is also copied into C<%ENV> as C<< QuickORM_<name>_<key> >>, and
the name itself is set as C<< QuickORM_<name>_name >>, so the ORM class's
C<orm()> constructor can pick up its configuration from the environment if
it prefers that to being passed arguments directly.

The configured C<class> must implement the following L<DBIx::QuickORM> features:

   $class->orm($name)                     # -> connection object
   $orm->schema($name)->tables            # -> list of table objects
   $table->name                           # -> table name string
   $orm->handle($table_name)              # -> handle object
   $handle->by_id($id)                    # -> single row (hashref) or undef
   $handle->where($hashref)->all          # -> list of matching rows
   $handle->all                           # -> list of every row

=head1 DEPENDENCIES

=over 4

=item *

L<Dancer2>, naturally.

=item *

L<DBIx::QuickORM>

=item *

L<Carp>,

=item *

L<Lingua::EN::Inflect::Phrase>

=head1 BUGS AND LIMITATIONS

Table names that singularise/pluralise to the same word as a Dancer2 core
DSL keyword or another already-registered keyword are only reachable via
their schema-prefixed keyword; see L</Keyword collisions>.

For tables whose singular and plural forms are identical, an arrayref
argument is treated as a primary key value (passed straight through to the
backend) rather than being rejected outright, since it isn't a hashref and
isn't some other clearly-invalid reference type; whether that's a
meaningful primary key value is left to the configured ORM class.

Please report any bugs or feature requests through the issue tracker for
this distribution.

=head1 SEE ALSO

L<Dancer2>, L<Dancer2::Plugin>, L<DBIx::QuickORM>

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Adds QuickORM syntactic sugar to Dancer2

