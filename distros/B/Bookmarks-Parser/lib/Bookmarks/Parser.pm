package Bookmarks::Parser;

use strict;
use warnings;

use Bookmarks::Netscape;
use Bookmarks::Opera;
use Bookmarks::XML;
use Bookmarks::Delicious;
use Bookmarks::A9;

use Carp 'croak';
use Storable 'dclone';

our $VERSION = '0.08';

sub new {
    my ($class, %opts) = @_;
    %opts = _check_options(%opts);

    $class = ref $class || $class;
    my $self = bless({%opts}, $class);
    $self->{_nextid}   = 1;
    $self->{_title}    = '';
    $self->{_items}    = { root => { name => 'root', url => '' } };
    $self->{_itemlist} = [];
    return $self;
}

sub _check_options {
    my %opts = @_;
    return %opts;
}

sub parse {
    my ($self, $args) = @_;

    croak "Parse can't be called as a class method" unless ref $self;
    croak "Arguments must be a hashref"             unless ref $args;

    my ($filename, $url, $user, $passwd)
        = @$args{ 'filename', 'url', 'user', 'passwd' };

    if ($filename =~ m/\.zip$/) {
        bless $self, 'Bookmarks::Explorer';
        $self->new();
        $self->_parse_file($filename);
    }
    elsif ($filename) {
        croak "No such file $filename" if (!-e $filename);

        my $fh;
        open $fh, "<$filename" or croak "Can't open $filename ($!)";
        my $firstline = <$fh>;
        close($fh);

        if ($firstline =~ /Opera/) {
            bless $self, 'Bookmarks::Opera';
            $self->new();
            $self->_parse_file($filename);
        }
        elsif ($firstline =~ /Netscape/i) {
            bless $self, 'Bookmarks::Netscape';
            $self->new();
            $self->_parse_file($filename);
        }
        else {
            croak('Unable to detect bookmark format(' . $firstline . ')');
        }
    }
    elsif ($url) {
        if ($url =~ /a9.com/) {
            bless $self, 'Bookmarks::A9';
            $self->new();
            $self->_parse_bookmarks($user, $passwd);
        }
        elsif ($url =~ /del.icio.us/) {
            bless $self, 'Bookmarks::Delicious';
            $self->new();
            $self->_parse_bookmarks($user, $passwd);
        }
    }
    else {
        croak "Nothing to parse!";
    }

    return $self;
}

sub set_title {
    my ($self, $title) = @_;

    $self->{_title} = $title;
}

sub add_bookmark {
    my ($self, $item, $parent) = @_;

    $parent = ref($parent) ? $parent->{id} : $parent;
    $parent ||= 'root';
    $item->{parent} ||= $parent;
    $self->{_nextid}++ while (defined $self->{_items}{ $self->{_nextid} });
    $item->{id}   ||= $self->{_nextid};
    $item->{url}  ||= '';
    $item->{name} ||= $item->{url};
    if (!$item->{url} && !$item->{name}) {
        warn 'No URL or NAME for this bookmark !?';
        return undef;
    }

    # check time formatting!

    if (!$self->{_items}{ $item->{id} }) {
        push @{ $self->{_itemslist} }, $item->{id};
        $self->{_items}{ $item->{id} } = $item;
    }
    push @{ $self->{_items}{ $item->{parent} }{children} }, $item->{id};

    return $item;
}

sub get_from_id {
    my ($self, $id) = @_;

    return $id if (ref($id));

    return $self->{_items}{$id};
}

sub get_path_of {
    my ($self, $item) = @_;

    $item = $self->{_items}{$item} if (!ref($item));

    my $path = '';

    while (my $p = $item->{parent}) {
        $item = $self->get_from_id($p);
        $path = $item->{name} . "/$path";
    }

    return $path;
}

sub as_opera {
    my ($self) = @_;

    my $newobj = dclone($self);
    bless $newobj, 'Bookmarks::Opera';

    return $newobj;
}

sub as_netscape {
    my ($self) = @_;

    my $newobj = dclone($self);
    bless $newobj, 'Bookmarks::Netscape';

    return $newobj;
}

sub as_xml {
    my ($self) = @_;

    my $newobj = dclone($self);
    bless $newobj, 'Bookmarks::XML';

    return $newobj;
}

sub as_a9 {
    my ($self) = @_;

    my $newobj = dclone($self);
    bless $newobj, 'Bookmarks::A9';

    return $newobj;

}

# Output to a file again
sub write_file {
    my ($self, $args) = @_;

    my $filename = $args->{filename};

    if (!$filename || -e $filename) {
        warn "No filename or $filename already exists!";
        return;
    }

    my $type = $args->{type};
    if (defined $type && $type ne "") {
        my $alias_method = "as_$type";
        if (!$self->can($alias_method)) {
            croak "No $alias_method method available!";
        }
        $self = $self->$alias_method();
    }

    open my $outfile, ">$filename"
        or croak "Can't open $filename for writing ($!)";
    binmode($outfile, ':utf8');
    print $outfile $self->as_string();
    close $outfile;

}

# Represent content as text (should reproduce original)
sub as_string {
    my ($self) = @_;

    my $output = '';
    $output .= $self->get_header_as_string();
    foreach (@{ $self->{_items}{root}{children} }) {
        $output .= $self->get_item_as_string($self->{_items}{$_});
    }
    $output .= $self->get_footer_as_string();

    return $output;
}

# Get file header if applicable
sub get_header_as_string {
    my ($self) = @_;

    return '';
}

# Get footer if applicable
sub get_footer_as_string {
    my ($self) = @_;

    return '';
}

# Write contents to a url, eg A9
# Replace/update param?
sub write_url {
    croak "write_url not Implemented";
}

# Return a list of all root items
sub get_top_level {
    my ($self) = @_;

    my @root_items
        = map { $self->{_items}{$_} } @{ $self->{_items}{root}{children} };

    return @root_items;
}

# Change/set the list of root items
sub set_top_level {
    my ($self, @items) = @_;

    if (exists $self->{_items}{root} && $self->{_items}{root}{children}) {
        warn
            "Root items already exist, use clear to empty or rename to rename an item!";
        return;
    }

    $self->{_items}{root}{children} = [];
    foreach my $root (@items) {
        my $newitem = {
            id       => $self->{_nextid}++,
            name     => $root,
            type     => 'folder',
            created  => time(),
            expanded => undef,
            parent   => 'root',
            children => []
        };
        unshift(@{ $self->{_itemlist} }, $newitem->{id});
        push(@{ $self->{_items}{root}{children} }, $newitem->{id});
        $self->{_items}{ $newitem->{id} } = $newitem;
    }

}

# rename an item
sub rename {
    my ($self, $item, $newname) = @_;

    if (!defined $item->{id} || !$self->{_items}{ $item->{id} }) {
        warn "You didn't pass in a valid item!";
        return;
    }

    $self->{_items}{ $item->{id} }{name} = $newname;

    return $self->{_items}{ $item->{id} }{name};
}

# Return a list of items under the given folder
sub get_folder_contents {
    my ($self, $folder) = @_;

    return () if ($folder->{type} ne 'folder');
    my @items = map { $self->{_items}{$_} } @{ $folder->{children} };

    return @items;
}

# Find bookmarks or folders
sub find_items {
    my ($self, $args) = @_;

    if (!$args->{name} && !$args->{url}) {
        warn "No name or url parameter passed";
        return 0;
    }

    $args->{name} ||= '';
    $args->{url}  ||= '';

    my @matches = grep {
               ($args->{name} && $_->{name} =~ /$args->{name}/)
            || ($args->{url} && $_->{url} =~ /$args->{url}/)
    } values %{ $self->{_items} };
    return @matches;
}

# Merge the items in a 2nd bookmarks object into this one
sub merge {
    my ($self, $import, $ifolder, $tfolder) = @_;
    my @items;
    my @folders;

    # Get next level of items from collection
    if (!$ifolder) {
        @items   = $import->get_top_level();
        @folders = $self->get_top_level();
    }
    else {
        @items = $import->get_folder_contents($ifolder);
    }

    foreach my $item (@items) {

        # At top level, no folders set:
        my $parent = $tfolder || 'root';
        if ($item->{type} eq 'url') {
            if (!grep {
                    $_->{url} eq $item->{url} && $_->{name} eq $item->{name}
                } @folders
                )
            {

                # It's a url, and it's not already there
                $self->add_bookmark($item, $parent);
            }
        }
        else {
            my ($folder) = grep { $_->{name} eq $item->{name} } @folders;
            if (!$folder) {

                # It's a folder, and its not already there
                $self->add_bookmark($item, $parent);
            }

            # Add sub items to this folder
            $self->merge($import, $item, $folder);
        }
    }

}

1;

__END__

=head1 NAME

Bookmarks::Parser - A class to parse and represent collections of bookmarks.

=head1 VERSION

This documentation refers to version 0.01.

=head1 SYNOPSIS

    use Bookmarks::Parser;
    my $parser = Bookmarks::Parser->new();
    my $bookmarks = $parser->parse({filename => 'bookmarks.html'});
    my @rootitems = $bookmarks->get_top_level();

=head1 DESCRIPTION

The Bookmarks::Parser class implements a collection of bookmarks. Supported representations currently include:

=over 4

=item Netscape/Mozilla

=item Opera

=item A9

=item Delicious

The various types of collections are automatically recognised. Each is parsed
into a tree like structure which can then be accessed in parts or re-written
as any of the supported bookmark collection types. Two types of bookmark item
are distinguished, folder objects can contain other items, url objects
cannot. For bookmark collections with tagging instead of folders, the tags
are stored as folders. Each unique URL is stored exactly once, but can appear
under many folder items.

=back

=head1 SUBROUTINES/METHODS

=head2 new (constructor)

Parameters:
    none

Create a new parser object, no parameters as yet.

=head2 parse (method)

Parameters:
    hashref of named arguments: filename, url, user, passwd

Parse a collection of bookmarks. This can be passed a filename of a bookmarks
file on a local disk, or a url and user/passwd combination of a bookmarks
collection stored on a remote server.

Currently, best guesses are made as to which type of bookmarks collection is
being parsed, Opera, Netscape/Mozilla and Delicious are supported so far.

=head2 set_title (method)

Parameters:
    title - String

Some bookmarks collections (Netscape) have an overall title for the
collection, this method can be used to set/change the title.

=head2 add_bookmark (method)

Parameters:
    bookmark - Bookmarks::Bookmark
    parent   - Bookmarks::Bookmark

Add a new Bookmarks::Bookmark object somewhere in the tree. If no parent
object is given, the insertion is made as a top level bookmark folder/tag. 
If a parent object is given, the item appears under it in a tree-like
fashion. The parent object needs to be of type folder.

=head2 as_a9 (constructor)

Returns a copy of this object as a Bookmarks::A9 object, which can be imported 
into a9.

=head2 as_opera (constructor)

Parameters:
    none

Returns a copy of this object as a Bookmarks::Opera object, which can be
written out as an Opera bookmarks file.

=head2 as_netscape (constructor)

Parameters:
    none

Returns a copy of this object, as a Bookmarks::Netscape object, which can 
be written out as an Opera bookmarks file.

=head2 as_xml (constructor)

Parameters:
    none

Returns a copy of this object, as a Bookmarks::XML object, which can be saved 
as an XML file.

=head2 write_file (method)

Parameters:
    a hashref of named arguments: filename, type

Create a file containing the bookmarks collection to disk. The default type
will be the same as the parsed in file, or the type converted to last by one 
of the as_ functions. Types that can be given are: opera, netscape and delicious.

=head2 as_string (method)

Parameters:
    type (optional)  - String

Return the contents of the bookmarks collection as a string. This is just the
 same content as will be written to the file by the write_file method.

=head2 get_header_as_string (method)

Parameters:
    type (optional)  - String

Called by as_string to get a header for the bookmarks collection. This is 
defined as all the text that appears in the bookmarks file before the actual 
bookmarks.

=head2 get_footer_as_string (method)

Parameters:
    type (optional)  - String

Called by as_string to get a footer for the bookmarks collection. This is 
defined as all the text that appears in the bookmarks file after the actual
bookmarks. 

=head2 get_top_level (method)

Parameters:
    none

Returns a list of the top level (root) items in the collection. 

=head2 set_top_level

Parameters:
    none

Add a list of top level (root) items to the collection.

=head2 rename (method)

Parameters:
    item    - Bookmarks::Bookmark
    newname - String

Rename an item in the collection. (Should be in Bookmarks::Bookmark).

=head2 find_items

Parameters
   url
   name

Will look through the parsed bookmarks and return bookmarks that
matches either url or name (based on a regex match)

=head2 merge <bookmarks object>

Takes another bookmark object, and merges it into this one.

=head2 get_folder_contents (method)

Parameters:
    folder  - Bookmarks::Bookmark

Returns a list of items that are children of the given folder item.

=head2 get_from_id <id>

Returns an element based on the element id.

=head2 get_path_of <elem>

Returns the full path of a given element.

=head2 write_url 

Not yet implemented.

=head1 DEPENDENCIES

L<WWW::A9TToolbar>

L<HTML::TreeBuilder>

L<Net::Delicious>

L<XML::Simple>

L<Test::More>

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find
any.

=head1 AUTHOR

Jess Robinson <castaway@desert-island.demon.co.uk>

Marcus Ramberg <mramberg@cpan.org>

Cosimo Streppone <cosimo@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
