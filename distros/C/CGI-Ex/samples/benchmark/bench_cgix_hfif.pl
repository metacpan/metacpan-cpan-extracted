#!/usr/bin/perl -w

# Benchmark: timing 1000 iterations of cgix_func, cgix_meth, hfif...
#  cgix_func:  1 wallclock secs ( 1.41 usr +  0.01 sys =  1.42 CPU) @ 704.23/s (n=1000)
#  cgix_meth:  2 wallclock secs ( 1.47 usr +  0.00 sys =  1.47 CPU) @ 680.27/s (n=1000)
#  hfif:  8 wallclock secs ( 8.34 usr +  0.04 sys =  8.38 CPU) @ 119.33/s (n=1000)
#            Rate      hfif cgix_meth cgix_func
# hfif      119/s        --      -82%      -83%
# cgix_meth 680/s      470%        --       -3%
# cgix_func 704/s      490%        4%        --

use strict;

use Benchmark qw(cmpthese);
use HTML::FillInForm;
use CGI::Ex;

my $t = q{

<!-- This is another thing -->
<html>
<form name=foo>

<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>

<input type=text name=foo value="wow">

<input type=password name="pass" value="">

<select name=garbage>
  <option value=lid>Lid</option>
  <option value=can>Can</option>
  <option value=wheel>Wheel</option>
  <option value=truck>Truck</option>
</select>

<!-- </form> -->

<textarea name=Mighty></textarea>

</form>

</html>
};

my $form = {
  foo => "bar",
  pass => "word",
  garbage => ['can','lid'],
  Mighty  => 'ducks',
};


my $fif = HTML::FillInForm->new;
my $fo  = CGI::Ex->new;
$fo->{remove_comments} = 1;

my $x = $fo->fill(scalarref => \$t,
                  fdat => $form,
                  target => 'foo',
                  );
#print $x;
#exit;

cmpthese(-2, {
  hfif => sub {
    my $copy = $t;
    my $new = $fif->fill(scalarref => \$copy,
                         fdat => $form,
                         target => 'foo',
                         );
  },
  cgix_meth => sub {
    my $copy = $t;
    $fo->fill(scalarref => \$copy,
              fdat => $form,
              target => 'foo',
              );
  },
  cgix_func => sub {
    my $copy = $t;
    &CGI::Ex::Fill::form_fill(\$copy, $form, 'foo');
  },
});
