use strict;
use warnings;
package App::WIoZ;
{
  $App::WIoZ::VERSION = '0.004';
}

#use feature 'say';
use Moose;
use Color::Mix;
use Cairo;
use Math::PlanePath::HilbertCurve;
use Graphics::ColorNames;
use App::WIoZ::Point;
use App::WIoZ::Word;

# ABSTRACT: App::WIoZ create a SVG or PNG image of a word cloud from a simple text file

=head1 NAME - App::WIoZ

App::WIoZ - a perl word cloud generator

=head1 VERSION

version 0.004

=head1 DESCRIPTION

App::WIoZ can create a SVG or PNG image of a word cloud from a simple text file with C<word;weight>.

App::WIoZ is an acronym for "Words for Io by Zeus", look for the Correggio painting to watch the cloud.

App::WIoZ is based on C<Wordle> strategy and C<yawc> perl clone.

Usage:

  my $File = 'words.txt';

  my $wioz = App::WIoZ->new(
    font_min => 18, font_max => 64,
    set_font => "DejaVuSans,normal,bold",
    filename => "testoutput",
    basecolor => '226666'); # violet

  if (-f $File) {
    my @words = $wioz->read_words($File);
    $wioz->do_layout(@words);
  }
  else {
    $wioz->chg_font("LiberationSans,normal,bold");
    $wioz->update_colors('testoutput.sl.txt');
  }

watch C<doc/freq.pl> to create a C<words.txt> file.

=head1 STATUS

App::WIoZ is actually a POC to play with Moose, Cairo or Math::PlanePath. 

The use of an Hilbert curve to manage free space is for playing with Math::PlanePath modules.

Performance can be improved in free space matching, or in spiral strategy to find free space.

Max and min font sizes can certainly be computed. 

Feel free to clone this project on GitHub.

=head1 SETTINGS

=head2 height

image height, default to 600

=cut

has 'height' => (
    is => 'ro', isa => 'Int', default => 600
);

=head2 width

image width, default to 800

=cut 

has 'width' => (
    is => 'ro', isa => 'Int', default => 800
);

has 'center' => (
    is => 'ro', isa => 'App::WIoZ::Point',
    lazy => 1,
    default => sub {
        my $self = shift;
        return App::WIoZ::Point->new(
            x => int($self->width/2),
            y => int($self->height/2));
    }
);

=head2 font_min, font_max

required min and max font size

=cut

has ['font_min','font_max'] => (
    is => 'ro', required => 1, isa => 'Int'
);

=head2 set_font, chg_font, font

accessors for font name, type and weight

C<set_font> : set font in new WIoZ object, default is C<'LiberationSans,normal,bold'>

C<chg_font> : change font

C<font> : read font object

Usage :

  $wioz = App::WIoZ->new( font_min => 18, font_max => 64,
                          set_font => 'DejaVuSans,normal,bold');
  
  $fontname = $wioz->font->{font};
  $wioz->chg_font('LiberationSans,normal,bold');


=cut

has 'font' => (
   isa    => 'HashRef',
   is => 'ro', lazy => 1,
   writer => 'chg_font',
   builder => '_set_font'
);

# for font builder
has 'set_font' => ( is => 'rw',isa => 'Str' );

sub _set_font {
    my ($self,$font) = @_;
    my ($fname,$ftype,$fweight) = split ',', ($self->set_font || ',,');
    return ( { font => $fname || 'LiberationSans',
               type => $ftype || 'normal',
               weight => $fweight || 'bold' });
};

# for font change
around 'chg_font' => sub  {
        my ($next,$self,$font) = @_;
        my ($fname,$ftype,$fweight) = split ',', $font;
        $self->$next( {font => $fname, type => $ftype, weight => $fweight});
};

has 'backcolor' => (
    is => 'ro', isa => 'Str',
    default => 'white'
);

has 'cr' => (
    is => 'rw', isa => 'Cairo::Context',
    lazy => 1, builder => '_create_cr'
);

has 'surface' => (
    is => 'rw', isa => 'Cairo::ImageSurface',
);

has 'svgsurface' => (
    is => 'rw', isa => 'Cairo::SvgSurface',
);

=head2 filename

file name output, extension C<.png> or C<.svg> will be added 

=cut

has 'filename' => (
    is => 'rw', isa => 'Str',
);

=head2 svg

produce a svg output, default value

set to 0 to write a png

=cut

has 'svg' => (
  is => 'ro', isa => 'Int', default => 1
);

has 'fcurve' => (
    is => 'rw', isa => 'Math::PlanePath',
);

=head2 scale

Scale for the Hilbert Curve granularity default to 10

Higer value produces better speed but more words recovery.

=cut

has 'scale' => (
    is =>'ro', isa => 'Int', default => 10 # 20 better
);

has 'cused' => (
    is => 'rw', isa => 'ArrayRef[Int]', default => sub {[]}
);

=head2 basecolor

Base color for color theme, default to 882222

=cut

has 'basecolor' => (
    is =>'ro', isa => 'Str', default => '882222'
);

=head1 METHODS

=cut

sub _create_cr {
    my $self = shift;
    my $scale = $self->scale;
    my $hilbert = Math::PlanePath::HilbertCurve->new;
    $self->fcurve($hilbert);
    my $cr;

    if ($self->svg) {
        my $svgsurface = Cairo::SvgSurface->create ($self->filename.'.svg', $self->width, $self->height);
        $self->svgsurface($svgsurface);
        $cr = Cairo::Context->create($svgsurface);
    }
    else {
        my $surface = Cairo::ImageSurface->create ('argb32', $self->width, $self->height);
        $self->surface($surface);
        $cr = Cairo::Context->create($surface);
    };

    $cr->save;
    $cr->rectangle (0, 0, $self->width, $self->height);
    my $po = Graphics::ColorNames->new;
    my @rgb = $po->rgb($self->backcolor);
    $cr->set_source_rgb ($rgb[0]/255.0, $rgb[1]/255.0, $rgb[2]/255.0);
    $cr->fill;
    $cr->restore;
    return $cr;
};

=head2 read_words

read words form file : C<word;weight>

Usage: 
 my @words = $wioz->read_words($File);

=cut

sub read_words {
    my ($self, $filename) = @_;
    my ($weight_min, $weight_max) = (1000000000, 0);
    my @res = ();
    my $fh;
    open $fh, '<:utf8', $filename;
    my @L = <$fh>;
    close $fh;
    foreach my $l (@L) {
        my ($t,$n) = split /;/,$l;
        if ( $t && $n ) {
            $t =~ s/\s*$//g; $n =~ s/\s*$//g;
            #$all_weight += $n;
            $weight_max = $n if ( $n >$weight_max );
            $weight_min = $n if ( $n <$weight_min );
            my $w = new App::WIoZ::Word(text => $t, weight => $n, font => $self->font);
            push @res, $w;
        } else {
            warn "error line: $_";
        }
    }
    # set initial size and color
    my @color = Color::Mix->new->analogous($self->basecolor, 12, 12);
    foreach my $v (@res) {
       $v->size( (($v->weight - $weight_min) / ($weight_max - $weight_min)) *
                      ($self->font_max - $self->font_min) +
                      $self->font_min );
       $v->color($color[int(rand(12))]);
    }
    return @res;
}


=head2 update_colors

Read words position from file and update colors.

Usage:

   $wioz->update_colors("file.sl.txt");

=cut

sub update_colors{
    my ($self, $filename) = @_;

    open my $fh, '<:utf8', $filename or die $filename . ' : ' .$!;
    my @L = <$fh>;
    close $fh;

    my @color = Color::Mix->new->analogous($self->basecolor, 12, 12);

    # reset background
    $self->cr->rectangle (0, 0, $self->width, $self->height);
    my $po = Graphics::ColorNames->new;
    my @rgb = $po->rgb($self->backcolor);
    $self->cr->set_source_rgb ($rgb[0]/255.0, $rgb[1]/255.0, $rgb[2]/255.0);
    $self->cr->fill;

    foreach my $l (@L) {
        my ($show,$text,$size,$x,$y,$angle) = split /\t/,$l;
        #say "$text - $size - $angle";
        my $w = App::WIoZ::Word->new(text => $text, size => $size, angle => $angle, show => $show, color => $color[int(rand(12))], font => $self->font);
        my $newc = App::WIoZ::Point->new( x => $x, y => $y);
        $w->update_size($self,$size);
        $w->update_c($newc);
        $self->_show_word($w);
    }
    $self->_save_to_png if (!$self->svg);
}

=head2 do_layout

Compute words position, save result to svg or png image, save in C<filename.sl.txt> words positions to update colors.

Usage :
   $wioz->do_layout(@words);

=cut

sub do_layout {
    my ($self,@words) = @_;
    my $c = 0;
    my $current = undef;
    my @dx = (1, 1, 0, 0,-1,-1,-1,-1, 0, 0, 1, 1);
    my @dy = (0, 1, 1, 1, 1, 0, 0,-1,-1,-1,-1, 0);

    #foreach my $w (@words) {
    foreach my $w (sort {$b->weight cmp $a->weight} @words) {
      # init
      $w->show(1);
      $w->update_size($self,$w->size) if (!$w->height && !$w->width);
      $current = $w if (! $current);

      # process
      my $inside;
      my @ranges;

    my ($x1, $y1) = my ($x, $y) = (int($self->width/2), int($self->height/2));
    my $step = $self->scale;
    my $dir = 0;
    my $i = 0;
    do {
        # spiral
        my $newc = App::WIoZ::Point->new( x => int($x), y => int($y));
        $x1 = $x1 + $dx[$i%12] * $step;
        $y1 = $y1 + $dy[$i%12] * $step;
        $x = $x1; $y = $y1;
        $step += 2 ;
        $w->update_c($newc);
        # is in free space
        $inside = ($w->p->x > 0 && $w->p->x <= $self->width &&
          $w->p2->x > 0 && $w->p2->x <= $self->width &&
          $w->p->y > 0 && $w->p->y <= $self->height &&
          $w->p2->y > 0 && $w->p2->y <= $self->height) || 0;
        @ranges = $w->is_free($self) if $inside;
        # try some other strategy
        $i++;
        if ($i>60 || !$inside) {
            $i = 10;
            $step=$self->scale;
            my ($xt,$yt) = $self->_random_point($current->width,$current->height);
            ($x1, $y1) = ($x, $y) = ($current->p->x + $xt,$current->p->y - $yt);
            if ( ! $dir ) {
                $dir = 1;
                #say '  revert : '.$w->text;
                my @rdx = reverse @dx;
                my @rdy = reverse @dy;
                @dx = @rdx; @dy = @rdy;
            }
            else {
                $dir = 0;
                if ($w->size - 1 <= 5) {
                    #say '  no place for : '.$w->text;
                    $w->show(0);
                    next;
                }
                #say '  decrease : '.$w->text;
                $w->update_size($self,$w->size - 1);
            }
        };
    } while ( ! $inside  || scalar @ranges == 1 );

    # register used space
    map { if ($_) {push @{ $self->cused }, $_} } @ranges;

    # show
    $self->_show_word($w) if ($w->show);

    #$c++; last if $c > 2;
    }

    $self->_save_to_png if (!$self->svg);

    $self->_save_layout(@words);

}

sub _save_to_png {
        my $self = shift;
        $self->surface->write_to_png ($self->filename . '.png');
}

# Save words position to a file. Usefull to update colors.
sub _save_layout {
    my ($self, @words) = @_;
    my $fh;
    open $fh, '>:utf8', $self->filename . '.sl.txt';
    foreach my $w (@words) {
        print $fh $w->show."\t".$w->text."\t".$w->size."\t".$w->c->x."\t".$w->c->y."\t".$w->angle."\n";
    }
    close $fh;
}


sub _show_word {
    my ($self,$w) = @_;

    $self->cr->select_font_face(
        $w->font->{font},$w->font->{type},$w->font->{weight});
    $self->cr->set_font_size($w->size);
    my $po = Graphics::ColorNames->new;
    my @rgb = $po->rgb($w->color);
    $self->cr->set_source_rgb ($rgb[0]/255.0, $rgb[1]/255.0, $rgb[2]/255.0);
    #say '  '.$w->text.' '.$w->color;
    if ($w->angle < 0) {
        $self->cr->save;
        $self->cr->move_to($w->p->x+$w->width,$w->p->y);
        $self->cr->rotate($w->angle);
        $self->cr->show_text($w->text);
        $self->cr->restore;
    }
    else {
     $self->cr->move_to($w->p->x,$w->p->y);
     $self->cr->show_text($w->text);
    }

}

sub _random_point {
    my ($self,$width, $height) = @_;
    my $x = rand( $width * 0.8 ) + $width * 0.1 ;
    my $y = rand( $height * 0.8 ) + $height * 0.1 ;
    return ($x, $y);
}

=head1 Git

L<https://github.com/yvesago/WIoZ/>

=head1 AUTHORS

Yves Agostini, C<< <yveago@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 - Yves Agostini 

This program is free software and may be modified or distributed under the same terms as Perl itself.

=cut

1;
