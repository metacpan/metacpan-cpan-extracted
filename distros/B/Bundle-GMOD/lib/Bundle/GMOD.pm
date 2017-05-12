package Bundle::GMOD;

our $VERSION = '1.0';

1;

#

__END__

=head1 NAME

Bundle::GMOD - Prerequisites for GMOD applications

=head1 SYNOPSIS

 C<perl -MCPAN -e 'install Bundle::GMOD'>

=head1 CONTENTS

URI::Escape
Pod::Usage
Config::General
DBI                     - gbrowse, chado
DBD::Pg                 - gbrowse, chado
Digest::MD5
Module::Build           - chado (installation only)
Class::DBI              - chado
Class::DBI::Pg          - chado
Class::DBI::Pager       - chado
Class::DBI::View        - chado
XML::Simple             - chado (installation only?)
LWP                     - chado (installation only)
Template                - chado
Log::Log4perl           - chado
XML::Parser::PerlSAX	- XORT, Apollo
XML::DOM		- XORT, Apollo
File::Path
Text::Tabs
File::Spec
XML::Writer             - SOI
Graph                   - Chaos
DBIx::DBStag            - chado, ontology loader
GO::Parser              - chado, ontology loader
XML::LibXSLT            - chaos
Ima::DBI                - SGN ontology loader
Class::MethodMaker      - SGN ontology loader
URI                     - SGN ontology loader
LWP::Simple             - SGN ontology loader
XML::Twig               - SGN ontology loader
Tie::UrlEncoder         - SGN ontology loader
HTML::TreeBuilder       - SGN ontology loader
Time::HiRes             - SGN ontology loader
File::NFSLock           - SGN ontology loader
Class::Data::Inheritable - SGN ontology loader
IO::Dir                 - chado install util
Text::Wrap              - snp2gff?



=head1 DESCRIPTION

The Generic Model Organism Database (GMOD) project (http://www.gmod.org) is
a collection of software for running a model organism database.  This bundle
is the minimum required for getting the schema installed in a PostgreSQL
database and running the Generic Genome Browser (http://www.gmod.org/ggb)
on it.  Other modules may be required for other components of GMOD.

=head1 AUTHOR

Scott Cain scain@cpan.org

=head1 LINCENSE

This bundle is distributed under the same license as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
