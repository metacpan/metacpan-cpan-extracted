use strict;
use warnings;
package Config::INI::Reader;
$Config::INI::Reader::VERSION = '0.027';
use Mixin::Linewise::Readers 0.110;
# ABSTRACT: a subclassable .ini-file parser

#pod =head1 SYNOPSIS
#pod
#pod If F<family.ini> contains:
#pod
#pod   admin = rjbs
#pod
#pod   [rjbs]
#pod   awesome = yes
#pod   height = 5' 10"
#pod
#pod   [mj]
#pod   awesome = totally
#pod   height = 23"
#pod
#pod Then when your program contains:
#pod
#pod   my $hash = Config::INI::Reader->read_file('family.ini');
#pod
#pod C<$hash> will contain:
#pod
#pod   {
#pod     '_'  => { admin => 'rjbs' },
#pod     rjbs => {
#pod       awesome => 'yes',
#pod       height  => q{5' 10"},
#pod     },
#pod     mj   => {
#pod       awesome => 'totally',
#pod       height  => '23"',
#pod     },
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod Config::INI::Reader is I<yet another> config module implementing I<yet another>
#pod slightly different take on the undeniably easy to read L<".ini" file
#pod format|Config::INI>.  Its default behavior is quite similar to that of
#pod L<Config::Tiny>, on which it is based.
#pod
#pod The chief difference is that Config::INI::Reader is designed to be subclassed
#pod to allow for side-effects and self-reconfiguration to occur during the course
#pod of reading its input.
#pod
#pod =cut

use Carp ();

our @CARP_NOT = qw(Mixin::Linewise::Readers);

#pod =head1 METHODS FOR READING CONFIG
#pod
#pod These methods are all that most users will need: they read configuration from a
#pod source of input, then they return the data extracted from that input.  There
#pod are three reader methods, C<read_string>, C<read_file>, and C<read_handle>.
#pod The first two are implemented in terms of the third.  It iterates over lines in
#pod a file, calling methods on the reader when events occur.  Those events are
#pod detailed below in the L</METHODS FOR SUBCLASSING> section.
#pod
#pod All of the reader methods return an unblessed reference to a hash.
#pod
#pod All throw an exception when they encounter an error.
#pod
#pod =head2 read_file
#pod
#pod   my $hash_ref = Config::INI::Reader->read_file($filename);
#pod
#pod Given a filename, this method returns a hashref of the contents of that file.
#pod
#pod =head2 read_string
#pod
#pod   my $hash_ref = Config::INI::Reader->read_string($string);
#pod
#pod Given a string, this method returns a hashref of the contents of that string.
#pod
#pod =head2 read_handle
#pod
#pod   my $hash_ref = Config::INI::Reader->read_handle($io_handle);
#pod
#pod Given an IO::Handle, this method returns a hashref of the contents of that
#pod handle.
#pod
#pod =cut

sub read_handle {
  my ($invocant, $handle) = @_;

  my $self = ref $invocant ? $invocant : $invocant->new;

  # parse the file
  LINE: while (my $line = $handle->getline) {
    if ($handle->input_line_number == 1 && $line =~ /\A\x{FEFF}/) {
      Carp::confess("input handle appears to start with a BOM");
    }

    $self->preprocess_line(\$line);

    next LINE if $self->can_ignore($line, $handle);

    # Handle section headers
    if (defined (my $name = $self->parse_section_header($line, $handle))) {
      # Create the sub-hash if it doesn't exist.
      # Without this sections without keys will not
      # appear at all in the completed struct.
      $self->change_section($name);
      next LINE;
    }

    if (my ($name, $value) = $self->parse_value_assignment($line, $handle)) {
      $self->set_value($name, $value);
      next LINE;
    }

    $self->handle_unparsed_line($line, $handle);
  }

  $self->finalize;

  return $self->{data};
}

#pod =head1 METHODS FOR SUBCLASSING
#pod
#pod These are the methods you need to understand and possibly change when
#pod subclassing Config::INI::Reader to handle a different format of input.
#pod
#pod =head2 current_section
#pod
#pod   my $section_name = $reader->current_section;
#pod
#pod This method returns the name of the current section.  If no section has yet
#pod been set, it returns the result of calling the C<starting_section> method.
#pod
#pod =cut

sub current_section {
  defined $_[0]->{section} ? $_[0]->{section} : $_[0]->starting_section;
}

#pod =head2 parse_section_header
#pod
#pod   my $name = $reader->parse_section_header($line, $handle);
#pod
#pod Given a line of input, this method decides whether the line is a section-change
#pod declaration.  If it is, it returns the name of the section to which to change.
#pod If the line is not a section-change, the method returns false.
#pod
#pod =cut

sub parse_section_header {
  return $1 if $_[1] =~ /^\s*\[\s*(.+?)\s*\]\s*$/;
  return;
}

#pod =head2 change_section
#pod
#pod   $reader->change_section($section_name);
#pod
#pod This method is called whenever a section change occurs in the file.
#pod
#pod The default implementation is to change the current section into which data is
#pod being read and to initialize that section to an empty hashref.
#pod
#pod =cut

sub change_section {
  my ($self, $section) = @_;

  $self->{section} = $section;

  if (!exists $self->{data}{$section}) {
    $self->{data}{$section} = {};
  }
}

#pod =head2 parse_value_assignment
#pod
#pod   my ($name, $value) = $reader->parse_value_assignment($line, $handle);
#pod
#pod Given a line of input, this method decides whether the line is a property
#pod value assignment.  If it is, it returns the name of the property and the value
#pod being assigned to it.  If the line is not a property assignment, the method
#pod returns false.
#pod
#pod =cut

sub parse_value_assignment {
  return ($1, $2) if $_[1] =~ /^\s*([^=\s\pC][^=\pC]*?)\s*=\s*(.*?)\s*$/;
  return;
}

#pod =head2 set_value
#pod
#pod   $reader->set_value($name, $value);
#pod
#pod This method is called whenever an assignment occurs in the file.  The default
#pod behavior is to change the value of the named property to the given value.
#pod
#pod =cut

sub set_value {
  my ($self, $name, $value) = @_;

  $self->{data}{ $self->current_section }{$name} = $value;
}

#pod =head2 starting_section
#pod
#pod   my $section = Config::INI::Reader->starting_section;
#pod
#pod This method returns the name of the starting section.  The default is: C<_>
#pod
#pod =cut

sub starting_section { q{_} }

#pod =head2 can_ignore
#pod
#pod   do_nothing if $reader->can_ignore($line, $handle)
#pod
#pod This method returns true if the given line of input is safe to ignore.  The
#pod default implementation ignores lines that contain only whitespace or comments.
#pod
#pod This is run I<after> L<preprocess_line>.
#pod
#pod =cut

sub can_ignore {
  my ($self, $line, $handle) = @_;

  # Skip comments and empty lines
  return $line =~ /\A\s*(?:;|$)/ ? 1 : 0;
}

#pod =head2 preprocess_line
#pod
#pod   $reader->preprocess_line(\$line);
#pod
#pod This method is called to preprocess each line after it's read but before it's
#pod parsed.  The default implementation just strips inline comments.  Alterations
#pod to the line are made in place.
#pod
#pod =cut

sub preprocess_line {
  my ($self, $line) = @_;

  # Remove inline comments
  ${$line} =~ s/\s+;.*$//g;
}

#pod =head2 handle_unparsed_line
#pod
#pod   $reader->handle_unparsed_line( $line, $handle );
#pod
#pod This method is called when the reader encounters a line that doesn't look like
#pod anything it recognizes.  By default, it throws an exception.
#pod
#pod =cut

sub handle_unparsed_line {
  my ($self, $line, $handle) = @_;
  my $lineno = $handle->input_line_number;
  Carp::croak "Syntax error at line $lineno: '$line'";
}

#pod =head2 finalize
#pod
#pod   $reader->finalize;
#pod
#pod This method is called when the reader has finished reading in every line of the
#pod file.
#pod
#pod =cut

sub finalize { }

#pod =head2 new
#pod
#pod   my $reader = Config::INI::Reader->new;
#pod
#pod This method returns a new reader.  This generally does not need to be called by
#pod anything but the various C<read_*> methods, which create a reader object only
#pod ephemerally.
#pod
#pod =cut

sub new {
  my ($class) = @_;

  my $self = { data => {}, };

  bless $self => $class;
}

#pod =head1 ORIGIN
#pod
#pod Originaly derived from L<Config::Tiny>, by Adam Kennedy.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::INI::Reader - a subclassable .ini-file parser

=head1 VERSION

version 0.027

=head1 SYNOPSIS

If F<family.ini> contains:

  admin = rjbs

  [rjbs]
  awesome = yes
  height = 5' 10"

  [mj]
  awesome = totally
  height = 23"

Then when your program contains:

  my $hash = Config::INI::Reader->read_file('family.ini');

C<$hash> will contain:

  {
    '_'  => { admin => 'rjbs' },
    rjbs => {
      awesome => 'yes',
      height  => q{5' 10"},
    },
    mj   => {
      awesome => 'totally',
      height  => '23"',
    },
  }

=head1 DESCRIPTION

Config::INI::Reader is I<yet another> config module implementing I<yet another>
slightly different take on the undeniably easy to read L<".ini" file
format|Config::INI>.  Its default behavior is quite similar to that of
L<Config::Tiny>, on which it is based.

The chief difference is that Config::INI::Reader is designed to be subclassed
to allow for side-effects and self-reconfiguration to occur during the course
of reading its input.

=head1 PERL VERSION SUPPORT

This module has a long-term perl support period.  That means it will not
require a version of perl released fewer than five years ago.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS FOR READING CONFIG

These methods are all that most users will need: they read configuration from a
source of input, then they return the data extracted from that input.  There
are three reader methods, C<read_string>, C<read_file>, and C<read_handle>.
The first two are implemented in terms of the third.  It iterates over lines in
a file, calling methods on the reader when events occur.  Those events are
detailed below in the L</METHODS FOR SUBCLASSING> section.

All of the reader methods return an unblessed reference to a hash.

All throw an exception when they encounter an error.

=head2 read_file

  my $hash_ref = Config::INI::Reader->read_file($filename);

Given a filename, this method returns a hashref of the contents of that file.

=head2 read_string

  my $hash_ref = Config::INI::Reader->read_string($string);

Given a string, this method returns a hashref of the contents of that string.

=head2 read_handle

  my $hash_ref = Config::INI::Reader->read_handle($io_handle);

Given an IO::Handle, this method returns a hashref of the contents of that
handle.

=head1 METHODS FOR SUBCLASSING

These are the methods you need to understand and possibly change when
subclassing Config::INI::Reader to handle a different format of input.

=head2 current_section

  my $section_name = $reader->current_section;

This method returns the name of the current section.  If no section has yet
been set, it returns the result of calling the C<starting_section> method.

=head2 parse_section_header

  my $name = $reader->parse_section_header($line, $handle);

Given a line of input, this method decides whether the line is a section-change
declaration.  If it is, it returns the name of the section to which to change.
If the line is not a section-change, the method returns false.

=head2 change_section

  $reader->change_section($section_name);

This method is called whenever a section change occurs in the file.

The default implementation is to change the current section into which data is
being read and to initialize that section to an empty hashref.

=head2 parse_value_assignment

  my ($name, $value) = $reader->parse_value_assignment($line, $handle);

Given a line of input, this method decides whether the line is a property
value assignment.  If it is, it returns the name of the property and the value
being assigned to it.  If the line is not a property assignment, the method
returns false.

=head2 set_value

  $reader->set_value($name, $value);

This method is called whenever an assignment occurs in the file.  The default
behavior is to change the value of the named property to the given value.

=head2 starting_section

  my $section = Config::INI::Reader->starting_section;

This method returns the name of the starting section.  The default is: C<_>

=head2 can_ignore

  do_nothing if $reader->can_ignore($line, $handle)

This method returns true if the given line of input is safe to ignore.  The
default implementation ignores lines that contain only whitespace or comments.

This is run I<after> L<preprocess_line>.

=head2 preprocess_line

  $reader->preprocess_line(\$line);

This method is called to preprocess each line after it's read but before it's
parsed.  The default implementation just strips inline comments.  Alterations
to the line are made in place.

=head2 handle_unparsed_line

  $reader->handle_unparsed_line( $line, $handle );

This method is called when the reader encounters a line that doesn't look like
anything it recognizes.  By default, it throws an exception.

=head2 finalize

  $reader->finalize;

This method is called when the reader has finished reading in every line of the
file.

=head2 new

  my $reader = Config::INI::Reader->new;

This method returns a new reader.  This generally does not need to be called by
anything but the various C<read_*> methods, which create a reader object only
ephemerally.

=head1 ORIGIN

Originaly derived from L<Config::Tiny>, by Adam Kennedy.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
