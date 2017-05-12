
package Chart::Plot::Tagged;

use strict;
use warnings;

our $VERSION = '0.02';

use GD;
use base qw(Chart::Plot);

sub setTag {
    my $self = shift;
    my ($arrayref) = @_;

    # record the dataset
    my $label = $self->{_numDataSets};
    $self->{_tag}->{$label} = $arrayref;
    return $label;
}

sub _drawData {
    my $self = shift;
    $self->SUPER::_drawData();
    $self->_drawTag();
}

sub _drawTag {
    my $self = shift;

    foreach my $dataSetLabel (keys %{$self->{_data}}) {
        next unless (exists $self->{_tag}->{$dataSetLabel});

        # get color
        my $color = '_black';
        if ( $self->{'_dataStyle'}->{$dataSetLabel} =~ /((red)|(blue)|(green))/i ) {
            $color = "_$1";
            $color =~ tr/A-Z/a-z/;
        }

        # get direction
        my $dir = '';
        $dir = 'up' if $self->{'_dataStyle'}->{$dataSetLabel} =~ /up/i;

        my $num = @{ $self->{'_data'}->{$dataSetLabel} };
        my $prevpx = 0;
        for (my $i = 0; $i < $num/2; $i ++) {

            # get next point
            my ($px, $py) = $self->_data2pxl (
                    $self->{_data}->{$dataSetLabel}[2*$i],
                    $self->{_data}->{$dataSetLabel}[2*$i+1]
            );

            my $lbl = $self->{_tag}->{$dataSetLabel}[$i] || '';
            if ($lbl ne '' && $px != $prevpx) {
                if ($dir eq 'up') {
                    $self->{'_im'}->stringUp(gdTinyFont, $px-8, $py-5,
                           $lbl, $self->{$color});
                }
                else {
                    $self->{'_im'}->string(gdTinyFont, $px+5, $py-4,
                           $lbl, $self->{$color});
                }
                $prevpx = $px;
            }
        }
    }
}

1;
__END__

=head1 NAME

Chart::Plot::Tagged - Plot with tags

=head1 SYNOPSIS

  use Chart::Plot::Tagged;

  my $img = Chart::Plot::Tagged->new;
  $img->setData(\@xdata, \@ydata, 'blue up');
  $img->setTag(\@tags);
  print  $img->draw();

=head1 DESCRIPTION

This package overloads Chart::Plot and adds a new method 'setTag'.

=head1 USAGE

See L<Chart::Plot> for all over methods.

=head2 setTag()

    $img->setTag(\@tags);

where @tags is an array of string or C<undef>.

By default, tags are written horizontal. The word C<up> in style option
allows the vertical mode.

=head1 SEE ALSO

L<Chart::Plot>

Some examples are available on L<http://fperrad.github.com/graph-versions/perl.html>
and on L<http://fperrad.github.com/graph-versions/scm.html>.

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Francois PERRAD

This library is distributed under the terms of the Artistic License 2.0.

=cut
