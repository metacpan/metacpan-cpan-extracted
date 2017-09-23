# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package t::request;
use strict;
use warnings;
use IO::Scalar;
use Carp;
use CGI;
use t::util;
use ClearPress::controller;
use base qw(Exporter);
use Readonly;
use English qw(-no_match_vars);
use Test::More;
use HTML::PullParser;
use JSON;

Readonly::Array our @EXPORT_OK => qw(is_xml is_json is_xls is_txt);

our $VERSION = q[476.4.2];

sub new {
  my ($class, $ref_in) = @_;

  my $ref = {%{$ref_in}};
  my $util = $ref->{util} || ClearPress::util->new;

  if(!exists $ref->{PATH_INFO}) {
    croak q[Must specify PATH_INFO];
  }

  if(!exists $ref->{REQUEST_METHOD}) {
    croak q[Must specify REQUEST_METHOD];
  }

  local $ENV{HTTP_HOST}             = q[test];
  local $ENV{SERVER_PROTOCOL}       = q[HTTP];
  local $ENV{SCRIPT_NAME}           = $ref->{SCRIPT_NAME};
  local $ENV{REQUEST_METHOD}        = $ref->{REQUEST_METHOD};
  local $ENV{HTTP_X_REQUESTED_WITH} = $ref->{xhr}?'XmlHttpRequest':q[];
  local $ENV{PATH_INFO}             = $ref->{PATH_INFO};
  local $ENV{REQUEST_URI}           = "/request$ref->{PATH_INFO}";

  my $stdin = q[];
  no warnings qw(redefine once);
  local *IO::Scalar::BINMODE = sub {};
  tie *STDIN, 'IO::Scalar', \$stdin;

#  $util->catch_email($ref);
  my $cgi = CGI->new();
  $util->cgi($cgi);

  for my $k (keys %{$ref->{cgi_params}}) {
    my $v = $ref->{cgi_params}->{$k};
    if(ref $v eq 'ARRAY') {
      $cgi->param($k, @{$v});

    } else {
      $cgi->param($k, $v);
    }
  }

  $ref->{util} = $util;

  my $str;
  my $io = tie *STDOUT, 'IO::Scalar', \$str;

  ClearPress::controller->handler($util);

  return $str;
}

sub is_xml {
  my ($chunk1, $chunk2, $desc) = @_;
  my $fn = $chunk2 || q[];

  if(!$chunk1) {
    diag q(No chunk1 in test_rendered);
  }

  if(!$chunk2) {
    diag q(No chunk2 in test_rendered);
  }

  if($chunk2 !~ m{<}smx) {
    open my $fh, q[<], qq[t/data/rendered/$chunk2] or croak qq[Error opening t/data/rendered/$chunk2: $ERRNO];
    local $RS = undef;
    $chunk2   = <$fh>;
    close $fh or croak $ERRNO;

    if(!length $chunk2) {
      diag("Zero-sized $chunk2. Expected something like\n$chunk1");
      return fail($desc);
    }
  }

  my $chunk1els = _parse_html_to_get_expected($chunk1);
  my $chunk2els = _parse_html_to_get_expected($chunk2);
  my $pass      = _match_tags($chunk2els, $chunk1els);

  if($pass) {
    return pass($desc);
  }

  if($fn =~ m{^t/}smx) {
    ($fn) = $fn =~ m{([^/]+)$}smx;
  }
  if(!$fn) {
    $fn = q[blob];
  }

  $fn    =~ s{/}{_}smxg;
  my $rx = "/tmp/${fn}-chunk-received";
  my $ex = "/tmp/${fn}-chunk-expected";
  open my $fh1, q(>), $rx or croak "Error opening $ex";
  open my $fh2, q(>), $ex or croak "Error opening $rx";
  print $fh1 $chunk1 or croak $ERRNO;
  print $fh2 $chunk2 or croak $ERRNO;
  close $fh1 or croak "Error closing $ex";
  close $fh2 or croak "Error closing $rx";
  diag("diff '$ex' '$rx'");

  return fail($desc);
}

sub _parse_html_to_get_expected {
  my ($html) = @_;
  my $p;
  my $array = [];

  if ($html =~ m{^t/}xms) {
    $p = HTML::PullParser->new(
			       file  => $html,
			       start => '"S", tagname, @attr',
			       end   => '"E", tagname',
			      );
  } else {
    $p = HTML::PullParser->new(
			       doc   => $html,
			       start => '"S", tagname, @attr',
			       end   => '"E", tagname',
			      );
  }

  my $count = 1;
  while (my $token = $p->get_token()) {
    my $tag = q{};
    for (@{$token}) {
      $_ =~ s/\d{4}-\d{2}-\d{2}/date/xms;
      $_ =~ s/\d{2}:\d{2}:\d{2}/time/xms;
      $tag .= " $_";
    }
    push @{$array}, [$count, $tag];
    $count++;
  }

  return $array;
}

sub _match_tags {
  my ($expected, $rendered) = @_;
  my $fail = 0;
  my $c;

  for my $tag (@{$expected}) {
    my @temp = @{$rendered};
    my $match = 0;
    for ($c= 0; $c < @temp;) {
      my $rendered_tag = shift @{$rendered};
      if ($tag->[1] eq $rendered_tag->[1]) {
        $match++;
        $c = scalar @temp;
      } else {
        $c++;
      }
    }

    if (!$match) {
      diag("Failed to match '$tag->[1]'");
      return 0;
    }
  }

  return 1;
}

sub is_json {
  my ($str1, $fn2, $desc) = @_;
  my $json = JSON->new();
  $json->utf8([1]);

  $fn2 = "t/data/rendered/$fn2";

  if(!-e $fn2) {
    croak "$fn2 does not exist";
  }

  open my $fh, q[<], $fn2 or croak $ERRNO;
  local $RS = undef;
  my $str2  = <$fh>;
  close $fh or croak $ERRNO;

  #########
  # substitute times for something static
  #
  $str1 =~ s/\d{4}-\d{2}-\d{2}[\sT]\d{2}:\d{2}:\d{2}/YYYY-MM-DD HH:MM:SS/smxg;
  $str2 =~ s/\d{4}-\d{2}-\d{2}[\sT]\d{2}:\d{2}:\d{2}/YYYY-MM-DD HH:MM:SS/smxg;

  my $js1 = $json->decode($str1 || q[{}]);
  my $js2 = $json->decode($str2 || q[{}]);

  return is_deeply($js1, $js2, $desc);
}

sub is_txt {
  my ($str1, $fn2, $desc) = @_;

  $fn2 = "t/data/rendered/$fn2";

  if(!-e $fn2) {
    croak "$fn2 does not exist";
  }

  $str1 =~ s/.*?\n\n//smx; # strip header

  open my $fh, q[<], $fn2 or croak $ERRNO;
  local $RS = undef;
  my $str2  = <$fh>;
  close $fh or croak $ERRNO;

  #########
  # substitute times for something static
  #
  $str1 =~ s/\d{4}-\d{2}-\d{2}[\sT]\d{2}:\d{2}:\d{2}/YYYY-MM-DD HH:MM:SS/smxg;
  $str2 =~ s/\d{4}-\d{2}-\d{2}[\sT]\d{2}:\d{2}:\d{2}/YYYY-MM-DD HH:MM:SS/smxg;

  return is($str1, $str2, $desc);
}

sub is_xls {
  my ($str1, $fn2, $desc) = @_;
  require Spreadsheet::ParseExcel;
  my $parser = Spreadsheet::ParseExcel->new();

  $fn2 = "t/data/rendered/$fn2";

  if(!-e $fn2) {
    croak "$fn2 does not exist";
  }

  $str1 =~ s/.*?\n\n//smx; # strip header

  my $book1 = $parser->Parse(\$str1) or croak q[Error parsing XLS string];
  my $book2 = $parser->Parse($fn2) or croak q[Error parsing XLS file];

  my $processor = sub {
    my $workbook = shift;
    my $bookref  = [];

    for my $worksheet ( $workbook->worksheets() ) {
      my $sheetref = [];
      my ( $row_min, $row_max ) = $worksheet->row_range();
      my ( $col_min, $col_max ) = $worksheet->col_range();

      for my $row ( $row_min .. $row_max ) {
	for my $col ( $col_min .. $col_max ) {

	  my $cell = $worksheet->get_cell( $row, $col );
	  if(!$cell) {
	    $sheetref->[$row]->[$col] = q[];
	    next;
	  }

	  my $val = $cell->value();
	  $val    =~ s/\d{4}-\d{2}-\d{2}[\sT]\d{2}:\d{2}:\d{2}/YYYY-MM-DD HH:MM:SS/smxg;

	  $sheetref->[$row]->[$col] = $val;
	}
      }
      push @{$bookref}, $sheetref;
    }
    return $bookref;
  };

  my $struct1 = $processor->($book1);
  my $struct2 = $processor->($book2);

#  use Data::Dumper; carp Dumper($struct1);  carp Dumper($struct2);

  return is_deeply($struct1, $struct2, $desc);
}

1;
__END__

=head1 NAME

t::request

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

  use t::request qw(is_xml);

  my $str = t::request->new({
			     PATH_INFO      => '/run/find',
			     REQUEST_METHOD => 'GET',
			     username       => 'public',
			     cgi_params     => {
						q => q[dat],
                                                ...
					       },
			    });
  is_xml($str, 'expected_data.html', 'test expected data');

=head1 DESCRIPTION

 This module is a test harness for ClearPress-based applications which
 roughly fakes an incoming HTTP request without needing any network
 connectivity or web server. It works by setting various required
 environment variables then calling into the application's request
 handler.

 t:request also exports some useful functions for helping with
 tests. See below for functions matching "is_*".

=head1 SUBROUTINES/METHODS

=head2 new - a new harnessed application request

  my $oRequest = t::request->new({
    PATH_INFO      => '/run/find',     # URI to request
    REQUEST_METHOD => 'GET',           # GET POST PUT DELETE
    username       => 'public',        # username to fake authentication
    cgi_params     => {                # optional hashref of CGI parameters
    },
  });

=head2 is_xml - test XML string correlates to file

  is_xml($sXML, $sFilename, $sTestDescription);

=head2 is_json - test JSON string correlates to file

  is_xml($sJSON, $sFilename, $sTestDescription);

=head2 is_txt - test text string correlates to file

  is_xml($sText, $sFilename, $sTestDescription);

=head2 is_xls - test XLS blob correlates to file

  is_xml($sXLS, $sFilename, $sTestDescription);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item base

=item strict

=item warnings

=item Carp

=item CGI

=item Exporter

=item English

=item HTML::PullParser

=item IO::Scalar

=item JSON

=item t::util

=item ontrack::controller

=item Readonly

=item Test::More

=item Spreadsheet::ParseExcel

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
