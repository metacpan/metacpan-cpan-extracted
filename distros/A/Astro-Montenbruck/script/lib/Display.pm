package Display;
use 5.22.0;
use strict;
use warnings;
use Exporter qw/import/;
use Readonly;
use Term::ANSIColor;

our $VERSION = 0.01;

our @EXPORT_OK = qw/%LIGHT_THEME %DARK_THEME print_data/;

Readonly::Hash our %DARK_THEME => (
  data_row_title  => 'white',
  data_row_data   => 'bright_white',
  table_row_title => 'white',
  table_row_data  => 'bright_yellow',
  table_row_error => 'red',
  table_col_title => 'white'
);

Readonly::Hash our %LIGHT_THEME => (
  data_row_title  => 'bright_blue',
  data_row_data   => 'black',
  table_row_title => 'bright_blue',
  table_row_data  => 'black',
  table_row_error => 'red',
  table_col_title => 'bright_blue'
);

sub print_data {
    my $title  = shift;
    my $data   = shift;
    my %arg    = (title_width => 20, @_);
    my $fmt    = '%-' . $arg{title_width} . 's';
    my $scheme = $arg{scheme};
    print colored( sprintf($fmt, $title), $scheme->{data_row_title} );
    print colored(': ', $scheme->{data_row_title});
    $data = " $data" unless $data =~ /^[-+]/;
    say colored( $data, $scheme->{data_row_data});
}

1;
