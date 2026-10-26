package App::Actions::Schema::Invalid;

use strict;
use warnings;

# An App::Actions::Error with the code schema.invalid, so a caller can ask
# either "is it an Invalid?" or "is it the error schema.invalid?".  It reports
# a document rather than a place in the code, so it has no location, and the
# message is the whole text, which keeps message and stringification equal.
use parent 'App::Actions::Error';

our $VERSION = '0.002.1';

sub new {
	my ($class, $message) = @_;

	return $class->SUPER::new(code => 'schema.invalid', message => $message, location => '');
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Schema::Invalid - the error for a document that does not match its schema

=head1 SYNOPSIS

Catch it after a check:

	use App::Actions::Schema qw(assert_valid);

	eval { assert_valid($document, $schema, 'the report does not match its schema'); 1 }
		or do {
			my $error = $@;
			if (ref $error && $error->isa('App::Actions::Schema::Invalid')) {
				print STDERR $error->message;
				exit App::Actions::Schema::invalid_exit();
			}
			die $error;
		};

Ask by code, as for any App::Actions::Error:

	if (my $error = App::Actions::Error->caught($@)) {
		exit 70 if $error->is('schema.invalid');
	}

Throw one yourself:

	die App::Actions::Schema::Invalid->new("my document: \$.name: missing\n");

=head1 DESCRIPTION

L<App::Actions::Schema/assert_valid> throws this object when a document does
not match its schema.  It is an L<App::Actions::Error>, so it has every
method that class has.  Three things are always the same:

=over 4

=item * its code is C<schema.invalid>;

=item * its location is empty, because the problem is in a document, not at
a place in the program;

=item * so, as a string, it is exactly its message, with the newline at the
end if the message has one.  C<die> and C<warn> print it unchanged.

=back

=head1 METHODS

=head2 new

	my $error = App::Actions::Schema::Invalid->new($message);

Makes the error.

=head3 ARGUMENTS

=over 4

=item * C<$message> - the whole text to show.  End it with a newline if it
is a complete line.

=back

=head3 RETURNS

The new object.  All the methods of L<App::Actions::Error> work on it, for
example C<message>, C<code> and C<is>.

=head3 SIDE EFFECTS

None.  The object is returned, not thrown; use C<die> to throw it.

=head3 EXAMPLE

	my $error = App::Actions::Schema::Invalid->new("\$.jobs: missing\n");
	print $error->code;       # schema.invalid
	print "$error";           # $.jobs: missing

=head3 API SPECIFICATION

=head4 INPUT

	{ message => { type => 'string', min => 1 } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Schema::Invalid' }

=head3 MESSAGES

None.

=head1 COMMON PITFALLS

=over 4

=item * B<Check the class or code, not the text.>  The message text can
change between releases.  Use C<isa('App::Actions::Schema::Invalid')> or
C<is('schema.invalid')>.

=item * B<The newline is part of the message.>  C<message> returns it too, so
C<chomp> the text if you put it inside another sentence.

=back

=head1 ENCODING

The message is a Perl character string and may contain any Unicode text,
including emoji.  Encode it (for example with C<binmode STDERR,
':encoding(UTF-8)'>) before you print it.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes the routine in the Z notation.  You do not need it to
use the module.  A name ending in C<?> is an input and one ending in C<!> is
an output.  C<Error> is the state described in
L<App::Actions::Error/FORMAL SPECIFICATION>.

=head2 new

	┌─ NewInvalid ──────────────────────────────────────
	│ message? : seq CHAR
	│ e!       : Error
	├───────────────────────────────────────────────────
	│ e!.code = "schema.invalid"
	│ e!.message = message?
	│ e!.location = ⟨⟩
	│ string(e!) = message?
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The object never changes after it is made:

	   new($message)              die $error              caught / isa / is
	--------------------> +-----------+ ----------> +--------+ -----------------> handled
	                      |  CREATED  |             | THROWN |   (e.g. exit 70)
	                      +-----------+             +--------+
	                                                    |
	                                                    | not caught
	                                                    v
	                                           program stops; STDERR shows
	                                           the message, with no location

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
