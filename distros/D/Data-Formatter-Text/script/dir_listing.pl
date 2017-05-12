#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Data::Formatter::Text;

# Create a table of file information
my @table = (['Filename', 'Size (bytes)', 'Mode']);

# Get a list of the files in the working directory
my @files = <*>;
foreach my $file (@files)
{
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
        $atime, $mtime, $ctime, $blksize, $blocks) = stat($file);

    push @table, [$file, $size, $mode];
} 

# Output the resulting table
my $text = new Data::Formatter::Text(\*STDOUT);
$text->out({ 'File Listing' => \@table });

__END__

=head1 NAME

dir_listing.pl - Lists the files in the current working directory in a table.

=head1 SYNOPSIS

  perl dir_listing.pl 
  File Listing:
      -----------------------------------
      |Filename      |Size (bytes)|Mode |
      |--------------|------------|-----|
      |check.h       |5108        |33204|
      |--------------|------------|-----|
      |check64bit.cpp|6540        |33204|
      |--------------|------------|-----|
      |check64bit.h  |3111        |33204|
      |--------------|------------|-----|
      |dir_listing.pl|1537        |33216|
      -----------------------------------


=head1 DESCRIPTION

This simple script uses the Data::Formatter::Text module to format a list of the files in the working directory into a table.

=head1 SEE ALSO

C<Data::Formatter::Text> - Formats data stored in scalars, hashes, and arrays into strings, definition lists, bulletted lists, and tables.

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Zachary D. Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut