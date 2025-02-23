
# input pattern of a subrule in current colors as one passive widget

package App::GUI::Cellgraph::Widget::RuleInput;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $cell_size, $pattern, $colors ) = @_;

    return unless ref $colors eq 'ARRAY' and defined $pattern;
    map { return unless ref $_ eq 'ARRAY' and @$_ == 3 } @$colors;

    $pattern = [split //, $pattern];
    my $ignore_center = !( @$pattern % 2);
    my $cell_count = @$pattern + $ignore_center;
    my $x = ($cell_size + 1) * $cell_count + 1;
    my $y = $cell_size + 2;
    my $half_count = int (@$pattern / 2);

    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y]);

    $self->{'pattern'} = $pattern;
    $self->{'colors'} = $colors;

    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        my $dc = Wx::PaintDC->new( $cpanel );
        my $bg_color = Wx::Colour->new( 255, 255, 255 );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();
        my $base_x = 0;
        if ($ignore_center) {
            $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 0, 0, 0 ), 1, &Wx::wxPENSTYLE_SOLID ) );
            my $cross_x = $half_count * ($cell_size + 1);
            $dc->DrawLine( $cross_x,              0, $cross_x + $cell_size + 1, $cell_size + 1);
            $dc->DrawLine( $cross_x, $cell_size + 1, $cross_x + $cell_size + 1,              0);
        }
        $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 170, 170, 170 ), 1, &Wx::wxPENSTYLE_SOLID ) );
        $dc->DrawLine(  $base_x,    0, $x-1,    0 );
        $dc->DrawLine(  $base_x, $y-1, $x-1, $y-1 );
        $dc->DrawLine( $_,    0,   $_, $y-1 ) for map { ($cell_size + 1) * $_ }  0 .. $cell_count;

        for my $cell_nr (0 .. $half_count - 1) {
            next if $pattern->[$cell_nr] >= @{$self->{'colors'}};
            my $color = Wx::Colour->new( @{$self->{'colors'}[ $pattern->[$cell_nr] ]});
            $dc->SetPen( Wx::Pen->new( $color, 1, &Wx::wxPENSTYLE_SOLID ) );
            $dc->SetBrush( Wx::Brush->new( $color, &Wx::wxBRUSHSTYLE_SOLID ) );
            $dc->DrawRectangle( $base_x + 1, 1, $cell_size, $cell_size );
            $base_x += $cell_size + 1;
        }
        $base_x += $cell_size + 1 if $ignore_center;
        for my $cell_nr ($half_count .. $#$pattern) {
            next if $pattern->[$cell_nr] >= @{$self->{'colors'}};
            my $color = Wx::Colour->new( @{$self->{'colors'}[ $pattern->[$cell_nr] ]});
            $dc->SetPen( Wx::Pen->new( $color, 1, &Wx::wxPENSTYLE_SOLID ) );
            $dc->SetBrush( Wx::Brush->new( $color, &Wx::wxBRUSHSTYLE_SOLID ) );
            $dc->DrawRectangle( $base_x + 1, 1, $cell_size, $cell_size );
            $base_x += $cell_size + 1;
        }
    } );
    $self;
}


sub SetColors {
    my ( $self, @colors ) = @_;
    return unless @colors > 1;
    for (@colors){ return unless ref $_ eq 'ARRAY' and @$_ == 3 }
    $self->{'colors'} = \@colors;
    $self->Refresh;
}


1;
