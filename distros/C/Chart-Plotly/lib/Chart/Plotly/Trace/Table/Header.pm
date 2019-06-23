package Chart::Plotly::Trace::Table::Header;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Table::Header::Fill;
use Chart::Plotly::Trace::Table::Header::Font;
use Chart::Plotly::Trace::Table::Header::Line;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace table.

sub TO_JSON {
    my $self       = shift;
    my $extra_args = $self->extra_args // {};
    my $meta       = $self->meta;
    my %hash       = %$self;
    for my $name ( sort keys %hash ) {
        my $attr = $meta->get_attribute($name);
        if ( defined $attr ) {
            my $value = $hash{$name};
            my $type  = $attr->type_constraint;
            if ( $type && $type->equals('Bool') ) {
                $hash{$name} = $value ? \1 : \0;
            }
        }
    }
    %hash = ( %hash, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has align => (
    is  => "rw",
    isa => union( [ enum( [ "left", "center", "right" ] ), "ArrayRef" ] ),
    documentation =>
      "Sets the horizontal alignment of the `text` within the box. Has an effect only if `text` spans more two or more lines (i.e. `text` contains one or more <br> HTML tags) or if an explicit width is set to override the text width.",
);

has alignsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  align .",
);

has fill => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Table::Header::Fill", );

has font => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Table::Header::Font", );

has format => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Sets the cell value formatting rule using d3 formatting mini-language which is similar to those of Python. See https://github.com/d3/d3-format/blob/master/README.md#locale_format",
);

has formatsrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on plot.ly for  format .",
);

has height => ( is            => "rw",
                isa           => "Num",
                documentation => "The height of cells.",
);

has line => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Table::Header::Line", );

has prefix => ( is            => "rw",
                isa           => "Str|ArrayRef[Str]",
                documentation => "Prefix for cell values.",
);

has prefixsrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on plot.ly for  prefix .",
);

has suffix => ( is            => "rw",
                isa           => "Str|ArrayRef[Str]",
                documentation => "Suffix for cell values.",
);

has suffixsrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on plot.ly for  suffix .",
);

has values => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Header cell values. `values[m][n]` represents the value of the `n`th point in column `m`, therefore the `values[m]` vector length for all columns must be the same (longer vectors will be truncated). Each value must be a finite number or a string.",
);

has valuessrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on plot.ly for  values .",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Table::Header - This attribute is one of the possible options for the trace table.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Table;
 # Example data from: https://plot.ly/javascript/table/#basic-table
 my $table = Chart::Plotly::Trace::Table->new(
 
     header => {
         values => [ [ "EXPENSES" ], [ "Q1" ],
             [ "Q2" ], [ "Q3" ], [ "Q4" ] ],
         align  => "center",
         line   => { width => 1, color => 'black' },
         fill   => { color => "grey" },
         font   => { family => "Arial", size => 12, color => "white" }
     },
     cells  => {
         values => [
             [ 'Salaries', 'Office', 'Merchandise', 'Legal', 'TOTAL' ],
             [ 1200000, 20000, 80000, 2000, 12120000 ],
             [ 1300000, 20000, 70000, 2000, 130902000 ],
             [ 1300000, 20000, 120000, 2000, 131222000 ],
             [ 1400000, 20000, 90000, 2000, 14102000 ] ],
         align  => "center",
         line   => { color => "black", width => 1 },
         font   => { family => "Arial", size => 11, color => [ "black" ] }
     }
 );
 
 show_plot([ $table ]);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace table.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#table>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * align

Sets the horizontal alignment of the `text` within the box. Has an effect only if `text` spans more two or more lines (i.e. `text` contains one or more <br> HTML tags) or if an explicit width is set to override the text width.

=item * alignsrc

Sets the source reference on plot.ly for  align .

=item * fill

=item * font

=item * format

Sets the cell value formatting rule using d3 formatting mini-language which is similar to those of Python. See https://github.com/d3/d3-format/blob/master/README.md#locale_format

=item * formatsrc

Sets the source reference on plot.ly for  format .

=item * height

The height of cells.

=item * line

=item * prefix

Prefix for cell values.

=item * prefixsrc

Sets the source reference on plot.ly for  prefix .

=item * suffix

Suffix for cell values.

=item * suffixsrc

Sets the source reference on plot.ly for  suffix .

=item * values

Header cell values. `values[m][n]` represents the value of the `n`th point in column `m`, therefore the `values[m]` vector length for all columns must be the same (longer vectors will be truncated). Each value must be a finite number or a string.

=item * valuessrc

Sets the source reference on plot.ly for  values .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
