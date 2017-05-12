package Data::Microformat::hFeed::hEntry;

use strict;
use base qw(Data::Microformat);
use Data::Microformat::hCard;
use DateTime::Format::W3CDTF;

sub class_name { "hentry" }
sub singular_fields { qw(id base geo title content summary modified issued link author) }
sub plural_fields { qw(tags) }

sub from_tree {
 	my $class = shift;
    my $tree  = shift;
	my $url   = shift;
	my @entries;
	foreach my $entry_tree ($tree->look_down('class', qr/hentry/)) {
		push @entries, $class->_convert($entry_tree, $url);
	}
	return wantarray ? @entries : $entries[0];
}

sub _convert {
	my $class = shift;
	my $tree  = shift;
	my $url   = shift;
	my $entry = $class->new;
	$entry->{_no_dupe_keys} = 1;
	$entry->base($url) if $url;
	my $title;
	my $id;
	$tree->look_down(sub {
		my $bit = shift;
		my $entry_class = $bit->attr('class') || $bit->attr('rel') || $bit->tag || return 0;
		# TODO 
		# Summary and Content as html


		if (!$entry_class) {
			return 0;
		} elsif (_match($entry_class, 'hentry')) {
			$entry->id($bit->attr('id'));
        } elsif (_match($entry_class, 'entry-title')) {
			$entry->title($bit->as_text);
			$entry->id($bit->attr('id'));
        } elsif ($entry_class =~ m!^h\d!) {
			$title = $bit->as_text    unless defined $title;
			$id    = $bit->attr('id') unless defined $id;
        } elsif (_match($entry_class, 'entry-summary')) {
			$entry->summary($class->_get_child_html_from_element($bit));
        } elsif (_match($entry_class, 'entry-content')) {
			$entry->content($class->_get_child_html_from_element($bit));
		} elsif (_match($entry_class, 'published')) {
			$entry->issued(_do_date($bit));
		} elsif (_match($entry_class, 'modified')) {
			$entry->modified(_do_date($bit));
		} elsif (_match($entry_class,'vcard')) {
			my $card = Data::Microformat::hCard->from_tree($bit);
			$entry->author($card);
        } elsif (_match($entry_class, 'geo')) {
            $bit->detach;
            my $geo = Data::Microformat::geo->from_tree($bit, $url);
            $entry->geo($geo);
		} elsif (_match($entry_class, 'bookmark')) {
			$entry->link($class->_url_decode($bit->attr('href')));
		} elsif (_match($entry_class, 'tag')) {
			$entry->tags($bit->as_text);
		} else {
			# print "Unknown class $entry_class\n";
		}
		return 0;
	});
	# Use first h tag we found if title or id isn't set
	$entry->title($title) if defined $title; 
	$entry->title($id)    if defined $id; 
    $entry->{_no_dupe_keys} = 0;
	return $entry;
}

sub _do_date {
	my $element = shift;
	my $title   = $element->attr('title') || return;
	$title      =~ s!(([+-])(\d+))$!$2.join(":", grep {length} split /(\d\d)/, $3)!e; # egregious hack to work with malformed dates
	my $dt      = eval { DateTime::Format::W3CDTF->parse_datetime($title) };
	print "Aargh: $@\n".caller()."\n" if $@;
	return $dt;
}

sub _match {
	my $field  = shift || return 0;
	my $target = shift;
	return $field =~ m!(^|\s*)$target(\s*|$)!i;
}

sub _to_hcard_elements {
	my $entry  = shift;

	my $root   = HTML::Element->new('div', class => 'hentry entry');

	# id
	$root->attr('id', $entry->id) if $entry->id;


	# title
	if ($entry->title) {
		my $title = HTML::Element->new('h3', class => 'entry-title');
		if ($entry->link) {
			my $a = HTML::Element->new('a', href => $entry->link, rel => 'bookmark', title => $entry->title );
			$a->push_content($entry->title);
			$title->push_content($a);
		} else {
			$title->push_content($entry->title);
		}
		$root->push_content($title);
	}

	# summary
	# content
	foreach my $attr (qw(summary content)) {
		next unless $entry->$attr;
		my $div = HTML::Element->new('div', class => "entry-$attr");
		$div->push_content($entry->$attr);
		$root->push_content($div);
	}

	# post info
	my $post_info     =  HTML::Element->new('ul');
	my $saw_something = 0;
	# published
	# modified
	foreach my $date (qw(issued modified)) {
		my $val  = $entry->$date || next;
		$saw_something++;
		my $name = ($date eq 'issued') ? 'published' : $date; 

       	my $li  = HTML::Element->new('li');
		$li->push_content(ucfirst($name).": ");
       	my $abbr = HTML::Element->new('abbr', class => $name, title => DateTime::Format::W3CDTF->format_datetime($entry->$date));
       	$abbr->push_content($entry->$date->strftime("%B %d, %Y"));
       	$li->push_content($abbr);
       	$post_info->push_content($li);
	}

    # author
    # geo
    foreach my $attr (qw(author geo)) {
		next unless $entry->$attr;
		$saw_something++;
        my $li = HTML::Element->new('li');
        $li->push_content($entry->$attr->_to_hcard_elements);
        $post_info->push_content($li);
    }

	$root->push_content($post_info) if $saw_something;
	return $root;
}

1;

__END__

=head1 NAME

Data::Microformat::hFeed::hEntry - A module to parse and create hEntries


=head1 SYNOPSIS

    use Data::Microformat::hFeed::hEntry;

    my $entry = Data::Microformat::hFeed:hEntry->parse($a_web_page);

	print "Entry title is ".$entry->title;
	print "Entry author is ".$entry->author->fullname;	

	# Create a new entry from scratch
	my $entry = Data::Microformat::hFeed::hEntry->new;
	$entry->id(rand().time().$$);
	$entry->title("A title");
	$entry->link("http://example.com/989691066");
	$entry->summary("A summary");
	$entry->content("Somebody did something");
	$entry->issued(DateTime->now);
	$entry->modified(DateTime->now);
	foreach my $tag (qw(tag1 tag2 tag3)) {
		$entry->tags($tags);
	}
	$entry->author($hcard);

=head1 DESCRIPTION

An hEntry is a microformat used in hFeeds.

This module exists both to parse existing hEntires from web pages, and to create
new hEntries so that they can be put onto the Internet.

To use it to parse an existing hEntry (or hEntries), simply give it the content
of the page containing them (there is no need to first eliminate extraneous
content, as the module will handle that itself):

    my $entry = Data::Microformat::hFeed::hEntry->parse($content);

If you would like to get all the entries on the webpage, simply ask using an
array:

    my @entries = Data::Microformat::hFeed::hEntry->parse($content);

To create a new hEntry, first create the new object:

    my $entry = Data::Microformat::hFeed::hEntry->new;

Then use the helper methods to add any data you would like. When you're ready
to output in the hEntry HTML format, simply write

    my $output = $entry->to_html;

And $output will be filled with an hEntry representation, using <div> tags
exclusively with the relevant class names.

=head1 SUBROUTINES/METHODS

=head2 class_name

The microformat class name for an entry; to wit, "hentry"

=head2 singular_fields

This is a method to list all the fields on an address that can hold exactly one value.

=head2 plural_fields

This is a method to list all the fields on an address that can hold multiple values.

=head2 Data::Microformat::organization->from_tree($tree [, $source_url])

This method overrides but provides the same functionality as the
method of the same name in L<Data::Microformat>, with the optional
addition of $source_url. If present, this latter term will set the
base of the entry automatically.

=head2 id

The id of this entry.

=head2 title

The title of this entry.

=head2 base

The base of this entry if available.

=head2 link

The permalink of this entry.

=head2 summary

The summary of this entry if available.

=head2 content

The contents of this entry if available.

=head2 issued

When this entry was created - returns a DateTime object.

=head2 modified

When this entry was modified - returns a DateTime object.

=head2 tags

All the tags for this entry.

=head2 author

The author of this entry. Returns a L<Data::Microformat::hCard|Data::Microformat::hCard> object.

=head2 geo

The geo location information for this entry. Returns a L<Data::Microformat::geo|Data::Microformat::geo> object.

=head2 to_html

Return this hEntry as HTML

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-microformat at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Microformat>.  I will be
notified,and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 AUTHOR

Simon Wistow, C<< <swistow@sixapart.com> >>

=head1 COPYRIGHT

Copyright 2008, Six Apart Ltd. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.

=cut
