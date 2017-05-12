package Bundle::WormBase;

$VERSION = '0.001';

1;

__END__

=head1 NAME

Bundle::WormBase - Prerequisites for a WormBase installation

=head1 SYNOPSIS

perl -MCPAN -e 'install Bundle::WormBase'

=head1 CONTENTS

Ace 1.87

Bio::Das

Bio::GMOD

Bundle::BioPerl

CGI 3.00

CGI::Cache

Cache::Filecache

GD 1.19             - 2.07?

GD::SVG

IO::Scalar

IO::String

DBI

DBD::mysql

Digest::MD5

LWP

Math::Derivative

Math::Spline

Net::FTP

Statistics::Descriptive

Statistics::OLS

Storable

SVG

SVG::Graph

Tree::DAG_Node

Text::Shellwords

XML::DOM

XML::Parser

XML::Twig

XML::Writer

=head1 DESCRIPTION

WormBase (http://www.wormbase.org/) is the online 
database for the model organism C. elegans and 
related nematodes.  This bundle contains the minimum
required Perl modules for running a local installation
of WormBase.

=head1 AUTHOR

Todd Harris (harris@cshl.edu)

=head1 LICENSE

This bundle is distributed under the same license as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
