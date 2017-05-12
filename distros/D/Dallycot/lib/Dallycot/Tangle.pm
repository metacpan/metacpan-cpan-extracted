package Dallycot::Tangle;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Extract Dallycot source from a markdown document

use utf8;
use Moose;
with 'Markdent::Role::Handler';

use Markdent::Parser;
use List::Util qw(any);

has code_blocks => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { +{} }
);

has extracted_code => (
  is      => 'rw',
  default => sub {''},
);

has seen_first_h1 => (
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
);

has start_with => (
  is      => 'rw',
  isa     => 'Str',
  default => ''
);

has section_name => (
  is      => 'rw',
  isa     => 'Str',
  default => ''
);

has code_link_name => (
  is      => 'rw',
  isa     => 'Str',
  default => ''
);

has in_header => (
  is      => 'rw',
  isa     => 'Int',
  default => 0
);

has in_link => ( is => 'rw' );

sub parse {
  my ( $self, $markdown ) = @_;

  my $parser = Markdent::Parser->new(
    dialect => 'GitHub',
    handler => $self
  );

  $parser->parse( markdown => $markdown );

  # now we go through and put things together
  # look for things like `_"section a"` or `_"section a:footer"` or
  #  `_":footer"`
  my $output = "";
  if ( $self->start_with ) {
    $output = $self->tangle_section( $self->start_with );
  }
  else {
    $output = $self->extracted_code;
  }
  return $output;
}

sub tangle_section {
  my ( $self, $section_name, @stack ) = @_;

  if ( any { $_ eq $section_name } @stack ) {
    die "Circular reference for $section_name\n";
  }

  my (@name_parts) = split( /:/, $section_name );
  my $code = $self->code_blocks->{$section_name};
  if ( !defined $code ) {
    return "";
  }

  $self->code_blocks->{$section_name} = '';

  my @references = $code =~ m{_"(.+?)"}xg;
  foreach my $ref (@references) {
    my $replacement;
    my @ref_bits = map { $self->_normalize_name($_) } split( /:/, $ref );
    if ( $ref_bits[0] eq '' ) {
      $ref_bits[0] = $name_parts[0];
    }
    $replacement = $self->tangle_section( join( ":", @ref_bits ), @stack, $section_name );
    $code =~ s{_"\Q$ref\E"}{$replacement}x;
  }

  return $code;
}

sub handle_event {
  my ( $self, $event ) = @_;
  my $method;
  if ( $method = $self->can( $event->event_name ) ) {
    $self->$method( $event->kv_pairs_for_attributes() );
  }
  return;
}

sub start_header {
  my ( $self, %info ) = @_;
  $self->in_header( $info{level} );
  return;
}

sub end_header {
  my ( $self, %info ) = @_;
  $self->in_header(0);
  return;
}

sub start_link {
  my ( $self, %info ) = @_;
  $self->in_link( \%info );
  return;
}

sub end_link {
  my ( $self, %info ) = @_;
  $self->in_link(0);
  return;
}

sub text {
  my ( $self, %info ) = @_;

  if ( $self->in_header ) {
    return $self->header( %info, level => $self->in_header );
  }
  elsif ( $self->in_link ) {
    return $self->save_link( %{ $self->in_link }, %info );
  }
}

sub code_block {
  my ( $self, %info ) = @_;

  return if defined( $info{language} ) && lc( $info{language} ) ne 'dallycot';

  $self->extracted_code( $self->extracted_code . "\n" . $info{code} );

  my $name = $self->section_name;
  if ( $self->code_link_name ) {
    $name .= ":" . $self->code_link_name;
  }
  $self->code_blocks->{$name} //= "";
  return $self->code_blocks->{$name} .= "\n" . $info{code};
}

sub _normalize_name {
  my ( $self, $name ) = @_;

  $name =~ s{^\s+}{};
  $name =~ s{\s+$}{};
  $name =~ s{\s+}{ }g;
  $name =~ s{:+}{--}g;
  $name =~ s{[^-_0-9A-Za-z ]+}{}xg;
  return lc($name);
}

sub save_link {
  my ( $self, %info ) = @_;

  use Data::Dumper;
  if ( $info{uri} eq '#' || $info{uri} eq '' ) {
    my $name = $self->_normalize_name( $info{text} );
    return if $name eq '';
    return $self->code_link_name($name);
  }
  elsif ( $info{uri} =~ m{^#(.*)$}x && $info{title} && $info{title} eq 'start:' ) {
    return $self->start_with( $self->_normalize_name($1) );
  }
}

sub header {
  my ( $self, %info ) = @_;

  $self->code_link_name('');
  if ( $info{level} < 2 && !$self->seen_first_h1 ) {
    $self->seen_first_h1(1);
    return;
  }
  $self->seen_first_h1(1);

  my $name = $self->_normalize_name( $info{text} );
  return if $name eq '';
  return $self->section_name($name);
}

__PACKAGE__ -> meta -> make_immutable;

1;
