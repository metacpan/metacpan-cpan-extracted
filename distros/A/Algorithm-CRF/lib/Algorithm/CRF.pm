package Algorithm::CRF;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Algorithm::CRF ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Algorithm::CRF', $VERSION);

sub new {
  my $package = shift;
  my $self = bless {
		    @_,
		   }, $package;
  return $self;
}

my @params = 
  qw(
	freq
	maxiter
	cost
	eta
	convert
	textmodel
	version
	help
    );



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Algorithm::CRF - Perl binding for CRF++

=head1 SYNOPSIS

  use Algorithm::CRF;
  Algorithm::CRF::crfpp_learn( ... );

=head1 DESCRIPTION

Stub documentation for Algorithm::CRF, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.


=head1 FUNCTIONS

=cut 

=head2 new
    
=cut

=head2 crfpp_learn
    
=cut

=head2 EXPORT

None by default.



=head1 SEE ALSO

=head1 AUTHOR

Cheng-Lung Sung, E<lt>clsung@FreeBSD.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Cheng-Lung Sung E<lt>clsung@FreeBSD.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
