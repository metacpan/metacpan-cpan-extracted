package Astro::Montenbruck::Utils::Display;
use 5.22.0;
use strict;
use warnings;
use Exporter qw/import/;
use Readonly;
use Term::ANSIColor;

our $VERSION = 0.03;

our @EXPORT_OK = qw/%LIGHT_THEME %DARK_THEME print_data/;

Readonly::Hash our %DARK_THEME => (
  data_row_title     => 'white',
  data_row_data      => 'bright_white',
  data_row_selected  => 'bright_yellow',
  table_row_title    => 'white',
  table_row_data     => 'bright_yellow',
  table_row_error    => 'red',
  table_col_title    => 'white'
);

Readonly::Hash our %LIGHT_THEME => (
  data_row_title     => 'bright_blue',
  data_row_data      => 'black',
  data_row_selected  => 'bright_blue',
  table_row_title    => 'bright_blue',
  table_row_data     => 'black',
  table_row_error    => 'red',
  table_col_title    => 'bright_blue'
);

sub print_data {
    my $title  = shift;
    my $data   = shift;
    my %arg    = (title_width => 20, highlited => 0, @_);
    my $fmt    = '%-' . $arg{title_width} . 's';
    my $scheme = $arg{scheme};
    my $data_color = $arg{highlited} ? $scheme->{data_row_selected}
                                     : $scheme->{data_row_data};
    print colored( sprintf($fmt, $title), $scheme->{data_row_title} );
    print colored(': ', $scheme->{data_row_data});
    $data = " $data" unless $data =~ /^[-+]/;
    say colored( $data, $data_color);
}

1;
