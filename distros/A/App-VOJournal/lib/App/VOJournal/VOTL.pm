package App::VOJournal::VOTL;
#
# vim: set sw=4 ts=4 tw=76 et ai si:
#
# Author Mathias Weidner <mamawe@cpan.org>
# Version 0.1
# Copyright (C) 2015 user <user@work>
# Modified On 2015-05-15 22:18
# Created  2015-05-15 22:18
#
use strict;
use warnings;

=head1 NAME

App::VOJournal::VOTL - deal with vimoutliner files

=head1 VERSION

Version v0.4.8

=cut

use version; our $VERSION = qv('v0.4.8');

=head1 SYNOPSIS

    use App::VOJournal::VOTL;

    my $votl = App::VOJournal::VOTL->new();

    $votl->fetch_line($pos);
    $votl->insert_line($pos,$line);

    $votl->read_file($infilename);

    $votl->write_file($outfilename);
    $votl->write_file($outfilename, \&filter);

    $votl->write_file_no_checked_boxes($outfilename);
    $votl->write_file_unchecked_boxes($outfilename);

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new object.

    my $votl = App::VOJournal::VOTL->new();

=cut

sub new
{
    my $class = shift;
    my $arg = shift;
    my $self = {};

    $self->{objects} = [];

    bless($self, $class);
    return $self;
}

=head2 fetch_line

  $votl->fetch_line( $pos );

Fetches the value of the object at position C<$pos>. That means the line as it
would appear in the Vimoutliner file.

The available positions start at 0 and at 1 before the number of objects.

If C<$pos> is outside the available positions the function returns nothing.

At the moment you can only retrieve the objcects in the top level.

=cut

sub fetch_line {
    my ($self, $pos) = @_;
    my $noobjs  = $#{$self->{objects}};
    my $position = (0 > $pos)       ? $noobjs
                 : ($pos > $noobjs) ? -1
                 :                    $pos;
    if (-1 == $position) {
        return;
    }
    return $self->{objects}->[$position]->{value};
} # fetch_line()

=head2 delete_line

  $votl->delete_line($pos);

Deletes an object from the Vimoutliner file. That means the line itself and
all immediately following lines that are more indented.

At the moment you can only delete objects in the top level.

=cut

sub delete_line {
    my ($self, $pos) = @_;
    my $objects = [];
    my $noobjs  = $#{$self->{objects}};
    my $position = (0 > $pos)       ? $noobjs
                 : ($pos > $noobjs) ? -1
                 :                    $pos;
    if (-1 == $position) {
        return;
    }
    while ($position) {
        push @$objects, shift @{$self->{objects}};
        $position--;
    }
    shift @{$self->{objects}};
    push @$objects, @{$self->{objects}};
    $self->{objects} = $objects;
} # delete_line()

=head2 insert_line

Inserts a line into a vimoutliner data structure.

    $votl->insert_line( $pos, $line );

=over 4

=item C<$pos>

determines the position where the object shall be inserted.

This could be a number telling the position:

=over 4

=item B<-1>

means at the last position, i.e. after the last already existing element.

=item B<0>

means at position 0, i.e. before the first already existing element.

=item B<n>

means at that position. 
All already existing objects at that and the following positions will be
shifted to the next position.

If the argument C<$pos> exceeds the number of already existing objects, the
object is inserted immediately following the last already existing object.

=back

At the moment all lines are inserted at the top level.

=item C<$line>

This may be a string which is inserted as is. 

=back

=cut

sub insert_line {
    my ($self, $pos, $line) = @_;
    my $objects = [];
    my $noobjs  = 1 + $#{$self->{objects}};
    my $position = (0 > $pos)       ? $noobjs
                 : ($pos > $noobjs) ? $noobjs 
                 :                    $pos;
    while ($position) {
        push @$objects, shift @{$self->{objects}};
        $position--;
    }
    push @$objects, {value => $line}, @{$self->{objects}};
    $self->{objects} = $objects;
} # insert_line()

=head2 read_file

Reads a vimoutliner file.

    $votl->read_file( $filename );

    sub filter { ... }
    
    $votl->read_file( $filename, \&filter );

C<$filename> is the name of the file read.

It is possible to give a reference to a filter function that decides, which
objects / lines to read. This filter function is called back with the content
of the current line (after the indentation) and the depth of indentation as
arguments. If you need to manage some state you can use closures like this:

    my $in_checked_box = 0;
    my $cbl            = 0;

    my $filter = sub {
        my ($object,$indent) = @_;
        if ($in_checked_box && $indent > $cbl) {
            return 0;
        }
        elsif (_checked_box($object)) {
            $in_checked_box = 1;
            $cbl            = $indent;
            return 0;
        }
        else {
            $in_checked_box = 0;
            return 1;
        }
    };

    $votl->read_file( $filename, $filter );

=cut

sub read_file {
    my ($self,$filename,$filter) = @_;

    if (open my $input, '<', $filename) {
        $self->{objects} = [];
        while (<$input>) {
            if (/^(\t*)(.*)$/) {
                $self->_add_something($1, {
                    children => [],
                    value => $2
                }, $filter);
            }
            else {
                die "unknown line: $_";
            }
        }
        close $input;
        return 1 + $#{$self->{objects}};
    }
    return;
} # read_file()

=head2 read_file_no_checked_boxes

This is a convenience function that reads all lines except checked boxes
(lines starting with C<[X]>).

    $votl->read_file_no_checked_boxes( $filename );

=cut

sub read_file_no_checked_boxes {
    my ($self,$filename) = @_;
    my $in_checked_box = 0;
    my $cbl            = 0;
    my $filter = sub {
        my ($object,$indent) = @_;
        if ($in_checked_box && $indent > $cbl) {
            return 0;
        }
        elsif (_checked_box($object)) {
            $in_checked_box = 1;
            $cbl            = $indent;
            return 0;
        }
        else {
            $in_checked_box = 0;
            return 1;
        }
    };
    $self->read_file( $filename, $filter );
} # read_file_no_checked_boxes()

=head2 read_file_unchecked_boxes

This is a convenience function that reads all lines with unchecked boxes
(lines starting with C<[_]>).

    $votl->read_file_unchecked_boxes( $filename );

=cut

sub read_file_unchecked_boxes {
    my ($self,$filename) = @_;
    my $unchecked_box = 0;
    my $cbl            = 0;
    my $filter = sub {
        my ($object,$indent) = @_;
        if ($unchecked_box && $indent > $cbl) {
            return 1;
        }
        elsif (_unchecked_box($object)) {
            $unchecked_box = 1;
            $cbl           = $indent;
            return 1;
        }
        else {
            $unchecked_box = 0;
            return 0;
        }
    };
    $self->read_file( $filename, $filter );
} # read_file_unchecked_boxes()

=head2 write_file

Writes a vimoutliner file.

    $votl->write_file( $filename );

    sub filter { ... }

    $votl->write_file( $filename, \&filter);

It is possible to give a reference to a filter function that decides, which
objects to write. This filter function is called back with the content
of the current line and the depth of indentation as arguments.
If you need to manage some state you can use closures as shown with the
C<read_file()> function.

=cut

sub write_file {
    my ($self,$filename,$filter) = @_;

    if (open my $output, '>', $filename) {
        foreach my $object (@{$self->{objects}}) {
            _write_object($object,0,$output,$filter);
        }
        close $output;
    }
} # write_file()

=head2 write_file_no_checked_boxes

Writes a vimoutliner file that contains no checked boxes.

    $votl->write_file_no_checked_boxes( $filename );

This is a convenience function using C<write_file()> and a predifined
filter.

=cut

sub write_file_no_checked_boxes {
    my ($self,$filename) = @_;
    my $filter = sub {
        my ($object) = @_;
        return ! _checked_box($object);
    };
    $self->write_file( $filename, $filter );
} # write_file_no_checked_boxes()

=head2 write_file_unchecked_boxes

Writes a vimoutliner file that only consists of unchecked boxes at level
zero and their descendants.

    $votl->write_file_unchecked_boxes( $filename );

This is a convenience function using C<write_file()> and a predifined
filter.

=cut

sub write_file_unchecked_boxes {
    my ($self,$filename) = @_;
    my $filter = sub {
        my ($object,$indent) = @_;
        return $indent ? 1 : _unchecked_box($object);
    };
    $self->write_file( $filename, $filter );
} # write_file_unchecked_boxes()

sub _add_something {
    my ($self,$tabs,$newobject,$filter) = @_;
    my $indent = length $tabs;
    if (defined $filter) {
        return unless ($filter->($newobject,$indent));
    }
    my $objects = $self->_descend_objects($indent);
    push @$objects, $newobject;
} # _add_something()

sub _checked_box {
    my ($object) = @_;

    return ($object->{value} =~ /^\[X\]/);
} # _checked_box()

sub _descend_objects {
    my ($self,$indent) = @_;
    my $objects = $self->{objects};

    while (0 < $indent) {
        if (0 > $#$objects) {
            my $newobject = {
                children => [],
            };
            push @$objects, $newobject;
            $objects = $newobject->{children};
        }
        else {
            $objects = $objects->[$#$objects]->{children};
        }
        $indent--;
    }
    return $objects;
} # _descend_objects()

sub _unchecked_box {
    my ($object) = @_;

    return ($object->{value} =~ /^\[_\]/);
} # _unchecked_box()

sub _write_object {
    my ($object,$indent,$outfh, $filter) = @_;

    if (defined $filter) {
        return unless ($filter->($object,$indent));
    }
    print $outfh "\t" x $indent, $object->{value}, "\n";

    foreach my $co (@{$object->{children}}) {
        _write_object($co,$indent + 1,$outfh,$filter);
    }
} # _write_object()

1;
# __END__

=head1 FORMAT OF VIMOUTLINER FILES

Vimoutliner files are text files with a hierarchical structure.

The hierarchical structure is characterized by the number of tabulator
signs (0x09) at the beginning of the line.

A line can be a simple-heading or an object, depending on the first
nontabulator sign of the line.

A simple heading starts with any non-whitespace character except
C<< : ; | < > >>.
A checkbox is a special form of a heading that starts with either
C<< [_] >> or C<< [X] >> after the leading tabulator signs.
A checkbox may contain a percent sign (C<%>) as a placeholder for
the percentage completed.
This percent sign must follow the initial C<< [_] >> after a separating
whitespace.

The following text objects are defined for vimoutliner files:

=over 4

=item C<:> - body text

The text following the C<:> will be wrapped automatically.

=item C<;> - preformatted body text

This text won't be wrapped automatically.

=item C<|> - table

The table headings can be marked with C<||>.

=item C<< > >> - user defined text.

This text will also be wrapped automatically.

=item C<< < >> - user defined preformatted text.

This text won't be wrapped automatically.

=back

=head1 AUTHOR

Mathias Weidner, C<< <mamawe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-vojournal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-VOJournal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::VOJournal::VOTL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-VOJournal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-VOJournal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-VOJournal>

=item * Search CPAN

L<http://search.cpan.org/dist/App-VOJournal/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mathias Weidner.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

