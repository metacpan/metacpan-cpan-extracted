package BorderStyleRole::Source::ASCIIArt;

use strict;
use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'BorderStyleRole::Source::Hash';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-14'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '3.0.3'; # VERSION

# offsets after newlines are removed
#    012345678901234567
#    ┌───────┬───┬───┐'
#+ 18│ ..... │ . │ . │'
#+ 36│ ..... ├───┼───┤'
#+ 54│ ..... │ . │ . │'
#+ 72│ ..... ├───┴───┤'
#+ 90│ ..... │ ..... │'
#+108├───┬───┤ ..... │'
#+126│ . │ . │ ..... │'
#+144└───┴───┴───────┘'

around get_border_char => sub {
    my $orig = shift;

    #my ($self, %ags) = @_;
    my $self = $_[0];

    #use DD; dd {@_[1.. $#_]};

    # initialize %CHARS from $PICTURE
    {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        my $picture = ${"$self->{orig_class}::PICTURE"};
        last unless defined $picture;

        my $chars = \%{"$self->{orig_class}::CHARS"};
        last if keys %$chars; # already initialized

        #say "D1";
        $picture =~ s/\R//g;
        $chars->{h_b}  = substr($picture, 144+ 1, 1); #  1
        $chars->{h_i}  = substr($picture, 108+ 1, 1); #  2
        $chars->{h_t}  = substr($picture,      1, 1); #  3
        $chars->{hd_i} = substr($picture, 108+ 4, 1); #  4
        $chars->{hd_t} = substr($picture,      8, 1); #  5
        $chars->{hu_b} = substr($picture, 144+ 4, 1); #  6
        $chars->{hu_i} = substr($picture,  72+12, 1); #  7
        $chars->{hv_i} = substr($picture,  36+12, 1); #  8
        $chars->{ld_t} = substr($picture,     16, 1); #  9
        $chars->{lu_b} = substr($picture, 144+16, 1); # 10
        $chars->{lv_i} = substr($picture, 108+ 8, 1); # 11
        $chars->{lv_r} = substr($picture,  36+16, 1); # 12
        $chars->{rd_t} = substr($picture,      0, 1); # 13
        $chars->{ru_b} = substr($picture, 144+ 0, 1); # 14
        $chars->{rv_i} = substr($picture,  36+ 8, 1); # 15
        $chars->{rv_l} = substr($picture, 108+ 0, 1); # 16
        $chars->{v_i}  = substr($picture,  18+ 8, 1); # 17
        $chars->{v_l}  = substr($picture,  18+ 0, 1); # 18
        $chars->{v_r}  = substr($picture,  18+16, 1); # 19
        #no strict 'refs'; use DDC; dd \%{"$self->{orig_class}::CHARS"};
    }

    # initialize @MULTI_CHARS from @PICTURES
    {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        my $pictures = \@{"$self->{orig_class}::PICTURES"};
        last unless @$pictures;

        my $multi_chars = \@{"$self->{orig_class}::MULTI_CHARS"};
        last if @$multi_chars; # already initialized

        #say "D2";
        for my $entry (@$pictures) {
            my $chars = {};
            my $picture = $entry->{picture};
            $picture =~ s/\R//g;
            $chars->{h_b}  = substr($picture, 144+ 1, 1); #  1
            $chars->{h_i}  = substr($picture, 108+ 1, 1); #  2
            $chars->{h_t}  = substr($picture,      1, 1); #  3
            $chars->{hd_i} = substr($picture, 108+ 4, 1); #  4
            $chars->{hd_t} = substr($picture,      8, 1); #  5
            $chars->{hu_b} = substr($picture, 144+ 4, 1); #  6
            $chars->{hu_i} = substr($picture,  72+12, 1); #  7
            $chars->{hv_i} = substr($picture,  36+12, 1); #  8
            $chars->{ld_t} = substr($picture,     16, 1); #  9
            $chars->{lu_b} = substr($picture, 144+16, 1); # 10
            $chars->{lv_i} = substr($picture, 108+ 8, 1); # 11
            $chars->{lv_r} = substr($picture,  36+16, 1); # 12
            $chars->{rd_t} = substr($picture,      0, 1); # 13
            $chars->{ru_b} = substr($picture, 144+ 0, 1); # 14
            $chars->{rv_i} = substr($picture,  36+ 8, 1); # 15
            $chars->{rv_l} = substr($picture, 108+ 0, 1); # 16
            $chars->{v_i}  = substr($picture,  18+ 8, 1); # 17
            $chars->{v_l}  = substr($picture,  18+ 0, 1); # 18
            $chars->{v_r}  = substr($picture,  18+16, 1); # 19

            push @$multi_chars, {
                %$entry,
                chars => $chars,
            };
        }
        #no strict 'refs'; use DDC; dd \@{"$self->{orig_class}::MULTI_CHARS"};
    } # init @MULTI_CHARS

    # pass
    $orig->(@_);
};

1;
# ABSTRACT: Get border characters from ASCII art

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyleRole::Source::ASCIIArt - Get border characters from ASCII art

=head1 VERSION

This document describes version 3.0.3 of BorderStyleRole::Source::ASCIIArt (from Perl distribution BorderStyle), released on 2023-07-14.

=head1 SYNOPSIS

 package BorderStyle::YourStyle;
 use strict;
 use warnings;
 use utf8;
 use Role::Tiny::With;
 with 'BorderStyleRole::Source::ASCIIArt';

 our $PICTURE = <<'_';
 ┌───────┬───┬───┐'
 │ ..... │ . │ . │'
 │ ..... ├───┼───┤'
 │ ..... │ . │ . │'
 │ ..... ├───┴───┤'
 │ ..... │ ..... │'
 ├───┬───┤ ..... │'
 │ . │ . │ ..... │'
 └───┴───┴───────┘'
 _

 our %BORDER = (
     v => 3,
     summary => 'Summary of your style',
     utf8 => 1,
 );
 1;

=head1 DESCRIPTION

To define border characters, you declare C<$PICTURE> package variable in your
border style class, using a specific ASCII art as shown in the Synopsis. You
then modify the border characters (the lines, not the spaces and the dots)
according to your actual style. This is a convenient way to define border styles
instead of declaring the characters specifically using a hash. Note that empty
border characters are not supported by this role.

For more complex border styles, you define C<@PICTURES> instead, with each
element being a hash:

 # this style is single bold line for header rows, single line for data rows.
 our @PICTURES = (
     {
         # imagine every line is a header-row separator line (theoretically, the
         # top and bottom lines won't ever be used as separator though)
         for_header_data_separator => 1,
         picture => <<'_',
 ┍━━━━━━━┯━━━┯━━━┑'
 ╿ ..... ╿ , ╿ . ╿'
 ╿ ..... ┡━━━╇━━━┫'
 ╿ ..... ╿ . ╿ . ╿'
 ╿ ..... ┡━━━┻━━━┫'
 ╿ ..... ╿ ..... ╿'
 ┡━━━┯━━━┩ ..... ╿'
 ╿ . ╿ . ╿ ..... ╿'
 ┗━━━┻━━━┻━━━━━━━┛'
 _
     },
     {
         for_header_row => 1,
         picture => <<'_',
 ┏━━━━━━━┳━━━┳━━━┓'
 ┃ ..... ┃ , ┃ . ┃'
 ┃ ..... ┣━━━╋━━━┫'
 ┃ ..... ┃ . ┃ . ┃'
 ┃ ..... ┣━━━┻━━━┫'
 ┃ ..... ┃ ..... ┃'
 ┣━━━┳━━━┫ ..... ┃'
 ┃ . ┃ . ┃ ..... ┃'
 ┗━━━┻━━━┻━━━━━━━┛'
 _
     },
     {
         picture => <<'_',
 ┌───────┬───┬───┐'
 │ ..... │ . │ . │'
 │ ..... ├───┼───┤'
 │ ..... │ . │ . │'
 │ ..... ├───┴───┤'
 │ ..... │ ..... │'
 ├───┬───┤ ..... │'
 │ . │ . │ ..... │'
 └───┴───┴───────┘'
 _
     },
 );

Internally, some characters from the ASCII art will be taken and put into
C<%CHARS> or C<@MULTI_CHARS> and this role's C<get_border_char()> will pass to
L<BorderStyleRole::Source::Hash>'s.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyle>.

=head1 SEE ALSO

L<BorderStyleRole::Source::Hash>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
