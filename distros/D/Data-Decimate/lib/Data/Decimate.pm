package Data::Decimate;

use strict;
use warnings;

use 5.010;

use Exporter qw/import/;

our @EXPORT_OK = qw(decimate);

=head1 NAME

Data::Decimate - A module that allows to decimate a data feed.

=head1 SYNOPSIS

  use Data::Decimate qw(decimate);

  my @data = (
        {epoch  => 1479203101,
        #...
        },
        {epoch  => 1479203102,
        #...
        },
        {epoch  => 1479203103,
        #...
        },
        #...
        {epoch  => 1479203114,
        #...
        },
        {epoch  => 1479203117,
        #...
        },
        {epoch  => 1479203118,
        #...
        },
        #...
  );

  my $output = Data::Decimate::decimate(15, \@data);

  #epoch=1479203114 , decimate_epoch=1479203115
  print $output->[0]->{epoch};
  print $output->[0]->{decimate_epoch};

=head1 DESCRIPTION

A module that allows you to resample a data feed

=cut

our $VERSION = '0.03';

=head1 SUBROUTINES/METHODS
=cut

=head2 decimate

Decimate a given data based on sampling frequency.

=cut

sub decimate {
    my ($interval, $data) = @_;

    if (not defined $interval or not defined $data or ref($data) ne "ARRAY") {
        die "interval and data are required parameters.";
    }

    my @res;
    my $el = $data->[0];
    my $decimate_epoch;
    $decimate_epoch = do {
        use integer;
        (($el->{epoch} + $interval - 1) / $interval) * $interval;
    } if $data->[0];
    $el->{count}          = 1;
    $el->{decimate_epoch} = $decimate_epoch;

    push @res, $el if $data->[0];

    for (my $i = 1; $i < @$data; $i++) {
        $el             = $data->[$i];
        $decimate_epoch = do {
            use integer;
            (($el->{epoch} + $interval - 1) / $interval) * $interval;
        };

        # same decimate_epoch
        if ($decimate_epoch == $res[-1]->{decimate_epoch}) {
            $res[-1]->{count}++;
            $el->{decimate_epoch} = $decimate_epoch;
            $el->{count}          = $res[-1]->{count};
            $res[-1]              = $el;
            next;
        }

        # fill in the gaps if any
        while ($res[-1]->{decimate_epoch} + $interval < $decimate_epoch) {
            my %clone = %{$res[-1]};
            $clone{count} = 0;
            $clone{decimate_epoch} += $interval;
            push @res, \%clone;
        }

        # and finally add the current element
        $el->{count}          = 1;
        $el->{decimate_epoch} = $decimate_epoch;
        push @res, $el;
    }

    return \@res;
}

=head1 AUTHOR

Binary.com, C<< <support at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-resample at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Decimate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Decimate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Decimate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Decimate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Decimate>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Decimate/>

=back


=head1 ACKNOWLEDGEMENTS


=cut

1;
