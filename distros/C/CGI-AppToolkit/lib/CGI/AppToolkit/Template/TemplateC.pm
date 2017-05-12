package CGI::AppToolkit::Template::TemplateC;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
$VERSION = '0.01';

bootstrap CGI::AppToolkit::Template::TemplateC $VERSION;

1;

__DATA__

=head1 DESCRIPTION

This is the perl sub for the C++ guts of C<CGI::AppToolkit::Template>.

=cut