##----------------------------------------------------------------------------
## DateTime Format Lite - ~/lib/DateTime/Format/Lite/PP.pm
## Version v0.1.0
## Copyright(c) 1 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/15
## Modified 2026/04/15
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# Pure-Perl fallback for the DateTime::Format::Lite XS layer.
# Loaded automatically by DateTime::Format::Lite when XSLoader fails, such as
# during development or on platforms without a C compiler, or when the
# PERL_DATETIME_FORMAT_LITE_PP environment variable is set to a true value.
#
# The two functions that are otherwise provided by XS:
#
#   _match_and_extract( self, regex, fields_aref, string )
#   format_datetime( self, dt )
#
# both have their pure-Perl equivalents inline in DateTime::Format::Lite (guarded by
# the $IsPurePerl flag), so this module's sole responsibility is to ensure that
# $IsPurePerl is set to 1 so those paths are taken.
# Nothing needs to be injected into the DateTime::Format::Lite namespace.
##----------------------------------------------------------------------------
package DateTime::Format::Lite::PP;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

$DateTime::Format::Lite::IsPurePerl = 1;

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DateTime::Format::Lite::PP - Pure-Perl fallback for the DateTime::Format::Lite XS layer

=head1 DESCRIPTION

This module is loaded automatically by L<DateTime::Format::Lite> when the XS shared object cannot be loaded. For instance when the distribution was installed without a C compiler, or when the C<PERL_DATETIME_FORMAT_LITE_PP> environment variable is set to a true value.

Its sole responsibility is to set C<$DateTime::Format::Lite::IsPurePerl> to C<1>. The two functions that are otherwise provided by XS, C<_match_and_extract> and C<format_datetime>, both have pure-Perl equivalents already present inline in L<DateTime::Format::Lite>, guarded by the C<$IsPurePerl> flag. No injection into the C<DateTime::Format::Lite> namespace is required.

You should not normally load or call this module directly.

=head1 VERSION

    v0.1.0

=head1 SEE ALSO

L<DateTime::Format::Lite>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
