package BorderStyle::Test::Random;

use strict;
use warnings;

use Role::Tiny::With;
with 'BorderStyleRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'BorderStyles-Test'; # DIST
our $VERSION = '0.005'; # VERSION

our %BORDER = (
    v => 3,
    summary => 'A border style that uses random characters',
    args => {
        cache => {
            schema => 'bool*',
            default => 1,
        },
    },
);

my @chars = map {chr($_)} 32 .. 127;

sub get_border_char {
    my ($self, %args) = @_;
    my $char = $args{char};
    my $repeat = $args{repeat} // 1;

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

    $c x $repeat;
}

1;
# ABSTRACT: A border style that uses random characters

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Test::Random - A border style that uses random characters

=head1 VERSION

This document describes version 0.005 of BorderStyle::Test::Random (from Perl distribution BorderStyles-Test), released on 2022-02-14.

=for Pod::Coverage ^(.+)$

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

 ..........................................
 . ColumName1 . ColumnNameB . ColumnNameC .
 ..........................................
 . row1A      . row1B       . row1C       .
 . row2A      . row2B       . row2C       .
 . row3A      . row3B       . row3C       .
 ..........................................

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

 llllllllllllllllllllllllllllllllllllllllll
 l ColumName1 l ColumnNameB l ColumnNameC l
 llllllllllllllllllllllllllllllllllllllllll
 l row1A      l row1B       l row1C       l
 llllllllllllllllllllllllllllllllllllllllll
 l row2A      l row2B       l row2C       l
 llllllllllllllllllllllllllllllllllllllllll
 l row3A      l row3B       l row3C       l
 llllllllllllllllllllllllllllllllllllllllll
 

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

 PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
 P ColumName1 P ColumnNameB P ColumnNameC P
 PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
 P row1A      P row1B       P row1C       P
 PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
 P row2A      P row2B       P row2C       P
 PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
 P row3A      P row3B       P row3C       P
 PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyles-Test>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyles-Test>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyles-Test>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
