package App::WRT::LaTeX;

use strict;
use warnings;
no  warnings 'uninitialized';

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all'       => [ qw(a div p em small strong table
                                         table_row table_cell entry_markup
                                         heading) ],

                     'highlevel' => [ qw(a p em small strong table
                                         table_row table_cell
                                         entry_markup heading) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

# Generate subs for these:
my %tags = (
    p      => \&escape,
    textbf => \&tag,
    em     => \&tag,
    small  => \&tag,
    strong => \&tag,
    table  => \&environment,
    tr     => \&tag,
    td     => \&tag,
    a      => \&tag,
    div    => \&tag,
);

# ...but map these tags to different sub names:
my %tagmap = (
    textbf => 'strong',
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

    if ($param =~ m/^([a-z]+): ?(.*)$/) {
      my ($name, $value) = ($1, $2);
      $attr_string .= qq{ $name="$value"}
    }
    else {
      $text .= "\n" if length($text) > 0;
      $text .= $param;
    }

  }

  # voila, an X(HT)ML tag:
  return "\\${tag}\{$text\}";

}

sub environment {
  my ($name) = shift;
}

sub escape {
  shift;
  return @_;
}

########################################
# Special cases and higher-level markup

sub entry_markup {
    my ($text) = @_;
    return div($text, 'class: entry') . "\n";
}

sub heading {
    my ($text, $level) = @_;
    my $h = "h$level";
    return tag($h, $text);
}

1;
