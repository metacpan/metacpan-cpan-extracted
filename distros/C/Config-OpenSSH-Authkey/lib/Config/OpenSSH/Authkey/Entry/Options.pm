# -*- Perl -*-
#
# Representation of authorized_keys entry options, either associated
# with a particular Config::OpenSSH::Authkey::Entry object, or
# standalone.

package Config::OpenSSH::Authkey::Entry::Options;

use 5.006000;
use strict;
use warnings;

use Carp qw/croak/;

our $VERSION = '1.05';

# Delved from sshd(8), auth-options.c of OpenSSH 5.2. Insensitive match
# required, as OpenSSH uses strncasecmp(3).
my $AUTHKEY_OPTION_NAME_RE = qr/(?i)[a-z0-9_-]+/;

######################################################################
#
# Class methods

sub new {
  my $class         = shift;
  my $option_string = shift;
  my $self          = { _options => [] };

  if ( defined $option_string ) {
    $self->{_options} =
      Config::OpenSSH::Authkey::Entry::Options->split_options($option_string);
  }

  bless $self, $class;
  return $self;
}

sub split_options {
  my $class         = shift;
  my $option_string = shift;
  my @options;

  # Inspected OpenSSH auth-options.c,v 1.44 to derive this lexer:
  #
  # In OpenSSH, unparsable options result in a call to bad_options and
  # the entry being rejected. This module is more permissive, in that
  # any option name is allowed, regardless of whether OpenSSH supports
  # such an option or whether the option is the correct type (boolean
  # vs. string value). This makes the module more future proof, at the
  # cost of allowing garbage through.
  #
  # Options are stored using a list of hashrefs, which allows for
  # duplicate options, and preserves the order of options. Also, an
  # index is maintained to speed lookups of the data, and to note if
  # duplicate options exist. This is due to inconsistent handling by
  # OpenSSH_5.1p1 of command="" vs. from="" vs. environment="" options
  # when multiple entries are present. Methods are offered to detect and
  # cleanup such (hopefully rare) duplicate options.

OPTION_LEXER: {
    # String Argument Options - value is a perhaps empty string enclosed
    # in double quotes. Internal double quotes are allowed, but only if
    # these are preceded by a backslash.
    if (
      $option_string =~ m/ \G ($AUTHKEY_OPTION_NAME_RE)="( (?: \\"|[^"] )*? )"
        (?:,|[ \t]+)? /cgx
      ) {
      my $option_name = $1;
      my $option_value = $2 || q{};

      push @options, { name => $option_name, value => $option_value };

      redo OPTION_LEXER;
    }

    # Boolean options - mere presence enables them in OpenSSH
    if (
      $option_string =~ m/ \G ($AUTHKEY_OPTION_NAME_RE) (?:,|[ \t]+)? /cgx ) {
      my $option_name = $1;

      push @options, { name => $option_name };

      redo OPTION_LEXER;
    }
  }

  return wantarray ? @options : \@options;
}

######################################################################
#
# Instance methods

sub parse {
  my $self          = shift;
  my $option_string = shift;

  $self->{_options} =
    Config::OpenSSH::Authkey::Entry::Options->split_options($option_string);
  return scalar @{ $self->{_options} };
}

sub as_string {
  my $self = shift;
  my @options;
  for my $options_ref ( @{ $self->{_options} } ) {
    if ( exists $options_ref->{value} ) {
      ( my $value = $options_ref->{value} ) =~ s/(?<!\\)"/\\"/g;
      push @options, $options_ref->{name} . '="' . $value . '"';
    } else {
      push @options, $options_ref->{name};
    }
  }
  return join( q{,}, @options );
}

# NOTE - boolean return the name of the option, while string value
# options the string. This may change, depending on how I like how this
# is handled...
sub get_option {
  my $self = shift;
  my $option_name = shift || croak 'get_option requires an option name';

  my @values =
    map { $_->{value} || $option_name }
    grep { $_->{name} eq $option_name } @{ $self->{_options} };

  return wantarray ? @values : defined $values[0] ? $values[0] : '';
}

sub get_options {
  map { $_->{name} } @{ shift->{_options} };
}

# Sets an option. To enable a boolean option, only supply the option
# name, and pass no value data.
sub set_option {
  my $self         = shift;
  my $option_name  = shift || croak 'set_option requires an option name';
  my $option_value = shift;

  my $updated      = 0;
  my $record_count = @{ $self->{_options} };

  for my $options_ref ( @{ $self->{_options} } ) {
    if ( $options_ref->{name} eq $option_name ) {
      $options_ref->{value} = $option_value if defined $option_value;
      ++$updated;
    }
  }
  if ( $updated == 0 ) {
    push @{ $self->{_options} },
      {
      name => $option_name,
      ( defined $option_value ? ( value => $option_value ) : () )
      };
  } elsif ( $updated > 1 ) {
    # KLUGE edge-case where duplicate entries exist for this option. Clear
    # all duplicates beyond the first entry.
    my $seen = 0;
    @{ $self->{_options} } = grep {
           $_->{name} ne $option_name
        or $_->{name} eq $option_name
        && !$seen++
    } @{ $self->{_options} };
  }

  return $record_count - @{ $self->{_options} };
}

sub unset_option {
  my $self = shift;
  my $option_name = shift || croak 'unset_option requires an option name';

  my $record_count = @{ $self->{_options} };
  @{ $self->{_options} } =
    grep { $_->{name} ne $option_name } @{ $self->{_options} };

  return $record_count - @{ $self->{_options} };
}

sub unset_options {
  shift->{_options} = [];
  return 1;
}

1;

__END__

=head1 NAME

Config::OpenSSH::Authkey::Entry::Options - authorized_keys entry options handler

=head1 SYNOPSIS

Parse an options string:

  my $op =
    Config::OpenSSH::Authkey::Entry::Options->new('no-pty,no-user-rc');
  
  $op->set_option('from', '127.0.0.1');
  $op->unset_option('no-pty');
  print $op->as_string;

=head1 DESCRIPTION

This module parses option strings (C<no-pty,from="",...>) from OpenSSH
C<authorized_keys> files. It is used by
L<Config::OpenSSH::Authkey::Entry>. Consult the C<AUTHORIZED_KEYS FILE
FORMAT> section of sshd(8) for more information about these options.

=head1 CLASS METHODS

=over 4

=item B<new> I<optional option string to parse>

Constructor. Optionally accepts an option string to parse.

=item B<split_options> I<option string>

Accepts a string of comma separated options, and parses these into a
list of hash references. In scalar context, returns a reference to the
list. In list context, returns a list.

=back

=head1 INSTANCE METHODS

=over 4

=item B<parse> I<option string>

Utility method in the event an option string was not passed to B<new>.

=item B<get_option> I<option name>

Returns the value (or values) for a named option. OpenSSH does allow
duplicate entries for options, though in most cases this method will
only return a single value. Options are boolean or string value; boolean
options return the name of the method, while string options return the
string value. Assuming the options have been set as shown above:

  # returns 'no-agent-forwarding'
  $entry->get_option('no-agent-forwarding');
  
  # returns '127.0.0.1'
  $entry->get_option('from');

In scalar context, only the first option is returned (or the empty
string). In list context, a list of one (or rarely more) values will be
returned (or the empty list).

=item B<get_options>

Returns a list of all option names that exist in the instance.

=item B<set_option> I<option name>, I<optional value>

Enables an option, or with an additional argument, sets the string value
for that option.

  # boolean
  $entry->set_option('no-agent-forwarding');
  
  # string value
  $entry->set_option(from => '127.0.0.1');

If multiple options with the same name are present in the options list,
only the first option found will be updated, and all subsequent entries
removed from the options list.

=item B<unset_option> I<option name>

Deletes all occurrences of the named option.

=item B<unset_options>

Removes all options.

=item B<as_string>

Returns the options as a comma separated value list. Any option values
that contain a doublequote (C<">) that is not escaped with a backslash
(C<\>) will be escaped with a backslash.

=back

=head1 BUGS

No known bugs. Newer versions of this module may be available from CPAN.
  
If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

=head1 SEE ALSO

sshd(8), ssh-keygen(1), L<Config::OpenSSH::Authkey::Entry>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010,2015 by Jeremy Mates.

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
