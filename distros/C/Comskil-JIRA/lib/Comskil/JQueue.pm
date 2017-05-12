
## #TODO Create the interface that will be standard
## #TODO See if you can make some functions abstract and some virtual in Perl.




package Comskil::JQueue;

=head1 NAME

Comskil::JWand - The great new Comskil::JWand!

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
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = '0.10';
    @ISA    = qw( Exporter );
    @EXPORT	= qw( );
    @EXPORT_OK   = ( );  ## qw($Var1 %Hashit &func3);
    %EXPORT_TAGS = ( );  ## e.g.  TAG => [ qw!name1 name2! ],
}
 
our @EXPORT_OK;

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
	my ($class,@args) = @_;
	my $self = ( );
	bless($self,$class);
	
	return($self);
}

1;
__END__
### EOF ###