package Data::Page::Viewport;

# Name:
#	Data::Page::Viewport.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Reference:
#	Object Oriented Perl
#	Damian Conway
#	Manning
#	1-884777-79-1
#	P 114
#
# Note:
#	o Tab = 4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 1999-2002 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
use warnings;
no warnings 'redefine';

require 5.005_62;

use Set::Window;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::Page::Viewport ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.06';

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_data_size	=> - 1,
		_old_style	=> 0,
		_page_size	=> - 1,
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		sort keys %_attr_data;
	}

}	# End of Encapsulated class data.

# -----------------------------------------------

sub current
{
	my($self) = @_;

	$$self{'_current'};

}	# End of current.

# -----------------------------------------------

sub new
{
	my($caller, %arg)	= @_;
	my($caller_is_obj)	= ref($caller);
	my($class)			= $caller_is_obj || $caller;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		elsif ($caller_is_obj)
		{
			$$self{$attr_name} = $$caller{$attr_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	$$self{'_current'}					= 0;
	$$self{'_port'}						= {};
	$$self{'_port'}{'inner'}			= {};
	$$self{'_port'}{'inner'}{'top'}		= 0; # Top (upwards on screen) and bottom of viewport.
	$$self{'_port'}{'inner'}{'bottom'}	= $$self{'_page_size'} - 1;
	$$self{'_port'}{'outer'}			= {};
	$$self{'_port'}{'outer'}{'top'}		= 0; # Top and bottom of fixed data.
	$$self{'_port'}{'outer'}{'bottom'}	= $$self{'_data_size'};
	$$self{'_inner'}					= Set::Window -> new_lr($$self{'_port'}{'inner'}{'top'}, $$self{'_port'}{'inner'}{'bottom'});
	$$self{'_outer'}					= Set::Window -> new_lr($$self{'_port'}{'outer'}{'top'}, $$self{'_port'}{'outer'}{'bottom'});
	$$self{'_page_size'}				= $$self{'_page_size'} - 1;

	$self;

}	# End of new.

# -----------------------------------------------

sub offset
{
    my($self, $offset) = @_;
	($$self{'_port'}{'inner'}{'top'}, $$self{'_port'}{'inner'}{'bottom'}) = $$self{'_inner'} -> bounds();

	if ($offset > 0)
	{
		$$self{'_current'}	+= $offset;
		$$self{'_current'}	= $$self{'_port'}{'outer'}{'bottom'} if ($$self{'_current'} > $$self{'_port'}{'outer'}{'bottom'});
		my($permit)			= $$self{'_old_style'} ? 1 : $$self{'_current'} > $$self{'_port'}{'inner'}{'bottom'} ? 1 : 0;

		# If we are scrolling down, and the scroll would leave something visible
		# within the viewport, then permit the scroll.

		while ($permit && ($offset > 0) && ( ($$self{'_port'}{'inner'}{'top'} + $$self{'_page_size'}) < $$self{'_port'}{'outer'}{'bottom'}) )
		{
			$offset--;

	 		$$self{'_inner'} = $$self{'_inner'} -> offset(1);
			($$self{'_port'}{'inner'}{'top'}, $$self{'_port'}{'inner'}{'bottom'}) = $$self{'_inner'} -> bounds();
		}
	}
	elsif ($offset < 0)
	{
		$$self{'_current'}	+= $offset; # + because offset is -!
		$$self{'_current'}	= $$self{'_port'}{'outer'}{'top'} if ($$self{'_current'} < $$self{'_port'}{'outer'}{'top'});
		my($permit)			= $$self{'_old_style'} ? 1 : $$self{'_current'} < $$self{'_port'}{'inner'}{'top'} ? 1 : 0;

		# If we are scrolling up, and the scroll would leave something visible
		# within the viewport, then permit the scroll.

		while ($permit && ($offset < 0) && ( ($$self{'_port'}{'inner'}{'bottom'} - $$self{'_page_size'}) > $$self{'_port'}{'outer'}{'top'}) )
		{
			$offset++;

	 		$$self{'_inner'} = $$self{'_inner'} -> offset(- 1);
			($$self{'_port'}{'inner'}{'top'}, $$self{'_port'}{'inner'}{'bottom'}) = $$self{'_inner'} -> bounds();
		}
	}

	# Return the viewport, knowing now that when the user calls bounds(),
	# there will definitely be something visible within the viewport.

	$$self{'_inner'} -> intersect($$self{'_outer'});

}	# End of offset.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<Data::Page::Viewport> - Scroll thru data a page, or just an item, at a time

=head1 Synopsis

This is a complete, tested, runnable program.

	#!/usr/bin/perl

	use strict;
	use warnings;

	use Data::Page::Viewport;

	# -----------------------------------------------

	my(@data) = (qw/zero one two three four five six
	seven eight nine ten eleven twelve thirteen fourteen/);
	my($page) = Data::Page::Viewport -> new
	(
		data_size => scalar @data,
		page_size => 4
	);

	print "Data bounds: 0 .. $#data. \n";
	print "Data:        ", join(', ', @data), ". \n";
	print "Page bounds: 0 .. 3. \n";
	print "Page data:   ", join(', ', @data[0 .. 3]), ". \n";
	print "\n";

	my(@bound);

	for (-2, 1, 4, 4, 1, 3, 3, -2, 1, 2, 1, -4, -4,
		-1, 1, 2, -1, -2, -2, -1, -4, 4, 4, 4)
	{
		print "Offset: $_. \n";

		@bound = $page -> offset($_) -> bounds();

		print "Page bounds: $bound[0] .. $bound[1]. \n";
		print 'Page data:   ',
			join(', ', @data[$bound[0] .. $bound[1] ]),
			". \n";
		print '-' x 50, "\n";
	}

=head1 Description

C<Data::Page::Viewport> is a pure Perl module.

This module keeps track of what items are on the 'current' page,
when you scroll forwards or backwards within a data set.

Similarly to Data::Page, you can call C<sub offset(N)>, for + or - N, to
scroll thru the data a page at a time.

And, like Set::Window, you can call C<sub offset(N)>, for + or - 1,
to scroll thru the data an item at a time.

Clearly, N does not have to be fixed.

The viewport provides access to the 'current' page, and the code shifts
indexes into and out of the viewport, according to the parameter passed
to C<sub offset()>.

Note that the data is I<not> passed into this module. The module only keeps
track of the indexes within the viewport, i.e. indexes on the 'current'
page.

You call C<sub bounds()> on the object (of type C<Set::Window>) returned by
C<sub offset()>, to determine what indexes are on the 'current' page at any
particular point in time.

Also note that, unlike Set::Window, the boundaries of the viewport are
rigid, so that changes to the indexes caused by C<sub offset()> are
limited by the size of the data set.

This means, if you do this:

	my($page) = Data::Page::Viewport -> new
	(
	    data_size => $#data,     # 0 .. $#data.
	    page_size => $page_size, # 1 .. N.
	);

	my(@bound) = $page -> offset(- 1) -> bounds();

the call to C<sub offset(- 1)> will have no effect.

That is, when trying to go back past the beginning of the data set, the
bounds will be locked to values within 0 .. data_size.

Similarly, a call which would go beyond the other end of the data set,
will lock the bounds to the same range.

In short, you can't fall off the edge by calling C<sub offset()>.

This in turn means that the values returned by C<sub bounds()> will
always be valid indexes within the range 0 .. data_size.

The module implements this by building 2 objects of type Set::Window,
one for the original data set (which never changes), and one for the
'current' page, which changes each time C<sub offset()> is called
(until the boundaries are hit, of course).

Note: No range checking is performed on the parameters to C<sub new()>.

Note: It should be obvious by now that this module differs from Data::Page,
and indeed all such modules, in that they never change the items which are
on a given page. They only allow you to change the page known as the
'current' page. This module differs, in that, by calling
C<sub offset(+ or - N)>, you are effectively changing the items which are
deemed to be on the 'current' page.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<Data::Page::Viewport> object.

This is the class's contructor.

Parameters:

=over 4

=item data_size

This is the upper limit on the indexes controlled by the viewport.

The lower limit is assumed to be 0.

This parameter is mandatory.

=item old_style

This controls whether you get the old style or new style scrolling.

The two types of scrolling are explained next, assuming you have tied the
up and down arrow keys to scrolling via user input, and assuming you highlight
the 'current' record. This just makes it easier to explain.

=over 4

=item Old style

The 1st record starts as the 'current' record, and the 1st down arrow causes
the next record to become the 'current' record. All this is as expected.

However, in old style scrolling, that 1st down arrow key also causes the list
of items to scroll upwards, so the 'current' record remains at the top of the
current page.

=item New style

With new style scrolling, which I feel is more natural, the list does not begin
to scroll upward until the 'current' record, and the highlight, reach the bottom
of the page.

That is, the 'current' record, and the highlight, move down the page each time the
down arrow key is hit, but the list of items which are displayed on the current
page does not change, until the point where a down arrow would select a 'current'
item not visible on the current page. At that point, the list of items visible on
the current page begins to scroll up, leaving the 'current' record, and the
highlight, at the last item on the current page.

=back

The up arrow key does the same thing at the top of the page.

The default is 0, meaning you get the new style scrolling.

Set it to 1 to get the old style scrolling.

This parameter is optional.

=item page_size

This is the number of items on a page.

This parameter is mandatory.

=back

For example, if you use this module in a program which accepts input from the user
in the form of the PgDn and PgUp keys, for instance, you could just call
C<sub offset(+ or - $page_size)>, to allow the user to scroll forwards and backwards
thru the data a page at a time.

But, if you want to allow the user to scroll by using the up and down arrow keys,
then these keys would result in calls like C<sub offset(+ or - 1)>.

=head1 Mathod: current()

The module keeps track of a 'current' item within the current page, and this method
returns the index of that 'current' item.

The value returned will be in the range 0 .. data_size.

This means that when you hit the down arrow, say, and call C<offset(1)>, and the items on
the current page do not change because the items at the end of the data set were already
visible before down arrow was hit, then you can still call C<current()> after each hit of
the down arrow key, and the value returned will increase (up to data_size), to indicate
which item, among those in the current window, is the 'current' item.

You could use this to highlight the 'current' item, which would change each time the down
arrow was hit, even though the current page of items was not changing (because the final
page of items was already being displayed).

=head1 Modules on CPAN which Manipulate Sets

There are quite a few modules on CPAN which provide scrolling capabilities, and one
or more even allow you to have pages of different sizes, but none seem to allow for
scrolling by anything other than a rigidly-fixed page size. This module does offer
such flexibility, by allowing you to scroll backwards or forwards by any number of
items, with differing step sizes per scroll.

=over 4

=item Array::IntSpan

=item Array::Window

=item Data::Page

=item Data::Page::Tied

=item Data::Pageset

=item Data::SpreadPagination

=item Data::Pageset::Variable

=item Data::Paginated

=item Set::IntSpan

=item Set::Window

=back

There may be others. After all, CPAN is the man (with apologies to feminists ;-).

=head1 Author

C<Data::Page::Viewport> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2004.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2004, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
