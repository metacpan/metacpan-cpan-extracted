# -*- Mode: Perl; -*-

=head1 NAME

2_fill_20_switcharoo.t - Test CGI::Ex::Fill's ability to handle many different types of broken html tags

=cut

use strict;
use Test::More tests => 27;

use_ok('CGI::Ex::Fill');


my $string;
my %fdat = (foo1 => 'bar1');
my $do_ok = sub {
  my @a;
  ok($string =~ m/ value=([\"\'])bar1\1/i
     && 1 == scalar(@a=$string =~ m/(value)/gi), "Should match ($string)");
};

###----------------------------------------------------------------###

$string = qq{<input name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input name=foo1>};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input name=foo1 />};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input value name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input value value name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input value value="" name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input grrr name="foo1" value="">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input value= name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input type=hidden value= name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input value= type="hidden" name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input value="" name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input value='' name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input value='one' name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input Value="one" name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input VALUE="one" name="foo1">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<input name="foo1" value="one">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE="one">};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE="one" >};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE="" >};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE= >};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE >};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE />};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE= />};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE="" />};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE="one" />};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();

$string = qq{<INPUT NAME="foo1" VALUE="one" />};
CGI::Ex::Fill::form_fill(\$string, \%fdat);
$do_ok->();


