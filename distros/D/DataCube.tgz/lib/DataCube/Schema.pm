


package DataCube::Schema;

use strict;
use warnings;
use Digest::MD5;

sub new {
    my($class,%opts) = @_;
    bless {
        %opts,
        parents           => {},
        measures          => [],
        hierarchies       => [],
        computed_measures => [],
    }, ref($class) || $class;
}

sub add_hierarchy {
    my($self,@hierarchy) = @_;
    $self->add_strict_hierarchy(undef,@hierarchy);
}

sub add_strict_hierarchy {
    my($self,@hierarchy) = @_;
    for(my $i = 0; $i < $#hierarchy; $i++){
        next unless my $parent = $hierarchy[$i];
        my $child = $hierarchy[$i+1];
        $self->{parents}->{$parent}->{$child} = undef;
    }
    $self->{field_names}->{$_} = undef for grep { defined } @hierarchy;
    push @{$self->{hierarchies}}, [@hierarchy];
}

sub initialize {
    my($self,%opts)      = @_;
    $self->{fields}      = [sort keys %{$self->{field_names}}];
    my $name             = join("\t", @{$self->{fields}});
    $self->{name}        = length($name) ? $name : 'overall';
    $self->{name_digest} = Digest::MD5->new->add($self->{name})->hexdigest;
    field_count:{
        ($self->{field_count}) = 0 and last field_count if $self->{name} eq 'overall';
         $self->{field_count}  = $self->{name} =~ s/\t/\t/g + 1; 
    }
    measure_string:
    for(my $i = 0; $i < @{$self->{measures}}; $i++){
        my @measure = @{$self->{measures}->[$i]};
        next measure_string if $self->{measures}->[$i][2] || $self->{measures}->[$i][0] eq 'key_count';
        $self->{measures}->[$i][2] = join('__',@{$self->{measures}->[$i]});
    }
    $self->{initialized} = 1;
    return $self;
}

sub columns {
    my($self) = @_;
    return $self->fields, $self->measure_names
}

sub measure_names {
    my($self) = @_;
    map { $_->[2] } $self->measures
}

sub confine_to {
    my($self,@fields) = @_;
    $self->{confine_to} = join("\t",sort @fields);
    return $self;
}

sub confine_to_base {
    my($self) = @_;
    $self->{confine_to_base} = 1;
    return $self;
}

sub is_confined {
    my($self) = @_;
    return $self->{confine_to};
}

sub strict_dimensions {
    my($self) = @_;
    return [] unless $self->has_strict_hierarchies;
    my $hierarchies = $self->hierarchies;
    my @dims;
    for(@$hierarchies){
        push @dims, $_->[0] if defined $_->[0];
    }
    return \@dims;
}

sub has_strict_hierarchies {
    my($self) = @_;
    my $hierarchies = $self->hierarchies;
    for(@$hierarchies){
        return 1 if defined $_->[0];
    }
    return 0;
}

sub has_asserted_lattice_points {
    my($self) = @_;
    my $points = $self->{asserted_lattice_points};
    return 1 if $points
         && ref($points)
         && ref($points) =~ /^hash$/i
         && keys %$points;  
    return 0;
}

sub add_strict_dimension {
    my($self,$dimension) = @_;
    $self->add_strict_hierarchy($dimension);
}

sub add_dimension {
    my($self,$dimension) = @_;
    $self->add_hierarchy($dimension);
}

sub add_measure {
    my($self,@measure) = @_;
    @measure = ('key_count') if @measure == 1 && $measure[0] eq 'count';
    push @{$self->{measures}}, [@measure];
}

sub add_computed_measure {
    my($self,@measure) = @_;
    push @{$self->{computed_measures}}, [@measure];
}

sub suppress_lattice_point {
    my($self,@point) = @_;
    my $point = join("\t",sort @point);
    $self->{suppressed_lattice_points}->{$point} = undef;
}

sub filter_lattice_point {
    my( $self, $code ) = @_;
    push @{ $self->{lattice_point_filters} }, $code; 
}

sub assert_lattice_point {
    my($self,@point,%point,$name) = @_;
    assert_opts:{
        if(@point % 2 == 0){
            %point = @point;
            $point{dims} ||= $point{dimensions};
            if($point{dims} && ref($point{dims}) =~ /^array$/i){
                @point = @{$point{dims}};
                $name  = $point{name} if $point{name};
            }
        }
    }
    my $point = join("\t",sort @point);
    $self->{lattice_point_names}->{$point} = $name;
    $self->{asserted_lattice_points}->{$point} = undef;
    return $self;
}

sub is_initialized {
    my($self) = @_;
    return $self->{initialized};
}

sub measures {
    my($self) = @_;
    @{$self->{measures}}
}

sub hierarchies {
    my($self) = @_;
    return $self->{hierarchies}
}

sub field_names {
    my($self) = @_;
    sort keys %{$self->{field_names}}
}

sub fields {
    my($self) = @_;
    return @{$self->{fields}};
}

sub field_count {
    my($self) = @_;
    return $self->{field_count};
}

sub measure_count {
    my($self) = @_;
    return scalar @{$self->{measures}};
}

sub name {
    my($self) = @_;
    return $self->{name};
}

sub name_digest {
    my($self) = @_;
    return $self->{name_digest};
}

sub lattice_point_name {
    my($self) = @_;
    return $self->{lattice_point_name};
}

sub asserted_lattice_points {
    my($self) = @_;
    return $self->{asserted_lattice_points};
}

sub safe_file_name {
    my($self) = @_;
    my $name = $self->name;
   (my $file_name = $name) =~ s/\t+/__/g;
    $file_name = $self->lattice_point_name
        if defined($self->lattice_point_name);
    return $file_name;
}

sub pg_types {
    my($self) = @_;
    
    my %types;

    for( $self->fields ) {
        $types{ $_ } = 'text'
    }

    for( $self->measures ) {
        if( $_->[0] eq 'sum' ) {
            $types{ $_->[2] } = 'numeric not null';
            next
        }
        die "Measure $_->[0] not yet implemented in pg_types";
    }
    
    %types;
}




sub check_conflicts {
    my($self) = @_;
    my @conflicts;
    
    strict_assertions:{
        last strict_assertions unless $self->has_asserted_lattice_points && $self->has_strict_hierarchies;
        my $strict = $self->strict_dimensions;
        my $points = $self->asserted_lattice_points;
        for(@$strict){
            my $dim = $_;
            for(keys %$points){
                my @fields = split/\t/,$_,-1;    
                my %fields = map { $_ => undef } @fields;
                push @conflicts, {
                    category      => 'strict dimensions versus asserted lattice points',
                    dimension     => $dim,
                    lattice_point => $_,
                    message       => "\n\n\tThe dimension\n\n\t\t$dim\n\n\tis marked as strict ".
                                     "but this conflicts with the asserted lattice point:\n\n\t\t$_\n\n\t" .
                                     "which does not contain this dimension\n",
                } unless exists $fields{$dim};
            }      
        }
    }
    
    confine:{
        if(my $confine = $self->is_confined){
            my @confine = split/\t/,$confine,-1;
            my %confine = map { $_ => undef } @confine;
            for(@confine){
                my $dim = $_;
                unless(exists $self->{field_names}->{$_}){
                    push @conflicts, {
                        category  => 'confined lattice point is not valid',
                        confine   => $confine,
                        dimension => $_,
                        message   => "\n\n\tThe dimension\n\n\t\t$dim\n\n\tis confined ".
                                     "but no such dimension exists in your schema\n",
                    };
                }
                for(keys %{$self->{parents}}){
                    my $parent = $_;
                    if(exists $self->{parents}->{$parent}->{$dim} && ! exists $confine{$parent}){
                        push @conflicts, {
                            category  => 'confined lattice point breaks hierarchical constraints',
                            confine   => $confine,
                            dimension => $dim,
                            parent    => $parent,
                            message   => "\n\n\tThe dimension\n\n\t\t$dim\n\n\tis confined ".
                                     "but the parent:\n\n\t\t$parent\n\n\tis not included\n",
                        }; 
                    }
                }
            }
        }
    }
    
    if(@conflicts){
        printf "\nconflicts were detected in your schema that must be resolved before cube creation:\n";
        print '-'x100,"\n\n";
        for(@conflicts){
            my $reason = $_;
            for(sort keys %$reason){
                next if /^message$/i;
                printf " %-15s  =>  %s\n",$_,$reason->{$_};
            }
            print "\n message:" . $reason->{message};
            print "\n",'-'x100,"\n";
        }
        die "\nplease fix these conflicts before continuing\n\n";
    }
    
    return $self;
}




1;






__END__


=head1 NAME

DataCube::Schema - An Object Oriented Perl Module for creating Snowflake Schemas.

=head1 SYNOPSIS

  use strict;
  use warnings;
  
  use DataCube::Schema;
  

  # the new constructor
  
  my $schema = DataCube::Schema->new;
    
  
  # basic: adding dimensions, hierarchies and measures
  
  $schema->add_dimension('country');
  $schema->add_dimension('product');
  $schema->add_dimension('salesperson');
  
  $schema->add_hierarchy('year','quarter','month','day');
  
  $schema->add_measure('sum','units_sold');
  $schema->add_measure('sum','dollar_volume');
  $schema->add_measure('average','price_per_unit');
  
    
  # advanced: adding strict dimensions / hierarchies
  
  $schema->add_strict_dimension('country');
  $schema->add_strict_hierarchy('year','quarter','month','day');
  
  
  # advanced: suppressing lattice points
    
  $schema->suppress_lattice_point('country','salesperson');
  
  
  
  

=head1 DESCRIPTION

This module provides a pure perl, object oriented, embeddable Star and Snowflake Schema engine.
It is self contained and ready to use in data mining and data warehousing applications.

All schemas created by this module are Snowflake Schemas.


=head2 BACKGROUND


Star and Snowflake Schemas are used to organize dimensions and measurements in Data Warehouses.
Snowflake Schemas encompass all the functionality of Star Schemas, and provide direct support for hierarchies. 



=head2 STAR SCHEMAS

=over 2

In a Star Schema, many peripheral tables of data are joined to one central table called the E<quot>Fact TableE<quot>.
Each peripheral table represents a single dimension.

=back


=head2 SNOWFLAKE SCHEMAS

=over 2

The Snowflake Schema is an extension of the Star Schema, in which each peripheral E<quot>Dimension TableE<quot> holding
hierarchical data is replaced by a group of tables representing that hierarchy.

To illustrate the difference, consider a single table in a Star Schema which contains a date field of the form E<quot>year/month/dayE<quot>.
In a Snowflake Schema, this table would be replaced by 3 tables:  one containg the year, one containing the month, and one containing the day,
all linked together by a primary key / foreign key relationship.


=back


=head2 FACT TABLES

=over 2

A special table called the E<quot>Fact TableE<quot> resides in the middle of both Star and Snowflake Schemas.
Fact Tables contain a single row of data for each factual event logged during the course of business.

The Fact Table contains redundant and repetitious data (usually in Second Normal Form)
and is therefore subject to update anamolies.  For this reason, Snowflake Schemas should rarely be used for high performance Relational Databases.
They should be used, however, to design E<quot>Dimensional DatabasesE<quot> and Data Warehouses,
where such redundancy allows for extreme performance gains for complex sql queries,
especially those containing aggregation functions on hierarchical relationships.

=back




=head1 BASIC OPERATIONS


This module provides several methods to design Snowflake Schemas. 



=head3 add_dimension

=over 3

This method adds a single dimension to a schema.  

=back


=head3 add_measure

=over 3

This method adds a single measures to the cubes measure table.

Supported measures inlcude:

    count
    min         [field name]
    max         [field name]
    sum         [field name]
    count       [field name]
    average     [field name]
    product     [field name]
    multi_count [field name]

Here is a description of each measure:


    count
    
    init_value     0
    update_rule    ++
    report_format  integer
    additivity     additive
    declaration    $schema->add_measure('count')
    description    the number of times a dimensional tuple has been inserted into the cube



    min
    
    init_value     undef
    update_rule    = if < or undefined
    report_format  decimal
    additivity     additive
    declaration    $schema->add_measure('min','field')
    description    the minimal value of inserted numbers from 'field'



    max
    
    init_value     undef
    update_rule    = if > or undefined
    report_format  decimal
    additivity     additive
    declaration    $schema->add_measure('max','field')
    description    the maximal value of inserted numbers from 'field'



    sum
    
    init_value     0
    update_rule    +=
    report_format  decimal
    additivity     additive
    declaration    $schema->add_measure('sum','field')
    description    the sum of inserted numbers from 'field'



    product
    
    init_value     1
    update_rule    *=
    report_format  decimal
    additivity     additive (ie separable)
    declaration    $schema->add_measure('product','field')
    description    the multiplication of inserted numbers from 'field'



    average
    
    init_value     0
    update_rule    {average}->{$field}->{sum_total}   += $field_value;
                   {average}->{$field}->{observations}++
    report_format  decimal (sum_total / observations)
    additivity     non-additive
    declaration    $schema->add_measure('average','field')
    description    the average of inserted values from 'field'



    count (distinct) 
    
    init_value     {} (empty hashref)
    update_rule    {count}->{$field}->{$field_value} = undef
    report_format  integer (ie scalar(keys(%{{count}->{$field}->{$field_value}})))
    additivity     non-additive
    declaration    $schema->add_measure('count','field')
    description    the count distinct of inserted values from 'field'



    multi_count (distinct with multiplicity) 
    
    init_value     {} (empty hashref)
    update_rule    {count}->{$field}->{$field_value}++
    report_format  integer (same as count)
    additivity     non-additive
    declaration    $schema->add_measure('multi_count','field')
    description    the count distinct of inserted values from 'field', also stores the *number of times* that $field_value was 'uniquefied'

=back


=head3 add_hierarchy


=over 3

This method adds a single hierarchy to a schema.  Hierarchies are like Dimensions, except that aggregate measures will be computed on complete Parent - Child chains.

For example, consider the hierarchy E<quot>yearE<quot>, E<quot>monthE<quot>, 
E<quot>dayE<quot> and the measure E<quot>sumE<quot> of E<quot>dollarsE<quot>.

The following code:

  $schema->add_measure('sum','dollars');
  $schema->add_hierarchy('year','month','day');
  
  $cube = DataCube->new($schema);

  # a bunch of data is fed to the cube
  #
  # [...]
  #
  # and some time later:

  $cube->rollup;
  $cube->report;


will create the following reports:

  1.  sum_of_dollars
  2.  sum_of_dollars by year
  3.  sum_of_dollars by year, month
  4.  sum_of_dollars by year, month, day 

as it probably should.


=back




=head1 ADVANCED OPERATIONS


=over 3

=back

=head3 add_strict_dimension

This method adds a single dimension to a schema, over which no aggregation will be performed.

For example, consider the following code:

  $schema->add_dimension('product');
  $schema->add_strict_dimension('country');

  $schema->add_measure('sum','dollars');
  
  $cube = DataCube->new($schema);

  # a bunch of data is fed to the cube
  #
  # [...]
  #
  # and some time later:

  $cube->rollup;
  $cube->report;


will create the following reports:

  1.  sum_of_dollars by country
  2.  sum_of_dollars by country, product

Notice that the datacube did not produce the sum_of_dollars irrespective of country.


=over 3

=back



=head3 add_strict_hierarchy


This method adds a single hierarchy to a schema.  No aggregation will be performed over the top-most dimension. 

=over 3

=back




=head3 suppress_lattice_point

=over 3

This method suppresses specific rollups / reports from being created during a call to rollup, which may lead to a saving of both time and space.

For example, consider the following code:

  $schema->add_measure('sum','dollars');
  $schema->add_hierarchy('year','month','day');
  $schema->suppress_lattice_point('year','month');
  
  $cube = DataCube->new($schema);

  # a bunch of data is fed to the cube
  #
  # [...]
  #
  # and some time later:

  $cube->rollup;
  $cube->report;


will create the following reports:

  1.  sum_of_dollars
  2.  sum_of_dollars by year
  3.  sum_of_dollars by year, month, day 




=back

=head3 assert_lattice_point

=over 3

This method restricts a datacube to only the specified list of dimensions during rollup.

This method superscedes all others except for add_strict_dimension and add_strict_hierarchy, and may lead to a saving of both time and space.

For example, consider the following code:

  $schema->add_measure('sum','dollars');
  $schema->add_hierarchy('year','month','day');
  
  $schema->assert_lattice_point('overall');
  $schema->assert_lattice_point('year','month');
  
  $cube = DataCube->new($schema);

  # a bunch of data is fed to the cube
  #
  # [...]
  #
  # and some time later:

  $cube->rollup;
  $cube->report;


will create the following reports:

  1.  sum_of_dollars
  2.  sum_of_dollars by year, month
  
If you do this:

  $schema->add_measure('sum','dollars');
  $schema->add_strict_hierarchy('year','month','day');
  
  $schema->assert_lattice_point('overall');
  $schema->assert_lattice_point('year','month');

you will not get the report

  1.  sum_of_dollars

because the method call

  $schema->add_strict_hierarchy('year','month','day');
  
confines 'year' to always be present.

When in doubt, do not use 'assert_lattice_point' in the presence of the other lattice assertions (such as 'strict' and 'suppress'). 

=back



=head3 confine_to

=over 3

This method restricts a datacube to only the specified list of dimensions and superscedes all other methods.

The base table becomes fixed to the confined point and no rollup occurs even if called.

For example, consider the following code:

    my $schema = DataCube::Schema->new;
    $schema->add_dimension('country');
    $schema->add_dimension('product');
    $schema->add_dimension('salesperson');
    
    $schema->add_hierarchy('year','quarter','month','day');
    
    $schema->add_measure('sum','units_sold');
    $schema->add_measure('sum','dollar_volume');
    $schema->add_measure('average','price_per_unit');
    
    $schema->confine_to('country','product','year');
    
    my $cube = DataCube->new($schema);


will create a cube with only one table (the base table: 'country','product','year') and only one report:

  1.  sum_of_dollars etc. by country, product, year

=back



=head1 EXPORT

None

=head1 SEE ALSO



Wikipedia on Snowflake Schema:

http://en.wikipedia.org/wiki/Snowflake_schema


=head1 AUTHOR

David Williams, E<lt>david@namimedia.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by David Williams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut














