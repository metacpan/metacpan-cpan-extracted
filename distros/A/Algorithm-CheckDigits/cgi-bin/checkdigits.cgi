#!/usr/bin/perl -w
# vim: ts=4 sw=4 tw=78 et si:
#
use strict;

use Algorithm::CheckDigits;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

my $algorithm = param('algorithm');
my $number    = param('number');
my $ok = '';
my @all_algorithms;
my %all_labels;

if ($ENV{ALL_ALGORITHMS}) {
    @all_algorithms = split /,/, $ENV{ALL_ALGORITHMS};
}
else {
    @all_algorithms = Algorithm::CheckDigits::method_list();
}

%all_labels = Algorithm::CheckDigits::method_descriptions(@all_algorithms);

if ($number and $algorithm) {
    my $cd = CheckDigits($algorithm);
    if ($cd->is_valid($number)) {
        $ok =  "$number is a valid $algorithm number";
        param('number','');
    }
    else {
        $ok =  "$number is not valid with algorithm $algorithm";
    }
}

print header(),
      start_html(),
      start_form(),
      textfield('number'),
      popup_menu(-name   => 'algorithm',
      		 -values => \@all_algorithms,
		 -labels => \%all_labels),
      submit('check'),
      end_form(),
      $ok,
      end_html(),
      "\n";

exit 0;
