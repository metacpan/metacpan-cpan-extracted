package Chart::Plotly::Trace::Heatmap::Stream;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

our $VERSION = '0.042';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace heatmap.

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

has maxpoints => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the maximum number of points to keep on the plots from an incoming stream. If `maxpoints` is set to *50*, only the newest 50 points will be displayed on the plot.",
);

has token => (
    is            => "rw",
    isa           => "Str",
    documentation =>
      "The stream id number links a data trace on a plot with a stream. See https://chart-studio.plotly.com/settings for more details.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Heatmap::Stream - This attribute is one of the possible options for the trace heatmap.

=head1 VERSION

version 0.042

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Heatmap;
 use English qw(-no_match_vars);
 
 my $heatmap = Chart::Plotly::Trace::Heatmap->new(
     x => [ 0 .. 10 ],
     y => [ 0 .. 10 ],
     z => [
         map {
             my $y = $ARG;
             [ map { $ARG * $ARG + $y * $y } ( 0 .. 10 ) ]
         } ( 0 .. 10 )
     ]
 );
 
 show_plot( [$heatmap] );

=head1 DESCRIPTION

This attribute is part of the possible options for the trace heatmap.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#heatmap>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * maxpoints

Sets the maximum number of points to keep on the plots from an incoming stream. If `maxpoints` is set to *50*, only the newest 50 points will be displayed on the plot.

=item * token

The stream id number links a data trace on a plot with a stream. See https://chart-studio.plotly.com/settings for more details.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
