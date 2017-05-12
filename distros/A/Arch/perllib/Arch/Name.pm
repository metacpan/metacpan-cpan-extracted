# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::Name;

my @ELEMENTS = qw(none archive category branch version revision);
my $i = -1;
my %ELEMENT_INDEX = map { $_ => $i, substr($_, 0, 1) => ++$i } @ELEMENTS;
my $ERROR = undef;  # yes, it is intentionally global

my $archive_re  = qr/[-\w]+(?:\.[-\w]+)*@[-\w.]*/;
my $category_re = qr/[a-zA-Z](?:[\w]|-[\w])*/;
my $branch_re   = $category_re;
my $version_re  = qr/\d+(?:\.\d+)*/;
my $revision_re = qr/base-0|(?:version|patch|versionfix)-\d+/;

sub new ($;$$) {
	my $class = shift;
	my $param = shift;
	my $on_error = shift || 0;
	$class = ref($class) if ref($class);

	my $self = [];
	bless $self, $class;
	if ($param) {
		$self->set($param);
	} else {
		$ERROR = "$class object constructed with empty name" if $on_error >= 0;
	}

	die "$ERROR\n" if $on_error > 1 && $ERROR;
	return $self;
}

sub set ($$) {
	my $self = shift;
	my $param = shift;

	@$self = ();
	$ERROR = undef;

	if (!$param) {
		# do nothing
	} elsif (!ref($param)) {
		# parse string
		if ($param =~ m!^($archive_re)(?:/($category_re)(?:(?:--($branch_re|))?(?:--($version_re|FIRST|LATEST)(?:--($revision_re|FIRST|LATEST))?)?)?)?$!o) {
			@$self = ($1, $2, $3, $4, $5);
			splice(@$self, @$self - 1) until defined $self->[-1];
			# handle branchless names
			$self->[$ELEMENT_INDEX{branch} - 1] ||= ""
				if defined $self->[$ELEMENT_INDEX{version} - 1];
		} else {
			$ERROR = "Can't parse name ($param)";
		}
	} elsif (UNIVERSAL::isa($param, 'Arch::Name')) {
		@$self = @$param;
	} elsif (ref($param) eq 'ARRAY') {
		$self->apply(@$param) if @$param;
	} elsif (ref($param) eq 'HASH') {
		$self->apply($param) if %$param;
	} else {
		$ERROR = "set: invalid parameter ($param), ignored";
	}
	return $self;
}

sub clone ($;@) {
	my $self = shift;
	my $clone = $self->new(undef, -1);
	@$clone = @$self;  # faster, don't perform checks
	$clone->apply(@_) if @_;
	return $clone;
}

sub apply ($;@) {
	my $self = shift;
	my $items = $_[0];

	$ERROR = undef;
	if (ref($items) eq 'HASH') {
		my %items = %$items;  # modify a copy
		my $i = 0;
		foreach my $regexp (
			$archive_re,
			$category_re,
			$branch_re,
			$version_re,
			$revision_re,
		) {
			my $elem = $ELEMENTS[$i + 1];
			next unless exists $items{$elem};
			my $item = $items{$elem};
			if (defined $item && $i > @$self) {
				$ERROR = "apply: can't change $elem without $ELEMENTS[$i]";
				last;
			}
			if (!defined $item) {
				splice(@$self, $i) if @$self > $i;
			} elsif ($elem eq "branch" && $item eq "" || $item =~ /^$regexp$/) {
				$self->[$i] = $item;
			} else {
				$ERROR = "apply: invalid $elem ($item)";
				last;
			}
			delete $items{$elem};
		} continue {
			$i++;
		}
		splice(@$self, $i) if @$self > $i;
		$ERROR ||= "apply: unknown elements (" . join(', ', keys %items) . "), ignored"
			if %items;
	} else {
		my %hash = ();
		if (ref($items) eq 'ARRAY') {
			my $level = @$self;
			$ERROR = "apply: excess of items (@$items), some but $level are ignored"
				if @$items > $level;
			$hash{$ELEMENTS[$level--] || 'none'} = $_ foreach @$items;
			shift;
		}
		my @items = @_;
		if (ref($items[0])) {
			$ERROR = "apply: unsupported arguments (@items)";
			@items = ();
		}
		my $level = @$self;
		$ERROR = "apply: excess of items (@items) for level $level, some are ignored"
			if @items >= @ELEMENTS - $level;
		$hash{$ELEMENTS[++$level] || 'none'} = $_ foreach @items;
		delete $hash{none};
		$self->apply(\%hash);
	}
	return $self;
}

sub go_up ($;$) {
	my $self = shift;
	my $level = shift || 1;
	return $self->apply([ (undef) x $level ]);
}

sub go_down ($@) {
	my $self = shift;
	return $self->apply(@_);
}

sub parent ($;$) {
	my $self = shift;
	return $self->clone->go_up(@_);
}

sub child ($@) {
	my $self = shift;
	return $self->clone->go_down(@_);
}

sub to_string ($) {
	my $self = shift;
	my $name = "";
	$name .= $self->[0] if @$self;
	$name .=  "/$self->[1]" if @$self > 1;
	$name .= "--$self->[2]" if @$self > 2 && $self->[2] ne "";
	$name .= "--$self->[3]" if @$self > 3;
	$name .= "--$self->[4]" if @$self > 4;
	return $name;
}

sub to_nonarch_string ($) {
	my $self = shift;
	my $name = $self->to_string;
	$name =~ s|^.*/||;
	return $name;
}

sub to_array ($) {
	my $self = shift;
	return wantarray? @$self: [ @$self ];
}

sub to_hash ($) {
	my $self = shift;
	my %hash = ();
	for (my $i = 0; $i < @$self; $i++) {
		$hash{$ELEMENTS[$i + 1]} = $self->[$i];
	}
	return wantarray? %hash: \%hash;
}

*fqn = *to_string; *fqn = *fqn;
*get = *to_array;  *get = *get;
*nan = *to_nonarch_string; *nan = *nan;

sub archive ($;$) {
	my $self = shift;
	return $self->[0] unless @_;
	$self->apply({ archive => shift });
}

sub category ($;$) {
	my $self = shift;
	return $self->[1] unless @_;
	$self->apply({ category => shift });
}

sub branch ($;$) {
	my $self = shift;
	return $self->[2] unless @_;
	$self->apply({ branch => shift });
}

sub version ($;$) {
	my $self = shift;
	return $self->[3] unless @_;
	$self->apply({ version => shift });
}

sub revision ($;$) {
	my $self = shift;
	return $self->[4] unless @_;
	$self->apply({ revision => shift });
}

sub error ($) {
	my $self = shift;
	return $ERROR;
}

sub level ($;$) {
	my $self = shift;
	my $stringify = shift;
	return scalar @$self unless $stringify;
	return $ELEMENTS[@$self];
}

sub cast ($$) {
	my $self = shift;
	my $elem = shift;
	my $index1 = $elem =~ /^\d+$/? $elem: $ELEMENT_INDEX{$elem};
	die "cast: invalid arg given ($elem)\n" unless defined $index1;
	return undef if $index1 > @$self;

	my $clone = $self->new(undef, -1);
	@$clone = (@$self)[0 .. $index1 - 1];
	return $clone;
}

sub is_valid ($;$$) {
	my $this = shift;
	my $self = ref($this)? $this: $this->new(shift);
	my $elem = shift;
	return @$self > 0 unless defined $elem;
	my $at_least = $elem =~ s/\+$//;
	my $index1 = $elem =~ /^\d+$/? $elem: $ELEMENT_INDEX{$elem};
	die "is_valid: invalid arg given ($elem)\n" unless defined $index1;
	return $index1 <= @$self if $at_least;
	return $index1 == @$self;
}

use overload
	'""'   => 'to_string',
	'0+'   => sub { $_[0]->level },
	'bool' => sub { $_[0]->is_valid },
	'='    => sub { $_[0]->clone },
	'+'    => sub { $_[0]->child($_[1]) },
	'-'    => sub { $_[0]->parent($_[1]) },
	'+='   => sub { $_[0]->go_down($_[1]) },
	'-='   => sub { $_[0]->go_up($_[1]) },
	'fallback' => 1;

1;

__END__

=head1 NAME

Arch::Name - parse, store and construct an arch name

=head1 SYNOPSIS 

    use Arch::Name;

    my $version_spec = 'some@hacker.org--pub/bugzilla--main--1.2';
    my $name = Arch::Name->new($version_spec);
    die unless $name eq $version;
    die unless $name - 2 eq 'some@hacker.org--pub/bugzilla';
    die unless $name->branch eq 'main';


    # list other branches (latest versions) in the tree archive
    my $category = Arch::Name->new($tree->get_version)->go_up(2);

    foreach my $branch_str ($session->branches($category)) {
        my $branch = $category->child($branch_str);
        my $latest_version = ($session->versions($branch))[-1];

        print $branch->go_down($latest_version)->to_string, "\n";
    }


    # another way to manipulate it
    my $category = Arch::Name->new($tree->get_version);
    $category->apply([undef, undef]);
    print $category->fqn, "\n", $category->parent->to_hash, "\n";


    # validate arch name from the user input
    # suppose we write a tool that accepts 3 command line args:
    #   * tree directory or branch+ (to get tree)
    #   * fully qualified revision (to get changeset)
    #   * archive+ (fully qualified category is ok too)
    my ($name_or_dir, $rvsn, $archv) = @ARGV;

    my $tree = Arch::Name->is_valid($name_or_dir, "branch+")?
        Arch::Session->new->get_tree($name_or_dir):
        Arch::Tree->new($name_or_dir);
    my $cset = $session->get_revision_changeset($rvsn)
        if Arch::Name->is_valid($rvsn, 'revision');
    my $possibly_archive = Arch::Name->new($archv);
    die "No archive" unless $possibly_archive->is_valid;
    my $archive = $possibly_archive->cast('archive');

=head1 DESCRIPTION

This class represents the Arch name concept and provides useful methods
to manipulate it.

The fully qualified Arch name looks like
I<archive>/I<category>--I<branch>--I<version>--I<revision> for revisions and
some prefix of it for other hierarchy citizens. The branchless names have
"--I<branch>" part removed.

=head1 METHODS

The following class methods are available:

B<new>,
B<set>,
B<clone>,
B<apply>,
B<go_up>,
B<go_down>,
B<parent>,
B<child>,
B<to_string>,
B<to_nonarch_string>,
B<to_array>,
B<to_hash>,
B<fqn>,
B<nan>,
B<get>,
B<archive>,
B<category>,
B<branch>,
B<version>,
B<revision>,
B<error>,
B<level>,
B<cast>,
B<is_valid>.

=over 4

=item B<new>

=item B<new> I<init> [I<on_error>=0]

Construct the C<Arch::Name> instanse. If the optional I<init> parameter is
given, then B<set> method is called with this parameter on the newly created
instanse.

By default (without I<init>), the empty name is created that does not pass
B<is_valid> check.

If I<on_error> is set and positive, then die on any initialization error,
i.e. when only a partial name is parsed or no name components are given.
By default an object representing a partial name is returning, and B<error>
may be used. If I<on_error> is set and is negative, then don't set any error.

Please note, that passing C<Arch::Name> object as the parameter does not
construct a new instance, but returns this passed object. Use B<clone>
instead if you want to clone the passed object. Or explicitly call B<set>.

=item B<set> I<object>

=item B<set> I<string>

=item B<set> I<arrayref>

=item B<set> I<hashref>

Store the new content. Multiple argument types supported. I<object> is another
reference object of type C<Arch::Name>. I<string> is fully qualified name.
I<arrayref> contains subnames, like the ones returned by B<to_array> method.
I<hashref> is hash with some or all keys I<archive>, I<category>, I<branch>,
I<version> and I<revision>, like the ones returned by B<to_hash> method.

=item B<clone> [I<init> ..]

Create and return a new C<Arch::Name> instanse that stores the same logical
arch name. If the optional I<init> parameter(s) given, then B<apply> method
is called with these parameters on the newly created instanse.

=item B<apply> I<hashref>

=item B<apply> [I<reversed_arrayref>] [I<subname> ..]

Similar to B<set>, but enables to apply a partial change. For example:

    my $name = Arch::Name->new("user@host--arch/cat--felix--1.2.3");

    $name->apply([ '1.2.4', 'leo' ]);        # ok, new branch-version
or:
    $name->apply({ branch => 'leo', version => '1.2.4' });  # ditto
or:
    $name->apply([ 'panther' ]);             # error, invalid version
or:
    $name->apply([ undef, 'panther' ]);      # ok, it is branch now
or:
    $name->apply({ category => 'dog' });     # ok, it is category now
or:
    $name->apply({ branch => 'leo' });       # ok, == [undef, 'leo']
or:
    $name->apply({ version => undef });      # ok, it is branch now
or:
    $name->apply({ revision => 'patch-6' }); # ok, it is revision now
or:
    $name->apply([], 'patch-6');             # ditto
or:
    $name->apply([ '1.2.4' ], 'patch-6');    # ditto with new version
or:
    $branch->apply([], '0', 'base-0');       # ok, go import revision
or:
    $branch->apply('0', 'base-0') ;          # ditto

=item B<go_up> [I<level>=1]

Remove one dimension (i.e. the last component) from the name,
or more than one dimension if I<level> is given. This is effectivelly
just a convenient shortcut for C<apply([ (undef) x I<level> ])>.

=item B<go_down> I<string> ..

Add one more dimension (i.e. new component I<string>) to the name.
Multiple new dimentions are supported. This is effectivelly just an
alias for C<apply(I<string>, .. )>.

=item B<parent> [I<level>=1]

Return object representing the parent arch name. This is just a shortcut for
C<clone-E<gt>go_up(I<level>)>.

=item B<child> I<string> ..

Return object representing the child arch name. This is just a shortcut for
C<clone-E<gt>go_down(I<string>)>.

=item B<to_string>

Return the fully qualified name.

=item B<to_nonarch_string>

Return the nonarch name (that is the fully qualified name without
I<archive/> part).

=item B<to_array>

Return the components of the name starting from archive to revision.
The returned array may contain 0 to 5 strings; the branch in branchless
names is represented by empty string.

Returns array or arrayref depending on context.

=item B<to_hash>

Return the hash containing the components of the name with keys:
I<archive>, I<category>, I<branch>, I<version> and I<revision>.

Returns hash or hashref depending on context.

=item B<fqn>

This is an alias for B<to_string>.

=item B<nan>

This is an alias for B<to_nonarch_string>.

=item B<get>

This is an alias for B<to_array>.

=item B<archive> [I<archive>]

Get or set the archive component only (the string). See also,
B<to_array> (getter) and B<apply> (setter).

=item B<category> [I<category>]

Get or set the category component only (the string). See also,
B<to_array> (getter) and B<apply> (setter).

=item B<branch> [I<branch>]

Get or set the branch component only (the string). See also,
B<to_array> (getter) and B<apply> (setter).

=item B<version> [I<version>]

Get or set the version component only (the string). See also,
B<to_array> (getter) and B<apply> (setter).

=item B<revision> [I<revision>]

Get or set the revision component only (the string). See also,
B<to_array> (getter) and B<apply> (setter).

=item B<error>

Return the last error string or undef. Some errors are fatal (like passing
unexiting [I<elem>] parameter to B<is_valid>), then the module dies. Some
errors are however not fatal (like setting malformed fully qualified name,
or setting revision part when no version part is set). In this case the name
is set to something adequate (usually empty name), and this method may be
used to get the error message.

This last error string is class global and it is (un)set on every B<set> or
B<apply> method.

=item B<level> [I<stringify-flag>]

Return 0 if the name is not valid (empty).
Return integer [1 .. 5] if the name is I<archive>, I<category>,
I<branch>, I<version> and I<revision> correspondingly.

If I<stringify-flag> is set, then return the same as a text, i.e. one of
the values: "none", "archive", "category", "branch", "version", "revision".

=item B<cast> I<elem>

Similar to B<parent> or B<clone>, but requires argument that is one of the
values that B<level> returns (i.e. either integers 0 .. 5 or strings
"none" .. "revision"). The returned cloned object contains only the number
of components specified by I<elem>.

If the original object contains less components than requested, then undef
if returned.

=item B<is_valid> [I<elem>]

Return true if the object contains the valid arch name (i.e. at least
one component).

If I<elem> is given that is one of the strings "archive", "category",
"branch", "version" and "revision", then return true if the object represents
the given element (for example, category), and false otherwise.

If I<elem> is given that is one of the strings "archive+", "category+",
"branch+", "version+" and "revision+", then return true if the object
represents at least the given element, and false otherwise.

=item Arch::Name->B<is_valid> I<name> [I<elem>]

This class method does two things, first constructs the C<Arch::Name>
object with I<name> as the constructor parameter, and then calls the
B<is_valid> method on this created object with optional I<elem> passed.

=back

=head1 OVERLOADED OPERATORS

The following operators are overloaded:

    ""    # to_string
    0+    # level
    bool  # is_valid
    =     # clone
    +     # child
    -     # parent
    +=    # go_down
    -=    # go_up

=head1 BUGS

No known bugs.

C<man perl | grep more>

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Session>, L<Arch::Library>,
L<Arch::Tree>.

=cut
