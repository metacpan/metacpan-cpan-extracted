package CSV::HistoryPlayer;

use List::MoreUtils qw(uniq);
use Moo;
use Path::Tiny;
use Text::CSV;

use strict;
use warnings;
use namespace::clean;

our $VERSION = '0.03';

=head1 NAME

=encoding utf8

CSV::HistoryPlayer - Plays scattered CSV files with historic data

=head1 STATUS

=begin HTML

<p>
    <a href="https://travis-ci.org/binary-com/perl-CSV-HistoryPlayer"><img src="https://travis-ci.org/binary-com/perl-CSV-HistoryPlayer.svg" /></a>
</p>

=end HTML


=head1 SYNOPSYS

  use CSV::HistoryPlayer;

  my $player = CSV::HistoryPlayer->(root_dir => 'path/to/directory');
  while (my $data = $player->poll) {
    my ($file, $row) = @$data;
    print "event occured at ", $row->[0], "\n";
  }

=head1 DESCRIPTION

Let's assume you have many of CSV-files, each one has some events
written in it (in the B<first> column in form of unix timestamp) and
filenames also have encoded date of the events within, i.e.

 ├── income
 │   ├── 2015-02-10.csv
 │   └── 2015-02-12.csv
 └── outcome
     ├── 2015-02-11.csv
     └── 2015-02-12.csv

Let's assume, that the files have content like:

 income/2015-02-10.csv: 1455106611, 10, "got pocket money from Mom"
 income/2015-02-12.csv: 1455301001, 15, "got pocket money from Dad"
 outcome/2015-02-11.csv: 1455203801, 10, "bought Immortal CD (black metal)"
 outcome/2015-02-12.csv: 1455307400, 10, "bought Obsidian Gate CD (black metal)"

Now, you would to replay all transactions. That's easy

  use CSV::HistoryPlayer;

  my $player = CSV::HistoryPlayer->(root_dir => 'path/to/directory');
  while (my $data = $player->poll) {
    my ($file, $row) = @$data;
    my ($when, $how_much, $description) = @$row;
    my $sign = $file =~ /income/ ? '+' : '-';
    print $sign, " ", $how_much, '$: ', $description, "\n";
  }

  # +10$: got pocket money from Mom
  # -10$: bought Immortal CD (black metal)
  # +15$: got pocket money from Dad
  # -10$: bought Obsidian Gate CD (black metal)

I.e. the L<CSV::HistoryPlayer> virtually unites scattered CSV files,
and allows to read evens from them in historically correct order.


=head1 ATTRIBUTES

=over 2

=item * C<root_dir>

The root directory, where the csv files should be searched from.
This attribute is B<mandatory>.

=item * C<dir_filter>

The closure, which allows to filter out unneeded directories,
in the file scan phase to do not include csv-files within

  my $player = CSV::HistoryPlayer->(
    ...,
    # if returns true, than dir will be scanned for csv-files
    dir_filter => sub { $_[0] =~ /income/ },
  );

By default, all found directories are allowed to be scanned
for CSV-files.

=item * C<files_mapper>

The closure, which allows to do custom sort and filtering of found
CSV-files in historical order.

By default CSV-files are lexically sorted and not filtered.

For example, if there are files C<3-Jan-16.csv>, C<4-Jan-16.csv>,
..., they can be sorted with L<Date::Utility>

  files_maper => sub {
    my $orig_files = shift;
    my @files =
      map  { $_->{file} }
      sort { $a->{epoch} <=> $b->{epoch} }
      map  {
        my $date = /(.*\/)(.+)/ ? $2 : die("wrong filename in $_");
        {
          file  => $_,
          epoch => Date::Utility->new($date)->epoch,
        }
      } @$orig_files;
    return \@files;
  }


=item * C<files>

Returns historically sorted list of found CSV-files; each item in
the list is L<Path::Tiny> instance.

=back

=head1 METHODS

=over 2

=item * C<peek>

Returns the reference to the current pointer in the i<virtual> CSV-file
and the actual file.

Initially it points to the earliest row of the historically first file.
If there are many concurrent files, than the earliest row of them is returned.

If end of i<virtual> CSV-file is reached, then C<undef> is returned

  my $data = $player->peak;
  if ($data) {
    my ($file, $row) = @$data;
  }

=item * C<poll>

The same as C<peak> method, but after return of the current row in
the  i<virtual> CSV-file, it moves the pointer to the next row.
Designed to serve as iterator,

  while (my $data = $player->poll) {
    my ($file, $row) = @$data;
  }

=back

=head1 ASSUMPTIONS

=over 2

=item * Same filenames for the same timeframe

CSV-files aggregate events on some time-frame (i.e. one day, one hour,
one week etc.). The L<CSV::HistoryPlayer> does not sort content of
files due to performance reasons. Than means, if you have files, organized
like:

 event-a/date_1.csv
 event-b/date_2.csv

and C<date_1> and C<date_2> intersects, then they should have exactly
the same name, e.g.:

 event-a/3-Jan-16.csv
 event-b/3-Jan-16.csv

to be replayed correctly.


=item * unix timestamp is the first column in CSV-files

=item * CSV-files are opened with the defaults of L<Text::CSV>

=back

=head1 SEE ALSO

L<Text::CSV>, L<Higher-Order Perl|http://hop.perl.plover.com>

=head1 SOURCE CODE

L<GitHub|https://github.com/binary-com/perl-CSV-HistoryPlayer>


=cut

has 'root_dir' => (
    is       => 'ro',
    required => 1
);

has 'dir_filter' => (
    is      => 'ro',
    default => sub {
        return sub { 1 }
    });

has 'files_mapper' => (
    is      => 'ro',
    default => sub {
        return sub {
            my $files = shift;
            return [sort { $a cmp $b } @$files];
            }
    });

has 'files' => (is => 'lazy');

has _current_data => (is => 'rw');

has '_reader' => (is => 'lazy');

sub _build_files {
    my $self = shift;

    my @files;
    my @dirs_queue = (path($self->root_dir));
    my $dir_filter = $self->dir_filter;
    while (@dirs_queue) {
        my $dir = shift(@dirs_queue);
        if ($dir_filter->($dir)) {
            for my $c ($dir->children) {
                push @dirs_queue, $c if (-d $c);
                push @files, $c
                    if ($c =~ /\.csv$/i && -s -r -f _);
            }
        }
    }
    my $sorted_files = $self->files_mapper->(\@files);
    return $sorted_files;
}

sub _build__reader {
    my $self        = shift;
    my $files       = $self->files;
    my $clusters    = [uniq map { $_->basename } @$files];
    my $cluster_idx = -1;
    my @cluster_fds;
    my @cluster_csvs;
    my @cluser_files;

    my $open_cluster = sub {
        my $cluster_id = $clusters->[$cluster_idx];
        @cluser_files = grep { $_->basename eq $cluster_id } @$files;
        @cluster_fds  = ();
        @cluster_csvs = ();
        for my $cf (@cluser_files) {
            my $csv = Text::CSV->new({binary => 1})
                or die "Cannot use CSV: " . Text::CSV->error_diag();
            my $fh = $cf->filehandle("<");
            push @cluster_fds,  $fh;
            push @cluster_csvs, $csv;
        }
    };

    my @lines;
    my $read_line_from_cluster = sub {
        REDO: {

            # make sure that we read last line from all cluster files
            for my $idx (0 .. @cluster_fds - 1) {
                if (!defined $lines[$idx] && !$cluster_csvs[$idx]->eof) {
                    $lines[$idx] =
                        $cluster_csvs[$idx]->getline($cluster_fds[$idx]);
                }
            }

            # we assume that timestamp is the 1st column
            my @ordered_idx =
                sort { $lines[$a]->[0] <=> $lines[$b]->[0] }
                grep { defined $lines[$_] } (0 .. @lines - 1);
            if (@ordered_idx) {
                my $idx  = shift @ordered_idx;
                my $line = $lines[$idx];
                my $file = $cluser_files[$idx];
                $self->_current_data([$file, $line]);
                $lines[$idx] = undef;
            } else {
                if ($cluster_idx < @$clusters - 1) {
                    $open_cluster->(++$cluster_idx);
                    goto REDO;
                }
            }
        }
    };

    return $read_line_from_cluster;
}

sub peek {
    my $self = shift;
    return $self->_current_data if $self->_current_data;
    $self->_reader->();
    return $self->_current_data;

}

sub poll {
    my $self   = shift;
    my $result = $self->_current_data;
    if (!$result) {
        $self->_reader->();
        $result = $self->_current_data;
    }
    $self->_current_data(undef);
    return $result;
}

=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/binary-com/perl-CSV-HistoryPlayer/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 binary.com

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

=cut

1;
