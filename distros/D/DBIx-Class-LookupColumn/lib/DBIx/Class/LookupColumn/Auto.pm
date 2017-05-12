package DBIx::Class::LookupColumn::Auto;
{
  $DBIx::Class::LookupColumn::Auto::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

DBIx::Class::LookupColumn::Auto - A dbic component for installing LookupColumn relations on a whole schema at once.

=cut


use base qw(DBIx::Class);

use Data::Dumper;
use Smart::Comments -ENV;
use Hash::Merge::Simple qw/merge/;
use Carp qw(confess);
use DBIx::Class::LookupColumn::LookupColumnComponent;


=head1 SYNOPSIS

 package MySchema; 

 __PACKAGE__->load_components( qw/LookupColumn::Auto/ );

 my @tables = __PACKAGE__->sources; # get all table names 
 
 my @candidates =  grep { ! /Type$/ } @tables;  # tables that do NOT end with Type
 my @lookups =  grep {  /Type$/ } @tables;      # tables that DO end with Type == the Lookup Tables !

 __PACKAGE__->add_lookups(
	targets => \@candidates, 
	lookups => \@lookups,
	
	# function that will generate the relation names: here we build it from the Lookup Table
	relation_name_builder => sub{
		my ( $class, %args) = @_;
		$args{lookup} =~ /^(.+)Type$/; # remove the end (Type) from the Lookup table name
		lc( $1 );
	},
	# function that gives the name of the column that holds the definitions/values: here it is always 'name'
	lookup_field_name_builder => sub { 'name' } 
 );


=head1 DESCRIPTION

This component automates the addition of the B<Lookup> (see L<DBIx::Class::LookupColumn/Lookup Tables>) relations to a whole set of tables.

Given a set of potential target tables (the tables on which to add the Lookup relations), and a set of Lookup tables,
the component will select all the I<belongs_to> relations defined in the target tables pointing to a Lookup table present in the set
and add a Lookup relation automatically.

It is also possible to add accessors manuall by doing a copy/paste of the code diplayed with the verbose option (See L<add_lookups>).


=head1 METHODS

=head2 add_lookups

 __PACKAGE__->add_lookups( { targets => [], lookups => [], relation_name_builder? => sub {}, lookup_field_name_builder? => sub {}, verbose? => boolean } )

This will iterate through the set of B<targets> tables on all B<belongs_to> relations pointing to a table included in B<lookups>
and add a corresponding relation.

B<Arguments (hash keys) >:

=over 4

=item targets

An ArrayRef of the names of the tables on which to detect and install the Lookup relations.

=item lookups

An ArrayRef of the names of the Lookup tables.

=item relation_name_builder?

Optional. FuncRef for building the accessors base name. By default the name of the Lookup table in small caps.
Arguments (hash keys) : { target => ?, lookup => ?, foreign_key => ? }.

=item lookup_field_name_builder?

Optional. FuncRef for specifying the concerned column name in the Lookup table. By default the first I<varchar> type column in the Lookup table.

=item verbose?

Optional. Boolean for displaying the code for adding a Lookup relation. Copy/paste it the right place of your code. By default set to false, then non-verbose.
 	
=back



=cut

sub add_lookups {

    my ( $class, %args ) = @_;
    
    
    my $targets_array_ref	= exists ( $args{targets} ) ? $args{targets} : confess 'targets arg is missing';
    my $lookups_array_ref	= exists ( $args{lookups} ) ? $args{lookups} : confess 'lookups arg is missing';
        
	my $options = {};
    if ( exists ( $args{relation_name_builder} ) )	{  $options->{relation_name_builder}	= $args{relation_name_builder} ;}
    if ( exists ( $args{lookup_field_name_builder})){ $options->{lookup_field_name_builder}	= $args{lookup_field_name_builder};}
    if ( exists ( $args{verbose} )				  )	{ $options->{verbose}	= $args{verbose}									;}
    
    my $defaults = {  
    				relation_name_builder => \&_guess_relation_name,
    				lookup_field_name_builder  => \&_guess_field_name,
    				verbose	=> 0
    				};


	my $params = merge $defaults, $options;

	my $verbose = $params->{verbose};
	
    my $target2lkp_hash_ref = $class->_target2lookups( $targets_array_ref,  $lookups_array_ref );
    
    #### target2lookups returned: $target2lkp_hash_ref
    
    my ( $target, $fk2lkp_hash_ref);
    while ( ( $target, $fk2lkp_hash_ref ) = each ( %$target2lkp_hash_ref ) ) {
    	 if($verbose) {
 			warn "adding to package $target\n";
 			warn "__PACKAGE__->load_components(LookupColumn)\n";
    	 }
 		foreach my $fk (keys %$fk2lkp_hash_ref) {
 			
 			my $lookup = $fk2lkp_hash_ref->{$fk};
 		
 			my @args = (
 				$params->{relation_name_builder}->( $class, target => $target, lookup => $lookup, foreign_key => $fk ),
 				$fk, $lookup, 
 				{
							field_name => $params->{lookup_field_name_builder}->( $class, target => $target, lookup => $lookup, foreign_key => $fk )
				}
			);

  			if($verbose) {
 				my $s = Dumper(\@args);
 				$s =~ s/^[^\[]*\[(.+)\];.*/$1/s;
 				warn "__PACKAGE__->add_lookup($s)\n" ;
 			}
			DBIx::Class::LookupColumn::LookupColumnComponent::add_lookup( $class->class( $target), @args );
 		}
    }
}


sub _target2lookups {
	my ( $class, $targets_array_ref, $lookups_array_ref ) = @_;
	
	my %lookups = map { ($class->class( $_ ), $_) } @$lookups_array_ref;
	
	my %relationships;
	foreach my $target ( @$targets_array_ref ) {
		#### processing target table: $target		        
		my $target_class = $class->class( $target );
		
		foreach my $rel ($target_class->relationships) {
			#### processing relation : $rel
			my $info = $target_class->relationship_info($rel);
			
			#### relationship_info:  $info
			
			next unless exists $lookups{$info->{source}};  # is the relation to a lookup
			
			my @fk_columns = keys %{$info->{attrs}->{fk_columns}};
			next if @fk_columns > 1; # if multiple foreign keys, not a belongs_to ?
			
			unless (@fk_columns) {
				### skipping relation because there is no foreign key, for table and relation:  $target, $rel
				next;
			}
			my $fk = shift @fk_columns; 
			 
			next unless $info->{attrs}->{accessor} eq 'single'; # heuristic to detect belongs_to relation
			
			$relationships{$target}->{$fk} = $lookups{$info->{source}};
		}
	}
	
	return \%relationships;
}




sub _guess_relation_name{
	my ( $class, %args ) = @_;
	return lc( $args{lookup});
}


  

sub _guess_field_name {
	my ( $class, %args ) = @_;
	
	my $schema	= $class;
	my $lookup	= $args{lookup};
	
	my @columns = $schema->source( $lookup )->columns;
	my @primary_columns = $schema->source(  $lookup )->primary_columns;
	my @columns_without_primary_keys = grep{ !($_ ~~ @primary_columns) }  @columns;
	my $guessed_field;
	
	# classic lookup table with only two columns
	if ( @columns == 2 && @columns_without_primary_keys == 1){
		$guessed_field = shift @columns_without_primary_keys; 
	}
	# lookup table with more than two columns
	else{
		foreach my $column ( @columns_without_primary_keys ){
			my $column_metas = $schema->source( $lookup )->column_info( $column );
			
			if ( $column_metas->{data_type} =~ /varchar/ ){
				#select the first varchar column 
				$guessed_field = $column;
				last;
			 }
		}
	}
	return $guessed_field;
}




=head1 AUTHORS

Karl Forner <karl.forner@gmail.com>

Thomas Rubattel <rubattel@cpan.org>


=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-lookupcolumn-auto at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-LookupColumn-Auto>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::LookupColumn::Auto


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-LookupColumn-Auto>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-LookupColumn-Auto>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-LookupColumn-Auto>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-LookupColumn-Auto/>

=back



=head1 LICENCE AND COPYRIGHT

Copyright 2012 Karl Forner and Thomas Rubattel, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms as Perl itself.

=cut

1; # End of DBIx::Class::LookupColumn::Auto
