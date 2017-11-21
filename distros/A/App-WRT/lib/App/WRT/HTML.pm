package App::WRT::HTML;

use strict;
use warnings;
no  warnings 'uninitialized';


use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all'       => [ qw(a div p em small strong table
                                         table_row table_cell entry_markup
                                         heading article nav section
                                         unordered_list ordered_list list_item) ],

                     'highlevel' => [ qw(a p em small strong table
                                         table_row table_cell
                                         entry_markup heading) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

use HTML::Entities qw(encode_entities);

# Generate subs for these:
my %tags = (
    p       => \&tag,
    em      => \&tag,
    small   => \&tag,
    strong  => \&tag,
    table   => \&tag,
    tr      => \&tag,
    td      => \&tag,
    a       => \&tag,
    div     => \&tag,
    article => \&tag,
    nav     => \&tag,
    section => \&tag,
    ul      => \&tag,
    ol      => \&tag,
    li      => \&tag,
);

# ...but map these tags to different sub names:
my %tagmap = (
    tr => 'table_row',
    td => 'table_cell',
    ul => 'unordered_list',
    ol => 'ordered_list',
    li => 'list_item',
);

# Install appropriate subs in symbol table:
{ no strict 'refs'; 

  for my $key (keys %tags) {
    my $subname = $tagmap{$key};
    $subname = $key unless ($subname);

    *{ $subname } = sub { $tags{$key}->($key, @_); };
  }

}

# handle most HTML tags:
sub tag {
  my ($tag) = shift;
  my (@params) = @_;

  my ($attr_string, $text);

  for my $param (@params) {

    if (ref($param)) {
      # We sort these because, if using each, order is random(ish), and
      # this can lead to different HTML for the same input:
      foreach my $name (sort keys %{ $param }) {
        my $value = encode_entities( ${ $param }{$name} );
        $attr_string .= qq{ $name="$value"};
      }
    }
    else {
      $text .= "\n" if length($text) > 0;
      $text .= $param;
    }

  }

  # voila, an X(HT)ML tag:
  return "<${tag}${attr_string}>$text</$tag>";
}

# Special cases and higher-level markup

sub entry_markup {
    my ($text) = @_;
    return "\n\n" . article(div($text, { class => 'entry' })) . "\n\n";
}

sub heading {
    my ($text, $level) = @_;
    my $h = "h$level";
    return tag($h, $text);
}

1;
