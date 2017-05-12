#!perl -T

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR})
{
    my $msg = 'Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan(skip_all => $msg);
}
else
{
    plan(tests => 3);
}

sub not_in_file_ok
{
    my ($filename, %regex) = @_;
    open(my $fh, '<', $filename)
      or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>)
    {
        while (my ($desc, $regex) = each %regex)
        {
            if ($line =~ $regex)
            {
                push @{$violated{$desc} ||= []}, $.;
            }
        }
    }

    if (%violated)
    {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    }
    else
    {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok
{
    my ($module) = @_;
    not_in_file_ok(
              $module => 'the great new $MODULENAME' => qr/ - The great new /,
              'boilerplate description' => qr/Quick summary of what the module/,
              'stub function definition' => qr/function[12]/,
    );
}

not_in_file_ok(
              README => "The README is used..." => qr/The README is used/,
              "'version information here'" => qr/to provide version information/
);

not_in_file_ok(Changes => "placeholder date/time" => qr(Date/time));

module_boilerplate_ok('lib/DBIx/Tree/MaterializedPath.pm');

