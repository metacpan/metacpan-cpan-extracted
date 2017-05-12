package Apache::LoadAvgLimit;

use strict;
use vars qw($VERSION);
use Apache;
use Apache::Constants qw(:common HTTP_SERVICE_UNAVAILABLE);
use Apache::LoadAvgLimit::GetAvg;

$VERSION = '0.04';

sub handler {
    my $r = shift;
    return DECLINED unless $r->is_initial_req;

    # get
    my @avg = Apache::LoadAvgLimit::GetAvg::get_loadavg()
        or do {
	  $r->log_error("Cannot get load avg !");
	  return SERVER_ERROR;
	};

    my $over = 0;
    if( (my $limit = $r->dir_config('LoadAvgLimit')) =~ /^[\d\.]{1,}$/ ){

	# at least one avg needs to be over the specified limit.
	for my $avg(@avg){
	    next if $avg <= $limit;
	    $over++;
	    last;
	}

    }else{

	my @limit;
	if( $r->dir_config('LoadAvgLimit_1') =~ /^[\d\.]{1,}$/ ){
	    $limit[0] = $r->dir_config('LoadAvgLimit_1')
	}
	if( $r->dir_config('LoadAvgLimit_5') =~ /^[\d\.]{1,}$/ ){
            $limit[1] = $r->dir_config('LoadAvgLimit_5')
	}
	if( $r->dir_config('LoadAvgLimit_15') =~ /^[\d\.]{1,}$/ ){
            $limit[2] = $r->dir_config('LoadAvgLimit_15')
	}

	# check
	for my $i(0..2){
	    next if not defined $limit[$i];
	    next if $avg[$i] <= $limit[$i];
	    $over++;
	    last;
	}

    }

    if( $over ){
	# set Retry-After field
	if( (my $retry_after = $r->dir_config('LoadAvgRetryAfter') ) =~ /^\d+$/ ){
	    $r->err_header_out('Retry-After' => int $retry_after);
	}

	$r->log_reason("System load average reaches limit.", $r->filename);
	return HTTP_SERVICE_UNAVAILABLE;
    }

    return OK;
}

1;
__END__

=encoding utf-8

=head1 NAME

Apache::LoadAvgLimit - limiting client request by system CPU load-averages (deprecated)

=head1 SYNOPSIS

  in httpd.conf, simply

  <Location /perl>
    PerlInitHandler Apache::LoadAvgLimit
    PerlSetVar LoadAvgLimit 2.5
  </Location>

  or fully

  <Location /perl>
    PerlInitHandler Apache::LoadAvgLimit
    PerlSetVar LoadAvgLimit_1 3.00
    PerlSetVar LoadAvgLimit_5 2.00
    PerlSetVar LoadAvgLimit_15 1.50
    PerlSetVar LoadAvgRetryAfter 120
  </Location>

=head1 CAUTION

B<THIS MODULE IS MARKED AS DEPRECATED.>

The module may still work for you, but consider switch to psgi like below:

  use Plack::Builder;
  use HTTP::Exception;
  use Sys::Load;

  builder {
      enable 'HTTPExceptions';
      enable_if { (Sys::Load::getload())[0] > 3.00 }
          sub { sub { HTTP::Exception::503->throw } };

      $app;
  };

You can run mod_perl1 application as psgi with L<Plack::Handler::Apache1>.

=head1 DESCRIPTION

If system load-average is over the value of B<LoadAvgLimit*>, 
Apache::LoadAvgLimit will try to reduce the machine load by returning
HTTP status 503 (Service Temporarily Unavailable) to client browser.

Especially, it may be useful in <Location> directory that has heavy CGI,
Apache::Registry script or contents-handler program.

=head1 PARAMETERS

B<LoadAvgLimit>

When at least one of three load-averages (1, 5, 15 min) is over this
value, returning status code 503.

B<LoadAvgLimit_1>, 
B<LoadAvgLimit_5>, 
B<LoadAvgLimit_15>

When Each minute's load-averages(1, 5, 15 min) is over this value,
returning status code 503.

B<LoadAvgRetryAfter>

The second(s) that indicates how long the service is expected to be
unavailable to browser. When this value exists, Retry-After field is
automatically set.

=head1 AUTHOR

Ryo Okamoto E<lt>ryo@aquahill.netE<gt>

=head1 SEE ALSO

mod_perl(3), Apache(3), getloadavg(3), uptime(1), RFC1945, RFC2616, 
mod_loadavg

=head1 REPOSITORY

https://github.com/ryochin/p5-apache-loadavglimit

=head1 AUTHOR

Ryo Okamoto E<lt>ryo@aquahill.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
