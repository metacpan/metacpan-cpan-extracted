
package Chart::Plot::Canvas::Tagged;

use strict;
use warnings;

use base qw(Chart::Plot::Tagged Chart::Plot::Canvas);

sub _createData {
    my $self = shift;
    $self->SUPER::_createData();
    $self->_createTag();
}

sub _createTag {
    my $self = shift;

    foreach my $dataSetLabel (keys %{$self->{_data}}) {
        next unless (exists $self->{_tag}->{$dataSetLabel});

        # get color
        my $color = 'black';
        if ( $self->{'_dataStyle'}->{$dataSetLabel} =~ /((red)|(blue)|(green))/i ) {
            $color = $1;
            $color =~ tr/A-Z/a-z/;
        }

        my $num = @{ $self->{'_data'}->{$dataSetLabel} };
        my $prevpx = 0;
        for (my $i = 0; $i < $num/2; $i ++) {

            # get next point
            my ($px, $py) = $self->_data2pxl (
                    $self->{_data}->{$dataSetLabel}[2*$i],
                    $self->{_data}->{$dataSetLabel}[2*$i+1]
            );

            if ($px != $prevpx) {
                foreach (reverse split//, $self->{_tag}->{$dataSetLabel}[$i]) {
                    $self->{'_cv'}->createText($px-5, $py,
                            -anchor => 's',
                            -font => $self->{_TinyFont},
                            -text => $_,
                            -fill => $color
                    );
                    $py -= 9;
                }
            }
            $prevpx = $px;
        }
    }
}

1;

__END__

=head1 NAME

Chart::Plot::Canvas::Tagged - Plot with tags

=head1 DESCRIPTION

This package overloads Chart::Plot::Canvas and adds a new method 'setTag'.

=head1 SEE ALSO

See L<Chart::Plot::Tagged>.

=cut
