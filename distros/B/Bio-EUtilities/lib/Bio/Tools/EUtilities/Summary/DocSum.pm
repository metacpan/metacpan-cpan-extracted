package Bio::Tools::EUtilities::Summary::DocSum;
our $AUTHORITY = 'cpan:BIOPERLML';
$Bio::Tools::EUtilities::Summary::DocSum::VERSION = '1.75';
use utf8;
use strict;
use warnings;
use base qw(Bio::Root::Root Bio::Tools::EUtilities::Summary::ItemContainerI);
use Bio::Tools::EUtilities::Summary::Item;

# ABSTRACT: Data object for document summary data from esummary.
# AUTHOR:   Chris Fields <cjfields@bioperl.org>
# OWNER:    2006-2013 Chris Fields
# LICENSE:  Perl_5



sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    my ($type) = $self->_rearrange(['DATATYPE'],@args);
    $type ||= 'docsum';
    $self->eutil('esummary');
    $self->datatype($type);
    return $self;
}


sub get_ids {
    my $self = shift;
    return wantarray ? $self->{'_id'} : [$self->{'_id'}];
}


sub get_id {
    my $self = shift;
    return $self->{'_id'};
}










sub rewind {
    my ($self, $request) = @_;
    if ($request && $request eq 'all') {
        map {$_->rewind('all') } $self->get_Items;
    }
    delete $self->{"_items_it"};
}

# private EUtilDataI method

sub _add_data {
    my ($self, $data) = @_;
    if ($data->{Item}) {
        $self->{'_id'} = $data->{Id} if exists $data->{Id};
        for my $sd (@{ $data->{Item} } ) {
            $sd->{Id} = $data->{Id} if exists $data->{Id};
            my $subdoc =
                Bio::Tools::EUtilities::Summary::Item->new(-datatype => 'item',
                                                  -verbose => $self->verbose);
            $subdoc->_add_data($sd);
            push @{ $self->{'_items'} }, $subdoc;
        }
    }
    $self->{'_id'} = $data->{Id} if exists $data->{Id};
}


sub to_string {
    my $self = shift;
    my $string = sprintf("%-20s%s\n",'UID', ':'.$self->get_id);
    while (my $item = $self->next_Item)  {
        $string .= $item->to_string;
    }
    return $string;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::Tools::EUtilities::Summary::DocSum - Data object for document summary data from esummary.

=head1 VERSION

version 1.75

=head1 SYNOPSIS

  # Implement ItemContainerI

  # $foo is any ItemContainerI (current implementations are DocSum and Item itself)

  while (my $item = $foo->next_Item) { # iterate through contained Items
     # do stuff here
  }

  @items = $foo->get_Items;  # all Items in the container (hierarchy intact)
  @items = $foo->get_all_Items;  # all Items in the container (flattened)
  @items = $foo->get_Items_by_name('bar'); # Specifically named Items
  ($content) = $foo->get_contents_by_name('bar'); # content from specific Items
  ($type) = $foo->get_type_by_name('bar'); # data type from specific Items

=head1 DESCRIPTION

This is the basic class for Document Summary data from NCBI eUtils, returned
from esummary.  This implements the simple ItemContainerI interface.

=head2 new

 Title    : new
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_ids

 Title    : get_ids
 Usage    : my ($id) = $item->get_ids;
 Function : returns array or array ref with id
 Returns  : array or array ref
 Args     : none
 Note     : the behavior of this method remains consistent with other
            implementations of get_ids(). To retrieve the single DocSum ID
            use get_id()

=head2 get_id

 Title    : get_id
 Usage    : my ($id) = $item->get_id;
 Function : returns UID of record
 Returns  : integer
 Args     : none

=head1 ItemContainerI methods

=head2 next_Item

 Title    : next_Item
 Usage    : while (my $item = $docsum->next_Item) {...}
 Function : iterates through Items (nested layer of Item)
 Returns  : single Item
 Args     : [optional] single arg (string)
            'flatten' - iterates through a flattened list ala
                          get_all_DocSum_Items()

=head2 get_Items

 Title    : get_Items
 Usage    : my @items = $docsum->get_Items
 Function : returns list of, well, Items
 Returns  : array of Items
 Args     : none

=head2 get_all_Items

 Title    : get_all_Items
 Usage    : my @items = $docsum->get_all_Items
 Function : returns flattened list of all Item objects (Items, ListItems,
            StructureItems)
 Returns  : array of Items
 Args     : none
 Note     : items are added top-down (similar order to using nested calls)
            in original list order.

             1         2        7        8
           Item  -   Item  -  Item  -  Item ...
                     |
                    | 3        6
                 ListItem - ListItem
                   |
                  | 4          5
               Structure - Structure

=head2 get_all_names

 Title    : get_all_names
 Usage    : my @names = get_all_names()
 Function : Returns an array of names for all Item(s) in DocSum.
 Returns  : array of unique strings
 Args     : none

=head2 get_Items_by_name

 Title    : get_Items_by_name
 Usage    : my @items = get_Items_by_name('CreateDate')
 Function : Returns named Item(s) in DocSum (indicated by passed argument)
 Returns  : array of Item objects
 Args     : string (Item name)

=head2 get_contents_by_name

 Title    : get_contents_by_name
 Usage    : my ($data) = get_contents_by_name('CreateDate')
 Function : Returns content for named Item(s) in DocSum (indicated by
            passed argument)
 Returns  : array of values (type varies per Item)
 Args     : string (Item name)

=head2 get_type_by_name

 Title    : get_type_by_name
 Usage    : my $data = get_type_by_name('CreateDate')
 Function : Returns data type for named Item in DocSum (indicated by
            passed argument)
 Returns  : scalar value (string) if present
 Args     : string (Item name)

=head2 rewind

 Title    : rewind
 Usage    : $docsum->rewind();
 Function : rewinds DocSum iterator
 Returns  : none
 Args     : [optional]
           'recursive' - rewind all DocSum object layers
                         (Items, ListItems, StructureItems)

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
