package Data::Format::Validate::URL;
our $VERSION = q/0.2/;

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

    $_ = shift || croak q/Value must be provided/;
    /^
        ((https?|ftp):\/\/)?
        [a-z0-9-]+(\.[a-z0-9-]+)+
        ([\/?].*)?
    $/ix
}

sub looks_like_full_url ($) {

    $_ = shift || croak q/Value must be provided/;
    /^
        (https?|ftp):\/\/
        (www|ftp)\.
        [a-z0-9-]+(\.[a-z0-9-]+)+
        ([\/?].*)?
    $/ix
}
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate::URL - A URL validating module.

=head1 SYNOPSIS

Module that validate URL.

=head1 Utilities

=over 4

=item Any URL

    use Data::Format::Validate::URL 'looks_like_any_url';

    looks_like_any_url 'duckduckgo.com';                              # 1
    looks_like_any_url 'www.duckduckgo.com';                          # 1
    looks_like_any_url 'ftp.duckduckgo.com';                          # 1
    looks_like_any_url 'http://duckduckgo.com';                       # 1
    looks_like_any_url 'ftp://www.duckduckgo.com';                    # 1
    looks_like_any_url 'https://www.duckduckgo.com';                  # 1
    looks_like_any_url 'https://www.youtube.com/watch?v=tqgBN44orKs'; # 1

    looks_like_any_url '.com';                                        # 0
    looks_like_any_url 'www. duckduckgo';                             # 0
    looks_like_any_url 'this is not an url';                          # 0
    looks_like_any_url 'perl.com is the best website';                # 0

=item Only full URL

    use Data::Format::Validate::URL 'looks_like_full_url';

    looks_like_full_url 'ftp://www.duckduckgo.com';                 # 1
    looks_like_full_url 'http://www.duckduckgo.com';                # 1
    looks_like_full_url 'https://www.duckduckgo.com';               # 1
    looks_like_full_url 'http://www.duckduckgo.com/search?q=perl';  # 1

    looks_like_full_url 'duckduckgo.com';                           # 0
    looks_like_full_url 'www.duckduckgo.com';                       # 0
    looks_like_full_url 'ftp.duckduckgo.com';                       # 0
    looks_like_full_url 'http://duckduckgo.com';                    # 0
    
=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate/blob/master/lib/Data/Format/Validate/URL.pm

=head1 AUTHOR

Created by Israel Batista <<israel.batista@univem.edu.br>>

=cut