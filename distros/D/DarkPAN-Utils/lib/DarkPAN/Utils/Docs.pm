########################################################################
package DarkPAN::Utils::Docs;
########################################################################

use strict;
use warnings;

use English qw(-no_match_vars);
use Data::Dumper;
use Pod::Extract;
use Pod::Markdown;
use Scalar::Util qw(openhandle);
use Text::Markdown::Discount qw(markdown);

our %ATTRIBUTES = (
  text       => 1,
  pod        => 0,
  code       => 0,
  sections   => 0,
  markdown   => 0,
  html       => 0,
  url_prefix => 0,
);

__PACKAGE__->setup_accessors( keys %ATTRIBUTES );

use parent qw(Class::Accessor::Validated);

our $VERSION = '0.01';

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $self = $class->SUPER::new(@args);

  my $text = $self->get_text;

  my $fh;

  if ( ref $text && openhandle $text ) {
    $fh = $text;

    local $RS = undef;
    $text = <$fh>;
    close $fh;
  }
  elsif ( ref $text ) {
    $text = ${$text};
  }

  return $self->parse_pod();
}

########################################################################
sub parse_pod {
########################################################################
  my ($self) = @_;

  my $text = $self->{text};

  my $fh = IO::Scalar->new( \$text );

  my @result = extract_pod( $fh, { markdown => 1, url_prefix => $self->get_url_prefix } );

  close $fh;

  foreach my $attr (qw(pod code sections markdown)) {
    my $setter = "set_$attr";

    $self->$setter( shift @result );
  }

  if ( $self->get_pod ) {
    $self->set_html( Text::Markdown::Discount::markdown( $self->get_markdown ) );
  }

  return $self;
}

########################################################################
sub to_html {
########################################################################
  my ( $self, $markdown ) = @_;

  $markdown //= $self->get_markdown;
  $markdown =~ s/^\s+$//xsm;

  if ( !$markdown ) {
    $markdown = $self->get_text;
  }

  return
    if !$markdown;

  $self->set_html( Text::Markdown::Discount::markdown($markdown) );

  return $self->get_html;
}

1;

__END__

=pod


=head1 NAME

DarkPAN::Utils::Docs - utilities to create documentation from modules

=head1 SYNOPSIS

 my $docs = DarkPAN::Utils::Docs->new(text => $file);

=head1 DESCRIPTION

=head1 METHODS AND SUBROUTINES

=head2 new

=head2 parse_pod

=head2 to_html

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=head1 SEE ALSO

=cut
