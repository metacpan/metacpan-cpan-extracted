package CGI::Deurl::XS;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw/parse_query_string/;
our @EXPORT = qw();

our $VERSION = '0.08';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&CGI::Deurl::XS::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        # Fixed between 5.005_53 and 5.005_61
#XXX        if ($] >= 5.00561) {
#XXX            *$AUTOLOAD = sub () { $val };
#XXX        }
#XXX        else {
            *$AUTOLOAD = sub { $val };
#XXX        }
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('CGI::Deurl::XS', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

CGI::Deurl::XS - Fast decoder for URL parameter strings

=head1 SYNOPSIS

  use CGI::Deurl::XS 'parse_query_string';

  my $hash = parse_query_string('foo=bar&baz=quux&baz=qiix');
  # $hash = { 'foo' => 'bar', 'baz' => ['quux', 'qiix'] };

=head1 DESCRIPTION

This module decodes a URL-encoded parameter string in the manner of CGI.pm.
However, as it uses C code from libapreq to perform the task, it's somewhere
from slightly to much faster (depending on your strings) than using L<CGI> or a
functionally similar module like L<CGI::Deurl>.

=head1 FUNCTIONS

=over 4

=item parse_query_string()

  $hash_ref = CGI::Deurl::XS::parse_query_string($query_string)

Parses the given query string. If the string is empty, returns undef. Otherwise
returns a hash reference containing the key/value pairs encoded by the string.
Empty values are returned as undef. If a parameter appears only once, it's
value in the hash is the scalar value of the encoded parameter value. If a
parameter appears more than once, the hash value is an array reference
containing each value given (with value order preserved). Obviously, parameter
order is not preserved in the hash.

HTTP escapes (ASCII and Unicode) are decoded in both keys and values. The utf8
flag is not set on returned strings, nor are non-utf8 encodings decoded.

=back

=head1 EXPORT

None by default, parse_query_string at request.

=head1 SEE ALSO

L<CGI>

L<libapreq>

=head1 AUTHOR

Adam Thomason, E<lt>athomason@sixapart.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Six Apart Ltd <cpan@sixapart.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
