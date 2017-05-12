package Data::Tabulate;

use warnings;
use strict;
use Carp;

# ABSTRACT: Table generation!

our $VERSION = '0.07';


sub new {
    my ($class) = @_;
    
    my $self = {};
    bless $self,$class;
    
    $self->max_columns(100_000);
    $self->min_columns(1);
    
    return $self;
}


sub render {
    my ($self,$module,$atts) = @_;
    
    unless(defined $atts and ref($atts) eq 'HASH' and
           exists $atts->{data} and ref($atts->{data}) eq 'ARRAY'){
        croak "no data given";
    }
    
    my @data = @{$atts->{data}};
    my $tmp  = $module;
    $module  = 'Data::Tabulate::Plugin::'.$module;
    
    $self->_load_module($module);
    
    @data          = $self->_data() unless @data;
    my @table      = $self->tabulate(@data);
    my $plugin_obj = $module->new();
    
    for my $method(@{$self->{method_calls}->{$tmp}}){
        if($plugin_obj->can($method->[0])){
            no strict 'refs';
            my $method_name = $method->[0];
            my @params      = @{$method->[1]}; 
            $plugin_obj->$method_name(@params);
        }
    }
    
    return $plugin_obj->output(@table);
}


sub tabulate {
    my ($self,@data) = @_;
    
    my $nr   = scalar @data;
    my $cols = int sqrt $nr;
    
    # the calculated number of columns should not exceed the maximum
    # number of columns that the user has specified
    if($cols > $self->max_columns){
        $cols    = $self->max_columns;
    }
    
    # the calculated number of columns should be greater the minimum
    # number of columns that the user has specified
    if($cols < $self->min_columns){
        $cols    = $self->min_columns;
    }
    
    $self->{cols} = $cols;
    
    my $index = $cols - 1;
    
    # tabulate data
    my @tmp_data;
    while ( $index < $nr ) {
        my $start = $index - $cols + 1;
        push @tmp_data, [ @data[ $start .. $index ] ];
        $index += $cols;
    }
               
    my $fill_value = $self->{fill_value};

    my $rest = ($cols - ($nr % $cols)) % $cols;
    $self->{rest} = $rest;
    if($rest > 0){
        
        my $start = $nr - ($cols - $rest);
        my $end   = $nr - 1;
        
        push @tmp_data, [
            @data[$start..$end],
            ($fill_value) x $rest,
        ];
    }
    
    $self->{rows} = scalar @tmp_data;
               
    return @tmp_data;
}


sub fill_with {
    my ($self,$value) = @_;
    
    $self->{fill_value} = $value;
}


sub cols{
    my ($self) = @_;
    return $self->{cols};
}


sub rows{
    my ($self) = @_;
    return $self->{rows};
}


sub max_columns{
    my ($self,$value) = @_;
    
    $self->{max_cols} = $value if defined $value and $value =~ /^[1-9]\d*$/;
    
    my $caller = (caller(1))[3];
    unless( ($caller and $caller =~ /min_columns/) or not defined $self->min_columns){
        $self->min_columns($self->{max_cols}) if $self->{max_cols} < $self->min_columns;
    }
    
    return $self->{max_cols};
}


sub min_columns{
    my ($self,$value) = @_;
    
    $self->{min_cols} = $value if defined $value and $value =~ /^[1-9]\d*$/;
    
    my $caller = (caller(1))[3];
    unless( $caller and $caller =~ /max_columns/){
        $self->max_columns($self->{min_cols}) if $self->{min_cols} > $self->max_columns;
    }
    
    return $self->{min_cols};
}


sub do_func{
    my ($self,$module,$method,@params) = @_;
    
    push @{$self->{method_calls}->{$module}},[$method,[@params]];
}


sub reset_func{
    my ($self,$module) = @_;
    delete $self->{method_calls}->{$module};
}


#------------------------------------------------------------------------------#
#                      "private" methods                                       #
#------------------------------------------------------------------------------#

sub _load_module {
    my ($self,$module) = @_;
    eval "use $module";
    croak "could not load $module" if $@; 
}

sub _data{
    my ($self,@data) = @_;
    $self->{data} = [@data] if @data;
    return @{$self->{data}};
}

1; # End of Data::Tabulate

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Tabulate - Table generation!

=head1 VERSION

version 0.07

=head1 SYNOPSIS

C<Data::Tabulate> aims to simplify the generation of tables. Often you don't have
tables like in databases (with header and several rows of data), but tables with
content only (like image galleries or listings displayed as tables).

You can use other modules (e.g. HTML::Table) to produce specific output.

Perhaps a little code snippet.

    use Data::Tabulate;
    use Data::Dumper;
    
    my @array = qw(1..12);
    
    my $foo   = Data::Tabulate->new();
    my @table = $foo->tabulate(@array);
    
    my $html  = $foo->render('HTMLTable',@array);

=head1 METHODS

=head2 new

create a new object of C<Data::Tabulate>.

=head2 render ( $plugin, {data => \@array [, attr => {%hash}]} )

This methods loads the Plugin I<$plugin> and renders the table with the plugin.

Example:

    my $html_table = $tabulator->render('HTMLTable',{data => [1..10]});

loads the module C<Data::Tabulate::Plugin::HTMLTable> and returns this string:

  <table>
  <tr><td>1</td><td>2</td><td>3</td></tr>
  <tr><td>4</td><td>5</td><td>6</td></tr>
  <tr><td>7</td><td>8</td><td>9</td></tr>
  <tr><td>10</td><td>&nbsp;</td><td>&nbsp;</td></tr>
  </table>

You can write your own plugins.

=head2 tabulate( @array )

This methods creates an array of arrays that can be used to render a table
or you can do your own thing with the array.

    my @array = $tabulator->tabulate(1..10);

returns

    (
      [ 1,     2,     3 ],
      [ 4,     5,     6 ],
      [ 7,     8,     9 ],
      [10, undef, undef ],
    )

=head2 fill_with

if the array doesn't provide enough elements the table is filled with 'undef' elements
sometimes this is not the wanted behaviour. So you can change the value that is used
to fill the array.

  $obj->fill_with( 'hi' );

for an example see t/04_fill_with.t

=head2 cols

returns the number of columns the table has

=head2 rows

returns the number of rows the table has

=head2 max_columns

set how many columns the table can have (at most).

    $tabulator->max_columns(3);

the table has at most three columns

=head2 min_columns

set how many columns the table can have (at least).

    $tabulator->min_columns(3);

the table has at least three columns

=head2 do_func($module, $method, @params)

If you need to call some methods of the rendering object, you can use this
method, to prepare these method calls.

=head2 reset_func( $module )

reset the method call preperations

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
