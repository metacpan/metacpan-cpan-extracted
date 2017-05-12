package CVS::Metrics::TaggedChart;

use strict;
use warnings;

our $VERSION = '0.18';

use GD;
use base qw(Chart::Plot::Canvas);

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

