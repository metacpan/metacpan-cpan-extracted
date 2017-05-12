#!perl -T
#
# $Id: boilerplate.t 52 2009-01-06 03:22:31Z jaldhar $
#
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 2 + <tmpl_var nummodules>;

sub not_in_file_ok {
    my ( $filename, %regex ) = @_;
    open my $fh, '<', $filename
        or die "couldn't open $filename for reading: $ERRNO";

    my %violated;

    while ( my $line = <$fh> ) {
        while ( my ( $desc, $regex ) = each %regex ) {
            if ( $line =~ $regex ) {
                push @{ $violated{$desc} ||= [] }, $NR;
            }
        }
    }
    close $fh or die "Close failed: $ERRNO";

    if (%violated) {
        fail("$filename contains boilerplate text");
        for ( keys %violated ) {
            diag "$_ appears on lines @{$violated{$_}}";
        }
    }
    else {
        pass("$filename contains no boilerplate text");
    }
    return;
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok(
        $module => 'the great new $MODULENAME' => qr/ - The great new /mx,
        'boilerplate description'  => qr/Quick summary of what the module/mx,
        'stub function definition' => qr/function[12]/mx,
    );
    return;
}

not_in_file_ok(
    README => 'The README is used...' => qr/The README is used/mx,
    "'version information here'" => qr/to provide version information/mx,
);

not_in_file_ok( Changes => 'placeholder date/time' => qr{Date/time}mx );

<tmpl_loop module_pm_files>
    module_boilerplate_ok('<tmpl_var module_pm_files_item>');
</tmpl_loop>
