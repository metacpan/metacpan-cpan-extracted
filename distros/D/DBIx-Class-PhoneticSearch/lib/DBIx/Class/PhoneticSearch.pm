package DBIx::Class::PhoneticSearch;

use warnings;
use strict;
use Carp;

our $VERSION = '0.01';


use constant PHONETIC_ALGORITHMS =>
  qw(DaitchMokotoff DoubleMetaphone Koeln Metaphone Phonem Phonix Soundex SoundexNara);

sub register_column {
    my ( $self, $column, $info, @rest ) = @_;

    $self->next::method( $column, $info, @rest );

    if ( my $config = $info->{phonetic_search} ) {
        $info->{phonetic_search} = $config = { algorithm => $config }
          unless ( ref $config eq "HASH" );
        $config->{algorithm} = 'Phonix'
          unless ( grep { $config->{algorithm} eq $_ } PHONETIC_ALGORITHMS );
        $self->add_column( $column
              . '_phonetic_'
              . lc( $config->{algorithm} ) =>
              { data_type => 'character varying', is_nullable => 1 } );
    }

    return undef;
}

sub store_column {
    my ( $self, $name, $value, @rest ) = @_;

    my $info = $self->column_info($name);

    if ( my $config = $info->{phonetic_search} ) {
        my $class  = 'Text::Phonetic::' . $config->{algorithm};
        my $column = $name . '_phonetic_' . lc( $config->{algorithm} );
        $self->_require_class($class);
        $self->set_column( $column, $class->new->encode($value) );
    }

    return $self->next::method( $name, $value, @rest );
}

sub sqlt_deploy_hook {
    my ($self, $table, @rest) = @_;
    $self->maybe::next::method($table, @rest);
    foreach my $column($self->columns) {
        next unless(my $config = $self->column_info($column)->{phonetic_search});
        next if($config->{no_indices});
        my $phonetic_column = $column.'_phonetic_' . lc( $config->{algorithm} );
        $table->add_index(name => 'idx_'.$phonetic_column, fields => [$phonetic_column]);
        $table->add_index(name => 'idx_'.$column, fields => [$column]);
        
    }
    
}

sub _require_class {
    my ($self, $class) = @_;

    croak "class argument missing" if !defined $class;

    $class =~ s|::|/|g;
    $class .= ".pm";

    if ( !exists $::INC{$class} ) {
        eval { require $class };
        croak $@ if $@;
    }

    return;
}

1;

__END__

=head1 NAME

DBIx::Class::PhoneticSearch - Phonetic search with DBIC

=head1 SYNOPSIS

    package MySchema::User;
  
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw(PhoneticSearch Core));

    __PACKAGE__->table('user');

    __PACKAGE__->add_columns(
      id       => { data_type => 'integer', auto_increment => 1, },
      surname  => { data_type => 'character varying', 
                    phonetic_search => 1 },
      forename => { data_type => 'character varying', 
                    phonetic_search => { algorithm => 'Koeln', 
                                         no_indices => 1 } },
      
    );

    __PACKAGE__->set_primary_key('id');

    __PACKAGE__->resultset_class('DBIx::Class::ResultSet::PhoneticSearch');
    
    
  # somewhere else
  $rs = $schema->resultset('User');
  $rs->create({ forename => 'John', surname => 'Night' });
  
  $rs->search_phonetic({ forename => 'Jon' })->first->forename;  # John
  $rs->search_phonetic({ surname => 'Knight' })->first->surname; # Night
  $rs->search_phonetic({ forename => 'Jon', 
                         surname => 'Knight' })->first->surname; # Night
  $rs->search_phonetic([ surname => 'Smith' ,
                         surname => 'Knight' ])->first->surname; # Night (ORed)
  
    

=head1 DESCRIPTION

This components allows for phonetic search of columns. 
If you add the C<phonetic_search> attribute to a 
column, this component will add an extra column to the result class which is basically an index of the value
based on its pronunciation. Every time the column is updated,
the phonetic column is set as well. It uses L<Text::Phonetic> to compute the phonetic representation
of the value in that column. Use L</search_phonetic> to search for rows which sound similar to a given value.

The name of the phonetic column consists of the original column name and the algorithm used:

  $column + _phonetic_ + $algorithm

The above example will require two additional columns:

  surname_phonetic_phonix character varying,
  forename_phonetic_koeln character varying,
  
Make sure they exist in you database!
  
  
The default algorithm is L<Text::Phonetic::Phonix>.

This component will also add indices for both the column and the phonetic column. This can be disabled by setting
L</no_indices>.

To set the phonetic column on an already populated resultset use L</update_phonetic_columns>.

=head1 RESULTSET METHODS

=head2 search_phonetic

This method is used to search a resultset for a given set of column/value pairs.

You can call this method with either an arrayref or hashref.
Arrayref will cause a query which will join the queries with C<OR>.
A hashref will join them with an C<AND>.

Returns a L<DBIx::Class::ResultSet>.

=head2 update_phonetic_column

  $rs->update_phonetic_column('columnname');

This method will update the phonetic column of a column. 

=head2 update_phonetic_columns

Calls L</update_phonetic_column> for each column with an phonetic column.

=head1 ADVANCED CONFIGURATION

=head2 algorithm

Choose one of C<DaitchMokotoff DoubleMetaphone Koeln Metaphone Phonem Phonix Soundex SoundexNara>.

See L<Text::Phonetic> for more details.

Defaults to C<Phonix>.

=head2 no_indices

By default this module will create indices on both the source column and the phonetic column. Set this attribute to a true value to disable this behaviour.

=head1 OVERWRITTEN RESULT METHODS

=head2 register_column

Set up the environment and add the phonetic columns.

=head2 store_column

Set the phonetic column to the encoded value.

=head2 sqlt_deploy_hook

This is where the indices are created.

=head1 AUTHOR

Moritz Onken, C<< <onken at netcubed.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-phoneticsearch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-PhoneticSearch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::PhoneticSearch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-PhoneticSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-PhoneticSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-PhoneticSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-PhoneticSearch/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

