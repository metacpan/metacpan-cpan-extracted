package CSS::Scopifier::Group;
use strict;
use warnings;

# ABSTRACT: Like CSS::Scopifier, but can handle rule groups

use Moo;
use Types::Standard qw(:all);

use CSS::Scopifier;
use Path::Class qw(file);
use Text::Balanced qw(extract_bracketed);

has 'group_name', is => 'ro', isa => Maybe[Str], default => sub {undef};
has 'local',      is => 'ro', isa => InstanceOf['CSS::Scopifier'], default => sub { CSS::Scopifier->new };
has '_members',   is => 'ro', isa => ArrayRef, default => sub {[]};

sub scopify {
  my $self = shift;
  $_->scopify(@_) for ($self->local,@{$self->_members});
  return 1;
}

sub write_string {
  my $self = shift;
  join("\n",
    $self->local->write_string,
    map { join('',$_->group_name," \{\n",$_->write_string,"\n\}\n") } @{$self->_members}
  )
}

sub read {
  my ($class, $file) = @_;
  $class->read_string( scalar file($file)->resolve->slurp )
}


sub read_string {
    my $self = ref $_[0] ? shift : (shift)->new;
    
    my $string = shift;
    
    # Flatten whitespace and remove /* comment */ style comments (copied from CSS::Tiny)
    $string =~ tr/\n\t/  /;
    $string =~ s!/\*.*?\*\/!!g;
    
    my $local = '';
    
    while($string) {
      my ($extracted,$remainder,$skipped) = extract_bracketed( $string, '{}', '[^\{]*' );
      
      my ($pre,$inner) = ($skipped,$extracted);
      if($pre) {
        $pre =~ s/^\s+//;
        $pre =~ s/\s+$//;
      }
      if($inner) {
        $inner =~ s/^\{//;
        $inner =~ s/\}$//;
      }
      
      # we consider this to be a 'group' if it starts with '@' and contains 
      # additional curly brace(s) within (i.e. @media print { h1 { ... } })
      if($pre && $inner && $pre =~ /^\@/ && $inner =~ /\{/) {
        push @{$self->_members}, (ref $self)
          ->new({ group_name => $pre })
          ->read_string($inner)
      }
      else {
        $self->local->read_string( join('', $skipped||'', $extracted||'') )
      }
      
      $string = $remainder;
      
      last unless ($extracted);
    }
 
    # Read in any leftover bits into the local/top-level object for god measure
    $self->local->read_string($string) if ($string);
 
    $self
}


### honor the origical CSS::Tiny API:

# Generate a HTML fragment for the CSS
sub html {
  my $css = $_[0]->write_string or return '';
  return "<style type=\"text/css\">\n<!--\n${css}-->\n</style>";
}
 
# Generate an xhtml fragment for the CSS
sub xhtml {
  my $css = $_[0]->write_string or return '';
  return "<style type=\"text/css\">\n/* <![CDATA[ */\n${css}/* ]]> */\n</style>";
}
 
# Error handling
sub errstr { $CSS::Tiny::errstr }
sub _error { $CSS::Tiny::errstr = $_[1]; undef }


1;

__END__

=pod

=head1 NAME

CSS::Scopifier::Group - Like CSS::Scopifier but can handle rule groups

=head1 SYNOPSIS

  use CSS::Scopifier::Group;
  my $CSS = CSS::Scopifier::Group->read('/path/to/base.css');
  $CSS->scopify('.myclass');
  
  # To scopify while also merging 'html' and 'body' into
  # the '.myclass' selector rule:
  $CSS->scopify('.myclass', merge => ['html','body']);
  
  # New, "scopified" version of the CSS with each rule 
  # prepended with '.myclass':
  my $newCss = $CSS->write_string;

=head1 DESCRIPTION

This module provides exactly the same API as L<CSS::Scopifier>, but is able to handle
nested "group" rules, such as:

  @media print {
    h5 { 
      font-size: 200%; 
    }
  }

It scopifies the inner/nested rules in the same manner as the top-level. Internally,
it creates and tracks separate L<CSS::Scopifier> objects for each group/level (which
can also be nested multiple levels deep).

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


