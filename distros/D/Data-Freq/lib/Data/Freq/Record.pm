use 5.006;
use strict;
use warnings;

package Data::Freq::Record;

=head1 NAME

Data::Freq::Record - Represents a record added to Data::Freq counting

=cut

use base 'Exporter';
use Carp qw(croak);
use Date::Parse qw(str2time);

our @EXPORT_OK = qw(logsplit);

=head1 EXPORT

=head2 logsplit

Splits a text that represents a line in a log file.

    use Data::Freq::Record qw(logsplit);
    
    logsplit("12.34.56.78 - user1 [01/Jan/2012:01:02:03 +0000] "GET / HTTP/1.1" 200 44");
    
    # Returns an array with:
    #     [0]: '12.34.56.78'
    #     [1]: '-'
    #     [2]: '[01/Jan/2012:01:02:03 +0000]'
    #     [3]: '"GET / HTTP/1.1"'
    #     [4]: '200'
    #     [5]: '44'

A log line is typically whitespace-separated, while anything inside
brackets C<[...]>, braces C<{...}>, parentheses C<(...)>, double quotes C<"...">,
or single quotes C<'...'> is considered as one chunk as a whole
even if whitespaces may be included inside.

The C<logsplit> function is intended to split such a log line into an array.

=cut

sub logsplit {
    my $log = shift;
    my @ret = ();
    
    push @ret, $1 while $log =~ m/ (
        " (?: \\" | "" | [^"]  )* " |
        ' (?: \\' | '' | [^']  )* ' |
        \[ (?: \\[\[\]] | \[\[ | \]\] | [^\]] )* \] |
        \( (?: \\[\(\)] | \(\( | \)\) | [^\)] )* \) |
        \{ (?: \\[\{\}] | \{\{ | \}\} | [^\}] )* \} |
        \S+
    ) /gx;
    
    return @ret;
}

=head1 METHODS

=head2 new

Usage:

    # Text
    Data::Freq::Record->new("text");
    
    Data::Freq::Record->new("an input line from a log file\n");
        # Line break at the end will be stripped off
    
    # Array ref
    Data::Freq::Record->new(['an', 'array', 'ref']);
    
    # Hash ref
    Data::Freq::Record->new({key => 'hash ref'});

Constructs a record object, which carries an input data
in the form of a text, an array ref, or a hash ref.
Each form of the input (or a converted value) can be retrieved
by the L<text()|/text>, L<array()|/array>, or L<hash()|/hash> function.

When an array ref is required via the L</array>() method
while a text is given as the input, the array ref is created internally
by the L<logsplit()|/logsplit> function.

When a text is required via the L<text()|/text> method
while an array ref is given as the input, the text is taken
from the first element of the array.

The hash form is incompatible with the other forms, and whenever an incompatible
form is required, the return value is C<undef>.

If the text input has a line break at the end, it is stripped off.
If the line break should not be stripped off, use an array ref with the first element
set to the text.

=cut

sub new {
    my ($class, $input) = @_;
    
    my $self = bless {
        init       => undef,
        text       => undef,
        array      => undef,
        hash       => undef,
        date       => undef,
        date_tried => 0,
    }, $class;
    
    if (!defined $input) {
        $self->{text} = '';
        $self->{init} = 'text';
    } elsif (!ref $input) {
        $input =~ s/\r?\n$//;
        $self->{text}  = $input;
        $self->{init}  = 'text';
    } elsif (ref $input eq 'ARRAY') {
        $self->{array} = $input;
        $self->{init}  = 'array';
    } elsif (ref $input eq 'HASH') {
        $self->{hash}  = $input;
        $self->{init}  = 'hash';
    } else {
        croak "invalid argument type: ".ref($input);
    }
    
    return $self;
}

=head2 text

Retrieves the text form of the input.

If the input was an array ref, the first element of the array is returned.

=cut

sub text {
    my $self = shift;
    return $self->{text} if defined $self->{text};
    
    if (defined $self->{array}) {
        $self->{text} = $self->{array}[0];
        return $self->{text};
    }
    
    return undef;
}

=head2 array

Retrieves the array ref form of the input.

If the input was a text, it is split by the L<logsplit()|/logsplit> function..

=cut

sub array {
    my $self = shift;
    return $self->{array} if defined $self->{array};
    
    if (defined $self->{text}) {
        $self->{array} = [logsplit $self->{text}];
        return $self->{array};
    }
    
    return undef;
}

=head2 hash

Retrieves the hash ref form of the input.

=cut

sub hash {
    my $self = shift;
    return $self->{hash} if defined $self->{hash};
    return undef;
}

=head2 date

Extracts a date/time from the input and returns the timestamp value.

The date/time is retrieved from the array ref form (or from a split text),
where the first element enclosed by a pair of brackets C<[...]> is
parsed by the L<Date::Parse::str2time()|Date::Parse/str2time> function.

=cut

sub date {
    my $self = shift;
    return $self->{date} if $self->{date_tried};
    
    $self->{date_tried} = 1;
    
    my $array = $self->array or return undef;
    
    if (my $pos = shift) {
        my $str = "@$array[@$pos]";
        $str =~ s/^ \[ (.*) \] $/$1/x;
        return $self->{date} = $str if $str !~ /\D/;
        return $self->{date} = _str2time($str);
    }
    
    for my $item (@$array) {
        if ($item =~ /^ \[ (.*) \] $/x) {
            my $t = _str2time($1);
            return $self->{date} = $t if defined $t;
        }
    }
    
    return undef;
}

sub _str2time {
    my $str = shift;
    
    my $msec = $1 if $str =~ s/[,\.](\d+)$//;
    my $t = str2time($str);
    return undef unless defined $t;
    
    $t += "0.$msec" if $msec;
    return $t;
}

=head1 AUTHOR

Mahiro Ando, C<< <mahiro at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mahiro Ando.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
