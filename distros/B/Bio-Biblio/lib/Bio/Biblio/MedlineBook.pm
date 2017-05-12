package Bio::Biblio::MedlineBook;
BEGIN {
  $Bio::Biblio::MedlineBook::AUTHORITY = 'cpan:BIOPERLML';
}
{
  $Bio::Biblio::MedlineBook::VERSION = '1.70';
}
use utf8;
use strict;
use warnings;

use parent qw(Bio::Biblio::Book);

# ABSTRACT: representation of a MEDLINE book
# AUTHOR:   Martin Senger <senger@ebi.ac.uk>
# AUTHOR:   Heikki Lehvaslaiho <heikki@bioperl.org>
# OWNER:    2002 European Bioinformatics Institute
# LICENSE:  Perl_5


#
# a closure with a list of allowed attribute names (these names
# correspond with the allowed 'get' and 'set' methods); each name also
# keep what type the attribute should be (use 'undef' if it is a
# simple scalar)
#
{
    my %_allowed =
        (
         );

    # return 1 if $attr is allowed to be set/get in this class
    sub _accessible {
        my ($self, $attr) = @_;
        exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }

    # return an expected type of given $attr
    sub _attr_type {
        my ($self, $attr) = @_;
        if (exists $_allowed{$attr}) {
            return $_allowed{$attr};
        } else {
            return $self->SUPER::_attr_type ($attr);
        }
    }
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::Biblio::MedlineBook - representation of a MEDLINE book

=head1 VERSION

version 1.70

=head1 SYNOPSIS

    $obj = Bio::Biblio::MedlineBook->new
                  (-editor => Bio::Biblio::Person->new
                             (-lastname => 'Loukides'),
                   -isbn  => '0-596-00068-5');
  #--- OR ---

    $obj = Bio::Biblio::MedlineBook->new();
    $obj->isbn ('0-596-00068-5');

=head1 DESCRIPTION

A storage object for a MEDLINE book.
See its place in the class hierarchy in
http://www.ebi.ac.uk/~senger/openbqs/images/bibobjects_perl.gif

=head2 Attributes

There are no specific attributes in this class
(however, you can set and get all attributes defined in the parent classes).
The main raison d'etre of this class is to be associated with MEDLINE book articles.

=head1 SEE ALSO

=over 4

=item *

OpenBQS home page

http://www.ebi.ac.uk/~senger/openbqs/

=item *

Comments to the Perl client

http://www.ebi.ac.uk/~senger/openbqs/Client_perl.html
=back

=back

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://redmine.open-bio.org/projects/bioperl/

=head1 LEGAL

=head2 Authors

Martin Senger <senger@ebi.ac.uk>

Heikki Lehvaslaiho <heikki@bioperl.org>

=head2 Copyright and License

This software is Copyright (c) by 2002 European Bioinformatics Institute and released under the license of the same terms as the perl 5 programming language system itself

=cut

