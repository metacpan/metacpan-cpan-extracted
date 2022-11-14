package DBIx::Class::PseudoEnum;
use Modern::Perl;
our $VERSION = '1.0002'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: Schema-based enumerations independent of database
use Carp;

use parent 'DBIx::Class::Row';
use DBIx::Class::Candy::Exports;
use Sub::Quote qw(quote_sub);

# Exports for DBIx::Class::Candy
export_methods [qw/enumerations_use_column_names enumerate/];

# New public methods
sub enumerate {
   my ( $class, $column, $values ) = @_;
   my $info = $class->source_info();
   $info->{enumerations} //= {};
   $info->{enumerations}->{$column} = $values;
   $class->source_info($info);
}

sub enumerations_use_column_names {
   my $class = shift;
   my $info  = $class->source_info();
   $info->{enumerations} //= {};
   $info->{enumerations}->{__use_column_names} = 1;
   $class->source_info($info);
}

# Overriden methods
sub new {
   my ( $class, $attrs ) = @_;
   my $new = $class->next::method($attrs);
   $new->_register_enumeration_methods();
   return $new;
}

sub insert {
   my $self = shift;
   my %data = $self->get_columns();
   my $info = $self->source_info()->{enumerations};
   foreach my $data_key ( keys %$info ) {
      # undef values will fall through and be captured by other
      # parts of the schema, if they're not allowed.
      next if !defined $data{$data_key};
      if ( !grep { $_ eq $data{$data_key} } @{ $info->{$data_key} } ) {
         croak
             "You have attempted to assign a value to $data_key that is not valid: $data{$data_key}";
      }
   }
   return $self->next::method(@_);
}

sub set_column {
   my ($self, $column_name, $value) = @_;

   my $values = $self->source_info()->{enumerations}->{$column_name};
   if (defined $value &&!grep { $value eq $_ } @$values) {
      croak
         "You have attempted to assign a value to $column_name that is not valid: $value";
   }
   return shift->next::method(@_);
}

# Internal methods
sub _register_enumeration_methods {
   my $class            = shift;
   my $classname        = ref $class;
   my $rs               = $class->result_source->resultset;
   my $rs_classname     = ref $rs;
   my $enumerations     = $class->source_info->{enumerations};
   my $use_column_names = defined $enumerations->{__use_column_names};
   foreach my $column ( keys %$enumerations ) {
      next if $column =~ /^__/;
      my $header    = "$classname\:\:";
      my $rs_header = "$rs_classname\:\:";
      if ($use_column_names) {
         $header    = "$classname\:\:${column}_";
         $rs_header = "$rs_classname\:\:${column}_";
      }
      foreach my $value ( @{ $enumerations->{$column} } ) {
         my $term = lc $value;
         $term =~ s/[[:punct:][:space:]]/_/g;
         quote_sub "${header}is_$term", qq/
            my \$class=shift;
            return 0 if !\$class->$column;
            return \$class->$column eq '$value';
         /, { '$rel' => \$column, '$column' => \$value };
         quote_sub "${rs_header}is_$term", qq/
            my \$class=shift;
            return \$class->search({ $column => '$value'});
         /, { '$rel' => \$column, '$column' => \$value };
      }
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::PseudoEnum - Schema-based enumerations independent of database

=head1 VERSION

version 1.0002

=head1 SYNOPSIS

   # In your Schema::Result class:
   __PACKAGE__->load_components('PseudoEnum');

   # Load your enumerations into source_info directly
   __PACKAGE__->table('contraption');
   __PACKAGE__->source_info(
   {
      enumerations => { 'status' => [qw/Sold Packaged Shipped/] }
   }

   # Or use the handy-dandy methods
   # (leave off the __PACKAGE__ if you're using DBIx::Class::Candy)
   __PACKAGE__->table('doodad');
   __PACKAGE__->enumerate( 'status', [qw/Ordered In-Stock Out-Of-Stock/] );
   __PACKAGE__->enumerate( 'color',  [qw/Black Blue Green Red/] );

   # Properly handle value collisions in the same table
   # (both fields here could create an 'is_blue' method!)
   __PACKAGE__->table('doohickey');
   __PACKAGE__->enumerations_use_column_names();
   __PACKAGE__->enumerate( 'field1', [qw/One Two Three Four Blue/] );
   __PACKAGE__->enumerate( 'field2', [qw/BLUE RED GREEN/] );

   # Later, in your application:
   # On Results:
   $doodad->is_ordered;                      # Boolean, true if doodad.status == 'Ordered'
   $doodad->is_blue;                         # Boolean, true if doodad.color == 'Blue'
   $doodad->update({ status => 'Dunno'});    # croaks!
   $doodad->update({ status => 'ordered' }); # croaks!
   $doodad->update({ color => 'Black' });    # okay!
   # The module will try to pass this on to the rest of the update() method; if the 
   # field is nullable, it'll work.
   $doodad->update({ color => undef });   

   # On ResultSets:
   $doodad_rs->create({ status => 'Dunno' });    # croaks!
   $doodad_rs->create({ status => 'ordered' });  # croaks!
   $doodad_rs->create({ color  => 'Black' });    # okay!
   $doodad_rs->is_blue                           # Returns a ResultSet where doodad.color == 'Blue'

   # With enumerations_use_column_names:
   $doohickey->is_blue                    # "no such method"
   $doohickey->field1_is_blue             # Now it does what you want!

=head1 DESCRIPTION

Enumerations can be a bit of a pain. Not all databases support them equally (or at all), which reduces
the portability of your application. Additionally, there are some 
L<philosophical and practical problems|https://chateau-logic.com/content/why-we-should-not-use-enums-databases>
with them. Lookup tables are an alternative, but maybe you don't want to clutter up your DB with single-column
lookup tables.

But searching around the interwebs, no one seems to mind enumerating valid values for a data entity within
the application layer. So that's what this module provides: a way to put the enumeration in the C<DBIx::Class>
schema, and have it enforced within the application, invisibly to the DB.

=head1 SUBROUTINES/METHODS

=head2 enumerate( C<$field>, C<[$value1, $value2,...]>)

This is the brains of the outfit, right here. The field must be a column in your table, and the values must be sent
in as a hashref.  Easy and obvious.

This method spins off methods in your Result and ResultSet classes for each value in your list, of the form
C<is_value>, which return a boolean (zero or one) if the current value of the enumerated field is the specified
value. If the field is nullable, you B<do not> get an C<is_undef> method. Yet. See LIMITATIONS below.

=head2 enumerations_use_column_names()

Calling this function will require the schema to create methods with the column name included.  E.g. instead of 
C<is_value>, you get C<fieldname_is_value> methods. It only operates on the Result class where you call it.

=head1 DEPENDENCIES

=over 4

=item L<Carp>

=item L<DBIx::Class>

=item L<Modern::Perl>

=item L<Sub::Quote>

=back

=head1 BUGS AND LIMITATIONS

Bugs?  What bugs?  (No, really. If you find one, open an issue, please.)

The following limitations are (currently) present:

=over 4

=item B<Text columns only!>:

At present, you may only use this with text-based columns.

=item B<Collisions>:

If you have two enumerated fields in a table, and their lower-cased, underscore-punctuated
values collide, the code will choose the B<last> one that you defined with an C<enumerate>
statement. In this instance, you should probably use C<enumerations_use_column_names> to force
column names to be listed.

If you have multiple enumerated values in a single field that collide on their lower-cased,
underscore-punctuated values, then B<any> of them will respond to test methods:  e.g. if you
have C<BLUE> and C<blue> values in an enumeration, then C<is_blue> will be true for either one.
(...but why would you do that?)

=item B<undef>

If a field is nullable in the DB and the schema, you do not get an C<is_undef> method. Yet.

=item B<Case-insensitive>

To make the method name, this module replaces all non-alphanumeric characters with underscores,
and smashes case on all upper-case letters. This may contribute to collisions (see above).

=item B<Adding to existing code>

If you have an application where you add this module's functionality after there is data in
the table, it B<will not> complain about already-existing invalid values in enumerated fields.
You will not, of course, be able to test for those values, nor set any other record to that
value, unless you enumerate it.  

=back

=head1 ROADMAP

I have these features in mind, going forward.

=over 4

=item * Handle non-text columns

=item * Automatically detect and force collision behavior

=item * Add an C<is_undef> method for nullable fields

=item * Option flag to make it work with case-sensitive enumerations

=item * Method to hunt for 'invalid' values in the database and report

=item * C<is_not_value> methods

=back

=head1 ACKNOWLEDGEMENTS

My boss at Clearbuilt really, really dislikes enumerations. Hopefully, this module will make
them a bit easier for him to use.

L<Jason Crome|https://metacpan.org/author/CROMEDOME> encourages this sort of craziness fairly
often.

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
