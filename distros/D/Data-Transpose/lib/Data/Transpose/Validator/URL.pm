package Data::Transpose::Validator::URL;

use strict;
use warnings;
use base 'Data::Transpose::Validator::Base';

=head1 NAME

Data::Transpose::Validator::URL - Validate http(s) urls

=head1 SYNOPSIS

=cut


my $urlre = qr/(https?:\/\/)[\w\-\.]+\.(\w+) # domain
	       (:\d+)* # the port
	       (\/[\w:\.,;\?'\\\+&%\$\#=~\@!\-]+)*
	      /x;


=head2 is_valid($url)

Validate the url or set an error

=cut


sub is_valid {
    my ($self, $url) = @_;
    $self->reset_errors;
    if ($url =~ m/^($urlre)$/s) {
        return $1;
    } else {
        $self->error(
                     ["badurl",
                      "URL is not correct (the protocol is required)"]);
        return undef;
    }
}





