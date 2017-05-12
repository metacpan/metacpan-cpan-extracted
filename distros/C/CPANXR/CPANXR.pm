# $Id: CPANXR.pm,v 1.11 2003/10/06 21:41:28 clajac Exp $

package CPANXR;

require 5.6.0;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CPANXR ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.08';

sub new {
  my ($pkg) = @_;
  return bless {}, $pkg;
}

1;
__END__

=head1 NAME

CPANXR - Cross Referencer for CPAN (and Perl code)

=head1 SYNOPSIS

N/A

=head1 DESCRIPTION

CPANXR is the software for the CPAN Cross Reference site. It consits of some HTML, and some Perl code for analysing Perl code and building a database. It also features a web-interface for browsing the database.

=head1 INSTALLATION

Read docs/Install.pod

=head1 HACKING

Read docs/Hacking.pod

=head1 AUTHOR

Claes Jacobsson, claes at surfar.nu

=head1 SEE ALSO

perl(1).

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright 2003 Claes Jacobsson

=cut
