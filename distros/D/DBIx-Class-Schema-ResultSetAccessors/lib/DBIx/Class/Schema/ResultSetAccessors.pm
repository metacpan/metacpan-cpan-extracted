package DBIx::Class::Schema::ResultSetAccessors;

use strict;
use warnings;

use base 'DBIx::Class::AccessorGroup';

use DBIx::Class::Carp qw(carp);
use String::CamelCase;
use Lingua::EN::Inflect::Phrase;
use Sub::Name 'subname';
use namespace::clean;

our $VERSION = 0.001005;

__PACKAGE__->mk_group_accessors(inherited => qw/
    resultset_accessor_map
    _track_resultset_accessors
/);
__PACKAGE__->resultset_accessor_map({});
__PACKAGE__->_track_resultset_accessors({});

sub register_source {
    my $self    = shift;
    my $moniker = $_[0];
    my $next    = $self->next::method(@_);
    my $schema  = ref($self) || $self;

    # need to track if we already ran register_source once, because
    # it might be re-run in sub-class, like in the case of
    # Catalyst::Model::DBIC::Schema via compose_namespaces
    return $next if
        exists $self->_track_resultset_accessors->{$schema}{$moniker};

    my $accessor_name =
        exists $self->resultset_accessor_map->{$moniker}
             ? $self->resultset_accessor_map->{$moniker}
             : $self->resultset_accessor_name($moniker);

    if ($schema->can($accessor_name)) {
        carp(
            "Can't create ResultSet accessor '$accessor_name'. " .
            "Schema method with the same name already exists. " .
            "Try overloading the name via resultset_accessor_map."
        );
    }

    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${schema}::${accessor_name}"} = subname "${schema}::${accessor_name}"
            => sub { shift->resultset($moniker) };
    }

    $self->_track_resultset_accessors->{$schema}{$moniker} = 1;

    return $next;
}

sub resultset_accessor_name {
    my ($self, $moniker) = @_;

    return $self->pluralize_resultset_accessor_name(
        String::CamelCase::decamelize($moniker)
    );
}

sub pluralize_resultset_accessor_name {
    my ($self, $original) = @_;

    return join '_', split /\s+/,
        Lingua::EN::Inflect::Phrase::to_PL(join ' ', split /_/, $original);
}

1; # eof

__END__

=head1 NAME

DBIx::Class::Schema::ResultSetAccessors - Short hand ResultSet Accessors

=head1 SYNOPSIS

  # in your schema class
  __PACKAGE__->load_components(qw/
      Schema::ResultSetAccessors
  /);
  __PACKAGE__->load_namespaces;

  # in your program
  use MyApp::Schema;
  my $schema = MyApp::Schema->connect(...);
  @artists = $schema->artists->all; # same as $schema->resultset('Artist')->all;

=head1 DESCRIPTION

Creates short hand accessor methods for each ResultSet. Accessor names are
properly converted into lowercase and pluralized. E.g.

 LinerNote -> liner_notes
 Artist    -> artists
 CD        -> cds

=head1 METHODS

=head2 resultset_accessor_map

Sometimes you will not want to, or will not be able to use an auto-generated
accessor name. A common case would be when the accessor name conflicts with a
built in DBIx::Class::Schema method. E.g. if you name your Result class
"Source", a pluralized version of this would be "sources", which is a built in
method.

This method allows you to redefine the names as you wish. Overload this method
in your schema class and return a hashref map of Source => accessor names. E.g.:

 # in your MyApp::Schema class
 sub resultset_accessor_map {
    {
        Source => 'my_sources',
        Artist => 'my_artists',
    }
 }

 # later in your code
 $schema->my_sources->all;

=head2 resultset_accessor_name($moniker)

This method is used to generate the accessor names. If you wish to create your
own logic for generating the name, you can overload this method. The method
takes a moniker (aka Source name) as a parameter and returns the accessor name.

Internally it simply uses L<String::CamelCase> to decamelize the name and pass
it to L</pluralize_resultset_accessor_name> method.

=head2 pluralize_resultset_accessor_name($decamelized_name)

If you only wish to overload the pluralization of the accessor name, in case you
want to add support for a language other than English, then you might only want
to overload this method. The method accepts decamelized name (e.g. liner_note)
and returns properly pluralized version of it.

=head1 SEE ALSO

=over 4

=item L<DBIx::Class>

=item L<String::CamelCase>

=item L<Lingua::EN::Inflect::Phrase>

=back

=head1 AUTHOR

 Roman F.
 romanf@cpan.org

=head1 COPYRIGHT

Copyright (c) 2011 Roman F.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut