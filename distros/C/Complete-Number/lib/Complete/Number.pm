package Complete::Number;

our $DATE = '2015-11-29'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;
#use experimental 'smartmatch';
#use Log::Any::IfLOG '$log';

use Complete::Common qw(:all);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_int
                       complete_float
               );
our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Complete numbers',
};

$SPEC{complete_int} = {
    v => 1.1,
    summary => 'Complete integer number',
    args => {
        %arg_word,
        max  => { schema=>['int'] },
        min  => { schema=>['int'] },
        xmax => { schema=>['int'] },
        xmin => { schema=>['int'] },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_int {
    require Complete::Util;

    my %args = @_;
    my $word = $args{word} // "";

    my @words;

    my $limit = 100;
    if(defined($args{min}) && defined($args{max}) &&
           $args{max}-$args{min} <= $limit) {
        push @words, $args{min} .. $args{max};
    } elsif (defined($args{min}) && defined($args{xmax}) &&
                 $args{xmax}-$args{min} <= $limit) {
        push @words, $args{min} .. $args{xmax}-1;
    } elsif (defined($args{xmin}) && defined($args{max}) &&
                 $args{max}-$args{xmin} <= $limit) {
        push @words, $args{xmin}+1 .. $args{max};
    } elsif (defined($args{xmin}) && defined($args{xmax}) &&
                 $args{xmax}-$args{xmin} <= $limit) {
        push @words, $args{xmin}+1 .. $args{xmax}-1;
    } elsif (length($word) && $word !~ /\A-?\d*\z/) {
        # warn: not an int
    } else {
        # do a digit by digit completion
        my @signs = ("");
        push @signs, "-" if $word =~ /\A-|\A\z/;
        for my $sign (@signs) {
            for ("", 0..9) {
                my $i = $sign . $word . $_;
                next unless length $i;
                next unless $i =~ /\A-?\d+\z/;
                next if $i eq '-0';
                next if $i =~ /\A-?0\d/;
                next if defined($args{min} ) && $i <  $args{min};
                next if defined($args{xmin}) && $i <= $args{xmin};
                next if defined($args{max} ) && $i >  $args{max};
                next if defined($args{xmin}) && $i >= $args{xmax};
                push @words, $i;
            }
        }
    }

    Complete::Util::complete_array_elem(array=>\@words, word=>$word);
}

$SPEC{complete_float} = {
    v => 1.1,
    summary => 'Complete floating number',
    args => {
        %arg_word,
        max  => { schema=>['float'] },
        min  => { schema=>['float'] },
        xmax => { schema=>['float'] },
        xmin => { schema=>['float'] },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_float {
    require Complete::Util;

    my %args = @_;
    my $word = $args{word} // "";

    my @words;

    my $limit = 100;

    if (length($word) && $word !~ /\A-?\d*(\.\d*)?\z/) {
        # warn: not a float
    } else {
        my @signs = ("");
        push @signs, "-" if $word =~ /\A-|\A\z/;
        for my $sign (@signs) {
            for ("", 0..9,
                 ".0",".1",".2",".3",".4",".5",".6",".7",".8",".9") {
                my $f = $sign . $word . $_;
                next unless length $f;
                next unless $f =~ /\A-?\d+(\.\d+)?\z/;
                next if $f eq '-0';
                next if $f =~ /\A-?0\d\z/;
                next if defined($args{min} ) && $f <  $args{min};
                next if defined($args{xmin}) && $f <= $args{xmin};
                next if defined($args{max} ) && $f >  $args{max};
                next if defined($args{xmin}) && $f >= $args{xmax};
                push @words, $f;
            }
        }
    }

    Complete::Util::complete_array_elem(array=>\@words, word=>$word);
}


1;
# ABSTRACT: Complete numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Number - Complete numbers

=head1 VERSION

This document describes version 0.04 of Complete::Number (from Perl distribution Complete-Number), released on 2015-11-29.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_float(%args) -> array

Complete floating number.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<max> => I<float>

=item * B<min> => I<float>

=item * B<word>* => I<str> (default: "")

Word to complete.

=item * B<xmax> => I<float>

=item * B<xmin> => I<float>

=back

Return value:  (array)


=head2 complete_int(%args) -> array

Complete integer number.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<max> => I<int>

=item * B<min> => I<int>

=item * B<word>* => I<str> (default: "")

Word to complete.

=item * B<xmax> => I<int>

=item * B<xmin> => I<int>

=back

Return value:  (array)

=head1 SEE ALSO

L<Complete>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Number>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Number>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Number>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
