package Acme::Jungle::CrawlerExample;
use Moose;
use Jungle;
our $VERSION     = '0.01';

has spider => (
    is => 'ro',
    isa => 'Jungle',
    default => sub { 
        return Jungle->new;
    },
); 



#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

CrawlerTest - crawler test using Jungle

=head1 SYNOPSIS

  use CrawlerTest;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    A. U. Thor
    CPAN ID: MODAUTHOR
    XYZ Corp.
    a.u.thor@a.galaxy.far.far.away
    http://a.galaxy.far.far.away/modules

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

