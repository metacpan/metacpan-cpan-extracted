package Config::IniFiles::Slurp;

use strict;
use warnings;

use File::Spec;

use parent 'Exporter';

use vars (qw(@EXPORT_OK));

@EXPORT_OK = (qw( bin_slurp slurp utf8_slurp utf8_spew ));

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

sub utf8_slurp
{
    my $filename = shift;

    open my $in, '<:encoding(utf8)', $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

sub utf8_spew
{
    my $filename = shift;

    open my $out, '>:encoding(utf8)', $filename
        or die "Cannot open '$filename' for spewing - $!";

    print {$out} @_;

    close($out);

    return;
}

1;
