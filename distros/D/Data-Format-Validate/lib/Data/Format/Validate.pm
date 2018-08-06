package Data::Format::Validate;
our $VERSION = q/0.3/;
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate - A data validating module.

=head1 SYNOPSIS

Module that validate data like URL and IP addresses.

=head1 UTILITIES

=over 4

=item Any E-mail

    use Data::Format::Validate::Email 'looks_like_any_email';

    looks_like_any_email 'rozcovo@cpan.org';    # returns 1
    looks_like_any_email 'rozcovo@cpan. org';   # returns 0

=item Common E-mail

    use Data::Format::Validate::Email 'looks_like_common_email';

    looks_like_common_email 'rozcovo@cpan.org';     # returns 1
    looks_like_common_email 'rozcovo.@cpan.org';    # returns 0

=item IP (ipv4)

    use Data::Format::Validate::IP 'looks_like_ipv4';

    looks_like_ipv4 '127.0.0.1';    # returns 1
    looks_like_ipv4 '255255255255'; # returns 0

=item IP (ipv6)

    use Data::Format::Validate::IP 'looks_like_ipv6';

    looks_like_ipv6 '1762:0:0:0:0:B03:1:AF18';  # returns 1
    looks_like_ipv6 '17620000AFFFB031AF187';    # returns 0

=item Any URL

    use Data::Format::Validate::URL 'looks_like_any_url';

    looks_like_any_url 'duckduckgo.com';    # returns 1
    looks_like_any_url 'www. duckduckgo';   # returns 0

=item Only full URL

    use Data::Format::Validate::URL 'looks_like_full_url';

    looks_like_full_url 'http://www.duckduckgo.com/search?q=perl';  # returns 1
    looks_like_full_url 'http://duckduckgo.com';                    # returns 0

=item URN

    use Data::Format::Validate::URN 'looks_like_urn';

    looks_like_urn 'urn:oid:2.16.840';          # returns 1
    looks_like_urn 'This is not a valid URN';   # returns 0
    
=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate

=head1 AUTHOR

Created by Israel Batista <rozcovo@cpan.org>

=cut
