# -*- cperl -*-
# ABSTRACT: Object


package BeamerReveal::Object;

use parent 'Exporter';
use Carp;

use Data::Dumper;

my $errorstring = "Error: BeamerReveal::Object is an abstract base class - only use derived objects\n";


sub new {
  carp( $errorstring );
}


sub makeSlide {
  carp( $errorstring );
}


sub readParameterLine {
  my ( $line ) = @_;
  my $braceconstructRegexp = qr { (?<brace_group>
				    \{
				    (?<val>
				      (?> (?:\\[{}]|(?![{}]).)* )
				    |
				      (?&brace_group)
				    )
				    \}
				  )
			      }xs;
  my $parmdb = {};
  while( $line =~ /(?<kw>\w+)=${braceconstructRegexp},*/g ) {
    $parmdb->{$+{kw}} = $+{val};
  }
  return $parmdb;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::Object - Object

=head1 VERSION

version 20251224.1500

=head1 SYNOPSIS

Abstract base class for main items in the C<.rvl> file.

=head1 METHODS

=head2 new()

Don't use this method directly. It will generate a fatal error.

=head2 makeSlide()

Don't use this method directly. It will generate a fatal error.

=head2 readParameterLine

  $parmdb  = readParameterLine( $line )

This is an auxiliary function (not a member function!) to read parameter lines of a C<.rvl> file.

=over 4

=item . C<$line>

line to parse

=item . C<$parmdb>

reference to hash that contains the parameters with their value.

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
