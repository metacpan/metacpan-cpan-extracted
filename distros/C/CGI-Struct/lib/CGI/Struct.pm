package CGI::Struct;

use strict;
use warnings;

=head1 NAME

CGI::Struct - Build structures from CGI data

=head1 VERSION

Version 1.21

=cut

our $VERSION = '1.21';


=head1 SYNOPSIS

This module allows transforming CGI GET/POST data into intricate data
structures.  It is reminiscent of PHP's building arrays from form data,
but with a perl twist.

  use CGI;
  use CGI::Struct;
  my $cgi = CGI->new;
  my %params = $cgi->Vars;
  my $struct = build_cgi_struct \%params;

=head1 DESCRIPTION

CGI::Struct lets you transform CGI data keys that I<look like> perl data
structures into I<actual> perl data structures.

CGI::Struct makes no attempt to actually I<read in> the variables from
the request.  You should be using L<CGI> or some equivalent for that.
CGI::Struct expects to be handed a reference to a hash containing all the
keys/values you care about.  The common way is to use something like
C<CGI-E<gt>Vars> or (as the author does)
C<Plack::Request-E<gt>parameters-E<gt>mixed>.

Whatever you use should give you a hash mapping the request variable
names (keys) to the values sent in by the users (values).  Any of the
major CGIish modules will have such a method; consult the documentation
for yours if you don't know it offhand.

Of course, this isn't necessarily tied strictly to CGI; you I<could> use
it to build data structures from any other source with similar syntax.
All CGI::Struct does is take one hash (reference) and turn it into
another hash (reference).  However, it's aimed at CGI uses, so it may or
may not work for something else.


=head1 EXAMPLES

=head2 Basic Usage

  <form action="request.cgi">
   Name:    <input type="text" name="uinfo{name}">
   Address: <input type="text" name="uinfo{addr}">
   Email:   <input type="text" name="uinfo{email}">
  </form>

When filled out and submitted the data will come in to request.cgi, which
will use something like C<CGI-E<gt>Vars> to parse it out into a hash

  use CGI;
  my $cgi = CGI->new;
  my %params = $cgi->Vars;

You'll wind up with something like

  %params = (
      'uinfo{name}'  => 'Bob',
      'uinfo{addr}'  => '123 Main Street',
      'uinfo{email}' => 'bob@bob.bob',
  )

Now we use CGI::Struct to parse that out

  use CGI::Struct;
  my $struct = build_cgi_struct \%params;

and we wind up with a structure that looks more like

  $struct = {
      'uinfo' => {
          name  => 'Bob',
          addr  => '123 Main Street',
          email => 'bob@bob.bob',
      }
  }

which is much simpler to use in your code.

=head2 Arrays

CGI::Struct also has the ability to build out arrays.

 First cousin:  <input type="text" name="cousins[0]">
 Second cousin: <input type="text" name="cousins[1]">
 Third cousin:  <input type="text" name="cousins[2]">

Run it through CGI to get the parameters, run through
L</build_cgi_struct>, and we get

  $struct = {
      'cousins' => [
        'Jill',
        'Joe',
        'Judy'
      ]
  }

Of course, most CGIish modules will roll that up into an array if you
just call it 'cousins' and have multiple inputs.  But this lets you
specify the indices.  For instance, you may want to base the array from 1
instead of 0:

 First cousin:  <input type="text" name="cousins[1]">
 Second cousin: <input type="text" name="cousins[2]">
 Third cousin:  <input type="text" name="cousins[3]">

  $struct = {
      'cousins' => [
        undef,
        'Jill',
        'Joe',
        'Judy'
      ]
  }

See also the L</Auto-arrays> section.

=head3 NULL delimited multiple values

When using L<CGI>'s C<-E<gt>Vars> and similar, multiple passed values
will wind up as a C<\0>-delimited string, rather than an array ref.  By
default, CGI::Struct will split it out into an array ref.  This behavior
can by disabled by using the C<nullsplit> config param; see the
L<function doc below|/build_cgi_struct>.

=head2 Deeper and deeper

Specifying arrays explicitly is also useful when building arbitrarily
deep structures, since the array doesn't have to be at the end

  <select name="users{bob}{cousins}[5]{firstname}">

After a quick trip through L</build_cgi_struct>, that'll turn into
C<$struct-E<gt>{users}{bob}{cousins}[5]{firstname}> just like you'd expect.

=head2 Dotted hashes

Also supported is dot notation for hash keys.  This saves you a few
keystrokes, and can look neater.  Hashes may be specified with either
the C<.> or with C<{}>.  Arrays can only be written with C<[]>.

The above C<select> could be written using dots for some or all of the
hash keys instead, looking a little Javascript-ish

  <select name="users.bob.cousins[5].firstname">
  <select name="users.bob{cousins}[5].firstname">
  <select name="users{bob}.cousins[5]{firstname}">

of course, you wouldn't really want to mix-and-match in one field in
practice; it just looks silly.

Sometimes, though, you may want to have dots in field names, and you
wouldn't want this parsing to happen then.  It can be disabled for a run
of L</build_cgi_struct> by passing a config param in; see the L<function
doc below|/build_cgi_struct>.

=head2 Auto-arrays

CGI::Struct also builds 'auto-arrays', which is to say it turns
parameters ending with an empty C<[]> into arrays and pushes things onto
them.

  <select multiple="multiple" name="users[]">

turns into

  $struct->{users} = ['lots', 'of', 'choices'];

This may seem unnecessary, given the ability of most CGI modules to
already build the array just by having multiple C<users> params given.
Also, since L</build_cgi_struct> only sees the data after your CGI module
has already parsed it out, it will only ever see a single key in its
input hash for any name anyway, since hashes can't have multiple keys
with the same name anyway.

However, there are a few uses for it.  PHP does this, so it makes for an
easier transition.  Also, it forces an array, so if you only chose one
entry in the list, L</build_cgi_struct> would still make that element in
the structure a (single-element) array

  $struct->{users} = ['one choice'];

which makes your code a bit simpler, since you don't have to expect both
a scalar and an array in that place (though of course you should make
sure it's what you expect for robustness).


=head1 FUNCTIONS

=cut


# Delimiters/groupers
my $delims = "[{.";

# Tuple types for each delim
my %dtypes = ( '[' => 'array', '{' => 'hash', '.' => 'hash' );

# Correponding ending groups
my %dcorr = ( '[' => ']', '{' => '}', '.' => undef );

# Yeah, export it
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(build_cgi_struct);

use Storable qw(dclone);





=head2 build_cgi_struct

  $struct = build_cgi_struct \%params;

  $struct = build_cgi_struct \%params, \@errs;

  $struct = build_cgi_struct \%params, \@errs, \%conf;

C<build_cgi_struct()> is the only function provided by this module.  It
takes as an argument a reference to a hash of parameter name keys and
parameter value values.  It returns a reference to a hash with the fully
built up structure.  Any keys that can't be figured out are not present
in the returned hash.

An optional array reference can be passed as the second argument, in
which case the array will be filled in with any warnings or errors found
in trying to build the structure.  This should be taken as a debugging
tool for the developer's eyes to parse, not a source of friendly-looking
warnings to hand to non-technical users or as strongly formatted strings
for automated error mining.

A hash reference may be supplied as a third argument for passing config
parameters.  The currently supported parameters are:

=over

=item nodot

This allows you to disable processing of C<.> as a hash element
separator.  There may be cases where you want a C<.> as part of a field
name, so this lets you still use C<{}> and C<[]> structure in those
cases.

The default is B<false> (i.e., I<do> use C<.> as separator).  Pass a true
value (like C<1>) to B<not> do so.

=item nullsplit

C<CGI-E<gt>Vars> and compatible functions tend to, in hash form, wind up
with a NULL-delimited list rather than an array ref when passed multiple
values with the same key.  CGI::Struct will check string values for
embedded C<\0>'s and, if found, C<split> the string on them and create an
arrayref.

The C<nullsplit> config param lets you disable this if you want strings
with embedded C<\0> to pass through unmolested.  Pass a false value (like
C<0>) to disable the splitting.

=item dclone

By default, CGI::Struct uses L<Storable>'s C<dclone> to do deep copies of
incoming data structures.  This ensures that whatever changes you might
make to C<$struct> later on don't change stuff in C<%params> too.  By
setting dclone to a B<false> value (like C<0>) you can disable this, and
make it so deeper refs in the data structures point to the same items.

You probably don't want to do this, unless some data is so huge you don't
want to keep 2 copies around, or you really I<do> want to edit the
original C<%params> for some reason.

=back

=cut

sub build_cgi_struct
{
	my ($iv, $errs, $conf) = @_;

	my (%ret, @errs);

	# Allow disabling '.'
	my $delims = $delims;
	$delims =~ s/\.// if($conf && $conf->{nodot});

	# nullsplit defaults on
	$conf->{nullsplit} = 1 unless exists $conf->{nullsplit};

	# So does deep cloning
	$conf->{dclone} = 1 unless exists $conf->{dclone};
	my $dclone = sub { @_ > 1 ? @_ : $_[0] };
	$dclone = \&dclone if $conf->{dclone};

	# Loop over keys, one at a time.
	DKEYS: for my $k (keys %$iv)
	{
		# Shortcut; if it doesn't contain any special chars, just assign
		# to the output and go back around.
		unless( $k =~ /[$delims]/)
		{
			my $nval = ref $iv->{$k} ? $dclone->($iv->{$k}) : $iv->{$k};
			$nval = [split /\0/, $nval]
					if($conf->{nullsplit} && ref($nval) eq ''
					   && $nval =~ /\0/);
			$ret{$k} = $nval;
			next;
		}

		# Bomb if it starts with a special
		if($k =~ /^[$delims]/)
		{
			push @errs, "Bad key; unexpected initial char in $k";
			next;
		}

		# Break it up into the pieces.  Use the capture in split's
		# pattern so we get the bits it matched, so we can differentiate
		# between hashes and arrays.
		my @kps = split /([$delims])/, $k;

		# The first of that is our top-level key.  Use that to initialize
		# our pointer to walk down the structure.
		# $p remains a reference to a reference all the way down the
		# walk.  That's necessary; if we just make it a single reference,
		# then it couldn't be used to replace a level as necessary (e.g.,
		# from undef to [] or {} when we initialize).
		my $p;
		{
			my $topname = shift @kps;

			# Make sure the key exists, then ref at it.
			$ret{$topname} ||= undef;

			# A reference to a reference
			$p = \$ret{$topname};
		}

		# Flag for autoarr'ing the value
		my $autoarr = 0;

		# Now walk over the rest of the pieces and create the structure
		# all the way down
		my $i = 0;
		while($i <= $#kps)
		{
			# First bit should be a special
			if(length($kps[$i]) != 1 || $kps[$i] !~ /^[$delims]$/)
			{
				# This should only be possible via internal error.  If
				# deliminters aren't properly matched anywhere along the
				# way, we _could_ end up with a case where the
				# even-numbered items here aren't valid openers, but if
				# that's the case then some error will have already
				# triggered about the mismatch.
				die "Internal error: Bad type $kps[$i] found at $i for $k";
			}

			# OK, pull out that delimiter, and the name of the piece
			my $sdel = $kps[$i++];
			my $sname = $kps[$i++];

			# The name should end with the corresponding ender...
			if($dcorr{$sdel} && $dcorr{$sdel} ne substr($sname, -1))
			{
				push @errs, "Didn't find ender for ${sdel} in $sname for $k";
				next DKEYS;
			}
			# ... and remove it, leaving just the name
			chop $sname if $dcorr{$sdel};

			# Better be >0 chars...
			unless(defined($sname) && length $sname)
			{
				# Special case: if this is the last bit, and it's an
				# array, then we do the auto-array stuff.
				if($i > $#kps && $dtypes{$sdel} eq "array")
				{
					$autoarr = 1;
					last;
				}

				# Otherwise a 0-length label is an error.
				push @errs, "Zero-length name element found in $k";
				next DKEYS;
			}

			# If it's an array, better be a number
			if($dtypes{$sdel} eq "array" && $sname !~ /^\d+$/)
			{
				push @errs, "Array subscript should be a number, "
				          . "not $sname in $k";
				next DKEYS;
			}


			# Now we know the type, so fill in that level of the
			# structure
			my $stype = $dtypes{$sdel};

			# Initialize if necessary.
			if($stype eq "array")
			{ ($$p) ||= [] }
			elsif($stype eq "hash")
			{ ($$p) ||= {} }
			else
			{ die "Internal error: unknown type $stype in $k" }

			# Check type
			unless(ref($$p) eq uc($stype))
			{
				push @errs, "Type mismatch: already have " . ref($$p)
				          . ", expecting $stype for $sname in $k";
				# Give up on this key totally; who knows what to do
				next DKEYS;
			}

			# Set.  Move our pointer down a step, and loop back around to
			# the next component in this path
			if($stype eq "array")
			{ $p = \($$p)->[$sname] }
			elsif($stype eq "hash")
			{ $p = \($$p)->{$sname} }

			# And back around
		}


		# OK, we're now all the way to the bottom, and $p is a reference
		# to that last step in the structure.  Fill in the value ($p
		# becomes a reference to a reference to that value).
		# Special case: for autoarrays, we make sure the value ends up
		# being a single-element array rather than a scalar, if it isn't
		# already an array.
		my $nval = ref $iv->{$k} ? $dclone->($iv->{$k}) : $iv->{$k};
		$nval = [split /\0/, $nval]
				if($conf->{nullsplit} && ref($nval) eq '' && $nval =~ /\0/);
		if($autoarr && $nval && ref($nval) ne 'ARRAY')
		{ $$p = [$nval]; }
		else
		{ $$p = $nval; }

		# And around to the next key
	}


	# If they asked for error details, give it to 'em
	push @$errs, @errs if $errs;

	# Done!
	return \%ret;
}

=head1 SEE ALSO

L<CGI>, L<CGI::Simple>, L<CGI::Minimal>, L<Plack>, and many other choices
for handling transforming a browser's request info a data structure
suitable for parsing.

L<CGI::State> is somewhat similar to CGI::Struct, but is extremely
tightly coupled to L<CGI> and doesn't have as much flexibility in the
structures it can build.

L<CGI::Expand> also does similar things, but is more closely tied to
L<CGI> or a near-equivalent.  It tries to DWIM hashes and arrays using
only a single separator.

The structure building done here is a perlish equivalent to the structure
building PHP does with passed-in parameters.

=head1 AUTHOR

Matthew Fuller, C<< <fullermd@over-yonder.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-struct at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Struct>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORTED VERSIONS

CGI::Struct should work on perl 5.6 and later.  It includes a
comprehensive test suite, so passing that should be an indicator that it
works.  If that's not the case, I want to hear about it so the testing
can be improved!

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Struct


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Struct>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Struct>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Struct>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Struct/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Matthew Fuller.

This software is licensed under the 2-clause BSD license.  See the
LICENSE file in the distribution for details.

=cut

1; # End of CGI::Struct
