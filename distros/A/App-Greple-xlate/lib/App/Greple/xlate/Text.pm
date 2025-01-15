package App::Greple::xlate::Text;

=encoding utf-8

=head1 NAME

App::Greple::xlate::Text - text normalization interface

=head1 SYNOPSIS

    my $obj = App::Greple::xlate::Text->new($text, paragraph => 1);
    my $normalized = $obj->normalized;

    $result = process($normalized);

    $obj->unstrip($result);

=head1 DESCRIPTION

This is an interface used within L<App::Greple::xlate> to normalize
text.

To get the normalized text, use the C<normalized> method.

During normalization process, any whitespace at the beginning and the
end of the line is removed.  Therefore, the result of processing the
normalized text does not preserve the whitespace in the original
string; the C<unstrip> method can be used to restore the removed
whitespace.

=head1 METHODS

=over 7

=item B<new>

Creates an object.  The first parameter is the original string; the
second and subsequent parameters are pairs of attribute name and values.

=over 4

=item B<paragraph>

Specifies whether or not the text should be treated as a paragraph.

If true, multiple lines are concatenated into a single line.

If false, multiple strings are processed as they are.

In both cases, leading and trailing whitespace is stripped from each
line.

=back

=item B<normalized>()

Returns a normalized string.

=item B<unstrip>(I<$text>)

Recover removed white spaces from normalized text or corresponding
cooked text.

If not in paragraph mode, the string to be processed must have the
same number of lines as the original string.

=item B<text>

Retrieve original text.

=back

=cut

use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Unicode::EastAsianWidth;
use Hash::Util qw(lock_keys);

sub new {
    my $class = shift;
    my $obj = bless {
	ATTR => {},
	TEXT => undef,
	STRIPPED => undef,
	NORMALIZED => undef,
	UNSTRIP => undef,
    }, $class;
    lock_keys %{$obj};
    $obj->text = shift;
    %{$obj->{ATTR}} = (%{$obj->{ATTR}}, @_);
    $obj;
}

sub attr :lvalue {
    my $obj = shift;
    my $key = shift;
    $obj->{ATTR}->{$key};
}

sub normalize {
    my $obj = shift;
    my $paragraph = $obj->attr('paragraph');
    local $_ = $obj->text;
    if (not $paragraph) {
	s{^.+}{
	    ${^MATCH}
		=~ s/\A\s+|\s+\z//gr
	    }pmger;
    } else {
	s{^.+(?:\n.+)*}{
	    ${^MATCH}
		# remove leading/trailing spaces
		=~ s/\A\s+|\s+\z//gr
		# remove newline after Japanese Punct char
		=~ s/(?<=\p{InFullwidth})(?<=\pP)\n//gr
		# join Japanese lines without space
		=~ s/(?<=\p{InFullwidth})\n(?=\p{InFullwidth})//gr
		# join ASCII lines with single space
		=~ s/\s+/ /gr
	    }pmger;
    }
}

sub text :lvalue {
    my $obj = shift;
    $obj->{TEXT};
}

sub normalized {
    my $obj = shift;
    $obj->{NORMALIZED} //= $obj->normalize;
}

sub strip {
    my $obj = shift;
    my $text = $obj->text;
    if ($obj->attr('paragraph')) {
	return $obj->paragraph_strip;
    }
    my $line_re = qr/.*\n|.+\z/;
    my @text = $text =~ /$line_re/g;
    my @space = map {
	[ s/\A(\s+)// ? $1 : '', s/(\h+)$// ? $1 : '' ]
    } @text;
    $obj->{STRIPPED} = join '', @text;
    $obj->{UNSTRIP} = sub {
	for (@_) {
	    my @text = /.*\n|.+\z/g;
	    if (@space == @text + 1) {
		push @text, '';
	    }
	    die "UNMATCH:\n".Dumper(\@text, \@space) if @text != @space;
	    for my $i (keys @text) {
		my($head, $tail) = @{$space[$i]};
		$text[$i] =~ s/\A/$head/ if length $head > 0;
		$text[$i] =~ s/\Z/$tail/ if length $tail > 0;
	    }
	    $_ = join '', @text;
	}
    };
    $obj;
}

sub paragraph_strip {
    my $obj = shift;
    local *_ = \($obj->{STRIPPED} = $obj->text);
    my $head = s/\A(\s+)// ? $1 : '' ;
    my $tail = s/(\h+)$//  ? $1 : '' ;
    $obj->{UNSTRIP} = sub {
	for (@_) {
	    s/\A/$head/ if length $head;
	    s/\Z/$tail/ if length $tail;
	}
    };
    $obj;
}

sub unstrip {
    my $obj = shift;
    $obj->strip if not $obj->{UNSTRIP};
    if (my $unstrip = $obj->{UNSTRIP}) {
	$unstrip->(@_);
    }
    $obj;
}

1;
