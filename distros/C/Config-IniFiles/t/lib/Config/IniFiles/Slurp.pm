package Config::IniFiles::Slurp;

use strict;
use warnings;

use File::Spec;

use base 'Exporter';

use vars (qw(@EXPORT_OK));

@EXPORT_OK = (qw( bin_slurp slurp ));

=head2 slurp()

Reads the entire file.

=cut


sub slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

=head2 slurp()

Reads the entire file with binmode

=cut
sub bin_slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    binmode $in;
    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

1;

