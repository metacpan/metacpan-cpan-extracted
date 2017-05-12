package Convert::ASCIInames;
#
# $Id: ASCIInames.pm,v 1.2 2004/02/18 13:58:58 coar Exp $
#
#   CPAN module Convert::ASCIInames
#
#   Copyright 2004 Ken A L Coar
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this package or any files in it except in
#   compliance with the License.  A copy of the License should be
#   included as part of the package; the normative version may be
#   obtained a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

use strict;
use Carp;

#
BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    use vars qw (%ord2name %ord2alt %name2ord %alt2ord $config);
    $VERSION     = sprintf('%d.%03d', q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
    @ISA         = qw (Exporter);
    #
    # Give a hoot and don't pollute, do not export more than needed by default
    #
    @EXPORT      = qw (ASCIIname
                       ASCIIaltname
                       ASCIIordinal
                       ASCIIdescription
                       ASCIIaltdescription
                      );
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();

    #
    # Set up our constants and configuration; since this isn't an
    # object-oriented module, these values apply throughout.
    #
    $config->{fallthrough} = 1;
    $config->{strict_ordinals} = 0;
    %ord2alt  = (
                 0x09 => [ 'TAB', 'Horizontal tab' ],
                 0x11 => [ 'XON', 'Flow control on' ],
                 0x13 => [ 'XOFF', 'Flow control off' ],
                 0x20 => [ 'SP', 'Space' ],
                );
    %ord2name = (
                 0x00 => [ 'NUL', 'Null character' ],
                 0x01 => [ 'SOH', 'Start of Header' ],
                 0x02 => [ 'STX', 'Start of Text' ],
                 0x03 => [ 'ETX', 'End Of Text' ],
                 0x04 => [ 'EOT', 'End Of Transmission' ],
                 0x05 => [ 'ENQ', 'Enquiry' ],
                 0x06 => [ 'ACK', 'Acknowledge' ],
                 0x07 => [ 'BEL', 'Bell' ],
                 0x08 => [ 'BS', 'Backspace' ],
                 0x09 => [ 'HT', 'Horizontal Tab' ],
                 0x0a => [ 'LF', 'Linefeed' ],
                 0x0b => [ 'VT', 'Vertical Tab' ],
                 0x0c => [ 'FF', 'Formfeed' ],
                 0x0d => [ 'CR', 'Carriage Return' ],
                 0x0e => [ 'SO', 'Shift Out' ],
                 0x0f => [ 'SI', 'Shift In' ],
                 0x10 => [ 'DLE', 'Data Link Escape' ],
                 0x11 => [ 'DC1', 'Device Control 1' ],
                 0x12 => [ 'DC2', 'Device Control 2' ],
                 0x13 => [ 'DC3', 'Device Control 3' ],
                 0x14 => [ 'DC4', 'Device Control 4' ],
                 0x15 => [ 'NAK', 'Negative Acknowledge' ],
                 0x16 => [ 'SYN', 'Synchronous Idle' ],
                 0x17 => [ 'ETB', 'End of Transmission Block' ],
                 0x18 => [ 'CAN', 'Cancel' ],
                 0x19 => [ 'EM', 'End of Medium' ],
                 0x1a => [ 'SUB', 'Substitute' ],
                 0x1b => [ 'ESC', 'Escape' ],
                 0x1c => [ 'FS', 'File Separator' ],
                 0x1d => [ 'GS', 'Group Separator' ],
                 0x1e => [ 'RS', 'Record Separator' ],
                 0x1f => [ 'US', 'Unit Separator' ],
                 0x7f => [ 'DEL', 'Delete' ],
                 0x80 => [ 'RES1', 'Reserved for future standardizaton' ],
                 0x81 => [ 'RES2', 'Reserved for future standardizaton' ],
                 0x82 => [ 'RES3', 'Reserved for future standardizaton' ],
                 0x83 => [ 'RES4', 'Reserved for future standardizaton' ],
                 0x84 => [ 'IND', 'Index' ],
                 0x85 => [ 'NEL', 'Next Line' ],
                 0x86 => [ 'SSA', 'Start of Selected Area' ],
                 0x87 => [ 'ESA', 'End of Selected Area' ],
                 0x88 => [ 'HTS', 'Horizontal Tabulation Set' ],
                 0x89 => [ 'HTJ', 'Horizontal Tab with Justify' ],
                 0x8a => [ 'VTS', 'Vertical Tabulation Set' ],
                 0x8b => [ 'PLD', 'Partial Line Down' ],
                 0x8c => [ 'PLU', 'Partial Line Up' ],
                 0x8d => [ 'RI', 'Reverse Index' ],
                 0x8e => [ 'SS2', 'Single Shift 2' ],
                 0x8f => [ 'SS3', 'Single Shift 3' ],
                 0x90 => [ 'DCS', 'Device control string' ],
                 0x91 => [ 'PU1', 'Private Use 1' ],
                 0x92 => [ 'PU2', 'Private Use 2' ],
                 0x93 => [ 'STS', 'Set Transmission State' ],
                 0x94 => [ 'CCH', 'Cancel Character' ],
                 0x95 => [ 'MW', 'Message Waiting' ],
                 0x96 => [ 'SPA', 'Start of Protected Area' ],
                 0x97 => [ 'EPA', 'End of Protected Area' ],
                 0x98 => [ 'RES5', 'Reserved for future standardization' ],
                 0x99 => [ 'RES6', 'Reserved for future standardization' ],
                 0x9a => [ 'RES7', 'Reserved for future standardization' ],
                 0x9b => [ 'CSI', 'Control Sequence Introducer' ],
                 0x9c => [ 'ST', 'String Terminator' ],
                 0x9d => [ 'OSC', 'Operating System Command' ],
                 0x9e => [ 'PM', 'Privacy Message' ],
                 0x9f => [ 'APC', 'Application Program Command' ],
                );
    %alt2ord = ();
    %name2ord = ();

    #
    # Now for the backward conversions
    #
    while (my ($ord, $name) = each(%ord2name)) {
        $name2ord{$name->[0]} = $ord;
    }
    while (my ($ord, $name) = each(%ord2alt)) {
        $alt2ord{$name->[0]} = $ord;
    }
}

=pod

=head1 NAME

Convert::ASCIInames - ASCII names for control characters

=head1 SYNOPSIS

 use Convert::ASCIInames;

 Convert::ASCIInames::Configure(fallthrough => 1);
 $name = ASCIIname($character_ordinal);
 $name = ASCIIaltname($character_ordinal);
 $name = ASCIIdescription($character_ordinal);
 $name = ASCIIaltdescription($character_ordinal);
 $character_ordinal = ASCIIordinal($name);

=head1 DESCRIPTION

Most if not all of the non-printing characters of the ASCII character set
had special significance in the days of teletypes and paper tapes.
For example, the character code 0x00 would be sent repeatedly in order
to give the receiving end a chance to catch up; it signified "no action"
and so was named C<NUL>.  The sending end might follow each line of text
with a number of C<NUL> bytes in order to give the receiving end
a chance to return its print carriage to the left margin.  The control
characters (so-called because they were used to control aspects of
communication or receiving devices) were given short 2-to-4 letter
names, like C<CR>, C<EOT>, C<ACK>, and C<NAK>.

Some of these special purposes have become obsolete, but some of them
are still in use.  For example, character 0x07 (C<BEL>) is used to
ring the feeper; 0x05 (C<ENQ>) is recognised by many terminals as
a trigger to report their status; and 0x08 (C<BS>) still means
"move the cursor back one space".

This module will return the ASCII name for specified characters,
or the character code if given an ASCII name.  In addition, the
full descriptive name ("Start of Heading" instead of C<SOH>) is
available, although reverse translation of the descriptions isn't
provided.

Some control characters have altername names.  Character 0x13
is named C<DC3> ("Device Control 3"), but is probably better
known by its alternate name of C<XOFF>.  These alternate names
are also available through this module's functions.

=head1 USAGE

Each of the functions in this module is described below.  They
are listed in lexical order, rather than functional.

If you request the name (or alternate name) of a character that
doesn't have one, you'll either get the actual character itself,
or the name (if it has one) from the other list.  For instance,
if you request the alternate name for 0x00, which doesn't have
one, the return value will either be C<NUL> (the primary name)
or the value of C<chr(0x00)>.  The former is called "falling
through," and is controlled by the setting of the C<fallthrough>
configuration option.  If the option is set to a true value,
the module will attempt to give you the best name it can; if
it's set to a false value, you'll either get exactly what you
requested (such as the alternate name) or the character itself.

If you provide an invalid character ordinal (such as a non-integer,
or one outside the range of 0-255), Convert::ASCIInames will
throw a message using C<carp()> and use a standard substitute
value instead:

=over 4

=item o B<Ordinal is omitted or is a zero-length string>

The value 0x00 will be used.

=item o B<Ordinal E<lt> 0 or E<gt> 255>

The value 255 (0xff) will be used instead.

=item o B<Ordinal is a non-integer>

The ordinal of the first character of the argument will be used.
If option C<strict_ordinals> is set, a warning message will be
issued.

=back

=cut

=pod

=head2 ASCIIaltdescription

 $text = ASCIIaltdescription($ordinal);

This function returns the description for the alternate name, if any,
for the character with the specified ordinal.  If there is no
altername name, the description of the primary name (if any) will be
returned if the C<fallthrough> option is set; otherwise the value of
C<chr($ordinal)> will be returned.

=cut

sub ASCIIaltdescription {
    my ($ord) = is_ord(@_);
    my $char;

    $char = ($ord2alt{$ord}->[1]
             || ($config->{fallthrough} ? $ord2name{$ord}->[1] : 0)
             || chr($ord));
    return $char;
}

=pod

=head2 ASCIIaltname

 $text = ASCIIaltname($ordinal);

This function returns the alternate name, if any, for the
character with the specified ordinal.  If there is no altername
name, the primary name (if any) will be returned if the C<fallthrough>
option is set; otherwise the value of C<chr($ordinal)> will be
returned.

=cut

sub ASCIIaltname {
    my ($ord) = is_ord(@_);
    my $char;

    $char = ($ord2alt{$ord}->[0]
             || ($config->{fallthrough} ? $ord2name{$ord}->[0] : 0)
             || chr($ord));
    return $char;
}

=pod

=head2 ASCIIdescription

 $text = ASCIIdescription($ordinal);

This function returns the description for the primary name, if any,
for the character with the specified ordinal.  If there is no
primary name, the description of the alternate name (if any) will be
returned if the C<fallthrough> option is set; otherwise the value of
C<chr($ordinal)> will be returned.

Note that it is unlikely that a character will have an alternate
name but not a primary one.

=cut

sub ASCIIdescription {
    my ($ord) = is_ord(@_);
    my $char;

    $char = ($ord2name{$ord}->[1]
             || ($config->{fallthrough} ? $ord2alt{$ord}->[1] : 0)
             || chr($ord));
    return $char;
}

=pod

=head2 ASCIIname

This function returns the primary name, if any, for the
character with the specified ordinal.  If there is no primary
name, the alternate name (if any) will be returned if the C<fallthrough>
option is set; otherwise the value of C<chr($ordinal)> will be
returned.

Note that it is unlikely that a character will have an alternate
name but not a primary one.

=cut

sub ASCIIname {
    my ($ord) = is_ord(@_);
    my $char;

    $char = ($ord2name{$ord}->[0]
             || ($config->{fallthrough} ? $ord2alt{$ord}->[0] : 0)
             || chr($ord));
    return $char;
}

=pod

=head2 ASCIIordinal

 $ordinal = ASCIIordinal($name)

This function will attempt to look up the specified name in
the primary and alternate lists, and return the ordinal of
any match it finds.  For example:

  my $ord = ASCIIordinal('xoff');
  printf("xoff = 0x%02x\n", $ord);

would print

  xoff = 0x13

If the name does not appear in the primary or alternate list, the
ordinal of the first character of the string will be returned.

The argument is not case-sensitive.

=cut

sub ASCIIordinal {
    my ($name) = is_char(@_);
    my $char;

    $char = ($name2ord{uc($name)}
             || ($config->{fallthrough} ? $alt2ord{uc($name)} : 0)
             || ord(substr($name, 0, 1)));
    return $char;
}

=pod

=head2 Convert::ASCIInames::Configure

 Convert::ASCIInames::Configure(..options..)

This function sets the options controlling some details of
Convert::ASCIInames' operation.  Options are specifed as either
a hash or a hashref:

 Convert::ASCIInames::Configure(fallback => 1);

 my $opts = { fallback => 1, strict_ordinals => 0};
 Convert::ASCIInames::Configure($opts);

The possible options are:

=over 4

=item o C<fallthrough>

If this option is set to a true value, Convert::ASCIInames will search
both the primary and the alternate (or I<vice versa>) lists for
the specified character or name.  If set to a false value, only the
list you indicate will be searched.

Default is true.

=item o C<strict_ordinals>

When a function that takes a character ordinal is passed an argument
that is nominally invalid (I<i.e.>, not a positive integer between 0
and 255 inclusive), it will use the C<ord()> value of the first byte
of the argument.  If the C<strict_ordinals> option is set to true,
a warning message will be generated, just in case this isn't
what you intended.  If set to false, there is no message.

The default value is false.

=back

=cut

sub Configure {
    my (@opts) = @_;
    my $prehash;
    my (%ohash) = ((ref($opts[0]) eq 'HASH') ? %{$opts[0]} : @opts);

    for (keys(%{$config})) {
        $prehash->{$_} = $config->{$_};
        if (defined($ohash{$_})) {
            $config->{$_} = $ohash{$_};
        }
    }
    return $prehash;
}

#
# Check that a value is really a valid character (or string).
#
sub is_char {
    my ($val, $truncate) = @_;

    if ((! defined($val)) || (length($val) == 0)) {
        carp('Null character; using NUL');
        return chr(0x00);
    }
    return ($truncate ? substr($val, 0, 1) : $val);
}

#
# Check that a value is really a valid ordinal.
#
sub is_ord {
    my ($val) = @_;

    if ((! defined($val)) || (length($val) == 0)) {
        carp('Null ordinal; using 0x00');
        return 0x00;
    }
    elsif (($val =~ /^[-+]?\d+$/)
           && (($val > 255)
               || ($val < 0))) {
        carp('Illegal ordinal value (< 0 or > 255); using 255');
        return 0xff;
    }
    elsif ($val !~ /^\+?\d+$/) {
        if ($config->{strict_ordinals}) {
            carp('Ordinal is not a positive integer; '
                 . 'converting the first character');
        }
        return ord(substr($val, 0, 1));
    }
    return $val;
}

1; #this line is important and will help the module return a true value

__END__

=pod

=head1 BUGS

None known.

=head1 SUPPORT

The C<cpan-modules@Sourcery.Org> mailing list; send a message
containing only the word C<subscribe> to cpan-modules-request@Sourcery.Org
to join the list.

=head1 AUTHOR

 Ken Coar
 CPAN ID: ROUS
 Ken.Coar@Golux.Com
 http://Ken.Coar.Org/

=end text

=head1 COPYRIGHT

This program is free software licensed under the...

    Apache Software License (Version 2.0)

The full text of the license can be found in the
LICENCE file included with this module.

=head1 SEE ALSO

L<perl(1)>, and
L<charnames(3pm)> (function C<viacode> in Perl 5.8.1 and later).

=cut

#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# End:
#
