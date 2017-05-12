package App::WIoZ::Word;
{
  $App::WIoZ::Word::VERSION = '0.004';
}
use Moose;
#use feature 'say';

has 'text' => (
    is => 'ro', required => 1, isa => 'Str'
);

has 'weight' => (
    is => 'ro', required => 0, isa => 'Int'
);

has 'font' => (
    is => 'rw', isa => 'HashRef',
    default => sub { {font => 'LiberationSans', type => 'normal', weight => 'bold'} }
);

has 'width' => (
    is => 'rw', isa => 'Int'
);

has 'height' => (
    is => 'rw', isa => 'Int'
);

has 'size' => (
    is => 'rw', isa => 'Num'
);

has 'color' => (
    is => 'rw', isa => 'Str'
);

has 'p' => (
    is => 'rw', isa => 'App::WIoZ::Point'
);

has 'c' => (
    is => 'rw', isa => 'App::WIoZ::Point'
);

has 'p2' => (
    is => 'rw', isa => 'App::WIoZ::Point'
);

has 'show' => (
    is => 'rw', isa => 'Int',
);

has 'angle' => (
    is => 'ro', isa => 'Str',
    default => sub {return rand(1.0) > 0.85 ? -1 * 2 * atan2(1, 1) : 0;}
);

sub update_c {
    my ($self,$c) = @_;
    my $th = $self->height;
    my $tl = $self->width;
    my $center = App::WIoZ::Point->new(x=>$c->x,y=>$c->y);
    my $p = App::WIoZ::Point->new(x=>$c->x-int($tl/2),y=>$c->y+int($th/2));
    my $p2 = App::WIoZ::Point->new(x=>$c->x+int($tl/2),y=>$c->y-int($th/2));
    $self->c($center);
    $self->p($p);
    $self->p2($p2);
}

sub update_size {
    my ($self,$ya,$size) = @_;
    $ya->cr->select_font_face($self->font->{font},$self->font->{type},$self->font->{weight});
    $ya->cr->set_font_size($size);
    #$ya->cr->rotate($self->angle);
    my $te = $ya->cr->text_extents ($self->text);
    my $fe = $ya->cr->font_extents;
    #my $th = $fe->{"height"};#-4*$fe->{"descent"};
    my $th = $fe->{"height"}-2*$fe->{"descent"};
    my $tl = $te->{"width"};#+2*$te->{"x_bearing"};
    $self->size($size);
    if ($self->angle < 0) {
        $self->height(int($tl+2*$te->{"x_bearing"}));
        $self->width(int($th));
    }
    else  {
        $self->height(int($th));
        $self->width(int($tl));
    };
}

sub crange {
    my ($self,$h,$scale) = @_;
    my $x1 = ($self->p->x/$scale);
    my $y1 = ($self->p->y/$scale);
    my $x2 = ($self->p2->x/$scale);
    my $y2 = ($self->p2->y/$scale);
    my ($min, $max) = $h->rect_to_n_range ($x1,$y1, $x2,$y2);
   my ($rx1,$ry1) =  $h->n_to_xy($h->xy_to_n($x1,$y1));
   my ($rx2,$ry2) = $h->n_to_xy($h->xy_to_n($x2,$y2));
#        say "    ==> ($rx1,$ry1 $rx2,$ry2) $min,$max";
    my @in = ();
    foreach my $n ($min .. $max) {
        my ($x,$y) = $h->n_to_xy($n);
        #say "$n $x,$y";
        #say " . $n in"
        # if $x>=$rx1 && $x<=$rx2 && $y<= $ry1 && $y >= $ry2;
        push @in, $n
         if $x>=$rx1 && $x<=$rx2 && $y<= $ry1 && $y >= $ry2;
    }
    #say join '-',@in;
    return @in;

}

sub is_free {
    my ($self,$ya) = @_;
    my $curve = $ya->fcurve;
    my $scale = $ya->scale;
    my @ranges = $self->crange($curve,$scale);
    foreach my $hp (@ranges) {
        my @test = @{$ya->cused} ;
        return undef if (  grep $_ == $hp, @test );
    }
    return @ranges;
}


1;
