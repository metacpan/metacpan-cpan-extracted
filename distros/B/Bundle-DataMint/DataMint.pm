package Bundle::DataMint;

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
	
);
our $VERSION = '1.02';

1;
__END__

=head1 NAME

Bundle::DataMint - A bundle to install external CPAN modules for Data Mining and
Data Integration

=head1 SYNOPSIS

Perl one liner using CPAN.pm:

  perl -MCPAN -e 'install Bundle::DataMint'

Use of CPAN.pm in interactive mode:

  $> perl -MCPAN -e shell
  cpan> install Bundle::DataMint
  cpan> quit

Just like the manual installation of perl modules, the user may
need root access during this process to insure write permission 
is allowed within the intstallation directory.

=head1 CONTENTS

CGI

Cwd

DBD::mysql

DBI

Data::Dumper

Digest::MD5

FileHandle

HTML::LinkExtor

HTTP::Status

IO

IO::Dir

IO::Handle

IO::Select

LWP::Simple

LWP::UserAgent

MIME::Lite

Parallel::ForkManager

SOAP::Lite

Storable

Text::ParseWords

Text::Soundex

Time::Local

UDDI::Lite

XML::Node

XML::Parser

XML::Twig

XML::Writer

=head1 DESCRIPTION

This Bundle contains makes easy the installation of
several CPAN modules, building a basic
toolset for Data Mining and Data Integration.

=head1 AUTHOR

Jaime Prilusky<lt>F<jaime.prilusky@weizmann.ac.il>E<gt>
(Author only of this bundle, not any the modules it lists)

=head1 SEE ALSO

perl(1).

=cut
