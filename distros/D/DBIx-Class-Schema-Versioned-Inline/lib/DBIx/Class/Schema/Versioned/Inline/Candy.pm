package DBIx::Class::Schema::Versioned::Inline::Candy;
use warnings;
use strict;

=head1 NAME

DBIx::Class::Schema::Versioned::Inline::Candy - add Candy to result classes

=head1 SYNOPSIS

  package MyApp::Schema::Candy;
  use base 'DBIx::Class::Candy';

  sub base { $_[1] || 'DBIx::Class::Core' }
  sub autotable { 1 }

  sub parse_arguments {
      my $self = shift;
      my $args = $self->next::method(@_);
      push @{$args->{components}}, 'Schema::Versioned::Inline::Candy';
      return $args;
  }

  ...

  package MyApp::Schema::Result::Foo;
  use MyApp::Schema::Candy -components => ['SomeExtraComponent'];

  since '0.2',
  renamed_from 'Bar';

  column age =>
      { data_type => "integer", is_nullable => 1, till => '0.7' };

  ...

  package MyApp::Schema::Result::Bar;
  use MyApp::Schema::Candy -components => ['SomeExtraComponent'];

  till '0.2',

=head1 CANDY EXPORTS

If used in conjunction with DBIx::Class::Candy this component will export:

=head2 since $version

The equivalent of:

  __PACKAGE__->resultset_attributes(
      { versioned => { since => $version } } );

=head2 till $version

The equivalent of:

  __PACKAGE__->resultset_attributes(
      { versioned => { until => $version } } );

=head2 renamed_from $old_class

The equivalent of:

  __PACKAGE__->resultset_attributes(
      { versioned =>
          { since => $version, renamed_from => $old_table }
      });

NOTE: when using the Candy version of L</renamed_from> the argument can be the name of the resultset class (actually the source_name) rather than the old table name so the following would be equivalent:

  
  __PACKAGE__->resultset_attributes(
      { versioned =>
          { since => '1.4', renamed_from => 'foos' }
      });


  since '1.4';
  renamed_from 'Foo';

The reasoning here is that if you user autotables => 1 then you might not know the old table name.

=cut

use DBIx::Class::Candy::Exports;

export_methods [qw(
    renamed_from
    since
    till
)];

sub _set_attr {
    my ( $self, $key, $value ) = @_;
    my $attrs = $self->resultset_attributes;
    $attrs->{versioned}->{$key} = $value;
    $self->resultset_attributes( $attrs );
}

sub renamed_from {
    shift->_set_attr( renamed_from => shift );
}

sub since {
    shift->_set_attr( since => shift );
}

sub till {
    shift->_set_attr( until => shift );
}

1;
