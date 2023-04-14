package CGI::Untaint::Facebook;

use warnings;
use strict;
use Carp;

# use base 'CGI::Untaint::object';
use base 'CGI::Untaint::url';
use LWP::UserAgent;
use URI::Heuristic;
use Mozilla::CA;
use LWP::Protocol::https;
use URI::Escape;

=head1 NAME

CGI::Untaint::Facebook - Validate a string is a valid Facebook URL or ID

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';

=head1 SYNOPSIS

CGI::Untaint::Facebook validate if a given ID in a form is a valid Facebook ID.
The ID can be either a full Facebook URL, or a page on facebook, so
'http://www.facebook.com/nigelhorne' and 'nigelhorne' will both return true.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::Facebook;
    # ...
    my $info = CGI::Info->new();
    my $params = $info->params();
    # ...
    my $u = CGI::Untaint->new($params);
    my $tid = $u->extract(-as_Facebook => 'web_address');
    # $tid will be lower case

=head1 SUBROUTINES/METHODS

=head2 is_valid

Validates the data.
Returns a boolean if $self->value is a valid Facebook URL.

=cut

sub is_valid {
	my $self = shift;

	my $value = $self->value;

	if(!defined($value)) {
		return 0;
	}

	# Ignore leading and trailing spaces
	$value =~ s/\s+$//;
	$value =~ s/^\s+//;

	if(length($value) == 0) {
		return 0;
	}

	if($value =~ /\s/) {
		return 0;
	}

	# Allow URLs such as https://m.facebook.com/#!/groups/6000106799?ref=bookmark&__user=764645045)
	if($value =~ /([a-zA-Z0-9\-\/\.:\?&_=#!]+)/) {
		$value = $1;
	} else {
		return 0;
	}

	my $url;
	if($value =~ /^http:\/\/www.facebook.com\/(.+)/) {
		$url = "https://www.facebook.com/$1";
		$self->value($url);
	} elsif($value =~ /^www\.facebook\.com/) {
		$url = "https://$value";
		$self->value($url);
	} elsif($value !~ /^https:\/\/(www|m).facebook.com\//) {
		$url = URI::Heuristic::uf_uristr("https://www.facebook.com/$value");
		$self->value($url);
	} else {
		if(!$self->SUPER::is_valid()) {
			return 0;
		}
		$url = $value;
	}

	my $request = HTTP::Request->new('HEAD' => $url);
	$request->header('Accept' => 'text/html');
	if($ENV{'HTTP_ACCEPT_LANGUAGE'}) {
		$request->header('Accept-Language' => $ENV{'HTTP_ACCEPT_LANGUAGE'});
	}
	my $browser = LWP::UserAgent->new();
	$browser->ssl_opts(verify_hostname => 1, SSL_ca_file => Mozilla::CA::SSL_ca_file());
	$browser->agent(ref($self));	# Should be CGI::Untaint::Facebook
	$browser->timeout(10);
	$browser->max_size(128);
	$browser->env_proxy(1);

	my $webdoc = $browser->simple_request($request);
	my $error_code = $webdoc->code();
	if(!$webdoc->is_success()) {
		if((($error_code == 301) || ($error_code == 302)) &&
		   ($webdoc->as_string =~ /^location: (.+)$/im)) {
		   	my $location = $1;
		   	if($location =~ /^https?:\/\/(www|m).facebook.com\/pages\/.+/) {
				$self->value($location);
				return 1;
			} else {
				my $e = uri_escape($url);
				if($location =~ /^https?:\/\/(www|m).facebook.com\/login\/\?next=\Q$e\E/) {
					return 1;
				}
				if($location =~ /^https?:\/\/(www|m).facebook.com\/login.php\?next=\Q$e\E/) {
					return 1;
				}
			}
			carp "redirect from $url to $location";
			return 1;
		} elsif($error_code != 404) {
			# Probably the certs file is wrong, or there
			# was a timeout
			carp "$url: ", $webdoc->status_line();
		}
		return 0;
	}
	my $response = $browser->decoded_content();
	if($response =~ /This content isn't available at the moment/mis) {
		return 0;
	}
	return 1;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-untaint-url-facebook at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-Twitter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

CGI::Untaint::url

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Untaint::Facebook

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-Facebook>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Untaint-Facebook>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2023 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of CGI::Untaint::Facebook
