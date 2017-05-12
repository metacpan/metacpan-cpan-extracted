package Data::Kanji::Tomoe;

our $VERSION = '0.05';

# Read in the data file from Tomoe

use warnings;
use strict;
use XML::Parser;
use utf8;
use Carp;

sub point()
{
    my ($tomoe) = @_;
    my $stroke_points = $$tomoe{stroke_points};
    my $attrval = $$tomoe{attrval};
    my $x = $$attrval{x};
    my $y = $$attrval{y};
#    print $x, $y;
    push @$stroke_points, [$x, $y];
}

sub stroke()
{
    my ($tomoe) = @_;
    $$tomoe{stroke_points} = [];
    $$tomoe{stroke_count}++;
}

sub strokes()
{
    my ($tomoe) = @_;
    $$tomoe{stroke_count} = 0;
}

sub character()
{
    my ($tomoe) = @_;
    # Kill old character.
    $tomoe->{character} = {};
}

sub utf8()
{
    my ($tomoe) = @_;
}

sub dictionary()
{
    my ($tomoe) = @_;

}

sub point_end()
{
    my ($tomoe) = @_;
}

sub stroke_end()
{
    my ($tomoe) = @_;
    my $stroke_points = $$tomoe{stroke_points};
    my $character = $tomoe->{character};
    push @{$character->{strokes}}, $stroke_points;
#    print "Number of points is ", scalar @$stroke_points, "\n";
#    my $stroke_data = StrokeRecognition::identify($stroke_points);
#    print $stroke_data;
}

sub strokes_end()
{
    my ($tomoe) = @_;
#    print " ", $$tomoe{stroke_count}, "\n";
}

sub character_end()
{
    my ($tomoe) = @_;
    my $character_callback = $tomoe->{character_callback};
    if ($character_callback) {
        &{$character_callback} ($tomoe, $tomoe->{character});
    }
}

sub utf8_end()
{
    my ($tomoe, $string) = @_;
    $tomoe->{character}->{utf8} = $string;
#    print $string, " ";
}

sub dictionary_end()
{
    my ($tomoe) = @_;

}

# Subroutines which handle the various tags in the Tomoe data.

my %start_handlers = (
    point => \& point,
    stroke => \& stroke,
    strokes => \& strokes,
    character => \& character,
    utf8 => \& utf8,
    dictionary => \& dictionary,
);

# Subroutines which handle the various tags in the Tomoe data.

my %end_handlers = (
    point => \& point_end,
    stroke => \& stroke_end,
    strokes => \& strokes_end,
    character => \& character_end,
    utf8 => \& utf8_end,
    dictionary => \& dictionary_end,
);

# Handle an XML starting tag

sub handle_start
{
    my ($tomoe, $parsexml, $element, %attrval) = @_;
    $$tomoe{element} = $element;
    $$tomoe{attrval} = \%attrval;
    if ($start_handlers{$element}) {
	&{$start_handlers{$element}}($tomoe);
    } else {
	print STDERR "No element handler for element `$element' at line $.\n";
    }
}

# Handle an XML ending tag

sub handle_end
{
    my ($tomoe, $parsexml, $element) = @_;
    my $values = $$tomoe{values};
    my $string = $$values{$element};
    $string =~ s/^\s+|\s+$//g if $string;
    if ($end_handlers{$element}) {
	&{$end_handlers{$element}}($tomoe, $string)
    }
    else {
	print STDERR "No end handler for element `$element' at line $.\n";
    }
    undef $$values{$element};
}

# Handle XML character data

sub handle_char
{
    my ($tomoe, $parsexml, $string) = @_;
    my $values = $$tomoe{values};
    $$values{$$tomoe{element}} .= $string;
}

sub parse
{
    my ($parser) = @_;
    $$parser{xmlparser}->parse($$parser{file});
}

sub parsefile
{
    my ($parser, $tomoe_data_file) = @_;
    open_file ($parser, $tomoe_data_file);
    $parser->parse ($parser->{file});
    close $parser->{file} or croak $!;
}

sub open_file
{
    my ($parser, $tomoe_data_file) = @_;
    open my $tomoe_data, "<:encoding(utf8)", $tomoe_data_file
	or die "Can't open $tomoe_data_file: $!";
    $$parser{file_name} = $tomoe_data_file;
    $$parser{file} = $tomoe_data;
}

sub new
{
    my ($package, %inputs) = @_;
    my $parser = \%inputs;
    $parser->{xmlparser} = new XML::Parser(
        Handlers => {
            Start => sub { handle_start ($parser, @_); },
            End => sub { handle_end ($parser, @_); },
            Char => sub { handle_char ($parser, @_); },
        },
    );
    $$parser{values} = {};
    bless $parser;
    if ($inputs{tomoe_data_file}) {
        open_file ($parser, $inputs{tomoe_data_file});
    }
    return $parser;
}

1;
