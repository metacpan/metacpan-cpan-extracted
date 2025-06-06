package Chart::Plotly::Trace::Histogram2d::Colorbar::Tickformatstops;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);

our $VERSION = '0.042';    # VERSION

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

has items => ( is => "rw", );

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Histogram2d::Colorbar::Tickformatstops

=head1 VERSION

version 0.042

=head1 SYNOPSIS

 use HTML::Show;
 use Chart::Plotly;
 use Chart::Plotly::Trace::Histogram2d;
 my $histogram2d = Chart::Plotly::Trace::Histogram2d->new( x => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ],
                                                           y => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ] );
 
 HTML::Show::show( Chart::Plotly::render_full_html( data => [$histogram2d] ) );

=head1 DESCRIPTION

This attribute is part of the possible options for the trace histogram2d.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#histogram2d>

=head1 NAME 

Chart::Plotly::Trace::Histogram2d::Colorbar::Tickformatstops

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * items

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
