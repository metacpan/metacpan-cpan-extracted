package App::Ikaros::Config;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw/CONFIG/;

our $config = {};

sub CONFIG { $config }

1;
