# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-26 12:00 (EST)
# Function: read files to map
#
# $Id: ReadInput.pm,v 1.1 2010/11/01 18:41:44 jaw Exp $

package AC::MrGamoo::ReadInput;
use AC::MrGamoo::Customize;
use AC::Import;
use strict;

our @ISA    = 'AC::MrGamoo::Customize';
our @EXPORT = qw(readinput);
our @CUSTOM = @EXPORT;


1;

=head1 NAME

AC::MrGamoo::ReadInput - read input records

=head1 SYNOPSIS

    emacs /myperldir/Local/MrGamoo/ReadInput.pm
    copy. paste. edit.

    use lib '/myperldir';
    my $m = AC::MrGamoo::D->new(
        class_readinput    => 'Local::MrGamoo::ReadInput',
    );

=head1 DESCRIPTION

In your map/reduce job, your C<map> function is called once per record.
The C<readinput> function is responsible for reading the actual files
and returning records.

The default C<readinput> returns one line at a time (just like <FILE>).

If you want different behavior, you can provide a C<ReadInput> class,
or spoecify a C<readinput> block in your map/reduce job.

Your function should return an array of 2 values

=head2 record

the record data

=head2 eof

have we reached the end-of-file


=head1 BUGS

none. you write this yourself.

=head1 SEE ALSO

    AC::MrGamoo

=head1 AUTHOR

    You!

=cut
