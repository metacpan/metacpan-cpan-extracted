package Acme::Gosub;

use strict;
use warnings;
use vars qw($VERSION);
use Carp;

$VERSION = '0.1.6';

# LOAD FILTERING MODULE...
use Filter::Util::Call;

# CATCH ATTEMPTS TO CALL case OUTSIDE THE SCOPE OF ANY switch

my $next_label_idx = 0;
use vars qw(%ret_labels);

$::_S_W_I_T_C_H = sub { croak "case/when statement not in switch/given block" };

my $offset;
my $fallthrough;

sub import
{
    $fallthrough = grep /\bfallthrough\b/, @_;
    $offset = (caller)[2]+1;
    filter_add({}) unless @_>1 && $_[1] eq 'noimport';
    my $pkg = caller;
    1;
}

sub unimport
{
    filter_del()
}

sub filter
{
    my($self) = @_ ;
    local $Acme::Gosub::file = (caller)[1];

    my $status = 1;
    $status = filter_read(1_000_000);
    return $status if $status<0;
        $_ = filter_blocks($_,$offset);
    $_ = "# line $offset\n" . $_ if $offset; undef $offset;
    return $status;
}

use Text::Balanced ':ALL';

sub line
{
    my ($pretext,$offset) = @_;
    ($pretext=~tr/\n/\n/)+($offset||0);
}

my $EOP = qr/\n\n|\Z/;
my $CUT = qr/\n=cut.*$EOP/;
my $pod_or_DATA = qr/ ^=(?:head[1-4]|item) .*? $CUT
                    | ^=pod .*? $CUT
                    | ^=for .*? $EOP
                    | ^=begin \s* (\S+) .*? \n=end \s* \1 .*? $EOP
                    | ^__(DATA|END)__\n.*
                    /smx;

my $casecounter = 1;
sub filter_blocks
{
    my ($source, $line) = @_;
    return $source unless $source =~ /gosub|greturn/;
    pos $source = 0;
    my $text = "";
    component: while (pos $source < length $source)
    {
        if ($source =~ m/(\G\s*use\s+Acme::Gosub\b)/gc)
        {
            $text .= q{use Acme::Gosub 'noimport'};
            next component;
        }
        my @pos = Text::Balanced::_match_quotelike(\$source,qr/\s*/,1,0);
        if (defined $pos[0])
        {
            my $pre = substr($source,$pos[0],$pos[1]); # matched prefix
            $text .= $pre . substr($source,$pos[2],$pos[18]-$pos[2]);
            next component;
        }
        if ($source =~ m/\G\s*($pod_or_DATA)/gc) {
            next component;
        }
        @pos = Text::Balanced::_match_variable(\$source,qr/\s*/);
        if (defined $pos[0])
        {
            $text .= " " if $pos[0] < $pos[2];
            $text .= substr($source,$pos[0],$pos[4]-$pos[0]);
            next component;
        }

        if ($source =~ m/\G(\n*)(\s*)gosub\b/gc)
        {
            $text .= "$1$2";
            my $arg;
            if ($source =~ m/\G\s*(\w+)\s*;/gc)
            {
                $arg = $1;
            }
            else
            {
                my $pos_source = pos($source);
                # This is an Evil hack that meant to get Text::Balanced to do
                # what we want. What happens is that we put an initial ";"
                # so the end of the statement will be a ";" too.
                my $source_for_text_balanced = ";" .
                    substr($source, $pos_source);
                pos($source_for_text_balanced) = 0;
                @pos = Text::Balanced::_match_codeblock(\$source_for_text_balanced,qr/\s*/,qr/;/,qr/;/,qr/[[{(<]/,qr/[]})>]/,undef)
                    or do {
                        die "Bad gosub statement (problem in the parentheses?) near $Acme::Gosub::file line ", line(substr($source_for_text_balanced,0,pos $source_for_text_balanced),$line), "\n";
                    };
                my $future_pos_source = $pos_source + pos($source_for_text_balanced);
                print join(",",@pos), "\n";
                $arg = filter_blocks(substr($source_for_text_balanced,1,$pos[4]-$pos[0]),line(substr($source_for_text_balanced,0,1),$line));
                print "\$arg = $arg\n";
                pos($source) = $future_pos_source;
            }

            my $next_ret_label = "__G_O_S_U_B_RET_LABEL_" .
                ($next_label_idx++);

            $text .= "push \@{\$Acme::Gosub::ret_labels{(caller(0))[3]}}, \"$next_ret_label\";";
            $text .= "goto $arg;";
            $text .= "$next_ret_label:";
            next component;
        }
        elsif ($source =~ m/\G(\s*)greturn\s*;/gc)
        {
            $text .= $1;
            $text .= "goto (pop(\@{\$Acme::Gosub::ret_labels{(caller(0))[3]}}));";
            next component;
        }

        $source =~ m/\G(\s*(-[sm]\s+|\w+|#.*\n|\W))/gc;
        $text .= $1;
    }
    $text;
}

1;

__END__

=head1 NAME

Acme::Gosub - Implement BASIC-like "gosub" and "greturn" in Perl

=head1 SYNOPSIS

    use Acme::Gosub;

    sub pythagoras
    {
        my ($x, $y) = (@_);
        my ($temp, $square, $sum);
        $sum = 0;
        $temp = $x;
        gosub SQUARE;
        $sum += $square;
        $temp = $y;
        gosub SQUARE;
        $sum += $square;
        return $sum;

    SQUARE:
        $square = $temp * $temp;
        greturn;
    }

=head1 DESCRIPTION

Using this function enables using the "gosub" and "greturn" statements inside
your program. "gosub" is identical to "goto" except that it records the
place from which it was invoked. Then, when a "greturn" is used, it jumps back
to the place of the last goto that was not "greturned" yet. If you're not
a BASIC programmer you can think of it as a poor man's recursion.

For more information consult the examples in the test files.

=head1 FUNCTIONS

=head2 filter()

Does the actual filtering to the code.

=head2 filter_blocks()

The workhorse of the module - does most of the work of transforming the code.

=head2 line()

Taken from Switch.pm.

=head2 unimport()

Cancels the filter.

=head1 AUTHOR

Damian Conway is the original author of L<Switch.pm>, on which this module
is based.

Shlomi Fish ( L<http://www.shlomifish.org/> ) converted Switch.pm to become
Acme::Gosub.

=head1 BUGS

The function's gosub recursion stack is function-wide and so different
instances of the function will all use the same recursion stack. Hopefully
it will be fixed in later versions.

I am not sure whether this will work on dynamic functions (a.k.a closures).

Please report any bugs or feature requests to
C<bug-acme-gosub@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Gosub>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 1997-2003, Damian Conway. All Rights Reserved.
Modified by Shlomi Fish, 2005 - all rights disclaimed.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Acme::ComeFrom> .

=cut
