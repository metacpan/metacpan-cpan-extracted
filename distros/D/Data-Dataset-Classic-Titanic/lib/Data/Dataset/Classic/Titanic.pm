package Data::Dataset::Classic::Titanic;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Provide the classic Titanic survivor dataset

our $VERSION = '0.0103';

use strict;
use warnings;

use Text::CSV_XS ();
use File::ShareDir qw(dist_dir);



sub as_file {
    my $file = eval { dist_dir('Data-Dataset-Classic-Titanic') . '/titanic.csv' };
    $file = 'share/titanic.csv'
        unless $file && -e $file;
    return $file;
}


sub as_list {
    my $file = as_file();

    my @data;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    my $counter = 0;

    while (my $row = $csv->getline($fh)) {
        $counter++;
        next if $counter == 1; # Skip the header
        push @data, $row;
    }

    close $fh;

    return @data;
}


sub as_hash {
    my $file = as_file();

    my %data;
    my @headers;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    my $counter = 0;

    while (my $row = $csv->getline($fh)) {
        $counter++;

        # If we are on the first row, grab the headers and skip the row
        if ($counter == 1) {
            push @headers, @$row;
            @data{@headers} = undef;
            next;
        }

        # Add each row item to the growing header lists
        for my $i (0 .. @headers - 1) {
            push @{ $data{ $headers[$i] } }, $row->[$i];
        }
    }

    close $fh;

    return %data;
}


sub headers {
    my $file = as_file();

    my @data;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    while (my $row = $csv->getline($fh)) {
        push @data, @$row;
        last;
    }

    close $fh;

    return @data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dataset::Classic::Titanic - Provide the classic Titanic survivor dataset

=head1 VERSION

version 0.0103

=head1 SYNOPSIS

  use Data::Dataset::Classic::Titanic;

  my $filename = Data::Dataset::Classic::Titanic::as_file();

  my @data = Data::Dataset::Classic::Titanic::headers();

  @data = Data::Dataset::Classic::Titanic::as_list();

  my %data = Data::Dataset::Classic::Titanic::as_hash();

=head1 DESCRIPTION

C<Data::Dataset::Classic::Titanic> provides access to the classic
Titanic survivor dataset.

=head1 FUNCTIONS

=head2 as_file

  $filename = Data::Dataset::Classic::Titanic::as_file();

Return the Titanic data filename location.

=head2 as_list

  @data = Data::Dataset::Classic::Titanic::as_list();

Return the Titanic data as an array.

The headers are not included in the returned data.  See the C<headers> function.

=head2 as_hash

  %data = Data::Dataset::Classic::Titanic::as_hash();

Return the Titanic data as a hash.

Keys are equal to the data column headers.  See the C<headers> function.

=head2 headers

  @headers = Data::Dataset::Classic::Titanic::headers();

Return the data headers.

 PassengerId, Survived, Pclass, Name, Sex, Age,
 SibSp, Parch, Ticket, Fare, Cabin, Embarked

These stand for the passenger ID, whether they survived or not, their
class (1st, 2nd, 3rd), their name, gender, age, the number of siblings
and spouses aboard, number of parents and children aboard, their
ticket number, the fare they paid, the cabin they were in, and
finally, the port of embarkation (C = Cherbourg; Q = Queenstown; S =
Southampton).

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/RMS_Titanic>

L<https://github.com/datasciencedojo/datasets/blob/master/titanic.csv>

L<Data::Dataset::Classic::Iris>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
