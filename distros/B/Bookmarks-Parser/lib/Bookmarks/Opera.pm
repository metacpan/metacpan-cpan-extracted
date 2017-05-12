# Opera-specific bookmarks parser and producer

package Bookmarks::Opera;

use strict;
use warnings;
use base 'Bookmarks::Parser';

# Last updated, September 2011,
# Opera Hotlist version 21
my @op_bookmark_fields = (
    "ACTIVE",
    "CREATED",
    "DELETABLE",
    "DESCRIPTION",
    "DISPLAY URL",
    "ICONFILE",
    "ID",
    "IN PANEL",
    "MOVE_IS_COPY",
    "NAME",
    "ON PERSONALBAR",
    "PANEL_POS",
    "PARTNERID",
    "PERSONALBAR_POS",
    "SEPARATOR_ALLOWED",
    "SHORT NAME",
    "TARGET",
    "TRASH FOLDER",
    "UNIQUEID",
    "URL",
    "VISITED",
);

my %op_bookmark_fields = map {

    # No qr{}x, field names contain significant whitespace
    $_ => qr{^\s+$_=(.*)}
} @op_bookmark_fields;

sub _parse_file {
    my ($self, $filename) = @_;

    return undef if (!-e $filename);

    my $fh;
    my $curitem   = {};
    my $curfolder = {};
    open $fh, "<$filename" or die "Can't open $filename ($!)";

    while (my $line = <$fh>) {

        #        chomp $line;
        $line =~ s/[\r\n]//g;
        next if ($line =~ /^Opera Hotlist version/);
        next if ($line =~ /^Options:/);

        if ($line =~ m{^ \s* $}x) {
            if ($curitem->{start}) {
                delete $curitem->{start};
                $curitem->{parent} = $curfolder->{id};
                $self->add_bookmark($curitem, $curfolder->{id});
                if ($curitem->{type} eq 'folder') {
                    $curfolder = $curitem;
                }
                $curitem = {};
            }
        }
        if ($line eq '-') {
            $curfolder = $self->{_items}{ $curfolder->{parent} };

            #            ($curfolder) = grep { $_->{id} eq $curfolder->{parent} }
            #                                     @{$self->{_items}};
        }
        if ($line =~ /^#(FOLDER|URL)/) {
            $curitem->{start} = 1;
            $curitem->{type}  = lc($1);
        }
        if ($curitem->{start}) {
            for my $key (keys %op_bookmark_fields) {
                my $re = $op_bookmark_fields{$key};
                if ($line =~ $re) {
                    my $value    = $1;
                    my $nicename = lc $key;
                    $nicename =~ s{\s}{_}g;
                    $nicename =~ s{iconfile}{icon};
                    $curitem->{$nicename} = $value;
                }
            }
        }
    }

    # Deal with last element if there's no closing empty line
    if ($curitem->{start}) {
        delete $curitem->{start};
        $curitem->{parent} = $curfolder->{id};
        $self->add_bookmark($curitem, $curfolder->{id});
        $curfolder = $curitem if $curitem->{type} eq 'folder';
        $curitem = {};
    }

    close($fh);
    return $self;
}

sub get_header_as_string {
    my ($self) = @_;

    my $header = << "HEADER";
Opera Hotlist version 2.0
Options: encoding = utf8, version=21

HEADER

    return $header;
}

{
    my $folorder = 0;

    sub get_item_as_string {
        my ($self, $item) = @_;

        if (!defined $item->{id} || !$self->{_items}{ $item->{id} }) {
            warn "No such item in get_item_as_string";
            return;
        }

        my $string = '';
        my ($id, $url, $name, $visited, $created, $modified, $icon, $desc,
            $expand, $trash, $order) = (
            $item->{id}          || 0,
            $item->{url}         || '',
            $item->{name}        || '',
            $item->{visited}     || 0,
            $item->{created}     || time(),
            $item->{modified}    || 0,
            $item->{icon}        || '',
            $item->{description} || '',
            $item->{expanded}    || '',
            $item->{trash}       || '',
            $item->{order}       || undef
            );

        if ($item->{type} eq 'folder') {
            if (!defined($order)) {
                $folorder = 0;
            }
            $string .= "#FOLDER\n";
            $string .= "        ID=$id\n";
            $string .= "        NAME=$name\n";
            $string .= "        CREATED=$created\n";
            $string .= "        TRASH FOLDER=$trash\n" if ($trash);
            $string .= "        VISITED=$visited\n" if ($visited);
            $string .= "        EXPANDED=$expand\n" if ($expand);
            $string .= "        DESCRIPTION=$desc\n" if ($desc);
            $string .= "        ICONFILE=$icon\n" if ($icon);
            $string .= "        ORDER=$order\n" if (defined $order);
            $string .= "\n";

            $string .= $self->get_item_as_string($self->{_items}{$_})
                foreach (@{ $item->{children} });
            $string .= "-\n";
        }
        elsif ($item->{type} eq 'url') {
            if (!defined($order)) {
                $order = $folorder++;
            }

            $string .= "#URL\n";
            $string .= "        ID=$id\n";
            $string .= "        NAME=$name\n";
            $string .= "        URL=$url\n" if ($url);
            $string .= "        CREATED=$created\n";
            $string .= "        TRASH FOLDER=$trash\n" if ($trash);
            $string .= "        VISITED=$visited\n" if ($visited);
            $string .= "        EXPANDED=$expand\n" if ($expand);
            $string .= "        DESCRIPTION=$desc\n" if ($desc);
            $string .= "        ICONFILE=$icon\n" if ($icon);
            $string .= "        ORDER=$order\n" if (defined $order);
            $string .= "\n";
        }

        return $string;
    }
}

1;

__END__

=head1 NAME

Bookmarks::Opera - Opera style bookmarks.

=head1 SYNOPSIS

    use Data::Dumper;
    use Bookmarks::Parser;

    # You don't need to explicitly use Bookmarks::Opera
    my $parser = Bookmarks::Parser->new();

    # Existing Opera bookmark file
    my $file = "bookmarks.adr";

    my $bookmarks = $parser->parse({filename => $file});
    my @nodes = $bookmarks->get_top_level();
    my @tree;

    # Depth-first bookmarks tree visit
    while (@nodes) {
        my $node = shift @nodes;
        push @tree, $node;
        if ($node->{children}) {
            push @nodes, $bookmarks->get_from_id($_)
                for @{ $node->{children} };
        }
    }

    print Dumper(\@tree);

=head1 DESCRIPTION

A subclass of L<Bookmarks::Parser> for handling Opera bookmarks.

=head1 METHODS

=head2 C<get_header_as_string>

=head2 C<get_item_as_string>

=head2 C<get_footer_as_string>

See L<Bookmarks::Parser> for these methods.

=head1 AUTHOR

Jess Robinson <castaway@desert-island.demon.co.uk>

Cosimo Streppone <cosimo@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

