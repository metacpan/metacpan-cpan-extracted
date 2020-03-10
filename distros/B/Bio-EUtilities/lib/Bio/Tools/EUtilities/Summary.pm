package Bio::Tools::EUtilities::Summary;
$Bio::Tools::EUtilities::Summary::VERSION = '1.77';
use utf8;
use strict;
use warnings;
use Bio::Tools::EUtilities::Summary::DocSum;
use base qw(Bio::Tools::EUtilities Bio::Tools::EUtilities::EUtilDataI);

# ABSTRACT: Class for handling data output (XML) from esummary.
# AUTHOR:   Chris Fields <cjfields@bioperl.org>
# OWNER:    2006-2013 Chris Fields
# LICENSE:  Perl_5


# private EUtilDataI method

sub _add_data {
    my ($self, $data) = @_;
    if (!exists $data->{DocSum}) {
        $self->warn('No returned docsums.');
        return;
    }

    my @docs;
    for my $docsum (@{ $data->{DocSum} }) {
        my $ds = Bio::Tools::EUtilities::Summary::DocSum->new(-datatype => 'docsum',
                                                              -verbose => $self->verbose);
        $ds->_add_data($docsum);
        push @{ $self->{'_docsums'} }, $ds;
    }
}


sub to_string {
    my $self = shift;
    my %data = (
        'DB'    => [1, join(', ',$self->get_databases) || ''],
    );
    my $string = $self->SUPER::to_string."\n";
    for my $k (sort {$data{$a}->[0] <=> $data{$b}->[0]} keys %data) {
        $string .= sprintf("%-20s:%s\n\n",$k, $self->_text_wrap('',' 'x 20 .':', $data{$k}->[1]));
    }
    while (my $ds = $self->next_DocSum) {
        $string .= $ds->to_string."\n";
    }
    return $string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tools::EUtilities::Summary - Class for handling data output (XML) from esummary.

=head1 VERSION

version 1.77

=head1 SYNOPSIS

  #### should not create instance directly; Bio::Tools::EUtilities does this ####

  my $esum = Bio::Tools::EUtilities->new(-eutil => 'esummary',
                                         -file => 'summary.xml');
  # can also use '-response' (for HTTP::Response objects) or '-fh' (for filehandles)

  while (my $docsum = $esum->next_DocSum) {
      my $id = $docsum->get_ids;  # EUtilDataI compliant method, returns docsum ID
      my @names = $docsum->get_item_names;
  }

=head1 DESCRIPTION

This class handles data output (XML) from esummary.

esummary retrieves information in the form of document summaries (docsums) when
passed a list of primary IDs or if using a previous search history.

This module breaks down the returned data from esummary into individual document
summaries per ID (using a DocSum object). As the data in a docsum can be nested,
subclasses of DocSums (Item, ListItem, Structure) are also present.

Further documentation for Link and Field subclass methods is included below.

=head2 to_string

 Title    : to_string
 Usage    : $foo->to_string()
 Function : converts current object to string
 Returns  : none
 Args     : (optional) simple data for text formatting
 Note     : Used generally for debugging and for the print_* methods

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org               - General discussion
  https://bioperl.org/Support.html    - About the mailing lists

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

  https://github.com/bioperl/bio-eutilities/issues

=head1 AUTHOR

Chris Fields <cjfields@bioperl.org>

=head1 COPYRIGHT

This software is copyright (c) 2006-2013 by Chris Fields.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
