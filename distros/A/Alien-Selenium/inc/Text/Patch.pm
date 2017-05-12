#!/usr/bin/perl
package Text::Patch;
use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( patch );
our $VERSION = '1.1';
use strict;
use warnings;
use Carp;

sub patch
{
  my $text = shift;
  my $diff = shift;
  my %options;
  
  if( ref $_[0] eq 'HASH' )
    {
    %options = %{ $_[0] };
    }
  else
    {
    %options = @_;
    }  

  return patch_unified( $text, $diff ) if $options{ 'STYLE' } eq 'Unified';
  croak "required STYLE option is missing";
}

sub patch_unified
{
  my $text = shift;
  my $diff = shift;
  
  my @text = split /^/m, $text;
  my @diff = split /^/m, $diff;
  
  my @hunks;
  my %hunk;
  
  for( @diff )
    {
    #print STDERR ">>> ... $_";
    if( /^\@\@\s*-(\d+),(\d+)/ )
      {
      #print STDERR ">>> *** HUNK!\n";
      push @hunks, { %hunk };
      %hunk = ();
      $hunk{ FROM } = $1 - 1; # diff is 1-based
      $hunk{ LEN  } = $2;
      $hunk{ DATA } = [];
      }
    push @{ $hunk{ DATA } }, $_;
    }
  push @hunks, { %hunk }; # push last hunk
  shift @hunks; # first is always empty  

  for my $hunk ( reverse @hunks )
    {
    #use Data::Dumper;
    #print STDERR Dumper( $hunk );
    my @pdata;
    for( @{ $hunk->{ DATA } } )
      {
      next unless s/^([ \-\+])//;
      #print STDERR ">>> ($1) $_";
      next if $1 eq '-';
      push @pdata, $_;
      }
    splice @text, $hunk->{ FROM }, $hunk->{ LEN }, @pdata;
    }
  
  return join '', @text;  
}

=pod

=head1 NAME

Text::Patch - Patches text with given patch

=head1 SYNOPSIS

    use Text::Patch;
    
    $output = patch( $source, $diff, STYLE => "Unified" );

    use Text::Diff;
    
    $src  = ...
    $dst  = ...
    
    $diff = diff( $src, $dst, { STYLE => 'Unified' } );
    
    $out  = patch( $src, $diff, { STYLE => 'Unified' } );
    
    print "Patch successful" if $out eq $dst;

=head1 DESCRIPTION

Text::Patch combines source text with given diff (difference) data. 
Diff data is produced by Text::Diff module or by the standard diff
utility (man diff, see -u option).

=over 4

=item patch( $source, $diff, options... )

First argument is source (original) text. Second is the diff data.
Third argument can be either hash reference with options or all the
rest arguments will be considered patch options:

    $output = patch( $source, $diff, STYLE => "Unified", ... );

    $output = patch( $source, $diff, { STYLE => "Unified", ... } );

Options are:

  STYLE => 'Unified'
  
Note that currently only 'Unified' diff format is supported!
STYLE names are the same described in Text::Diff.

The 'Unified' diff format looks like this:

  @@ -1,7 +1,6 @@
  -The Way that can be told of is not the eternal Way;
  -The name that can be named is not the eternal name.
   The Nameless is the origin of Heaven and Earth;
  -The Named is the mother of all things.
  +The named is the mother of all things.
  +
   Therefore let there always be non-being,
     so we may see their subtlety,
   And let there always be being,
  @@ -9,3 +8,6 @@
   The two are the same,
   But after they are produced,
     they have different names.
  +They both may be called deep and profound.
  +Deeper and more profound,
  +The door of all subtleties!


=back

=head1 LIMITS

  Only 'Unified' diff format is supported.
  
=head1 TODO

  Interfaces with files, arrays, etc.
  Diff formats support: "Context", "OldStyle" (As noted in Text::Diff)

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
 
  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=head1 VERSION

  $Id: Patch.pm,v 1.2 2004/12/07 21:26:41 cade Exp $

=cut

