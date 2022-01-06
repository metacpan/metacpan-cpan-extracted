package Chart::GGPlot::Guide::Legend;

# ABSTRACT: Legend guide

use Chart::GGPlot::Setup;

our $VERSION = '0.002000'; # VERSION

use parent qw(Chart::GGPlot::Guide);

use Data::Frame;

sub BUILD {
    my ($self, $args) = @_;

    $self->set( 'key', {} );
}   

method train ($scale, $aesthetic=undef) {
    my $breaks = $scale->get_breaks();
    if ($breaks->length == 0 or $breaks->ngood == 0) {
        return;
    }

    my $aes_column_name = $aesthetic // $scale->aesthetics->[0];
    my $key = Data::Frame->new(
        columns => [
            $aes_column_name => $scale->map_to_limits($breaks),
            label            => $scale->get_labels($breaks),
        ]
    );

    if ( $self->reverse ) { 
        $key = $self->_reverse_df($key);
    }   

    $self->set('key', $key);

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Guide::Legend - Legend guide

=head1 VERSION

version 0.002000

=head1 SEE ALSO

L<Chart::GGPlot::Guide>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
