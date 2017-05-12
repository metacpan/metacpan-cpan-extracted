package CAM::PDF::GS::NoText;

use 5.006;
use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);

our $VERSION = '1.60';

##no critic (Bangs::ProhibitNumberedNames)

=for stopwords fallback

=head1 NAME

CAM::PDF::GS::NoText - PDF graphic state

=head1 LICENSE

See CAM::PDF.

=head1 SYNOPSIS

    use CAM::PDF;
    my $pdf = CAM::PDF->new($filename);
    my $contentTree = $pdf->getPageContentTree(4);
    my $gs = $contentTree->computeGS(1);

=head1 DESCRIPTION

This class is used to represent the graphic state at a point in the
rendering flow of a PDF page.  This does not include the graphics
state for text blocks.  That functionality is in the subclass,
CAM::PDF::GS.

=head1 FUNCTIONS

=over

=item $pkg->new($hashref)

Create a new instance, setting all state values to their defaults.
Stores a reference to C<$hashref> and sets the property
C<$hashref->{fm}> to C<undef>.

=cut

sub new
{
   my $pkg = shift;
   my $refs = shift;

   my $self = bless {

      mode => 'n',            # 'c'har, 's'tring, 'n'oop

      refs => $refs || {},

      c => undef,                # color
      cm => [1, 0, 0, 1, 0, 0],  # current transformation matrix
      w => 1.0,                  # line width
      J => 0,                    # line cap
      j => 0,                    # line join
      M => 0,                    # miter limit
      da => [],                  # dash pattern array
      dp => 0,                   # dash phase
      ri => undef,               # rendering intent
      i => 0,                    # flatness

      # Others, see PDF Ref page 149

      Tm => [1, 0, 0, 1, 0, 0],  # text matrix
      Tlm => [1, 0, 0, 1, 0, 0], # text matrix
      Tc => 0,                   # character spacing
      Tw => 0,                   # word spacing
      Tz => 1,                   # horizontal scaling
      TL => 0,                   # leading
      Tf => undef,               # font
      Tfs => undef,              # font size
      Tr => 0,                   # render mode
      Ts => 0,                   # rise
      wm => 0,                   # writing mode (0=horiz, 1=vert)

      Device => undef,
      device => undef,
      G => undef,
      g => undef,
      RG => undef,
      rg => undef,
      K => undef,
      k => undef,

      moved => [0,0],

      start => [0,0],
      last => [0,0],
      current => [0,0],

   }, $pkg;

   $self->{refs}->{fm} = undef;

   return $self;
}

=item $self->clone()

Duplicate the instance.

=cut

sub clone
{
   my $self = shift;

   require Data::Dumper;
   my $newself;

   # don't clone references, just point to them
   my $refs = delete $self->{refs};

   if (!eval Data::Dumper->Dump([$self], ['newself']))  ## no critic (StringyEval)
   {
      die 'Error in '.__PACKAGE__."::clone() - $EVAL_ERROR";
   }
   $self->{refs} = $newself->{refs} = $refs;  # restore references
   @{$newself->{moved}} = (0,0);
   return $newself;
}

=back

=head1 CONVERSION FUNCTIONS

=over

=item $self->applyMatrix($m1, $m2)

Apply C<$m1> to C<$m2>, save in C<$m2>.

=cut

sub applyMatrix
{
   my $self = shift;
   my $m1 = shift;
   my $m2 = shift;

   if (ref $m1 ne 'ARRAY' || ref $m2 ne 'ARRAY')
   {
      require Data::Dumper;
      croak "Bad arrays:\n".Dumper($m1,$m2);
   }

   my @m3;

   $m3[0] = $m2->[0]*$m1->[0] + $m2->[2]*$m1->[1];
   $m3[1] = $m2->[1]*$m1->[0] + $m2->[3]*$m1->[1];
   $m3[2] = $m2->[0]*$m1->[2] + $m2->[2]*$m1->[3];
   $m3[3] = $m2->[1]*$m1->[2] + $m2->[3]*$m1->[3];
   $m3[4] = $m2->[0]*$m1->[4] + $m2->[2]*$m1->[5] + $m2->[4];
   $m3[5] = $m2->[1]*$m1->[4] + $m2->[3]*$m1->[5] + $m2->[5];

   @{$m2} = @m3;
   return;
}

=item $self->dot($matrix, $x, $y)

Compute the dot product of a position against the coordinate matrix.

=cut

sub dot
{
   my $self = shift;
   my $cm = shift;
   my $x = shift;
   my $y = shift;

   return ($cm->[0]*$x + $cm->[2]*$y + $cm->[4],
           $cm->[1]*$x + $cm->[3]*$y + $cm->[5]);
}

=item $self->userToDevice($x, $y)

Convert user coordinates to device coordinates.

=cut

sub userToDevice
{
   my $self = shift;
   my $x = shift;
   my $y = shift;

   ($x,$y) = $self->dot($self->{cm}, $x, $y);
   $x -= $self->{refs}->{mediabox}->[0];
   $y -= $self->{refs}->{mediabox}->[1];
   return ($x, $y);
}

=item $self->getCoords($node)

Computes device coordinates for the specified node.  This implementation
handles line-drawing nodes.

=cut

my %path_cmds  = map {$_ => 1} qw(m l h c v y re);
my %paint_cmds = map {$_ => 1} qw(S s F f f* B B* b b* n);

sub getCoords
{
   my $self = shift;
   my $node = shift;

   my ($x1,$y1,$x2,$y2);
   if ($path_cmds{$node->{name}})
   {
      ($x1,$y1) = $self->userToDevice(@{$self->{last}});
      ($x2,$y2) = $self->userToDevice(@{$self->{current}});
   }
   return ($x1,$y1,$x2,$y2);
}

=item $self->nodeType($node)

Returns one of C<block>, C<path>, C<paint>, C<text> or (the fallback
case) C<op> for the type of the specified node.

=cut

sub nodeType
{
   my $self = shift;
   my $node = shift;

   return $node->{type} eq 'block'     ? 'block'
        : $path_cmds{$node->{name}}    ? 'path'
        : $paint_cmds{$node->{name}}   ? 'paint'
        : $node->{name} =~ / \A T /xms ? 'text'
        :                                'op';
}

=back

=head1 DATA FUNCTIONS

=over

=item $self->i($flatness)

=item $self->j($linejoin)

=item $self->J($linecap)

=item $self->ri($rendering_intent)

=item $self->Tc($charspace)

=item $self->TL($leading)

=item $self->Tr($rendering_mode)

=item $self->Ts($rise)

=item $self->Tw($wordspace)

=item $self->w($linewidth)

=cut

# default setters
{
   no strict 'refs'; ## no critic(ProhibitNoStrict)
   foreach my $name (qw(i j J ri Tc TL Tr Ts Tw w))
   {
      *{$name} = sub { $_[0]->{$name} = $_[1]; return; };
   }
}

=item $self->g($gray)

=cut

sub g
{
   my $self = shift;
   my $g = shift;

   $self->{g} = [$g];
   $self->{device} = 'DeviceGray';
   return;
}

=item $self->G($gray)

=cut

sub G
{
   my $self = shift;
   my $g = shift;

   $self->{G} = [$g];
   $self->{Device} = 'DeviceGray';
   return;
}

=item $self->rg($red, $green, $blue)

=cut

sub rg
{
   my $self = shift;
   my $rd = shift;
   my $gr = shift;
   my $bl = shift;

   $self->{rg} = [$rd, $gr, $bl];
   $self->{device} = 'DeviceRGB';
   return;
}

=item $self->RG($red, $green, $blue)

=cut

sub RG
{
   my $self = shift;
   my $rd = shift;
   my $gr = shift;
   my $bl = shift;

   $self->{RG} = [$rd, $gr, $bl];
   $self->{Device} = 'DeviceRGB';
   return;
}

=item $self->k($cyan, $magenta, $yellow, $black)

=cut

sub k
{
   my $self = shift;
   my $c = shift;
   my $m = shift;
   my $y = shift;
   my $k = shift;

   $self->{k} = [$c, $m, $y, $k];
   $self->{device} = 'DeviceCMYK';
   return;
}

=item $self->K($cyan, $magenta, $yellow, $black)

=cut

sub K
{
   my $self = shift;
   my $c = shift;
   my $m = shift;
   my $y = shift;
   my $k = shift;

   $self->{K} = [$c, $m, $y, $k];
   $self->{Device} = 'DeviceCMYK';
   return;
}

=item $self->gs()

(Not implemented...)

=cut

sub gs
{
   my $self = shift;

   # See PDF Ref page 157
   #warn 'gs operator not yet implemented';
   return;
}

=item $self->cm M1, M2, M3, M4, M5, M6

=cut

sub cm
{
   my ($self, @mtx) = @_;

   $self->applyMatrix([@mtx], $self->{cm});
   return;
}

=item $self->d($arrayref, $scalar)

=cut

sub d
{
   my $self = shift;
   my $da = shift;
   my $dp = shift;

   @{$self->{da}} = @{$da};
   $self->{dp} = $dp;
   return;
}

=item $self->m($x, $y)

Move path.

=cut

sub m    ##no critic (Homonym)
{
   my $self = shift;
   my $x = shift;
   my $y = shift;

   @{$self->{start}} = @{$self->{last}} = @{$self->{current}} = ($x,$y);
   return;
}

=item $self->l($x, $y)

Line path.

=cut

sub l
{
   my $self = shift;
   my $x = shift;
   my $y = shift;

   @{$self->{last}} = @{$self->{current}};
   @{$self->{current}} = ($x,$y);
   return;
}

=item $self->h()

=cut

sub h
{
   my $self = shift;

   @{$self->{last}} = @{$self->{current}};
   @{$self->{current}} = @{$self->{start}};
   return;
}

=item $self->c($x1, $y1, $x2, $y2, $x3, $y3)

=cut

sub c  ## no critic (ProhibitManyArgs)
{
   my $self = shift;
   my $x1 = shift;
   my $y1 = shift;
   my $x2 = shift;
   my $y2 = shift;
   my $x3 = shift;
   my $y3 = shift;

   @{$self->{last}} = @{$self->{current}};
   @{$self->{current}} = ($x3,$y3);
   return;
}

=item $self->v($x1, $y1, $x2, $y2)

=cut

sub v
{
   my $self = shift;
   my $x1 = shift;
   my $y1 = shift;
   my $x2 = shift;
   my $y2 = shift;

   @{$self->{last}} = @{$self->{current}};
   @{$self->{current}} = ($x2,$y2);
   return;
}

=item $self->y($x1, $y1, $x2, $y2)

=cut

sub y    ##no critic (Homonym)
{
   my $self = shift;
   my $x1 = shift;
   my $y1 = shift;
   my $x2 = shift;
   my $y2 = shift;

   @{$self->{last}} = @{$self->{current}};
   @{$self->{current}} = ($x2,$y2);
   return;
}

=item $self->re($x, $y, $width, $height)

Rectangle path.

=cut

sub re
{
   my $self = shift;
   my $x = shift;
   my $y = shift;
   my $w = shift;
   my $h = shift;

   @{$self->{start}} = @{$self->{last}} = @{$self->{current}} = ($x,$y);
   return;
}

1;
__END__

=back

=head1 AUTHOR

See L<CAM::PDF>

=cut
