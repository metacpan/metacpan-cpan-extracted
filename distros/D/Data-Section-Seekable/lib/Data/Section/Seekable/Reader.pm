package Data::Section::Seekable::Reader;

our $DATE = '2016-02-19'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    no strict 'refs';

    my $class = shift;

    my $caller = caller;
    my $self = bless {@_}, $class;

    $self->{handle} //= \*{"$caller\::DATA"};

    {
        my $fh = $self->{handle};

# BEGIN_BLOCK: read_dss_toc

        my $header_line;
        my $header_found;
        while (1) {
            my $header_line = <$fh>;
            defined($header_line)
                or die "Unexpected end of data section while reading header line";
            chomp($header_line);
            if ($header_line eq 'Data::Section::Seekable v1') {
                $header_found++;
                last;
            }
        }
        die "Can't find header 'Data::Section::Seekable v1'"
            unless $header_found;

        my %toc;
        my $i = 0;
        while (1) {
            $i++;
            my $toc_line = <$fh>;
            defined($toc_line)
                or die "Unexpected end of data section while reading TOC line #$i";
            chomp($toc_line);
            $toc_line =~ /\S/ or last;
            $toc_line =~ /^([^,]+),(\d+),(\d+)(?:,(.*))?$/
                or die "Invalid TOC line #$i in data section: $toc_line";
            $toc{$1} = [$2, $3, $4];
        }
        my $pos = tell $fh;
        $toc{$_}[0] += $pos for keys %toc;

# END_BLOCK: read_dss_toc

        $self->{_toc} = \%toc;
    }

    $self;
}

sub parts {
    my $self = shift;
    sort keys %{$self->{_toc}};
}

sub read_part {
    my ($self, $name) = @_;

    defined($self->{_toc}{$name})
        or die "Unknown part '$name'";

    seek $self->{handle}, $self->{_toc}{$name}[0], 0;
    read $self->{handle}, my($content), $self->{_toc}{$name}[1];

    $content;
}

sub read_extra {
    my ($self, $name) = @_;

    defined($self->{_toc}{$name})
        or die "Unknown part '$name'";

    $self->{_toc}{$name}[2];
}

1;
# ABSTRACT: Read parts from data section

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Seekable::Reader - Read parts from data section

=head1 VERSION

This document describes version 0.09 of Data::Section::Seekable::Reader (from Perl distribution Data-Section-Seekable), released on 2016-02-19.

=head1 SYNOPSIS

In your script:

 use Data::Section::Seekable::Reader;

 my $reader = Data::Section::Seekable::Reader->new;

 my $p2 = $reader->read_part('part2'); # -> "This is part\ntwo\n"
 my $p1 = $reader->read_part('part1'); # -> "This is part1\n"
 my $p3 = $reader->read_part('part3'); # dies, unknown part

 my $e1 = $reader->read_extra('part1'); # -> undef
 my $e2 = $reader->read_extra('part2'); # -> "important"
 my $e3 = $reader->read_extra('part3'); # dies, unknown part

 __DATA__
 Data::Section::Seekable v1
 part1,0,14
 part2,14,17,important

 This is part1
 This is part
 two

=head1 DESCRIPTION

This class lets you read parts from __DATA__ section. Data section should
contain data in the format described by L<Data::Section::Seekable>.

=head1 METHODS

=head2 new(%attrs) => obj

Constructor. Attributes:

=over

=item * handle => filehandle (default: C<DATA>)

To access another package's data section, you can do:

 my $reader = Data::Section::Seekable::Reader->new(handle => \*Another::Package::DATA);

=back

The constructor will also read the header and TOC in the data section. Will die
on failure.

=head2 $reader->parts($name) => list

Return list of all known parts in the data section, sorted lexicographically.

=head2 $reader->read_part($name) => str

Read the content of a part named C<$name>. Will die if part is unknown.

=head2 $reader->read_extra($name) => str

Read the extra information field (the fourth field of TOC line) of a part named
C<$name>. Will die if part is unknown.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Section-Seekable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Section-Seekable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Section-Seekable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Section::Seekable> for the description of the data format.

L<Data::Section::Seekable::Writer> to generate the data section.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
