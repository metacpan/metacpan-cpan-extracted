=head1 NAME
package Comskil-JIRA A Perl library for working with JIRA.
=cut

package Comskil;

=head1 NAME

Comskil - The great new Comskil!

=head1 VERSION

Version 0.1

=cut

use strict;
use warnings;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Comskil::JWand;

    my $foo = Comskil::JWand->new();
    ...
=cut

BEGIN {
    use Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION = "00.12345";
    @ISA = qw( Exporter );
    @EXPORT = qw( );
    %EXPORT_TAGS = ( );
    @EXPORT_OK = qw( );
}

END { }

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=over 8

=item * new()

=item * grabVersions()

=item * grabStatuses()

=back

=head1 SUBROUTINES/METHODS

=cut

sub new {
	my ($class,$self,@args) = @_;
	bless($self,$class);
	return($self);
}

1;
__END__
#TODO Perl documentation for the library would go in here.
#TODO Move the global values for release, version, copyright, etc. into here and export them.
