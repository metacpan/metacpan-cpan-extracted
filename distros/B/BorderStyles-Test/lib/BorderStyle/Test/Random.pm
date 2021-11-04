package BorderStyle::Test::Random;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-12'; # DATE
our $DIST = 'BorderStyles-Test'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use parent 'BorderStyleBase';

our %BORDER = (
    v => 2,
    summary => 'A border style that uses random characters',
    dynamic => 1,
    args => {
        cache => {
            schema => 'bool*',
            default => 1,
        },
    },
);

my @chars = map {chr($_)} 32 .. 127;

sub get_border_char {
    my ($self, $y, $x, $n, $args) = @_;
    $n = 1 unless defined $n;

    my $c;
    if ($self->{args}{cache}) {
        if (defined $self->{_cache}) {
            $c = $self->{_cache};
        } else {
            $self->{_cache} = $c = $chars[@chars * rand()];
        }
    } else {
        $c = $chars[@chars * rand()];
    }

    $c x $n;
}

1;
# ABSTRACT: A border style that uses random characters

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Test::Random - A border style that uses random characters

=head1 VERSION

This document describes version 0.003 of BorderStyle::Test::Random (from Perl distribution BorderStyles-Test), released on 2021-05-12.

=head1 SYNOPSIS

To use with L<Text::ANSITable>:

 use Text::ANSITable;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 my $t = Text::ANSITable->new;
 $t->border_style("Test::Random");
 $t->columns($rows->[0]);
 $t->add_row($rows->[$_]) for 1 .. $#{ $rows };
 print $t->draw;


Sample output:

 cccccccccccccccccccccccccccccccccccccccccc
 c ColumName1 c ColumnNameB c ColumnNameC c
 cccccccccccccccccccccccccccccccccccccccccc
 c row1A      c row1B       c row1C       c
 c row2A      c row2B       c row2C       c
 c row3A      c row3B       c row3C       c
 cccccccccccccccccccccccccccccccccccccccccc

To use with L<Text::Table::More>:

 use Text::Table::More qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"Test::Random");


Sample output:

 wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
 w ColumName1 w ColumnNameB w ColumnNameC w
 wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
 w row1A      w row1B       w row1C       w
 wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
 w row2A      w row2B       w row2C       w
 wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
 w row3A      w row3B       w row3C       w
 wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
 

To use with L<Text::Table::TinyBorderStyle>:

 use Text::Table::TinyBorderStyle qw/generate_table/;
 my $rows =
   [
     ["ColumName1", "ColumnNameB", "ColumnNameC"],
     ["row1A", "row1B", "row1C"],
     ["row2A", "row2B", "row2C"],
     ["row3A", "row3B", "row3C"],
   ];
 generate_table(rows=>$rows, header_row=>1, separate_rows=>1, border_style=>"BorderStyle::Test::Random");


Sample output:

 ))))))))))))))))))))))))))))))))))))))))))
 ) ColumName1 ) ColumnNameB ) ColumnNameC )
 ))))))))))))))))))))))))))))))))))))))))))
 ) row1A      ) row1B       ) row1C       )
 ))))))))))))))))))))))))))))))))))))))))))
 ) row2A      ) row2B       ) row2C       )
 ))))))))))))))))))))))))))))))))))))))))))
 ) row3A      ) row3B       ) row3C       )
 ))))))))))))))))))))))))))))))))))))))))))

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyles-Test>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyles-Test>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyles-Test>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
