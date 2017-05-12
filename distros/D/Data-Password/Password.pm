package Data::Password;

# Ariel Brosh (RIP), January 2002, for Raz Information Systems
# Oded S. Resnik, 3 April 2004, for Raz Information Systems



use strict;
require Exporter;
use vars qw($DICTIONARY $FOLLOWING $GROUPS $MINLEN $MAXLEN $SKIPCHAR
		$FOLLOWING_KEYBOARD @DICTIONARIES $BADCHARS
		$VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

@EXPORT_OK = qw($DICTIONARY $FOLLOWING $GROUPS $FOLLOWING_KEYBOARD $SKIPCHAR $BADCHARS
	@DICTIONARIES $MINLEN $MAXLEN IsBadPassword IsBadPasswordForUNIX);
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
@ISA = qw(Exporter);

$VERSION = '1.12';

# Settings
$DICTIONARY = 5;
$FOLLOWING = 3;
$FOLLOWING_KEYBOARD = 1;
$GROUPS = 2;

$MINLEN = 6;
$MAXLEN = 8;
$SKIPCHAR = 0;
$BADCHARS = '\0-\x1F\x7F';

@DICTIONARIES = qw(/usr/dict/web2 /usr/dict/words /usr/share/dict/words /usr/share/dict/linux.words);

sub OpenDictionary {
	foreach my $sym (@DICTIONARIES) {
		return $sym if -r $sym;
	}
	return;
}

sub CheckDict {
	return unless $DICTIONARY;
	my $pass = shift;
	my $dict = OpenDictionary();
	return unless $dict;
	open (DICT,"$dict") || return;
        $pass = lc($pass);

	while (my $dict_line  = <DICT>) {
		chomp ($dict_line);
		next if length($dict_line) < $DICTIONARY;
		$dict_line = lc($dict_line);
		if (index($pass,$dict_line)>-1) {
			close(DICT);
			return $dict_line;
		}
	}
	close(DICT);
	return;
}

sub CheckSort {
	return unless $FOLLOWING;
	my $pass = shift;
	foreach (1 .. 2) {
		my @letters = split(//, $pass);
		my $diffs;
		my $last = shift @letters;
		foreach (@letters) {
			$diffs .= chr((ord($_) - ord($last) + 256 + 65) % 256);
			$last = $_;
		}
		my $len = $FOLLOWING - 1;
		return 1 if $diffs =~ /([\@AB])\1{$len}/;
		return unless $FOLLOWING_KEYBOARD;

		my $mask = $pass;
		$pass =~ tr/A-Z/a-z/;
		$mask ^= $pass;
		$pass =~ tr/qwertyuiopasdfghjklzxcvbnm/abcdefghijKLMNOPQRStuvwxyz/;
		$pass ^= $mask;
	}
	return;
}

sub CheckTypes {
	return undef unless $GROUPS;
	my $pass = shift;
	my @groups = qw(a-z A-Z 0-9 ^A-Za-z0-9);
	my $count;
	foreach (@groups) {
		$count++ if $pass =~ /[$_]/;
	}
	$count < $GROUPS;
}

sub CheckCharset {
	my $pass = shift;
        return 0 if $SKIPCHAR;
	$pass =~ /[$BADCHARS]/; 
}

sub CheckLength {
	my $pass = shift;
	my $len = length($pass);
	return 1 if ($MINLEN && $len < $MINLEN);
	return 1 if ($MAXLEN && $len > $MAXLEN);
	return;
}

sub IsBadPassword {
	my $pass = shift;
	if (CheckLength($pass)) {
    if ($MAXLEN && $MINLEN) {
      return "Not between $MINLEN and $MAXLEN characters";
    }
    elsif (!$MAXLEN) { return "Not $MINLEN characters or greater"; }
    else { return "Not less than or equal to $MAXLEN characters"; }
  }
  return "contains bad characters" if CheckCharset($pass);
	return "contains less than $GROUPS character groups"
		if CheckTypes($pass);
	return "contains over $FOLLOWING leading characters in sequence"
		if CheckSort($pass);
	my $dict = CheckDict($pass);
	return "contains the dictionary word '$dict'" if $dict;
	return;
}

sub IsBadPasswordForUNIX {
	my ($user, $pass) = @_;
	my $reason = IsBadPassword($pass);
	return $reason if $reason;
	my $tuser = $user;
	$tuser =~ s/[^a-zA-Z]//g;
	return "is based on the username" if ($pass =~ /$tuser/i);

	my ($name,$passwd,$uid,$gid,
       		$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($user);
	return unless $comment;
	foreach ($comment =~ /([A-Z]+)/ig) {
		return "is based on the finger information" if ($pass =~ /$_/i);
	}
	return;
}

1;
__END__

=head1 NAME

Data::Password - Perl extension for assessing password quality.

=head1 SYNOPSIS

	use Data::Password qw(IsBadPassword);

	print IsBadPassword("clearant");

	# Bad password - contains the word 'clear', only lowercase

	use Data::Password qw(:all);

	$DICTIONARY = 0;

	$GROUPS = 0;
   
        $SKIPCHAR = 0;

	print IsBadPassword("clearant");

=head1 DESCRIPTION

This module checks potential passwords for crackability.
It checks that the password is in the appropriate length,
that it has enough character groups, that it does not contain the same 
characters repeatedly or ascending or descending characters, or charcters
close to each other in the keyboard.
It will also attempt to search the ispell word file for existance 
of whole words.
The module's policies can be modified by changing its variables.  (Check L<"VARIABLES">).
For doing it, it is recommended to import the ':all' shortcut
when requiring it:

I<use Data::Password qw(:all);>

=head1 FUNCTIONS

=over 4

=item 1

IsBadPassword(password)

Returns undef if the password is ok, or a textual description of the fault if any.

=item 2

IsBadPasswordForUNIX(user, password)

Performs two additional checks: compares the password against the
login name and the "comment" (ie, real name) found on the user file.

=back

=head1 VARIABLES

=over 4

=item 1

$DICTIONARY

Minimal length for dictionary words that are not allowed to appear in the password. Set to false to disable dictionary check.

=item 2

$FOLLOWING

Maximal length of characters in a row to allow if the same or following.
If $FOLLOWING_KEYBOARD is true (default), the module will also check
for alphabetical keys following, according to the English keyboard
layout.
Set $FOLLOWING to false to bypass this check.

=item 3

$GROUPS

Groups of characters are lowercase letters, uppercase letters, digits
and the rest of the allowed characters. Set $GROUPS to the number
of minimal character groups a password is required to have.
Setting to false or to 1 will bypass the check.

=item 4

$MINLEN

$MAXLEN

Minimum and maximum length of a password. Both can be set to false.

=item 5

@DICTIONARIES

Location where we are looking for dictionary files. You may want to 
set this variable if you are using not *NIX like operating system.

=item 6

$SKIPCHAR

Set $SKIPCHAR to 1 to skip checking for bad characters.

=item 7 

$BADCHARS

Prohibit a specific character range. Excluded character range 
regualr experssion is expect. (You may use ^ to allow specific range)
Default value is: '\0-\x1F\x7F'
For ASCII only set value $BADCHARS = '^\x20-\x7F';
Force numbers and upper case only $BADCHARS = '^A-Z1-9';

=back

=head1 FILES

=over 4

=item *

/usr/dict/web2

=item *

/usr/dict/words

=item *

/etc/passwd

=back

=head1 SEE ALSO

See L<Data::Password::BasicCheck> if you need only basic password checking.
Other modules L<Data::Password::Common>, L<Data::Password::Check>,
L<Data::Password::Meter>, L<Data::Password::Entropy> 
and L<String::Validator::Password>


=head1 AUTHOR

Ariel Brosh (RIP), January 2002.

Oded S. Resnik, from April 2004.

=head1 COPYRIGHT

Copyright (c) 2001 - 2014  Raz Information Systems Ltd.
L<http://www.raz.co.il/>

This package is distributed under the same terms as Perl itself, see the
Artistic License on Perl's home page.


=cut
