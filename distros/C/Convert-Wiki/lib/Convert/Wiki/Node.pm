#############################################################################
# (c) by Tels 2004. Part of Convert::Wiki
#
#############################################################################

package Convert::Wiki::Node;

use 5.006001;
use strict;
use warnings;

use vars qw/$VERSION/;

$VERSION = '0.04';

#############################################################################

sub new
  {
  my $class = shift;

  my $args = $_[0];
  $args = { @_ } if ref($args) ne 'HASH';
  
  my $self = bless {}, $class;

  # XXX TODO check arguments
 
  if (defined $args->{type})
    { 
    my $type = ucfirst($args->{type});
    $type = 'Para' if $type eq 'Paragraph';

    if ($type =~ /(\d)\z/)
      {
      # convert XX9 => XX (for Head1 etc)
      $args->{level} = abs($1 || 1);
      $type =~ s/\d\z//;
      }

    $self->error('Node type must be one of Head, Item, Mono, Line or Para but is \'' . $type . "'") and return $self
      unless $type =~ /^(Head|Item|Line|Mono|Para)\z/;

    $class .= '::' . $type;
    $self = bless $self, $class;	# rebless
    }

  if ($class ne __PACKAGE__)
    {
    my $pm = $class; $pm =~ s/::/\//g;	# :: => /
    $pm .= '.pm';
    require $pm;			# XXX not very portable I am afraid
    }

  $self->_init($args);
  }

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;

  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
  
  $self->{error} = '';
  $self->{txt} = '' unless defined $self->{txt};

  $self->{txt} =~ s/\n+\z//;		# remove trailing newline
  $self->{txt} =~ s/^\n+//;		# remove newlines at start
  
  $self->{prev} = undef;
  $self->{next} = undef;

  $self;
  }

sub _as_wiki
  {
  my ($self,$txt) = @_;

  $txt;
  }

sub as_wiki
  {
  my ($self, $wiki) = @_;

  $self->_as_wiki( $self->interlink($wiki) );
  }

sub interlink
  {
  # turn text in pragraph into links
  my ($self, $wiki) = @_;

  my $txt = $self->{txt};
  # for all phrases, find them case-insensitive, then link them
  for my $link (@{$wiki->{interlink}})
    {
    # turn "Foo" into "Foo|Foo"
    $link .= '|' . $link unless $link =~ /\|/;
    # split "Foobar|Foo" into "Foobar", "Foo"
    my ($target, $phrase) = split /\|/, $link;

    my $p = quotemeta(lc($phrase));

    if ($target =~ /^[a-z]+:/)
      {
      $txt =~ s/([^a-z])($p)([^a-z]|$)/${1}[$target ${2}]$3/i;

      }
    else
      {
      # no /g, since we want to interlink the phrase only once per paragraph
      # XXX TODO: this will turn "foo" into [[foo[[bar]]]] when searching
      # for bar after "foobar|foo"
      $txt =~ s/([^a-z]|^)($p)([^a-z]|$)/ "${1}[[$target" . ( ($2 eq $phrase && $2 eq $target) ? '' : "|$2") . "]]$3"/ie;
      }
    }
  $txt;
  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

sub type
  {
  my $self = shift;

  # XXX head1 => head
  my $type = ref($self); $type =~ s/.*:://;		# only last part
  lc($type);						# head, para, node etc
  }

sub prev_by_type
  {
  # find a previous node with a certain type
  my ($self,$type) = @_;

  my $prev = $self->{prev};

#  print "Looking for '$type'\n";
#  print "# At $prev $prev->{type}\n" if defined $prev;

  while (defined $prev && $prev->{type} !~ /$type/)
    {
    $prev = $prev->{prev};
#    print "# At $prev $prev->{type}\n" if defined $prev;
    }
  # found something, or hit the first node (aka undef)
  $prev;
  }

sub prev
  {
  my $self = shift;

  $self->{prev}
  }

sub next
  {
  my $self = shift;

  $self->{next};
  }

sub link
  {
  my $self = shift;

  $self->{next} = $_[0];
  $self->{next}->{prev} = $self;

  $self;
  }

sub _remove_me
  {
  0;
  }

1;
__END__

=head1 NAME

Convert::Wiki::Node - Represents a node (headline, paragraph etc) in a text

=head1 SYNOPSIS

	use Convert::Wiki::Node;

	my $head = Convert::Wiki::Node->new( txt => 'About Foo', type => 'head1' );
	my $text = Convert::Wiki::Node->new( txt => 'Foo is a foobar.', type => 'paragraph' );

	print $head->as_wiki(), $text->as_wiki();

=head1 DESCRIPTION

A C<Convert::Wiki::Node> represents a node (headline, paragraph etc) in a
text. All the nodes together represent the entire document.

=head1 METHODS

=head2 error()

	$last_error = $cvt->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_wiki()

	my $txt = $node->as_wiki($wiki);

Return the contents of the node as wiki code. The parameter C<$wiki> is the
Convert::Wiki object the node belongs to. It can be used to access parameters
like C<interlink>.

=head2 type()

	my $type = $node->type();

Returns the type of the node as string.

=head2 prev()

	my $prev = $node->prev();

Get the node's previous node.

=head2 prev_by_type

	my $prev = $node->prev_by_type( $type );

Find a previous node with a certain type, for instance 'head' or 'line'.

=head2 next()

	my $next = $node->next();

Get the node's next node.

=head2 link()

	$node->link( $other );

Set C<$node>'s next node to C<$other> and set C<$other>s prev to C< $node >.

=head2 _remove_me()

	$rc = $node->_remove_me();

Internally called by Convert::Wiki to fix up the nodes after the first pass.
A true return value indicates that this node must be removed entirely.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Convert::Wiki>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Tels

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut
