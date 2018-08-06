package Data::Format::Validate::URL;
our $VERSION = q/0.3/;

use Carp;
use base q/Exporter/;

our @EXPORT_OK = qw/
    looks_like_any_url
    looks_like_full_url
/;

our %EXPORT_TAGS = (
    q/all/ => [qw/
        looks_like_any_url
        looks_like_full_url
    /]
);

sub looks_like_any_url ($) {

    my $url = shift || croak q/Value must be provided/;
    $url =~ /^
        ((https?|ftp):\/\/)?        # Protocol (optional)
        [a-z0-9-]+(\.[a-z0-9-]+)+   # URL name (with optional hostname)
        ([\/?].*)?                  # URL path & params (both optional)
    $/ix
}

sub looks_like_full_url ($) {

    my $url = shift || croak q/Value must be provided/;
    $url =~ /^
        (https?|ftp):\/\/           # Protocol
        (www|ftp)\.                 # Hostname
        [a-z0-9-]+(\.[a-z0-9-]+)+   # URL name
        ([\/?].*)?                  # URL path & params (both optional)
    $/ix
}
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate::URL - A URL validating module.

=head1 SYNOPSIS

Function-oriented module capable of validating:
- Any URL with name, with or without protocol, hostname, path or params
- Full URL, with protocol, hostname and name, with or without path or params

=head1 UTILITIES

=over 4

=item Any URL

    use Data::Format::Validate::URL 'looks_like_any_url';

    looks_like_any_url 'duckduckgo.com';    # returns 1
    looks_like_any_url 'www. duckduckgo';   # returns 0

=item Only full URL

    use Data::Format::Validate::URL 'looks_like_full_url';

    looks_like_full_url 'http://www.duckduckgo.com/search?q=perl';  # returns 1
    looks_like_full_url 'http://duckduckgo.com';                    # returns 0
    
=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate/blob/master/lib/Data/Format/Validate/URL.pm

=head1 AUTHOR

Created by Israel Batista <rozcovo@cpan.org>

=cut