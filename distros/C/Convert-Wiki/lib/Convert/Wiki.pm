#############################################################################
# (c) by Tels 2004.
#
#############################################################################

package Convert::Wiki;

use 5.006001;
use strict;
use warnings;

use vars qw/$VERSION/;

$VERSION = '0.05';

use Convert::Wiki::Node;

#############################################################################

sub new
  {
  my $class = shift;

  my $self = bless {}, $class;

  my $args = $_[0];
  $args = { @_ } if ref($args) ne 'HASH';

  $self->clear();
  $self->_init($args);
  }

sub _init
  {
  my ($self,$args) = @_;

  $self->{interlink} = [];			# default none
  foreach my $k (keys %$args)
    {
    if ($k !~ /^(interlink|debug)\z/)
      {
      $self->error ("Unknown option '$k'");
      }
    $self->{$k} = $args->{$k};
    }
  
  if (ref($self->{interlink}) ne 'ARRAY')
    {
    $self->error ("Option 'interlink' needs a list of phrases");
    }

  $self->{nodes} = undef;
  $self;
  }

sub nodes
  {
  my $self = shift;

  my $node = $self->{nodes};

  my $nodes = 0;
  while (defined $node)
    {
    $nodes++;
    $node = $node->{next};
    }

  $nodes;
  }

sub clear
  {
  my $self = shift;
  
  $self->{error} = '';

  my $node = $self->{nodes};
  # break circular references (this should not be necc., but play safe)
  while (defined $node)
    {
    $node->{prev} = undef;
    my $next = $node->{next};
    $node->{next} = undef;
    $node = $next;
    }
  $self->{nodes} = undef;
  $self;
  }

sub from_txt
  {
  my ($self,$txt) = @_;

  require Convert::Wiki::Txt;

  $self->_from_txt($txt);

  $self->_pull_nodes();
  }

sub _pull_nodes
  {
  # ask each node whether it should be removed (based on context)
  my $self = shift;

  my $node = $self->{nodes};
  while (defined $node)
    {
    if ($node->_remove_me())
      {
      $node->{prev}->{next} = $node->{next};
      $node->{next}->{prev} = $node->{prev};
      my $next = $node->{next};
      $node->{prev} = undef;
      $node->{next} = undef;
      $node = $next;
      }
    else
      {
      $node = $node->{next};
      }
    }
  $self;
  }

sub as_wiki
  {
  my $self = shift;

  my $wiki = '';
  my $node = $self->{nodes};
  while (defined $node)
    {
    $wiki .= $node->as_wiki($self);
    $node = $node->{next};
    }
  $wiki;
  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

sub debug
  {
  my $self = shift;

  $self->{debug};
  }

1;
__END__

=head1 NAME

Convert::Wiki - Convert HTML/POD/txt from/to Wiki code

=head1 SYNOPSIS

	use Convert::Wiki;

	my $wiki = Convert::Wiki->new();
	
	$wiki->from_txt ( $txt );
	die ("Error: " . $wiki->error()) if $wiki->error;
	print $wiki->as_wiki();

	$wiki->from_html ( $html );
	die ("Error: " . $wiki->error()) if $wiki->error;
	print $wiki->as_wiki();

	# clear the object manually
	$wiki->clear();
	$wiki->add_txt ( $txt );
	die ("Error: " . $wiki->error()) if $wiki->error;
	print $wiki->as_wiki();

=head1 DESCRIPTION

C<Convert::Wiki> converts from various formats to various Wiki formats.

Input can come as HTML, POD or plain TXT (like it is written in many READMEs).
The data will be converted to an internal, node based format and can then be
converted to Wikicode as used by many wikis like the Wikipedia.

=head1 METHODS

=head2 new()

	$cvt = Convert::Wiki->new();

Creates a new conversion object. It takes an optional list of options. The
following are valid:

	debug		if set, will enable some debug outputs
	interlink	a list of phrases, that if found in a paragraph,
			are turned into links (into the same Wiki)

The phrases in interlink are searched case-sensitive, and if the found phrase
differs from the searched one, a piped link will be generated. In addition, you
can give a different link target and link name by separating them with C< | >:

	Foo		# turn "foo" into "[[Foo|foo]]", "Foo" into [Foo] etc
	Foobar|foo	# find "foo", "Foo" etc. and makes them [[Foobar|foo]]

=head2 as_txt()

	$cvt->as_wiki();

Returns the internally stored contents in wiki code.

=head2 clear()

	$cvt->clear();

Clears the conversion object by resetting the last error and
throwing away all internally stored nodes. There is usually
no need to do this manually, except if you want to reuse
a conversion object with the C<add> methods.

=head2 debug()

	$debugmode = $cvt->debug();		# true or false

Returns true if the debug mode is enabled.

=head2 error()

	$last_error = $cvt->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 from_txt()

	$cvt->from_txt();

Clears the object via L<clear()> and then converts the given text
to the internal format.

=head2 nodes()

	print "Nodes: ", $cvt->nodes(), "\n";

Returns the number of nodes the current document consists of. A fresh
C<Convert::Wiki> object has zero, and after you
=head2 EXPORT

None by default.

=head1 SEE ALSO

L<http://en.wikipedia.org/>, L<Pod::Simple::Wiki>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Tels

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut
