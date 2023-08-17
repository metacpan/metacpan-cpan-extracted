# ABSTRACT Get the openssl Configured API level if it is defined
package Crypt::OpenSSL::ConfiguredAPI;

use 5.014;
use strict;
use warnings;

require Exporter;

our $VERSION  = "0.03";

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

require XSLoader;
XSLoader::load('Crypt::OpenSSL::ConfiguredAPI', $VERSION);

1;
__END__

=head1 NAME

Crypt::OpenSSL::ConfiguredAPI - Get the Configured API level if it is defined

=head1 SYNOPSIS

  use Crypt::OpenSSL::ConfiguredAPI;

  my $api = Crypt::OpenSSL::ConfiguredAPI->get_configured_api()

=head1 DESCRIPTION

Some OpenSSL versions allows you to specify the configured api level.  This
module simply checks whether OPENSSL_CONFIGURED_API is defined and returns that
value.

=head1 METHODS

=head2 get_configured_api()

Returns the value of the OPENSSL_CONFIGURED_API if it is defined or 0 if it is undefined

Arguments:

None

=head1 SEE ALSO

Crypt::OpenSSL::Guess allows you to guess the version of openssl installed

=head1 AUTHOR

Timothy Legge, E<lt>timlegge@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2023 by Timothy Legge

=head1 LICENSE

Licensed under the Apache License 2.0 (the "License").  You may not use
this file except in compliance with the License.  You can obtain a copy
in the file LICENSE in the source distribution or at
https://www.openssl.org/source/license.html

=cut
