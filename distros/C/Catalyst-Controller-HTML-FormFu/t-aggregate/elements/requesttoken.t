{
package 
  main;

use strict;
use warnings;

use Test::More tests => 2;

use HTML::FormFu;

my $form = HTML::FormFu->new;

$form->stash->{context} = new C::Fake;

$form->load_config_file('t-aggregate/elements/requesttoken.yml');

like( $form, qr/<input name="_token" type="hidden" value="/, "RequestToken field is a hidden field" );

like( $form, qr/value="\w+"/, "RequestToken field has a random value" );

}
{
package 
  C::Fake;

sub new { return bless({}, shift) }

sub session { return {} }

}