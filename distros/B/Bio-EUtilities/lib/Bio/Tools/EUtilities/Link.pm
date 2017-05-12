package Bio::Tools::EUtilities::Link;
our $AUTHORITY = 'cpan:BIOPERLML';
$Bio::Tools::EUtilities::Link::VERSION = '1.75';
use utf8;
use strict;
use warnings;
use base qw(Bio::Tools::EUtilities Bio::Tools::EUtilities::EUtilDataI);
use Bio::Tools::EUtilities::Link::LinkSet;

# ABSTRACT: General API for accessing data retrieved from elink queries.
# AUTHOR:   Chris Fields <cjfields@bioperl.org>
# OWNER:    2006-2013 Chris Fields
# LICENSE:  Perl_5



# private EUtilDataI method

{
    my %SUBCLASS = (
                    'LinkSetDb' => 'dblink',
                    'LinkSetDbHistory' => 'history',
                    'IdUrlList' => 'urllink',
                    'IdCheckList' => 'idcheck',
                    'NoLinks' => 'nolinks',
                    );

sub _add_data {
    my ($self, $data) = @_;
    # divide up per linkset
    if (!exists $data->{LinkSet}) {
        $self->warn("No linksets returned");
        return;
    }
    for my $ls (@{ $data->{LinkSet} }) {
        my $subclass;
        # attempt to catch linkset errors
        if (exists $ls->{ERROR}) {
            my ($error, $dbfrom) = ($ls->{ERROR},$ls->{DbFrom});
            $self->warn("NCBI LinkSet error: $dbfrom: $error\n");
            # try to save the rest of the data, if any
            next;
        }
        # caching for efficiency; no need to recheck
        if (!exists $self->{'_subclass_type'}) {
            ($subclass) = grep { exists $ls->{$_} } qw(LinkSetDb LinkSetDbHistory IdUrlList IdCheckList);
            $subclass ||= 'NoLinks';
            $self->{'_subclass_type'} = $subclass;
        } else {
            $subclass = $self->{'_subclass_type'};
        }
        # split these up by ID, since using correspondence() clobbers them...
        if ($subclass eq 'IdUrlList' || $subclass eq 'IdCheckList') {
            my $list = $subclass eq 'IdUrlList' ? 'IdUrlSet' :
                $subclass eq 'IdCheckList' && exists $ls->{$subclass}->{IdLinkSet} ? 'IdLinkSet' :
                'Id';
            $ls->{$subclass} = $ls->{$subclass}->{$list};
        }
        # divide up linkset per link
        for my $ls_sub (@{ $ls->{$subclass} }) {
            for my $key (qw(WebEnv DbFrom IdList)) {
                $ls_sub->{$key} = $ls->{$key} if exists $ls->{$key};
            }
            my $obj = Bio::Tools::EUtilities::Link::LinkSet->new(-eutil => 'elink',
                                                    -datatype => $SUBCLASS{$subclass},
                                                    -verbose => $self->verbose);
            $obj->_add_data($ls_sub);
            push @{$self->{'_linksets'}}, $obj;
            # push only potential history-carrying objects into history queue
            if ($subclass eq 'LinkSetDbHistory') {
                push @{$self->{'_histories'}}, $obj;
            }
        }
    }
}

}


sub to_string {
    my $self = shift;
    my $string = $self->SUPER::to_string;
    while (my $ls = $self->next_LinkSet) {
        $string .= $ls->to_string;
    }
    return $string;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::Tools::EUtilities::Link - General API for accessing data retrieved from elink queries.

=head1 VERSION

version 1.75

=head1 SYNOPSIS

  ...TODO

=head1 DESCRIPTION

Bio::Tools::EUtilities::Link is a loadable plugin for Bio::Tools::EUtilities
that specifically handles NCBI elink-related data.

=head2 to_string

 Title    : to_string
 Usage    : $foo->to_string()
 Function : converts current object to string
 Returns  : none
 Args     : (optional) simple data for text formatting
 Note     : Used generally for debugging and for various print methods

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

  https://github.com/bioperl/%%7Bdist%7D

=head1 AUTHOR

Chris Fields <cjfields@bioperl.org>

=head1 COPYRIGHT

This software is copyright (c) 2006-2013 by Chris Fields.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
