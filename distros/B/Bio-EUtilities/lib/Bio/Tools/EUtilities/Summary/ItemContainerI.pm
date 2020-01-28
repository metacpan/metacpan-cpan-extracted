package Bio::Tools::EUtilities::Summary::ItemContainerI;
$Bio::Tools::EUtilities::Summary::ItemContainerI::VERSION = '1.76';
use utf8;
use strict;
use warnings;
use base qw(Bio::Tools::EUtilities::EUtilDataI);

# ABSTRACT: Abtract interface methods for accessing Item information from any Item-containing class. This pertains to either DocSums or to Items themselves (which can be layered).
# AUTHOR:   Chris Fields <cjfields@bioperl.org>
# OWNER:    2006-2013 Chris Fields
# LICENSE:  Perl_5



sub next_Item {
    my ($self, $request) = @_;
    unless ($self->{"_items_it"}) {
        my @items = ($request && $request eq 'flatten') ?
                    $self->get_all_Items :
                    $self->get_Items ;
        $self->{"_items_it"} = sub {return shift @items}
    }
    $self->{'_items_it'}->();
}


sub get_Items {
    my $self = shift;
    return ref $self->{'_items'} ? @{ $self->{'_items'} } : return ();
}


sub get_all_Items {
    my $self = shift;
    unless ($self->{'_ordered_items'}) {
        for my $item ($self->get_Items) {
            push @{$self->{'_ordered_items'}}, $item;
            for my $ls ($item->get_ListItems) {
                push @{$self->{'_ordered_items'}}, $ls;
                for my $st ($ls->get_StructureItems) {
                    push @{$self->{'_ordered_items'}}, $st;
                }
            }
        }
    }
    return @{$self->{'_ordered_items'}};
}


sub get_all_names {
    my ($self) = @_;
    my %tmp;
    my @data = grep {!$tmp{$_}++}
        map {$_->get_name} $self->get_all_Items;
    return @data;
}


sub get_Items_by_name {
    my ($self, $key) = @_;
    return unless $key;
    my @data = grep {$_->get_name eq $key}
        $self->get_all_Items;
    return @data;
}


sub get_contents_by_name {
    my ($self, $key) = @_;
    return unless $key;
    my @data = map {$_->get_content}
        grep {$_->get_name eq $key}
        $self->get_all_Items;
    return @data;
}


sub get_type_by_name {
    my ($self, $key) = @_;
    return unless $key;
    my ($it) = grep {$_->get_name eq $key} $self->get_all_Items;
    return $it->get_type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tools::EUtilities::Summary::ItemContainerI - Abtract interface methods for accessing Item information from any Item-containing class. This pertains to either DocSums or to Items themselves (which can be layered).

=head1 VERSION

version 1.76

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

DocSum data, as returned from esummary, normally is a simple list of
item-content-content_type groups. However, items can also contain nested data to
represent more complex data (such as structural data). This interface describes
the basic methods to generically retrieve the next layer of Item data. For
convenience classes may describe more specific methods, but they should be
defined in terms of this interface and it's methods.

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
 Usage    : my ($data) = $eutil->get_contents_by_name('CreateDate')
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
