#!perl -T
BEGIN {
    use lib qw( ./erecipes/perl/lib );
}
use strict;
use warnings;
use Test::More tests => 13;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open my $fh, "<", $filename
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}


module_boilerplate_ok('lib/CGI/Ex/Recipes.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/View.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/Edit.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/Add.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/Delete.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/Template/Menu.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/DBIx.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/Default.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/Imager.pm');
module_boilerplate_ok('erecipes/perl/lib/CGI/Ex/Recipes/Cache.pm');


