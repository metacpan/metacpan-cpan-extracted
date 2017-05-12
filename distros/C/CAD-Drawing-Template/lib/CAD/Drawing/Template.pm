package CAD::Drawing::Template;
our $VERSION = '0.01';

# This code is copyright 2004 Eric L. Wilhelm.
# See below for licensing details.

use warnings;
use strict;

use Carp;

use CAD::Drawing;
use CAD::Calc qw(
	iswithin
	print_line
	);
use Storable qw(dclone);

our @tags = qw(
	data
	vtable
	geo
	block
	function
	);

# allow later configurability:
my $comment_layer = "comment";
my $fit_layer = "fit";
########################################################################
=pod

=head1 NAME

CAD::Drawing::Template - Replace tags with text and geometry.

=head1 SYNOPSIS

  my $bp = CAD::Drawing::Template->new();
  $bp->load('my_template.dxf');
  # set some values for the boiler-plate:
  $bp->set_data(foo => 'value for foo');
  my @parts = qw(E8955 Q4200);
  $bp->set_vtable(parts => \@parts);
  $bp->set_geom(birdseye => 'birdseye.dwg');
  my $drw = $bp->done(pass => qr/^shipping/, die => 0);
  $drw->save('output.dxf');

=head1 Input Templates

Input templates must be CAD::Drawing compatible files or objects.  These
are brought into the CAD::Drawing::Template object via load() or
import() and searched for 'texts' items which match the formats listed
below.

The tags may be on any layer in the drawing except 'comments' and 'fit'
which are reserved names.  The 'comments' layer is completely discarded,
and the 'fit' layer must only contain rectangles (which are necessary
for scaling calculations, but are also discarded.)

=head1 Tag Formats

The 'tags' are 'texts' entities (single-line text in dwg/dxf formats)
which must begin and end with matching angle-brackets ('<' and '>'.)
These text entities are sourced for their insertion point, text height,
and name.  Future versions of this module will support orientations,
fonts, and options within the tag text itself.

In general, tags are formatted as <$type:$name>.  Where $type is one of
the types defined below and $name is the name of the tag (to be used in
addressing it via the set_*() functions.

Tag names should adhere to the same rules as perl variable names:

  1.  Alphanumeric characters (and underscores) only (a-z, A-Z, 0-9, _)
  2.  Must start with a letter ("a2", not "2a", and not "_2")
  3.  Case senSitive

The following tag types are supported.  Examples show the text string
that would be in the template.

=over

=item data

A 'data' tag is replaced with a single scalar value.

Examples:

  <data:department>
  <data:item_code>
  <data:A5>

=item vtable

A 'vtable' tag is replaced with a list of values, each one some distance
below the previous, with the top line's insertion point at the tag's
insertion point.

Examples:

  <vtable:revision>
  <vtable:part_list>

=item geo

Loads a drawing and fits it into a rectangle.

NOTE:  The rectangle must be on a layer named 'fit' and contain the
insertion point of the tag.  Each <geo:name> tag must be within a
rectangle on the 'fit' layer and each rectangle on the 'fit' layer must
have exactly one <geo:name> tag inside of it.  If this is not true,
death ensues.  These rectangles are removed from the drawing before
output.

While a rectangle may contain two 'geo' tags, each tag must be contained
in one rectangle (the innermost containing rectangle wins.)

Examples:

  <geo:section>
  <geo:isometric>

=item block

Loads a drawing to the insertion point.

Examples:

  <block:north_arrow>
  <block:scale>

=item function

A 'function' tag calls a perl function, and afterwards behaves like a
data tag.  There is no set_function() function, since this tag is
supposed to be fully-automatic.

The function is assumed to be a member of a Perl module.  If that module
is not already loaded, it is require()'d within an eval() statement
before the function is called.  There is no provision for passing values
to these functions.  The function is called in a list context, and the
results joined by spaces.  Any errors encountered in calling the
function will be croak()'d along with the function name.

If the module is contained under a non-standard path (one which is not
included in @INC), it should be preceded by a directory path.  This
directory is then brought into @INC via the 'use lib' pragma.

Examples:

  <function:date>                  # uses main::date()
  <function:Date::Calc::Today>
  <function:CAD::Calc::pi>
  <function:my_perl_lib/Functions::foo>

=back

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 Modifications

The source code of this module is made freely available and
distributable under the GPL or Artistic License.  Modifications to and
use of this software must adhere to one of these licenses.  Changes to
the code should be noted as such and this notification (as well as the
above copyright information) must remain intact on all copies of the
code.

Additionally, while the author is actively developing this code,
notification of any intended changes or extensions would be most helpful
in avoiding repeated work for all parties involved.  Please contact the
author with any such development plans.

=head1 SEE ALSO

  CAD::Drawing

=cut
########################################################################

=head1 Constructors

=head2 new

  my $bp = CAD::Drawing::Template->new(%options);

=over

=item Valid options

  pass => [@list], # type:name strings only

=back

=cut
sub new {
	my $caller = shift;
	my $class = ref($caller) || $caller;
	my $self = {@_};
	bless($self, $class);
	return($self);
} # end subroutine new definition
########################################################################

=head2 clone

Duplicates the boiler-plate as a snapshot in time (useful to save effort
in loops.)

  my $bp2 = $bp->clone();

=cut
sub clone {
	my $self = shift;
	# accept the same options as done() ?
	my $ret = dclone($self);
	return($ret);
} # end subroutine clone definition
########################################################################

=head1 Template Handling

Getting template data in and finished data out.

=head2 load

  $bp->load($filename);
  # or:
  $bp->load($drawing_object);

=cut
sub load {
	my $self = shift;
	my $file = shift;
	if(ref($file)) {
		$self->{drw} = $file;
	}
	else {
		my $drw = CAD::Drawing->new();
		$drw->load($file, {nl => ['comment']});
		$self->{drw} = $drw;
	}
	$self->find_tags();
} # end subroutine load definition
########################################################################

=head2 done

  $drw = $bp->done(%options);

Options:

  pass     - array ref of pass-able tags ("type:name" strings)
  strict   - croak on tags not listed in pass
  warnings - carp warnings
  default  - "drop" or "pass" (default) action for un-passed tags

=cut
sub done {
	my $self = shift;
	my %options = @_;
	my %pass;
	if($options{pass}) {
		(ref($options{pass}) eq "ARRAY") or 
			croak("done() option 'pass' must be an array\n");
		%pass = map({$_ => 1} @{$options{pass}});
	}
	else {
		carp "strict option without pass"
			if $options{strict} and $options{warnings};
	}
	foreach my $type (keys(%{$self->{tags}})) {
		foreach my $name (keys(%{$self->{tags}{$type}})) {
			$pass{"$type:$name"} and next;
			my $message = "tag not set:  '$type:$name'";
			$options{strict} and
				die "\n  DEATH:  $message\n";
			$options{warnings} and 
				warn "$message\n";
			if($options{default} eq "drop") {
				$options{warnings} and 
					warn "implicit drop of tag: '$type:$name'\n";
				my $tag = $self->{tags}{$type}{$name};
				my $drw = $self->{drw};
				$drw->remove($tag->{addr});

			}
			else {
				$options{warnings} and 
					warn "implicit passing tag: '$type:$name'\n";
			}
		}
	}
	my $drw = $self->{drw};
	return($drw);
} # end subroutine done definition
########################################################################

=head2 tag_list

  $bp->tag_list();

=cut
sub tag_list {
	my $self = shift;
	my @ret;
	foreach my $type (keys(%{$self->{tags}})) {
		foreach my $item (keys(%{$self->{tags}{$type}})) {
			push(@ret, "$type:$item");
		}
	}
	return(@ret);
} # end subroutine tag_list definition
########################################################################

=head1 Methods

These methods allow you to manipulate the template.

=head2 set_data

Replace the tag's text with a string.

  $bp->set_data($name => $value);

  # replace the tag <data:department> with the department's name:
  $dep = 'Department of Redundancy Department';
  $bp->set_data(department => $dep);

=cut
sub set_data {
	my $self = shift;
	my ($name, $val) = @_;
	my $type = 'data';
	$self->{tags}{$type}{$name} or
		die "no such tag $type:$name\n";
	my $drw = $self->{drw};
	my $tag = $self->{tags}{$type}{$name};
	$drw->Set({string => $val}, $tag->{addr});
	delete($self->{tags}{$type}{$name});
} # end subroutine set_data definition
########################################################################

=head2 set_vtable

Remove the tag entity, and create a series of texts, each spaced
slightly below the previous.

  $bp->set_vtable($name => \@list);

  # uses the tag:  <vtable:revision>
  # create a table of revision notes:
  my @rev = (
    '  1  Changed fonts for PHB',
    '  2  Changed fonts back (for same)',
    '  3  Removed all text',
    );
  $bp->set_vtable(revision => \@rev);

=cut
sub set_vtable {
	my $self = shift;
	my ($name, $val) = @_;
	my $type = 'vtable';
	$self->{tags}{$type}{$name} or
		die "no such tag $type:$name\n";
	my $drw = $self->{drw};
	my $tag = $self->{tags}{$type}{$name};
	my $h = $drw->Get("height", $tag->{addr});
	my @pt = $drw->Get("pt", $tag->{addr});
	$drw->remove($tag->{addr});
	$drw->addtextlines(\@pt, join("\n", @$val),
		{height => $h, spacing => 1.2});
	delete($self->{tags}{$type}{$name});
} # end subroutine set_vtable definition
########################################################################

=head2 set_geo

Load a drawing into the template, scaling it to fit within an enclosing
rectangle.

  $bp->set_geo($name => $filename);
  # or:
  $bp->set_geo($name => $drawing_object);

=cut
sub set_geo {
	my $self = shift;
	my ($name, $source) = @_;
	# print "apply geo $name\n";
	my $type = 'geo';
	$self->{tags}{$type}{$name} or
		die "no such tag $type:$name\n";
	my $in = $self->load_drawing($name, $source);
	my $drw = $self->{drw};
	my $tag = $self->{tags}{$type}{$name};
	my @rec = @{$tag->{rectangle}{pts}};
	# print "rectangle: @{$rec[0]} x @{$rec[1]}\n";
	$in->fit_to_bound(\@rec, 0);
	my @list = $in->GroupClone($drw);
	$drw->remove($tag->{addr});
	$drw->remove($tag->{rectangle}{addr});
	delete($self->{tags}{$type}{$name});
	# $drw->show(hang => 1);

} # end subroutine set_geo definition
########################################################################

=head2 set_block

Identical to set_geo, except no scaling is performed.

  $bp->set_block($name => $filename);
  # or:
  $bp->set_block($name => $drawing_object);

=cut
sub set_block {
	my $self = shift;
	my ($name, $source) = @_;
	my $type = 'block';
	$self->{tags}{$type}{$name} or
		die "no such tag $type:$name\n";
	my $in = $self->load_drawing($name, $source);
	my $drw = $self->{drw};
	my $tag = $self->{tags}{$type}{$name};
	my @pt = @{$tag->{pt}};
	my @list = $drw->place($in, \@pt);
	$drw->remove($tag->{addr});
	delete($self->{tags}{$type}{$name});
} # end subroutine set_block definition
########################################################################

=head1 Guts

These methods are used internally.

=head2 find_tags

Grabs the addresses of all tags which match the regex m/^<.*>$/.  Any
which were are in the array @{$self->{pass}} are left untouched.

After finding all of the tags, execute any <function:*> tags which were
found.

  $bp->find_tags();

=cut
sub find_tags {
	my $self = shift;
	my $drw = $self->{drw};
	my %pass;
	if(my $pass = $self->{pass}) {
		(ref($pass) eq "ARRAY") or
			croak "pass => $pass is not an array ref";
		foreach my $tag (@$pass) {
			$pass{$tag} = 1;
		}
	}
	# first get all of the texts with <>
	my @layers = $drw->list_layers();
	my $regex = qr/^<.*>$/;
	my @addr;
	foreach my $layer (@layers) {
		push(@addr, $drw->addr_by_regex($layer, $regex));
	}
	# print scalar(@addr), " texts found\n";
	my %tags_okay = map({$_ => 1} @tags);
	foreach my $addr (@addr) {
		my $tag = $drw->Get("string", $addr);
		my ($type, $name, $opts) = parse_tag($tag);
		# just ignore pass-through tags
		$pass{"$type:$name"} and next;
		# print "type: $type, name: $name\n";
		$tags_okay{$type} or
			croak("$type is not one of @tags\n");
		if($type eq "function") {
			# print "must call function $name\n";
			$self->run_function($name, $addr);
			next;
			# XXX why would we need to create a tag item for functions?
		}
		$self->{tags}{$type}{$name} and
			croak "multiple tags found for $type:$name\n";
		my @pt = $drw->Get("pt", $addr);
		$self->{tags}{$type}{$name} = {
			pt   => \@pt,
			type => $type,
			name => $name,
			addr => $addr,
		};
	}
	# this guy needs to see all of the geo tags
	$self->geo_match();
} # end subroutine find_tags definition
########################################################################

=head2 geo_match

Performs the rectangle-tag matching.  Must be able to reduce each geo
tag to an innermost enclosing rectangle or dies with much whining.

  $bp->geo_match();

=cut
sub geo_match {
	my $self = shift;
	$self->{tags} or die "geo_match called before find_tags?";
	my $geo = $self->{tags}{geo};
	$geo or return();
	my @tags = keys(%$geo);
	unless(@tags) {
		warn("tags/geo defined, but null!(?)\n");
		return();
	}
	my $drw = $self->{drw};
	my @fit_addr = $drw->addr_by_type('fit', 'plines');
	(@fit_addr == @tags) or croak("geo (",
		scalar(@tags), ")/fit (", scalar(@fit_addr),
		") count mismatch\n");
	my @recs = map({[$drw->Get("pts", $_)]} @fit_addr);
	my @matches;
	for(my $i = 0; $i < @recs; $i++) {
		for(my $g = 0; $g < @tags; $g++) {
			my $addr = $geo->{$tags[$g]}{addr};
			my @pt = $drw->Get("pt", $addr);
			## print "check ", print_line($recs[$i]), " vs @pt\n";
			if(iswithin($recs[$i], \@pt)) {
				push(@{$matches[$i]}, $tags[$g]);
			}
		}
	}
	# go through matches in least-matched order (thus, the first to
	# speak for a tag gets to keep it
	my @order = sort(
		{
			scalar(@{$matches[$a]}) <=>
			scalar(@{$matches[$b]})
		} 0..$#matches);
	my %map_rec;
	foreach my $i (@order) {
		my @found = @{$matches[$i]};
		foreach my $name (@found) {
			defined($map_rec{$name}) and next;
			$map_rec{$name} = $i;
		}
	}
	foreach my $name (@tags) {
		defined($map_rec{$name}) or
			die "geo tag $name has no rectangle!\n";
		my $i = $map_rec{$name};
		# print "rectangle $i connects to $name\n";
		$geo->{$name}{rectangle} = {
			addr => $fit_addr[$i],
			pts  => [
				($drw->getExtentsRec([$fit_addr[$i]]))[0,2]
				],
		};
	}
	
} # end subroutine geo_match definition
########################################################################

=head2 run_function

Runs the function $name (in a list context) and places it's results
(joined with spaces) into the string at $addr.

  $bp->run_function($name, $addr);

=cut
sub run_function {
	my $self = shift;
	my ($name, $addr) = @_;
	if($name =~ s#^(.*)/+##) {
		my $lib = $1;
		# print "using lib: $lib\n";	
		eval("use lib '$lib';");
		$@ and croak("problem with lib '$lib'\n\t $@\n");
	}
	my $mod = 'main';
	if($name =~ s/^(.*):://) {
		$mod = $1;
		eval("require $mod;");
		$@ and croak("problem with module '$mod'\n\t: $@\n");
	}
	if($mod->can($name)) {
		my @data = $mod->$name;
		my $string = join(" ", @data);
		# print "got data '@data' out of $mod->$name\n";
		my $drw = $self->{drw};
		$drw->Set({string => $string}, $addr);
	}
	else {
		croak("$mod does not define a function named '$name'\n");
	}
} # end subroutine run_function definition
########################################################################

=head2 load_drawing

Loads a drawing from a filename or CAD::Drawing object and returns a
CAD::Drawing object.

  $drw = $bp->load_drawing($name => $filename);
  # or:
  $drw = $bp->load_drawing($name => $drawing_object);

=cut
sub load_drawing {
	my $self = shift;
	my ($name, $source) = @_;
	my $in;
	if(ref($source)) {
		# had better be a drw
		$in = $source;
	}
	else {
		$in = CAD::Drawing->new();
		$in->load($source);
	}
	return($in);
} # end subroutine load_drawing definition
########################################################################

=head1 Functions

Not object-oriented, and likely not exported.

=head2 parse_tag

Break a tag into type, name, and options.  When (and if) options are
supported within the tags, they will be handled here.

  ($type, $name, $options) = parse_tag($tag);

=cut
sub parse_tag {
	my ($string) = @_;
	my $tag = $string;
	# print "tag: $tag\n";
	($tag =~ s/^<//) or croak("string:  '$string' is invalid\n");
	($tag =~ s/>$//) or croak("string:  '$string' is invalid\n");
	my ($type, $name) = split(/:/, $tag, 2);
	# XXX for options, we must parse $type
	my $options = {};
	return($type, $name, $options);
} # end subroutine parse_tag definition
########################################################################
1;
