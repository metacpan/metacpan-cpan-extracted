# $Id: /local/CPAN/AxKit-XSP-L10N/t/lib/TestHelper.pm 1396 2005-03-25T03:58:41.995755Z claco  $
package TestHelper;
use strict;
use warnings;
use FileHandle;
use vars qw(@EXPORT_OK);
use base 'Exporter';

@EXPORT_OK = qw(comp_to_file);

sub comp_to_file {
    my ($string, $file) = @_;

    return 0 unless $string && $file && -e $file && -r $file;

    $string =~ s/\n//g;
    $string =~ s/\s//g;
    $string =~ s/\t//g;

    my $fh = FileHandle->new("<$file");
    if (defined $fh) {
        local $/ = undef;
        my $contents = <$fh>;
        $contents =~ s/\n//g;
        $contents =~ s/\s//g;
        $contents =~ s/\t//g;

        # remove the tt2 and xml Ids
        $contents =~ s/<!--.*-->//;
        $contents =~ s/\[%#.*%\]//;

        undef $fh;

        if ($string eq $contents) {
            return (1, $string, $contents);
        } else {
            return (0, $string, $contents);
        };
    };

    return 0;
};

1;