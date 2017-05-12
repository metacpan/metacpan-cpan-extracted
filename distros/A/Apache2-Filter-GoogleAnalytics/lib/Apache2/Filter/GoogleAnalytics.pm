package Apache2::Filter::GoogleAnalytics;

=head1 NAME

Apache2::Filter::GoogleAnalytics - Add GA code to served HTML document

=head1 SYNOPSIS

  PerlLoadModule Apache2::Filter::GoogleAnalytics
  <Location /to-analyze>
          WebPropertyID UA-80868086-2
          PerlOutputFilterHandler Apache2::Filter::GoogleAnalytics
  </Location>

=head1 DESCRIPTION

This module transparently adds a Google Analytics service scriptlet to each
HTML document that Apache httpd serves. It behaves asynchronous pass-thru
filter, thus its impact on performance is minimal.

=head1 OPTIONS

=over 4

=item B<WebPropertyID>

A Web Property ID obtained from Google. It can be specified both globally
and per-resource basis.

=back

=cut

use strict;
use warnings;

use HTML::Parser;
use Apache2::Filter;
use Apache2::Module;
use Apache2::RequestRec;
use APR::Table;
use Apache2::Const -compile => qw/OK/;

our $VERSION = '1.01';

# Register an Apache directive
Apache2::Module::add (__PACKAGE__, [{ name => 'WebPropertyID' }]);

# Process an Apache directive
sub WebPropertyID
{
	my ($self, $parms, $arg) = @_;
	$self->{WebPropertyID} = $arg;
}

# Taken verbatim from Google
sub ga_script
{
	my $web_property_id = shift;

return <<GA_CODE;
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '$web_property_id']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
GA_CODE
}

# Inject the GA Code before the end of the HEAD tag
sub end_handler
{
	my $self = shift;
	if (lc(shift) eq 'head') {
		default_handler ($self, $self->{ga_code});
		# There should not be more than a single
		# instance of GA code in the file
		$self->{ga_code} = '';
	}
	default_handler ($self, shift);
}

# Pipe the rest of the HTML untouched
sub default_handler
{
	my $self = shift;
	$self->{filter}->print (shift);
}

# mod_perl dispatches here
sub handler
{
	my $filter = shift;

	my $parser = new HTML::Parser (
		api_version => 3,
		end_h => [\&end_handler, 'self, tagname, text'],
		default_h => [\&default_handler, 'self, text'],
	);
	# This is opaque structure passed to callbacks
	$parser->{filter} = $filter;

	# If the GA ID is present, format the GA Code
	# Only for HTML resources
	my $config = Apache2::Module::get_config (__PACKAGE__,
		$filter->r->server, $filter->r->per_dir_config);
	$parser->{ga_code} = '';
	$parser->{ga_code} = ga_script ($config->{'WebPropertyID'})
		if exists $config->{'WebPropertyID'}
		and ($filter->r->content_type () eq 'text/html'
		or $filter->r->content_type () eq 'application/xhtml+xml');

	# Extend the body length
	if ($filter->r->headers_out->get ('Content-Length')) {
		$filter->r->headers_out->set ('Content-Length'
			=> $filter->r->headers_out->get ('Content-Length')
			+ length $parser->{ga_code});
	}

	# Process the output data as we get it
	my $buffer;
	while ($filter->read ($buffer)) {
		$parser->parse ($buffer);
	}
	$parser->eof ();

	# Just in case there was not </head>, place this at the end
	# (at the very least so that we don't confuse the UA with
	# bogus body length)
	$filter->print ($parser->{ga_code});

	return Apache2::Const::OK;
}

=head1 SEE ALSO

L<HTML::Parser>, L<Apache2::Filter>.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Lubomir Rintel, C<< <lkundrak@v3.sk> >>

The code is hosted on GitHub L<https://github.com/lkundrak/perl-Apache2-Filter-GoogleAnalytics>
Bug fixes and feature enhancements are always welcome.

=cut

1;
