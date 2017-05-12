package Data::FormValidator::Constraints::Words;

use strict;
use warnings;

use vars qw($VERSION $AUTOLOAD
            $REALNAME $BASICWORDS $SIMPLEWORDS $PRINTSAFE $PARAGRAPH
            $USERNAME $PASSWORD);

$VERSION = '0.10';

#----------------------------------------------------------------------------

=head1 NAME

Data::FormValidator::Constraints::Words - Data constraints for word inputs.

=head1 SYNOPSIS

  use Data::FormValidator::Constraints::Words;

  my $rv = Data::FormValidator->check(\%input, {
     real_name      => realname(),
     basic_words    => basicwords(),
     simple_words   => simplewords(),
     print_safe     => printsafe(),
     paragraph      => paragraph(),
     username       => username(),
     password       => password(),
  },

  # or, use the regular functions
  my $rv = Data::FormValidator->check(\%input, {
     comments => sub {
        my($dfv, $value) = @_;
        return $dfv->match_paragraph($value);
     }
  });

=head1 DESCRIPTION

C<Data::FormValidator::Constraints::Words> provides several methods that
can be used to generate constraint closures for use with C<Data::FormValidator>
for the purpose of validating textual input.

=cut

#----------------------------------------------------------------------------
# Exporter Settings

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(
	realname	valid_realname		match_realname
    basicwords	valid_basicwords	match_basicwords
    simplewords	valid_simplewords	match_simplewords
	printsafe	valid_printsafe		match_printsafe
    paragraph	valid_paragraph		match_paragraph
    username	valid_username		match_username
    password	valid_password		match_password
);

#----------------------------------------------------------------------------
# Variables

=head1 CHARACTER SETS

In the methods below several character code ranges are specified, below is
a quick guide to what those ranges represent:

  Dec     Oct     Hex   Description
  ---------------------------------------------------------
   32-47  040-057 20-2F ASCII symbols
   48-57  060-071 30-39 ASCII numerals
   58-64  072-100 3A-40 ASCII symbols
   65-90  101-132 41-5A ASCII uppercase alphabetics
   91-96  133-140 5B-60 ASCII symbols
   97-122 141-172 61-7A ASCII lowercase alphabetics
  123-126 173-176 7B-7E ASCII symbols
  128-159 200-237 80-9F Extended symbols (unsupported in HTML4 standard)
  160-191 240-277 A0-BF Extended symbols
  192-255 300-377 C0-FF Extended alphabetics

The above table is based on the ISO Latin 1 (ISO 8859-1) set of encodings. The
character range of 128-159 has no corresponding HTML entity encodings, and are
considered control characters in the ISO Latin 1 character set. See 
http://www.ascii-code.com/ for more details.

If you wish to override these settings, subclass this module and set the 
appropriate values for the following regular expression settings:

  $REALNAME    = q/\-\s\w.,\'\xC0-\xFF/;
  $BASICWORDS  = q/\-\s\w.,\'\"&;:\?\#\xC0-\xFF/;
  $SIMPLEWORDS = q/\-\s\w.,\'\"&;:\?\#~\+=\(\)\[\]\{\}<>\/!\xC0-\xFF/;
  $PRINTSAFE   = q/\s\x20-\x7E\xA0-\xFF/;
  $PARAGRAPH   = q/\s\x20-\x7E\xA0-\xFF/;
  $USERNAME    = q/\x30-\x39\x41-\x5A\x61-\x7A\x8A\x8C\x8E\x9A\x9C\x9E\x9F\xC0-\xFF/;
  $PASSWORD    = q/\x21-\x7E\x80\x82-\x8C\x8E\x91-\x9C\x9E-\x9F\xA1-\xAC\xAE-\xFF/;

Note that these are used within a character class, so characters such as '-'
must be escaped.

Although here PRINTSAFE and PARAGRAPH are the same, they may not be when
subclassed.

Both USERNAME and PASSWORD exclude whitespace characters, while USERNAME also
excludes all symbol characters.

=cut

$REALNAME    = q/\-\s\w.,\'\xC0-\xFF/;
$BASICWORDS  = q/\-\s\w.,\'\"&;:\?\#\xC0-\xFF/;
$SIMPLEWORDS = q/\-\s\w.,\'\"&;:\?\#~\+=\(\)\[\]\{\}<>\/!\xC0-\xFF/;
$PRINTSAFE   = q/\s\x20-\x7E\xA0-\xFF/;
$PARAGRAPH   = q/\s\x20-\x7E\xA0-\xFF/;
$USERNAME    = q/\x30-\x39\x41-\x5A\x61-\x7A\x8A\x8C\x8E\x9A\x9C\x9E\x9F\xC0-\xFF/;
$PASSWORD    = q/\x21-\x7E\x80\x82-\x8C\x8E\x91-\x9C\x9E-\x9F\xA1-\xAC\xAE-\xFF/;

#----------------------------------------------------------------------------
# Subroutines

=head1 METHODS

=head2 realname

The realname methods allows commonly used characters within a person's name
to be used. Also restricts the string length to 128 characters. Acceptable
characters must match the $REALNAME regular expression.

=over 4

=item * realname

=item * valid_realname

=item * match_realname

=back

=cut

sub realname {
	return sub {
		my ($self,$word) = @_;
		$self->set_current_constraint_name('realname');
		$self->valid_realname($word);
	}
}

sub valid_realname {
    my ($self,$word) = @_;
    return 0    unless($word);
	$word =~ m< ^( [$REALNAME]+ )$ >x ? 1 : 0;
}

sub match_realname {
    my ($self,$word) = @_;
	return unless defined $word;
	$word =~ s/\s+/ /g;
	$word =~ s/[^$REALNAME]+//g;
	return substr $word, 0, 128;
}

=head2 basicwords

The basicwords methods allow a restricted character set to match simple
strings, such as reference codes. Acceptable characters must match the
$BASICWORDS regular expression:

=over 4

=item * basicwords

=item * valid_basicwords

=item * match_basicwords

=back

=cut

sub basicwords {
	return sub {
		my ($self,$word) = @_;
		$self->set_current_constraint_name('basicwords');
		$self->valid_basicwords($word);
	}
}

sub match_basicwords {
    my ($self,$word) = @_;
	return unless defined $word;
	$word =~ m< ^( [$BASICWORDS]+ )$ >x ? $1 : undef;
}

=head2 simplewords

The simplewords methods allow commonly used characters within simple text box
input, such as for titles. Acceptable characters must match the $SIMPLEWORDS
regular expression.

=over 4

=item * simplewords

=item * valid_simplewords

=item * match_simplewords

=back

=cut

sub simplewords {
	return sub {
		my ($self,$word) = @_;
		$self->set_current_constraint_name('simplewords');
		$self->valid_simplewords($word);
	}
}

sub match_simplewords {
    my ($self,$word) = @_;
	return unless defined $word;
	$word =~ m< ^( [$SIMPLEWORDS]+ )$ >x ? $1 : undef;
}

=head2 printsafe

The printsafe methods restrict characters to those non-control characters
within the character set. Acceptable characters must match the $PRINTSAFE
regular expression.

=over 4

=item * printsafe

=item * valid_printsafe

=item * match_printsafe

=back

=cut

sub printsafe {
	return sub {
		my ($self,$word) = @_;
		$self->set_current_constraint_name('printsafe');
		$self->valid_printsafe($word);
	}
}

sub valid_printsafe {
    my ($self,$word) = @_;
	return unless defined $word;
	$word =~ m< ^( [$PRINTSAFE]+ )$ >x ? 1 : 0;
}

sub match_printsafe {
    my ($self,$word) = @_;
	return  unless defined $word;
	$word =~ s/[^$PRINTSAFE]+//;
	return $word || undef;
}

=head2 paragraph

The paragraph methods allows for a larger range of characters that would be
expected to appear in a textarea input, such as a news story or a review.
Acceptable characters must match the $PARAGRAPH regular expression:

=over 4

=item * paragraph

=item * valid_paragraph

=item * match_paragraph

=back

=cut

sub paragraph {
	return sub {
		my ($self,$word) = @_;
		$self->set_current_constraint_name('paragraph');
		$self->valid_paragraph($word);
	}
}

sub match_paragraph {
    my ($self,$word) = @_;
	return unless defined $word;
	$word =~ m< ^( [$PARAGRAPH]+ )$ >x ? $1 : undef;
}

=head2 username

The username methods allows for a restricted range of letter only characters
that would be expected to appear in a username style input field. Acceptable 
characters must match the $USERNAME regular expression:

=over 4

=item * username

=item * valid_username

=item * match_username

=back

=cut

sub username {
	return sub {
		my ($self,$word) = @_;
		$self->set_current_constraint_name('username');
		$self->valid_username($word);
	}
}

sub match_username {
    my ($self,$word) = @_;
	return unless defined $word;
	$word =~ m< ^( [$USERNAME]+ )$ >x ? $1 : undef;
}

=head2 password

The password methods allows for a restricted range of characters that would be
expected to appear in a password style input field. Acceptable characters must 
match the $PASSWORD regular expression:

=over 4

=item * password

=item * valid_password

=item * match_password

=back

=cut

sub password {
	return sub {
		my ($self,$word) = @_;
		$self->set_current_constraint_name('password');
		$self->valid_password($word);
	}
}

sub match_password {
    my ($self,$word) = @_;
	return unless defined $word;
	$word =~ m< ^( [$PASSWORD]+ )$ >x ? $1 : undef;
}

sub AUTOLOAD {
    my $name = $AUTOLOAD;

	no strict qw/refs/;

	my ($pkg,$sub) = $name =~ m/^(.*::)valid_(.*)/;
    return unless($sub);

    # All non-defined valid_* routines are essentially identical to their
    # match_* counterpart, we're going to generate them dynamically from
    # the appropriate match_* routine.
    return defined &{$pkg.'match_' . $sub}(@_);
}

1;

__END__

=head1 NOTES

Although Data-FormValidator is not a dependency, it is expected that this
module will be used as part of DFV's constraint framework.

This module was originally written as part of the Labyrinth website management
tool.

=head1 SEE ALSO

L<Data::FormValidator>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
