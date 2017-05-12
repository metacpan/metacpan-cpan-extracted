
###############################################################################
##                                                                           ##
##    Copyright (c) 2009 by Steffen Beyer.                                   ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Bundle::STBEY::Favourites;

use strict;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();

@EXPORT_OK = qw();

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.2';

sub Version { return $VERSION; }

1;

__END__

=pod

=head1 NAME

Bundle::STBEY::Favourites - a Bundle of my favourite modules

=head1 DESCRIPTION

This module only serves the purpose of automatically
installing the following modules as "prerequisites"
when this module is installed with "CPAN" or "CPANPLUS":

=head1 CONTENTS

YAML              0.70
Carp::Clan        6.04
Storable          2.21
Bit::Vector       7.1
Date::Calc        6.2
Date::Calc::XS    6.2
Date::Calc::Util  1.0
Data::Locations   5.5
Math::MatrixBool  5.8
Set::IntRange     5.2
Scalar::Util
V
Bundle::libwin32
Bundle::CPAN
CPAN::Reporter
Bundle::libnet
Bundle::LWP
Parse::RecDescent
Digest::MD5
Digest::SHA1
Unicode::String
IO::Stringy
MIME::Parser
Getopt::Long
MIME::Base64
MIME::Tools
Time::HiRes
HTML::Parser
MIME::Lite

=head1 VERSION

This man page documents "Bundle::STBEY::Favourites" version 1.2.

=head1 AUTHOR

  Steffen Beyer
  mailto:STBEY@cpan.org
  http://www.engelschall.com/u/sb/download/

=head1 COPYRIGHT

Copyright (c) 2009 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

