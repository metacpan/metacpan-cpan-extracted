# -*- Perl -*-
#
# representation of individual OpenSSH authorized_keys entries, based on
# a study of the sshd(8) manual, along with the OpenSSH 5.2 sources.
# this module only weakly validates the data; in particular, no effort
# is made to confirm whether the key options are actual valid options
# for the version of OpenSSH in question

package Config::OpenSSH::Authkey::Entry;

use 5.006000;
use strict;
use warnings;

use Config::OpenSSH::Authkey::Entry::Options ();

use Carp qw/croak/;

our $VERSION = '1.06';

# This limit is set for various things under OpenSSH code. Used here to
# limit length of authorized_keys lines.
my $MAX_PUBKEY_BYTES = 8192;

# Sanity check to ensure at least some data exists in the key field
my $MIN_KEY_LENGTH = 42;

######################################################################
#
# Data Parsing & Utility Methods - Internal

my $_parse_entry = sub {
    my $self = shift;
    my $data = shift || q{};

    my ( $options, $key, $comment, $protocol, $keytype );

    chomp $data;

    if ( $data =~ m/^\s*$/ or $data =~ m/^\s*#/ ) {
        return ( 0, 'no public key data' );
    } elsif ( length $data >= $MAX_PUBKEY_BYTES ) {
        return ( 0, 'exceeds size limit' );
    }

    # OpenSSH supports leading whitespace before options or key. Strip
    # this optional whitespace to simplify parsing.
    $data =~ s/^[ \t]+//;

  ENTRY_LEXER: {
        # Optional trailing comment (user@host, usually)
        if ( defined $key and $data =~ m/ \G (.+) /cgx ) {
            $comment = $1;

            last ENTRY_LEXER;
        }

        # SSH2 public keys
        if ( !defined $key
            and $data =~
            m/ \G ( (ssh-(rsa|dss|ed25519)|ecdsa-sha2-nistp256) [ \t]+? [A-Za-z0-9+\/]+ =* ) [ \t]* /cgx
        ) {

            $key = $1;
            my $type = $2;
            my $subtype = $3;
            # follow the -t argument option to ssh-keygen(1)
            if ( $type =~ m/^ssh-/ ) {
                if ( $subtype eq 'dss' ) {
                    $keytype = 'dsa';
                } else {
                    $keytype = $subtype;
                }
            } else {
                $keytype = 'ecdsa';
            }
            $protocol = 2;

            redo ENTRY_LEXER;
        }

        # SSH1 RSA public key
        if ( !defined $key
            and $data =~ m/ \G ( \d{3,5} [ \t]+? \d+ [ \t]+? \d+ ) [ \t]* /cgx ) {

            $key      = $1;
            $keytype  = 'rsa1';
            $protocol = 1;

            redo ENTRY_LEXER;
        }

        # Optional leading options - may contain whitespace inside ""
        if ( !defined $key and $data =~ m/ \G ([^ \t]+? [ \t]*) /cgx ) {
            $options .= $1;

            redo ENTRY_LEXER;
        }
    }

    if ( !defined $key ) {
        return ( 0, 'unable to parse public key' );

    } else {
        $self->{_key}      = $key;
        $self->{_protocol} = $protocol;
        $self->{_keytype}  = $keytype;

        if ( defined $options ) {
            $options =~ s/\s*$//;
            $self->{_options} = $options;
        }

        if ( defined $comment ) {
            $comment =~ s/\s*$//;
            $self->{_comment} = $comment;
        }
    }

    return ( 1, 'ok' );
};

######################################################################
#
# Class methods

sub new {
    my $class = shift;
    my $data  = shift;

    my $self = { _dup_of => 0 };

    if ( defined $data ) {
        my ( $is_parsed, $err_msg ) = $_parse_entry->( $self, $data );
        if ( !$is_parsed ) {
            croak $err_msg;
        }
    }

    bless $self, $class;
    return $self;
}

sub split_options {
    my $class = shift;
    Config::OpenSSH::Authkey::Entry::Options->split_options(@_);
}

######################################################################
#
# Instance methods

sub parse {
    my $self = shift;
    my $data = shift || croak 'no data supplied to parse';

    my ( $is_parsed, $err_msg ) = $_parse_entry->( $self, $data );
    if ( !$is_parsed ) {
        croak $err_msg;
    }

    return $self;
}

sub as_string {
    my $self   = shift;
    my $string = q{};

    if ( exists $self->{_parsed_options} ) {
        $string .= $self->{_parsed_options}->as_string . q{ };

    } elsif ( exists $self->{_options} and length $self->{_options} > 0 ) {
        $string .= $self->{_options} . q{ };
    }

    if ( !defined $self->{_key} or length $self->{_key} < $MIN_KEY_LENGTH ) {
        croak 'no key material present';
    }
    $string .= $self->{_key};

    if ( exists $self->{_comment} and length $self->{_comment} > 0 ) {
        $string .= q{ } . $self->{_comment};
    }

    return $string;
}

sub key {
    my $self = shift;
    my $key  = shift;
    if ( defined $key ) {
        my ( $is_parsed, $err_msg ) = $_parse_entry->( $self, $key );
        if ( !$is_parsed ) {
            croak $err_msg;
        }
    }
    if ( !defined $self->{_key} or length $self->{_key} < $MIN_KEY_LENGTH ) {
        croak 'no key material present';
    }
    return $self->{_key};
}

sub protocol {
    shift->{_protocol} || 0;
}

sub keytype {
    shift->{_keytype} || '';
}

sub comment {
    my $self    = shift;
    my $comment = shift;
    if ( defined $comment ) {
        $self->{_comment} = $comment;
    }
    return defined $self->{_comment} ? $self->{_comment} : '';
}

sub unset_comment {
    my $self = shift;
    delete $self->{_comment};
    return 1;
}

# The leading (optional!) options can be dealt with as a string
# (options, unset_options), or if parsed, as individual options
# (get_option, set_option, unset_option).

sub options {
    my $self        = shift;
    my $new_options = shift;

    if ( defined $new_options ) {
        delete $self->{_parsed_options};
        $self->{_options} = $new_options;
    }

    my $options_str =
      exists $self->{_parsed_options}
      ? $self->{_parsed_options}->as_string
      : $self->{_options};
    return defined $options_str ? $options_str : '';
}

sub unset_options {
    my $self = shift;
    delete $self->{_parsed_options};
    delete $self->{_options};
    return 1;
}

sub get_option {
    my $self = shift;

    if ( !exists $self->{_parsed_options} ) {
        $self->{_parsed_options} =
          Config::OpenSSH::Authkey::Entry::Options->new( $self->{_options} );
    }

    $self->{_parsed_options}->get_option(@_);
}

sub set_option {
    my $self = shift;

    if ( !exists $self->{_parsed_options} ) {
        $self->{_parsed_options} =
          Config::OpenSSH::Authkey::Entry::Options->new( $self->{_options} );
    }

    $self->{_parsed_options}->set_option(@_);
}

sub unset_option {
    my $self = shift;

    if ( !exists $self->{_parsed_options} ) {
        $self->{_parsed_options} =
          Config::OpenSSH::Authkey::Entry::Options->new( $self->{_options} );
    }

    $self->{_parsed_options}->unset_option(@_);
}

sub duplicate_of {
    my $self = shift;
    my $ref  = shift;

    if ( defined $ref ) {
        $self->{_dup_of} = $ref;
    }

    return $self->{_dup_of};
}

sub unset_duplicate {
    my $self = shift;
    $self->{_dup_of} = 0;
    return 1;
}

1;

__END__

=head1 NAME

Config::OpenSSH::Authkey::Entry - authorized_keys file entry handler

=head1 SYNOPSIS

This module is used by L<Config::OpenSSH::Authkey>, though can be used
standalone:
  
  my $entry = Config::OpenSSH::Authkey::Entry->new();
  
  # assuming $fh is opened to an authorized_keys file...
  eval {
    $entry->parse($fh->getline);
    if ($entry->protocol == 1) {
      warn "warning: deprecated SSHv1 key detected ...\n";
    }
  };
  ...

=head1 DESCRIPTION

This module parses lines from OpenSSH C<authorized_keys> files, and
offers various methods to interact with the data. The B<AUTHORIZED_KEYS
FILE FORMAT> section of sshd(8) details the format of these lines. I use
the term entry to mean a line from an C<authorized_keys> file.

Errors are thrown via C<die> or C<croak>, notably when parsing an entry
via the B<new> or B<key> methods. Some of the options handling is
provided by L<Config::OpenSSH::Authkey::Entry::Options>.

=head1 CLASS METHODS

=over 4

=item B<new> I<optional data to parse>

Constructor. Optionally accepts an C<authorized_keys> file entry to
parse.

=item B<split_options> I<option string>

Accepts a string of comma separated options, and parses these into a
list of hash references. In scalar context, returns a reference to the
list. In list context, returns a list.

=back

=head1 INSTANCE METHODS

=over 4

=item B<parse> I<data to parse>

Utility method in event data to parse was not passed to B<new>.

=item B<key> I<optional key to parse>

Returns the public key material. If passed a string, will attempt to
parse that string as a new key (and options, and comment, if those
are present).

Throws an exception if no key material present in the instance.

=item B<keytype>

Returns the type of the key, either C<rsa1> for a SSHv1 key, or C<dsa>,
C<ecdsa>, C<ed25519>, C<rsa> for SSH2 type keys. This is the same format
as the L<ssh-keygen(1)> C<-t> option accepts, though modern C<ssh> have
dropped support for C<rsa1>, hopefully.

=item B<protocol>

Returns the major SSH protocol version of the key, 1 or 2.

Note that SSHv1 has been replaced by SSHv2 for over a decade as of 2010.
I strongly recommend that SSHv1 be disabled.

=item B<comment> I<optional new comment>

Returns the comment, if any, of the parsed entry. ssh-keygen(1) defaults
to C<user@host> for this field. If a string is passed, updates the
comment to that string. If no comment is set, returns the empty string.

Note that OpenSSH 5.5 may truncate key comments to 72 characters if
keys are converted to the RFC 4716 format via C<ssh-keygen -e ...>.

=item B<unset_comment>

Deletes the comment.

=item B<options> I<optional new option string>

Returns any options set in the entry as a comma separated value string,
or, if passed a string, sets that string as the new option set.

  # get
  my $option_str = $entry->options();
  
  # set
  $entry->options('from="127.0.0.1",no-agent-forwarding');

Returns the empty string if no options have been set.

=item B<unset_options>

Deletes all the options.

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

=item B<as_string>

Returns the entry formatted as an OpenSSH authorized_keys line. Throws
an exception if no key material present in the instance.

=item B<duplicate_of> I<optional value>

If supplied with an argument, stores this data in the object. Always
returns the value of this data, which is C<0> by default. Used by
L<Config::OpenSSH::Authkey> to track whether (and of what) a key is a
duplicate of.

=item B<unset_duplicate>

Clears the duplicate status of the instance, if any.

=back

=head1 BUGS

No known bugs. Newer versions of this module may be available from CPAN.
  
If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

=head1 SEE ALSO

sshd(8), ssh-keygen(1), L<Config::OpenSSH::Authkey>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT

Copyright 2009-2010,2012,2015,2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>


=cut
