package ClarionUnlock;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use ClarionUnlock ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.0';


# Preloaded methods go here.

sub generate{
    
    my($serial) = @_;
    # check length of option passed. Length must be 4 digits
    if (length($serial) eq 4) {
        # If the length is valid, break the 4 digits into individual variables
        my $char1 = substr($serial,0,1);
        my $char2 = substr($serial,1,1);
        my $char3 = substr($serial,2,1);
        my $char4 = substr($serial,3,1);
        # Convert the 1st digit into the 1st unlock digit
        if ($char1 < 6) {
            $char1 = 1 + $char1;
        } else {
            $char1 = $char1 - 5;        
        }
        # Convert the 2nd digit into the 2nd unlock digit
        if ($char2 < 5) {
            $char2 = 2 + $char2;
        } else {
            $char2 = $char2 - 4;        
        }
        # Convert the 3rd digit into the 3rd unlock digit
        if ($char3 < 4) {
            $char3 = 3 + $char3;
        } else {
            $char3 = $char3 - 3;        
        }
        # Convert the final digit into the last unlock digit
        if ($char4 < 3) {
            $char4 = 4 + $char4;
        } else {
            $char4 = $char4 -2;        
        }
        return($char1.$char2.$char3.$char4);
    } else {
        return("ERROR-RTFM");
    }
    
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

ClarionUnlock - Perl extension for generating unlock codes for many models of Clarion car stereos

=head1 SYNOPSIS

  use ClarionUnlock;
  $unlockcode = ClarionUnlock::generate("4652");

=head1 DESCRIPTION

Generates the unlock code based on the unit serial number. The extension ONLY REQUIRES THE LAST 4 DIGITS OF THE SERIAL NUMBER.

=head2 EXPORT

None by default.



=head1 SEE ALSO

n/a

=head1 AUTHOR

Andy Dixon, E<lt>andy.dixon@twistedindustries.co.uk<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Andy Dixon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
