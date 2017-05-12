package TestAjax::error_html;
use strict;
use warnings;
use Apache2::Ajax;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache::Test;
use Apache::TestUtil;

sub handler {
  my ($r) = @_;
  my $ajax = Apache2::Ajax->new($r);
  t_server_log_error_is_expected();
  my $html = $ajax->build_html() or return Apache2::Const::SERVER_ERROR;
  $r->print($html);
  return Apache2::Const::OK;
}

sub exported_fx {
  my $value_a = shift;
  my $value_b = shift;
  $value_a = "" if not defined $value_a; # make sure there's def
  $value_b = "" if not defined $value_b; # make sure there's def

  if ( $value_a =~ /\D+/ or $value_a eq "" ) {
    return( $value_a . " and " . $value_b );
  } elsif ( $value_b =~ /\D+/ or $value_b eq "" ) {
    return( $value_a . " and " . $value_b );
  } else {
    # got two numbers, so lets multiply them together
    return( $value_a * $value_b );
  }
}

1;

__END__

PJX_fn myfunc exported_fx
PJX_JSDEBUG 2
PJX_DEBUG 0

<Base>
  PerlLoadModule TestAjax::error_html
</Base>
