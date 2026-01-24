# -*- cperl -*-
# ABSTRACT: Presentation object


package BeamerReveal::Object::Presentation;
our $VERSION = '20260123.1702'; # VERSION

use parent 'BeamerReveal::Object';
use Carp;

use Data::Dumper;

use BeamerReveal::TemplateStore;
use BeamerReveal::Log;


sub new {
  my $class = shift;
  my ( $chunkData, $lines, $lineCtr ) = @_;

  my $logger = $BeamerReveal::Log::logger;
  
  $class = (ref $class ? ref $class : $class );
  my $self = {};
  bless $self, $class;

  $self->{videos} = [];
  foreach my $line ( @$lines ) {
    ++$lineCtr;
    ( $line =~ /^-(?<command>\w+):(?<payload>.*)$/ )
      or $logger->fatal( "Error: syntax incorrect in rvl file on line $lineCtr '$line'\n" );
    if ( $+{command} eq 'parameters' ) {
      $self->{parameters} = BeamerReveal::Object::readParameterLine( $+{payload} );
    }
    else {
      $logger->fatal( "Error: unknown Presentation data on line $lineCtr '$line'\n" );
    }
  }

  return $self;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::Object::Presentation - Presentation object

=head1 VERSION

version 20260123.1702

=head1 SYNOPSIS

Represents a Presentation

=head1 METHODS

=head2 new()

  $p = BeamerReveal::Object::Presentation->new( $data, $lines, $linectr )

Generates a presentation from the corresponding chunk data in the C<.rvl> file.

=over 4

=item . C<$data>

chunkdata to parse

=item . C<$lines>

lines to parse

=item . C<$lineCtr>

starting line of the chunk (used for error reporting)

=item . C<$p>

the presentation object

=back

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
