package CSS::Scopifier;
use strict;
use warnings;

# ABSTRACT: Prepends CSS selectors to apply scope/context

our $VERSION = 0.04;

use CSS::Tiny 1.19;

use Moo;
extends 'CSS::Tiny';

sub scopify {
  my ($self, $selector, @arg) = @_;
  my %opt = ref($arg[0]) ? %{$arg[0]} : @arg;
  
  die "scopify() requires string selector argument" 
    unless ($selector && ! ref($selector));
  
  # Merge specified selectors into the root/scoped selector. Useful
  # with  merge => ['html','body'] if scopifying a base css file
  my $root_sel;
  if($opt{merge}) {
    my @list = ref $opt{merge} ? @{$opt{merge}} : ($opt{merge});
    $root_sel = {};
    %$root_sel = ( %$root_sel, %$_ ) for (
      map { delete $self->{$_} } 
      grep { exists $self->{$_} }
      @list
    );
  }

	$self->{"$selector $_"} = delete $self->{$_} for (keys %$self);
  $self->{$selector} = $root_sel if ($root_sel);
  
  return 1;
}

# Redefining read_string() until CSS::Tiny bug [rt.cpan.org #87261] is fixed
sub read_string {
    my $self = ref $_[0] ? shift : bless {}, shift;
 
    # Flatten whitespace and remove /* comment */ style comments
    my $string = shift;
    $string =~ tr/\n\t/  /;
    $string =~ s!/\*.*?\*\/!!g;
 
    # Split into styles
    foreach ( grep { /\S/ } split /(?<=\})/, $string ) {
        unless ( /^\s*([^{]+?)\s*\{(.*)\}\s*$/ ) {
            return $self->_error( "Invalid or unexpected style data '$_'" );
        }
 
        # Split in such a way as to support grouped styles
        my $style      = $1;
        my $properties = $2;
        $style =~ s/\s{2,}/ /g;
        my @styles = grep { s/\s+/ /g; 1; } grep { /\S/ } split /\s*,\s*/, $style;
        foreach ( @styles ) { $self->{$_} ||= {} }
 
        # Split into properties
        foreach ( grep { /\S/ } split /\;/, $properties ) {
            unless ( /^\s*(\*?[\w._-]+)\s*:\s*(.*?)\s*$/ ) { #<-- updated regex to support starting with '*'
                return $self->_error( "Invalid or unexpected property '$_' in style '$style'" );
            }
            foreach ( @styles ) { $self->{$_}->{lc $1} = $2 }
        }
    }
 
    $self
}


1;

__END__

=pod

=head1 NAME

CSS::Scopifier - Prepends CSS selectors to apply scope/context

=head1 SYNOPSIS

  use CSS::Scopifier;
  my $CSS = CSS::Scopifier->read('/path/to/base.css');
  $CSS->scopify('.myclass');
  
  # To scopify while also merging 'html' and 'body' into
  # the '.myclass' selector rule:
  $CSS->scopify('.myclass', merge => ['html','body']);
  
  # New, "scopified" version of the CSS with each rule 
  # prepended with '.myclass':
  my $newCss = $CSS->write_string;

=head1 DESCRIPTION

CSS::Scopifier extends L<CSS::Tiny> adding the C<scopify> method. The C<scopify> method rewrites and prepends
all the rules in the CSS object with the supplied selector string.

For instance, consider a C<CSS::Scopifier> object C<$CSS> representing the following CSS:

  h1, h2 {
    font-family: Georgia, "DejaVu Serif", serif;
    letter-spacing: .1em;
  }
  h1 {font-size: 1.5em;}
  h2 {font-size: 1.4em;}

Then, after calling:

  $CSS->scopify('.myclass');

The CSS would then be:

  .myclass h2 {
    font-family: Georgia, "DejaVu Serif", serif;
    font-size: 1.4em;
    letter-spacing: .1em;
  }
  .myclass h1 {
    font-family: Georgia, "DejaVu Serif", serif;
    font-size: 1.5em;
    letter-spacing: .1em;
  }

Note: C<CSS::Scopifier> only supports single-level CSS; to scopify across nested/grouped rules
(i.e. grouped within rules like C<@media print { ... }>) use L<CSS::Scopifier::Group>.

=head1 METHODS

Note: C<CSS::Scopifier> extends L<CSS::Tiny>. Please see L<CSS::Tiny> for complete API reference.

=head2 scopify

Prepends the selector string supplied in the first argument to each rule in the object.

Also accepts optional hash param C<merge> to rewrite and merge specific selector rules into the
top selector, instead of prepending it.

For instance, consider a C<CSS::Scopifier> object C<$CSS> representing the following CSS:

  html {
    height: 100%;
    overflow-y: scroll;
  }
  body {
    height: 100%;
    background: #fff;
    color: #444;
    line-height: 1.4;
  }
  h1, h2 {
    font-family: Georgia, "DejaVu Serif", serif;
    letter-spacing: .1em;
  }
  h1 {font-size: 1.5em;}

Then, after calling:

  $CSS->scopify('#myid', merge => ['html','body']);

The CSS would then be:

  #myid h2 {
    font-family: Georgia, "DejaVu Serif", serif;
    letter-spacing: .1em;
  }
  #myid h1 {
    font-family: Georgia, "DejaVu Serif", serif;
    font-size: 1.5em;
    letter-spacing: .1em;
  }
  #myid {
    background: #fff;
    color: #444;
    height: 100%;
    line-height: 1.4;
    overflow-y: scroll;
  }

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


