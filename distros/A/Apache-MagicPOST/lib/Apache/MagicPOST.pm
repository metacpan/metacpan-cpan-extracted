package Apache::MagicPOST;
 
require 5.005_62;
use strict;
use vars qw($VERSION @EXPORTER @ISA);
use warnings;
 
require Exporter;
use AutoLoader qw(AUTOLOAD);
 
our @ISA = qw(Exporter);
 
our @EXPORT = qw();
our $VERSION = '1.2';
 
use Apache::Constants qw(:common );

use Apache::Request;

# ********************************************
# This module isn't usable, it destroys POST
# data for subsequent handlers ;-(
# ********************************************
sub _handler {
        my $r = shift;
        return DECLINED unless $r->method() eq 'POST' ;
	return DECLINED unless ($r->header_in('Content-type') eq 'application/x-www-form-urlencoded');

	my $method_param_name = $r->dir_config('MagicPOSTMethodParamName');
	$method_param_name = 'method' unless ( $method_param_name );

	my %params = $r->content;
	return DECLINED unless ( exists ( $params{$method_param_name} ));
	$r->method( $params{$method_param_name} );
	delete $params{$method_param_name};

	foreach(keys %params)
	{
		$r->header_in( $_ => $params{$_} );
		delete $params{$_}; 
	}
	$r->header_in( 'Content-length' => undef );
	$r->header_in( 'Content-type' => undef );

        return OK;
}
 
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Apache::MagicPOST - Perl module to emulate arbitray HTTP methods through POST

=head1 SYNOPSIS

=head1 DESCRIPTION

***********************************************************************
NOTE: This module is not working as I intended since the poking into
the POST data makes the data unavailable for subsequent modules. To
make sure that you do not accidentally run into this, the handler method
has been renamed to _handler(). I'll change this module to work with
Apache2 (where the intended behavior is possible) in a while.
***********************************************************************


Apache::MagicPOST allows you to send HTTP methods to a server that
are currently not supported by available browsers. The module,
once installed in the PostReadRequest phase will react on the
presence of the POST parameter 'method', alter the request
method to the value of this parameter and turn all additional
parameters into HTTP headers.

In your http.conf put the following line:

  PerlPostReadRequestHandler Apache::MagicPOST

If you need to override the default method parameter name
'method' (because you already use 'method' in your other
HTML forms), use the following directive:

  PerlSetVar MagicPOSTMethodParamName yourParamName

Make sure you put it *before* other handlers of this
phase so it gets invoked first.

In your HTML pages, put <form> tags like:

  <form method="POST">
    <input type="hidden" name="method" value="MONITOR" />
    <input type="text" name="Reply-To" value="" size="40" />
  </form>

All parameters other than 'method' will be translated into HTTP
headers.


=head1 SEE ALSO

=head1 AUTHOR

Jan Algermissen, algermissen@acm.org

=head1 COPYRIGHT AND LICENSE

Copyright 2003 , 2004 by Jan Algermissen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
