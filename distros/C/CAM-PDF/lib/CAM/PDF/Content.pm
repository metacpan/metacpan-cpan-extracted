package CAM::PDF::Content;

use 5.006;
use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);
use CAM::PDF;
use CAM::PDF::Node;

our $VERSION = '1.60';

=for stopwords renderers unvalidated

=head1 NAME

CAM::PDF::Content - PDF page layout parser

=head1 LICENSE

Same as L<CAM::PDF>

=head1 SYNOPSIS

    use CAM::PDF;
    my $pdf = CAM::PDF->new($filename);
    
    my $contentTree = $pdf->getPageContentTree(4);
    $contentTree->validate() || die 'Syntax error';
    print $contentTree->render('CAM::PDF::Renderer::Text');
    $pdf->setPageContent(5, $contentTree->toString());

=head1 DESCRIPTION

This class is used to manipulate the layout commands for a single page
of PDF.  The page content is passed as a scalar and parsed according
to Adobe's PDF Reference 3rd edition (for PDF v1.4).  All of the
commands from Appendix A of that document are parsed and understood.

Much of the content object's functionality is wrapped up in renderers
that can be applied to it.  See the canonical renderer, CAM::PDF::GS,
and the render() method below for more details.

=cut

# Package globals:

my %loaded; # keep track of eval'd renderers
my %endings = (
               q   => 'Q',
               BT  => 'ET',
               BDC => 'EMC',
               BMC => 'EMC',
               BX  => 'EX',
               );
my $starts = join q{|}, map {quotemeta} keys %endings;
my $ends   = join q{|}, map {quotemeta} values %endings;

sub _buildOpSyntax
{
   %CAM::PDF::Content::ops = (
      b    => [],
      B    => [],
      'b*' => [],
      'B*' => [],
      BDC  => ['label','dictionary|label'],
      BI   => ['image'],
      BMC  => ['label'],
      BT   => [],
      BX   => [],
      c    => ['number','number','number','number','number','number'],
      cm   => ['number','number','number','number','number','number'],
      CS   => ['label'],
      cs   => ['label'],
      d    => ['array','number'],
      d0   => ['number','number'],
      d1   => ['number','number','number','number','number','number'],
      Do   => ['label'],
      DP   => ['label','dictionary'],
      EI   => ['end'],
      EMC  => ['end'],
      ET   => ['end'],
      EX   => ['end'],
      F    => [],
      f    => [],
      'f*' => [],
      G    => ['number'],
      g    => ['number'],
      gs   => ['label'],
      h    => [],
      i    => ['number'],
      ID   => ['end'],
      j    => ['integer'],
      J    => ['integer'],
      K    => ['number','number','number','number'],
      k    => ['number','number','number','number'],
      l    => ['number','number'],
      m    => ['number','number'],
      M    => ['number'],
      MP   => ['label'],
      n    => [],
      q    => [],
      Q    => ['end'],
      re   => ['number','number','number','number'],
      RG   => ['number','number','number'],
      rg   => ['number','number','number'],
      ri   => ['...'], # not really variable, I just don't understand this one
      s    => [],
      S    => [],
      SC   => ['...'],
      sc   => ['...'],
      SCN  => ['...'],
      scn  => ['...'],
      sh   => ['label'],
      'T*' => [],
      Tc   => ['number'],
      TD   => ['number','number'],
      Td   => ['number','number'],
      Tf   => ['label','number'],
      TJ   => ['array'],
      Tj   => ['string'],
      TL   => ['number'],
      Tm   => ['number','number','number','number','number','number'],
      Tr   => ['integer'],
      Ts   => ['number'],
      Tw   => ['number'],
      Tz   => ['number'],
      v    => ['number','number','number','number'],
      w    => ['number'],
      W    => [],
      'W*' => [],
      y    => ['number','number','number','number'],
      q{'} => ['string'],
      q{"} => ['number','number','string'],
   );
   return;
}

=head1 FUNCTIONS

=over

=item $pkg->new($content)

=item $pkg->new($content, $data)

=item $pkg->new($content, $data, $verbose)

Parse a scalar CONTENT containing PDF page layout content.  Returns a parsed,
but unvalidated, data structure.

The DATA argument is a hash reference of contextual data that may be
needed to work with content.  This is only needed for toString()
method (which needs C<doc =E<gt> CAM::PDF object> to work with images)
and the render methods, to which the DATA reference is passed
verbatim.  See the individual renderer modules for details about
required elements.

The VERBOSE boolean indicates whether the parser should Carp when it
encounters problems.  The default is false.

=cut

sub new
{
   my $pkg     = shift;
   my $content = shift;
   my $refs    = shift;
   my $verbose = shift;

   my $self = bless {
      refs    => $refs || {},
      content => $content,
      blocks  => [],
      verbose => $verbose,
   }, $pkg;
   return $self->parse(\$content);
}

=item $self->parse($contentref)

This is intended to be called by the new() method.  The argument
should be a reference to the content scalar.  It's passed by reference
so it is never copied.

=cut

my $progress = 0;
sub parse
{
   my $self = shift;
   my $c    = shift;

   $progress = 0;
   pos(${$c}) = 0;   ## no critic(CodeLayout::ProhibitParensWithBuiltins)
   ${$c} =~ m/ \A \s+ /cgxms; # prime the regex
   my $result = $self->_parseBlocks($c, $self->{blocks});
   if (!defined $result)
   {
      if ($self->{verbose})
      {
         carp 'Parse failed';
      }
      return;
   }
   if (${$c} =~ m/ \G\S /cgxms)
   {
      if ($self->{verbose})
      {
         carp 'Trailing unparsed content: ' . CAM::PDF->trimstr(${$c});
      }
      return;
   }
   return $self;
}

# Internal method
#

sub _parseBlocks
{
   my $self = shift;
   my $c = shift;
   my $A_blocks = shift;
   my $end = shift;

   my @stack;
   while (${$c} =~ m/ \G.*\S /xms)
   {
      my $block = $self->_parseBlock($c, $end);
      if (!defined $block)
      {
         return;
      }
      if (!$block)
      {
         return $self;
      }
      if ($block->{type} eq 'block' || $block->{type} eq 'op')
      {
         push @{$block->{args}}, @stack;
         @stack = ();
         push @{$A_blocks}, $block;
      }
      else
      {
         push @stack, $block;
      }
   }
   if (@stack > 0)
   {
      if ($self->{verbose})
      {
         carp 'Error: '.@stack.' unprocessed arguments';
      }
      return;
   }
   return $self;
}

# Internal method
#

sub _parseBlock
{
   my $self = shift;
   my $c    = shift;
   my $end  = shift;

   # Start a new block?
   if (${$c} =~ m/ \G($starts)\s* /ocgxms)
   {
      my $type = $1;
      my $blocks = [];
      if ($self->_parseBlocks($c, $blocks, $endings{$type}))
      {
         return _b('block', $type, $blocks);
      }
      else
      {
         return;
      }
   }

   # Balanced end to open block?
   if (defined $end && ${$c} =~ m/ \G$end\s* /cgxms)
   {
      return q{};
   }

   # Unbalanced end?
   if (${$c} =~ m/ \G($ends)\s* /ocgxms)
   {
      my $op = $1;
      if ($self->{verbose})
      {
         if ($end)
         {
            carp "Wrong block ending (expected '$end', got '$op')";
         }
         else
         {
            carp "Unexpected block ending '$op'";
         }
      }
      return;
   }

   # Inline image?
   if (${$c} =~ m/ \G BI \b /xms)
   {
      my $img = CAM::PDF->parseInlineImage($c);
      if (!$img)
      {
         if ($self->{verbose})
         {
            carp 'Failed to parse inline image';
         }
         return;
      }
      my $blockimage = _b('op', 'BI', _b('image', $img->{value}));
      return $blockimage;
   }

   # Non-block operand?

=for referencecode
   ## This is the REAL list
   #if (${$c} =~ m/ \G(
   #                    [bBcdfFgGhijJkKlmMnsSvwWy\'\"]|
   #                    b\*|B\*|BDC|BI|d[01]|c[sm]|CS|Do|DP|f\*|gs|MP|
   #                    re|RG|rg|ri|sc|SC|scn|SCN|sh|T[cdDfJjLmrswz\*]|W\*
   #                   )\b\s*
   #               /cgxms)

=cut

   ## This is a cheat version of the above
   if (${$c} =~ m/ \G([A-Za-z\'\"][*\w]*)\s* /cgxms) ## no critic (ProhibitEnumeratedClasses,ProhibitEscapedMetacharacters)
   {
      my $op = $1;
      return _b('op', $op);
   }

   # If we get here, it's data instead of an operand

   my $node = CAM::PDF->parseAny($c);
   return _b($node->{type}, $node->{value});
}

=item $self->validate()

Returns a boolean if the parsed content tree conforms to the PDF
specification.

=cut

sub validate  ## no critic(Subroutines::ProhibitExcessComplexity)
{
   my $self   = shift;
   my $blocks = shift || $self->{blocks};

   $self->_buildOpSyntax();

 BLOCK:
   foreach my $block (@{$blocks})
   {
      if ($block->{type} eq 'block')
      {
         return if (!$self->validate($block->{value}));
      }
      elsif ($block->{type} ne 'op')
      {
         if ($self->{verbose})
         {
            carp 'Neither a block nor an op';
         }
         return;
      }

      my $syntax = $CAM::PDF::Content::ops{$block->{name}};
      if ($syntax)
      {
         if ($syntax->[0] && $syntax->[0] eq '...')
         {
            # variable args, skip
            next BLOCK;
         }
         elsif (@{$block->{args}} != @{$syntax})
         {
            if ($self->{verbose})
            {
               carp "Wrong number of arguments to '$block->{name}' (got ".@{$block->{args}}.' instead of '.@{$syntax}.')';
            }
            return;
         }

       ARG:
         foreach my $i (0 .. $#{$syntax})
         {
            my $arg   = $block->{args}->[$i];
            my $types = $syntax->[$i];

          ARGTYPE_OPT:
            foreach my $type (split /[|]/xms, $types)
            {
               # These are the successful match cases
               next ARG if ($arg->{type} eq $type);
               next ARG if ($type eq 'integer' && $arg->{type} eq 'number' && $arg->{value} =~ m/ \A\d+\z /xms);
               next ARG if ($type eq 'string' && $arg->{type} eq 'hexstring');
            }

            if ($self->{verbose})
            {
               carp "Expected '$types' argument for '$block->{name}' (got $arg->{type})";
            }
            return;
         }
      }
   }
   return $self;
}

=item $self->render($rendererclass)

Traverse the content tree using the specified rendering class.  See
CAM::PDF::GS or CAM::PDF::Renderer::Text for renderer examples.
Renderers should typically derive from CAM::PDF::GS, but it's not
essential.  Typically returns an instance of the renderer class.

The rendering class is loaded via C<require> if not already in memory.

=cut

sub render
{
   my $self = shift;
   my $renderer = shift;  # a package name

   if (!$loaded{$renderer})
   {
      if (!eval "require $renderer")   ## no critic (StringyEval)
      {
         die $EVAL_ERROR;
      }
      $loaded{$renderer} = 1;
   }
   return $self->traverse($renderer);
}

=item $self->computeGS()

=item $self->computeGS($skiptext)

Traverses the content tree and computes the coordinates of each
graphic point along the way.  If the C<$skiptext> boolean is true
(default: false) then text blocks are ignored to save time, since they
do not change the global graphic state.

This is a thin wrapper around render() with CAM::PDF::GS or
CAM::PDF::GS::NoText selected as the rendering class.

=cut

sub computeGS
{
   my $self      = shift;
   my $skip_text = shift;

   return $self->render('CAM::PDF::GS' . ($skip_text ? '::NoText' : q{}));
}

=item $self->findImages()

Traverse the content tree, accumulating embedded images and image
references, according to the CAM::PDF::Renderer::Images renderer.

=cut

sub findImages
{
   my $self = shift;

   return $self->render('CAM::PDF::Renderer::Images');
}

=item $self->traverse($rendererclass)

This recursive method is typically called only by wrapper methods,
like render().  It instantiates renderers as needed and calls methods
on them.

=cut

sub traverse
{
   my $self = shift;
   my $renderer = shift; # class
   my $blocks = shift || $self->{blocks};
   my $gs = shift;

   if (!$gs)
   {
      $gs = $renderer->new($self->{refs});
   }

   foreach my $block (@{$blocks})
   {
      $block->{gs} = $gs;

      # Enact the GS change performed by this operation
      my $func = $block->{name};
      $func =~ s/ [*] /star/gxms;
      $func =~ s/ \' /quote/gxms;
      $func =~ s/ \" /doublequote/gxms;

      if ($gs->can($func))
      {
         my $newgs = $gs->clone();

         {
            no strict 'refs'; ## no critic(ProhibitNoStrict)
            $newgs->$func(map {$_->{value}} @{$block->{args}});
         }

         $gs = $newgs;
      }

      if ($block->{type} eq 'block')
      {
         my $newgs = $self->traverse($renderer, $block->{value}, $gs);
         if ($block->{name} ne 'q')
         {
            $gs = $newgs;
         }
      }
   }
   return $gs;
}

=item $self->toString()

Flattens a content tree back into a scalar, ready to be inserted back
into a PDF document.  Since whitespace is discarded by the parser, the
resulting scalar will not be identical to the original.

=cut

sub toString
{
   my $self = shift;
   my $blocks = shift || $self->{blocks};

   my $str = q{};
   my $doc = $self->{refs}->{doc};
   foreach my $block (@{$blocks})
   {
      if ($block->{name} eq 'BI')
      {
         $str .= $doc->writeInlineImage($block->{args}->[0]) . "\n";
      }
      else
      {
         foreach my $arg (@{$block->{args}})
         {
            $str .= $doc->writeAny($arg) . q{ };
         }
         $str .= $block->{name} . "\n";
         if ($block->{type} eq 'block')
         {
            $str .= $self->toString($block->{value});
            $str .= $endings{$block->{name}} . "\n";
         }
      }
   }
   return $str;
}

# internal function
# Node creator

sub _b
{
   my ($type, @args) = @_;
   if ($type eq 'block')
   {
      return {
         type => $type,
         name => shift @args,
         value => shift @args,
         args => \@args,
      };
   }
   elsif ($type eq 'op')
   {
      return {
         type => $type,
         name => shift @args,
         args => \@args,
      };
   }
   else
   {
      return {
         type => $type,
         value => shift @args,
         args => \@args,
      };
   }
}

1;
__END__

=back

=head1 AUTHOR

See L<CAM::PDF>

=cut
