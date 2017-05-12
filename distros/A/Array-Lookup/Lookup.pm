# Array::Lookup.pm

package Array::Lookup;

$VERSION = '2.3';

@ISA    = qw(Exporter);
@EXPORT = qw(lookup lookup_error);

sub lookup;
sub lookup_error;

use Carp;
use Array::PrintCols;

sub lookup {
    my $key    = shift;
    length($key)       or croak "Missing lookup key argument.\n";
    my $keytab = shift or croak "Missing keyword table argument\n";
    my $nfsub  = shift;
    my $tmsub  = shift;

    my @keys;
    if (ref($keytab) eq 'HASH') {
	@keys = sort(keys %$keytab);      # get sorted list of keys
    } elsif (ref($keytab) eq 'ARRAY') {
	@keys = sort(@$keytab);           # get the sorted list of array items
    } else {
	croak "lookup: Second argument must be a HASH or ARRAY ref!\n";
    }
    # first check for any *exact* match
    my @matches = grep(/^\Q$key\E$/i, @keys);
    if (@matches or		# any exact matches?
				# if not, try abbreviation search
	((@matches = grep(/^\Q$key\E/i,@keys)) and 
	 $#matches == 0)) {	# is there exactly one abbrev?
	$value = $matches[0];	# yes, either an exact or abbrev
	$value = $keytab->{$value} if ref($keytab) eq 'HASH';
	return $value;
    }
    if ($#matches < 0) {	# no matches?
	&$nfsub($key, $keytab, '') if ref($nfsub) eq 'CODE';
    } elsif ($#matches > 0) {	# too many matches
	&$tmsub($key, $keytab, \@matches) if ref($tmsub) eq 'CODE';
    }
    undef;
}

# Standard error handler for "lookup"

sub lookup_error {
    my $key    = shift;
    my $keytab = shift;
    my $err    = shift;
    my $msg    = shift || "lookup failed: '%s' %s; use one of:\n";
    printf STDERR ($msg, $key, ($err ? 'is ambiguous' : 'not found'));
    print_cols $keytab,'','',1;
    undef;
}

1;

__END__

=head1 NAME

B<Array::Lookup> - Lookup strings in arrays or hash tables with abbreviation.

=head1 SYNOPSIS

    use Array::Lookup;

    $value = lookup $key, \@keywords, \&notfound, \&toomany;

    $value = lookup $key, \%keywords, \&notfound, \&toomany;

    lookup_error $key, $keywords, $err, $msg;

=head1 DESCRIPTION

=head2 B<lookup>

Lookup C<I<$key>> in the table C<I<@keywords>> and return the
unambiguously matching keyword, if any.  If the second argument is given
as a hash array, C<I<%keywords>>, then lookup a matching key, with
abbreviation, and return the value corresponding to the unambiguously
matching key.

If there are no matches, invoke C<I<&notfound>> like this:

    &$notfound( $key, \@keywords, '');

If there are two or more matches, invoke C<I<&toomany>> like this:

    &$toomany( $key, \@keywords, \@matches);

If either subroutine is omitted or null, then no special action is taken
except that C<undef> is returned for the failed lookup.

Note that the third argument, the array of ambiguous matches, allows a 
common subroutine to be used for both error conditions and still 
distinguish the error.

See L<"lookup_error"> for a standard method of handling lookup failures.

=head2 B<lookup_error>

Handle an error for the C<I<lookup>> subroutine.  The arguments:

=over 10

=item $key

The search key which failed the lookup.

=item $keywords

The hash or array reference containing the keywords none of which matched
the C<$key>.

=item $err

A flag indicating if the lookup failed because of no matches at all (''), or
if the lookup failed because of too many matches (C<\@matches>);

=item $msg

A format string used to format and print the error message.  It should
contain two I<printf> substitution sequences: C<%s>.  The first will be
substituted with the failed lookup key; the second with one of the
phrases: C<"not found"> or C<"is ambiguous">, depending upon C<I<$err>>.

If C<I<$msg>> is omitted or null, a default message will be used:

  "lookup failed: %s %s; use one of:\n"

followed by a listing of the strings in the C<I<$keywords>> array.

=back

=head1 EXAMPLES

=head2 Using arrays

    use Array::Lookup;
    ...
    @keywords = qw(quit find get set show);
    ...
    $command = <STDIN>;
    $command = lookup $command, \@keywords, 
	sub { lookup_error @_, "Unknown command '%s'; use one of:\n"; },
	sub { lookup_error @_, "Command '%s' %s; use one of:\n"; };

=head2 Using hashes

    use Array::Lookup;
    ...
    %Commands = ( 'quit' => \&quit,  'get' => \&get,  'set' => \&set,
    	          'find' => \&find,  'show' => \&show );
    ...
    $input = <STDIN>;
    $command_sub = lookup $input, \%Commands, 
	sub { lookup_error @_, "Unknown command '%s'; use one of:\n"; },
	sub { lookup_error @_, "Command '%s' %s; use one of:\n"; };

=head1 SEE ALSO

L<Array::PrintCols>

=head1 AUTHOR

Alan K. Stebbens <aks@stebbens.org>

=cut


# Emacs Local Variables:
# Emacs mode: perl
# Emacs backup-by-copying-when-linked: t
# Emacs End:
