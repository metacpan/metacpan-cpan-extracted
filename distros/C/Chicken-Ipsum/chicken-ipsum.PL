#!perl
use strict;
use warnings;
use Carp qw/ croak /;

my $file_out = shift;
my $file_in = "$file_out.in";
open my $fhi, '<', $file_in
    or croak "Failed to open file `$file_in` for reading: $!";
my $code = squash_strip($fhi);
close $fhi;
open my $fho, '>', $file_out
    or croak "Failed to open file `$file_out` for writing: $!";
print $fho $code;
close $fho;
chmod 0755, $file_out;

sub squash_strip {
    my $fh = shift;
    my $stripped;
    my $in_ignore_section = 0;
    while (<$fhi>) {
        if (/#.*:squash-remove-start:$/) {
            $in_ignore_section = 1;
            next;
        } elsif (/#.*:squash-remove-end:$/) {
            $in_ignore_section = 0;
            next;
        }
        next if $in_ignore_section;
        next if /#.*:squash-remove-line:$/;
        $stripped .= $_;
    }
    return $stripped;
}
