package DBIx::Class::Schema::ResultSetNames;
use Modern::Perl;
our $VERSION = '1.0301'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: Create resultset accessors from schema result class names
use base qw(DBIx::Class::Schema);
use Carp;
use Lingua::EN::Inflect::Phrase;

__PACKAGE__->mk_group_accessors( inherited => 'resultset_name_methods' );

__PACKAGE__->resultset_name_methods( {} );

sub register_source {
   my ( $class, $source_name, @rest ) = @_;
   my $source = $class->next::method( $source_name, @rest );
   $class->_register_resultset_name_methods($source_name);
   return $source;
}

sub _ensure_resultset_name_method {
   my ( $class, $name, $sub ) = @_;
   return if $class->can($name);
   {
      no strict 'refs';
      *{"${class}::${name}"} = $sub;
   }
   $class->resultset_name_methods( { %{ $class->resultset_name_methods }, $name => 1 }, );
   return;
}

sub _register_resultset_name_methods {
   my ( $class, $source_name ) = @_;
   my $rsname_overrides = {};
   if ( $class->can('override_rsnames') ) {
      $rsname_overrides = $class->override_rsnames;
   }
   my $method_name = $rsname_overrides->{$source_name}->{singular}
       || $class->_source_name_to_method_name($source_name);
   my $plural_name = $rsname_overrides->{$source_name}->{plural}
       || $class->_source_name_to_plural_name($source_name);
   if ( $method_name eq $plural_name ) {
      croak << "END_MESSAGE";
The ResultSet $source_name is the same word in both singular and
plural forms. Use an override to choose different words for one
or the other, or both.  Consult the documentation for assistance
in doing this.

END_MESSAGE
   }
   $class->_ensure_resultset_name_method(
      $method_name => sub {
         my ( $self, @args ) = @_;
         die "Can't call ${method_name} without arguments" unless @args;
         $self->resultset($source_name)->find(@args);
      }
   );
   $class->_ensure_resultset_name_method(
      $plural_name => sub {
         my ( $self, @args ) = @_;
         my $rs = $self->resultset($source_name);
         return $rs unless @args;
         return $rs->search_rs(@args);
      }
   );
   return;
}

sub _source_name_to_method_name {
   my ( $class, $source_name ) = @_;
   my $phrase       = $class->_source_name_to_phrase($source_name);
   my $singularised = Lingua::EN::Inflect::Phrase::to_S($phrase);
   return join '_', split q{ }, $singularised;
}

sub _source_name_to_phrase {
   my ( $class, $source_name ) = @_;
   join q{ }, map {
      join( q{ }, map { lc } grep { length } split /([A-Z]{1}[^A-Z]*)/ )
   } split /::/, $source_name;
}

sub _source_name_to_plural_name {
   my ( $class, $source_name ) = @_;
   my $phrase     = $class->_source_name_to_phrase($source_name);
   my $pluralised = Lingua::EN::Inflect::Phrase::to_PL($phrase);
   return join '_', split q{ }, $pluralised;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Schema::ResultSetNames - Create resultset accessors from schema result class names

=head1 VERSION

version 1.0301

=head1 SYNOPSIS

    # in MyApp::Schema
    __PACKAGE__->load_components('Schema::ResultSetNames');

   sub override_rsnames {
      return {
         'Widget' => {               # Your schema's result class name
            singular => 'block',     # singular word you wish to use
            plural => 'clocks'       # plural word
         }
      };
   }

=head1 DESCRIPTION

DBIx::Class::Schema::ResultSetNames adds both singular and plural method accessors for all resultsets.

So, instead of this:

    my $schema = MyApp::Schema->connect(...);
    my $result = $schema->resultset('Author')->search({...});

you may choose to this:

    my $schema = MyApp::Schema->connect(...);
    my $result = $schema->authors->search({...});

And instead of this:

    my $schema = MyApp::Schema->connect(...);
    my $result = $schema->resultset('Author')->find($id);

you may choose to this:

    my $schema = MyApp::Schema->connect(...);
    my $result = $schema->author($id)

=head2 What is returned?

If you call the plural form of the resultset (e.g. `authors`), you will get a L<DBIx::Class::ResultSet>,
which may be empty, if no rows satisfy whatever criteria you've chained behind it.

For the singular form (`author`), you'll get a L<DBIx::Class::Row>, or `undef`, if the selected row does not exist.

Don't worry if your ResultSet schema class name is already plural (e.g. 'Authors'). This module will
Do The Right Thing, according to the behavior of L<Lingua::EN::Inflect::Phrase>

=head2 Optional overriding of terms

If your schema set name is a word that is the same term in both singular and plural forms (in English), then
the module will C<croak>.  You can create an otherwise-optional subroutine named C<override_rsnames> to give
the terms you wish to use to the module.  You do not need to define both, as was done in the Synopsis above;
if one is missing, the default behavior will be used.  So in the case of, for instance, a 
L<DBIx::Class::ResultSet> named "Moose" (no, not *that* L<Moose>!), the module will C<croak>; you can do
something like this to overcome the problem:

   package MyApp::Schema;
   __PACKAGE__->load_components('Schema::ResultSetNames');

   sub override_rsnames {
      return {
         'Moose' => { 
            plural => 'm00ses'   # singular will be 'moose'
         },
         # other RSes that you want to override ... 
      };
   }

=head2 A note about `find`.

It is perfectly permissible to use find (or the singular accessor, in this module) to locate something
by including a hashref of search terms:

   my $result = $schema->resultSet('Author')->find({ name => 'John Smith });  # Old way
   my $result = $schema->author({ name => 'John Smith' });                    # New way 

However, be aware that `find()` and this module will both complain if your request will return multiple
rows, and throw a warning. `find()` expects to return one row or undef, which is why it is best used on unique keys.

=head2 "Let not your heart be troubled..." about relationships.

This doesn't tamper with relationship accessors in any way. If you have a table of Authors and a table of Books,
the usual sort of `book($id)->author()`, and `author($id)->books()` relationship tools will still work just fine.

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class::ResultSet>

=item * L<DBIx::Class::Row>

=back

=head1 CREDIT WHERE CREDIT IS DUE

Practically all of this code is the work of L<Matt S Trout (mst)|https://metacpan.org/author/MSTROUT>. It was
created alongside a Dancer2 plugin that he has helped greatly with. I just tidied things up and wrote
documentation.

=head1 SOURCE

L<https://gitlab.com/geekruthie/DBIx-Class-Schema-ResultSetNames>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Schema-ResultSetNames>

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
