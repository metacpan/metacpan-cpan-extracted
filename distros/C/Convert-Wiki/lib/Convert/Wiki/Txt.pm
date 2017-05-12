#############################################################################
# (c) by Tels 2004. Part of Convert::Wiki
#
# contains the from_txt() fuctionality for Convert::Wiki
#############################################################################

package Convert::Wiki;

sub _from_txt
  {
  my ($self,$txt) = @_;

  $self->clear();

  #########################################################################
  # Stage 0: global normalization

  # convert "\n \n" to "\n\n"
  $txt =~ s/\n\s+\n/\n\n/;

  # convert "foo:\nbah" to "foo:\n\nbah" (but not headlines ending in ":")
  $txt =~ s/:\s*\n([^=_-])/:\n\n$1/g;

  # remove leading \n:
  $txt =~ s/^\n+//g;

  # remove leading lines:
  $txt =~ s/^\s*[=_-]+\n+//;

  # take the text, recognize parts at it's beginning until we no longer have
  # anything left
  my ($opt);
  my $tries = 0;
  my $node_nr = 0;

  my $last_node = $self->{nodes};

  while ((length($txt) > 0) && ($tries++ < 16))
    {

    #########################################################################
    # Stage 1: local normalization
 
    # remove superflous newlines
    $txt =~ s/^\n+//g;
    
    # remove "=========" and similiar stray delimiters
    $txt =~ s/^[=]+\n+//;
   
    #########################################################################
    # Stage 2: conversion to internal format

    $opt = undef;						# reset

    if ($self->{debug})
      {
      $txt =~ /^(.*)\n(.*)\n(.*)/;
      my $a = $1 || '';
      my $b = $2 || '';
      my $c = $3 || '';
      print STDERR "# at node $node_nr\n";
      print STDERR "# Text start is now:\n# '$a'\n# '$b'\n# '$c'\n";
      }
   
    # "Foo\n===" looks like a headline
    if ($txt =~ s/^([^=_-].+)\n[=_-]+\n+//)
      {
      print STDERR "# case 1\n" if $self->{debug};
      $opt = { txt => $1, type => 'head1' };
      }
    # '-----' or '_____' to rulers
    elsif ($txt =~ s/^[-_]+\n//)
      {
      print STDERR "# case 2\n" if $self->{debug};
      $opt = { type => 'line' };
      }
    # "1. Foo\n" looks like a bullet
    elsif ($txt =~ s/^([\d\.]+) (.+)\n//)
      {
      print STDERR "# case 3\n" if $self->{debug};
      $opt = { txt => $2, name => $1, type => 'item' };
      }
    # "* Foo\n" looks like a bullet
    elsif ($txt =~ s/^(\s*[*+-](\s+(.|\n)+?))(\n\n|\n\s*[*+-])/$4/)
      {
      print STDERR "# case 4\n" if $self->{debug};
      my $t = $1;
      $t =~ s/^\s*[*+-]\s+//;		# "- Foo" => "Foo"
      $t =~ s/\n\s+/\n/g;		# "\n Boo" => "\nBoo"

      $t =~ s/\s+\z//g;			# remove trailing space
      $t =~ s/\n/ /g;			# remove newlines entirely

      $opt = { txt => $t, type => 'item' };
      }
    # " some text\nmore text" is one paragraph and not monospaced
    elsif ($txt =~ s/^\s+(([^\s].+\n){2,})//)
      {
      print STDERR "# case 5\n" if $self->{debug};
      $opt = { txt => $1, type => 'para' };
      }
    # " some text\n\n" is one monospaced line
    elsif ($txt =~ s/^\s+(((.+)\n\n))//)
      {
      print STDERR "# case 6\n" if $self->{debug};
      my $t = $1;
      $t =~ s/\n\s+/\n/g;		# "\n Boo" => "\nBoo"
      $t =~ s/\n\z//g;			# remove trailing \n

      $opt = { txt => $t, type => 'mono' };
      }
    # " Foo\n" looks like a monospaced text
    elsif ($txt =~ s/^(([ \t]+[^\s\n*+=-].+\n){2,})//)
      {
      print STDERR "# case 7 '$1'\n" if $self->{debug};
      my $t = $1;

      $t =~ s/^\s+//g;			# " Boo" => "Boo"
      $t =~ s/\n\s+/\n/g;		# "\n Boo" => "\nBoo"
      $t =~ s/\n\z//g;			# remove trailing \n

      $opt = { txt => $t, type => 'mono' };
      }
    # Also: "$ Foo\n" and "# bah" look like a monospaced text
    elsif ($txt =~ s/^([\$\#])\s+(((.+)\n){1,})//)
      {
      print STDERR "# case 8\n" if $self->{debug};
      my $t = "$1 $2";
      $t =~ s/\n\s+/\n/g;		# "\n Boo" => "\nBoo"
      $t =~ s/\n\z//g;			# remove trailing \n

      $opt = { txt => $t, type => 'mono' };
      }
    # "Foo\n" looks like a text
    elsif ($txt =~ s/^([^\s](([^*+\n-].+)\n){1,})//)
      {
      print STDERR "# case 9\n" if $self->{debug};
      $opt = { txt => $1, type => 'para' };
      }
    
    if (defined $opt)
      { 
      $tries = 0;
      if ($self->{debug})
        {
        require Data::Dumper;
        print STDERR Data::Dumper::Dumper($opt);
        }
      $opt->{interlink} = $self->{interlink};
      my $node = Convert::Wiki::Node->new( $opt );
      if ($last_node)
        {
        # link node to last node
        $last_node->link( $node );
        }
      else
        {
        $self->{nodes} = $node;
        }
      $last_node = $node;
      $node_nr++;
      }
    }
  if ($tries > 0 && length($txt) > 0)
    {
    # something was left over
    $self->error( "Cannot recognize text ahead of me. Giving up." );
    }
 
  $self; 
  }

1;
__END__
