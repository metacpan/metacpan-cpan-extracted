package DBICx::DataDictionary;
our $VERSION = '0.002';

use strict;
use warnings;
use parent 'Exporter';

@DBICx::DataDictionary::EXPORT = qw( add_type );

sub import {
  {
    no strict 'refs';
    unshift @{caller().'::ISA'}, 'Exporter';
  }

  goto \&Exporter::import;
}

sub add_type {
  my ($name, $spec) = @_;
  my $ns          = caller();
  my $full_name   = join('::', $ns, $name);
  my $export_ok   = join('::', $ns, 'EXPORT_OK');
  my $export_tags = join('::', $ns, 'EXPORT_TAGS');

  no strict 'refs';
  *{$full_name} = sub { +{ %$spec, @_ } };
  push @{$export_ok}, $name;
  ${$export_tags}{all} ||= \@{$export_ok};

  return;
}

1;

__END__

=encoding utf8

=head1 NAME

DBICx::DataDictionary - Define a data dictionary to use with your DBIx::Class Schema


=head1 VERSION

version 0.002

=head1 SYNOPSIS

    ## declare your data dictionary class
    package My::DataDictionary;
    
    use strict;
    use warnings;
    use DBICx::DataDictionary;
    
    add_type PK => {
      data_type         => 'integer',
      is_nullable       => 0,
      is_auto_increment => 1,
    };
    
    add_type NAME => {
      data_type   => 'varchar',
      is_nullable => 0,
      size        => 100,
    };
    
    # SHORT_NAME is based on NAME
    add_type SHORT_NAME => NAME(size => 40);
    
    1;
    
    
    ## Use it on your own Sources
    package My::Schema::Result::Table;
    
    use strict;
    use warnings;
    use base 'DBIx::Class';
    
    use My::Schema::DataDictionary qw( PK NAME );
    
    __PACKAGE__->load_components(qw(Core));
    __PACKAGE__->table('table');
    
    __PACKAGE__->add_columns(
      table_id => PK,
      name     => NAME(is_nullable => 1),
    );
    
    __PACKAGE__->set_primary_key('table_id');
    
    1;
    

=head1 DESCRIPTION

As your L<DBIx::Class|DBIx::Class>-based application starts to grown,
you start to use the same definitions for some columns.

All your primary keys are probably alike, and some fields, like names,
addresses and other elements are also similar.

The L<DBICx::DataDictionary|DBICx::DataDictionary> module allows
you to create your own libraries of column types, and reuse them in
your sources.

First you create a class for you class library and use the
L<DBICx::DataDictionary|DBICx::DataDictionary> module. This will update
your class C<@ISA> to subclass the L<Exporter|Exporter>:

    package My::DataDictionary;
    
    use DBICx::DataDictionary;


Then you declare your types using the L<add_type()> function (imported
by default) like this:

    add_type PK => {
      data_type         => 'integer',
      is_nullable       => 0,
      is_auto_increment => 1,
    };


Each type declared is available as an optional exported symbol from your
class library.

You can even create another type extending a previous one like this:

    add_type SHORT_NAME => NAME(size => 40);


This creates the C<SHORT_NAME> type, using C<NAME> as a base and changing the size to 40.

To use these types in your sources, do:

    use My::DataDictionary qw( PK );


Alternatively you can import all your types with:

    use My::DataDictionary qw( :all );


To use your types in a column definition:

    __PACKAGE__->add_columns(
      id => PK,
    );


In this case the C<id> column will use the C<PK> type definition.

You can override the type definition passing as arguments the
override values:

    __PACKAGE__->add_columns(
      id => PK(data_type => 'bigint'),
    );


=head1 FUNCTIONS

=head2 add_type()

    add_type($type_name, \%column_definition);
    add_type NAME => { data_type => 'varchar', size => 150 };

Defines a new type named C<$type_name>. The default column specification
is C<< \%column_definition >>.

Each type is defined as a exportable function inside you data dictionary
class. This function accepts a C<%hash> with column definition options
that will override the C<< \%column_definition >>.

Returns nothing.


=head1 SEE ALSO

Inspired by L<MooseX::Types>


=head1 AUTHOR

Pedro Melo, C<< <melo@simplicidade.org> >>

API design by Matt S Trout


=head1 COPYRIGHT & LICENSE

Copyright 2010 Pedro Melo

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut