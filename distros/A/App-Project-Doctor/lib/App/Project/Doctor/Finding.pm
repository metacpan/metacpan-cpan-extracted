package App::Project::Doctor::Finding;

# A Finding is a single diagnostic result produced by a check plugin.
# It carries a severity level (error/warning/pass/info), a human-readable
# message, an optional automated fix coderef, and optional file/line location.

use strict;
use warnings;
use autodie qw(:all);

# croak reports errors at the caller's location rather than inside this module.
use Carp qw(croak carp);
# Params::Get normalises @_ into a hashref, handling both hash and hashref args.
use Params::Get;
# validate_strict enforces the parameter schema and throws on any violation.
use Params::Validate::Strict qw(validate_strict);
# Readonly creates truly immutable constants -- assigning to them throws at runtime.
use Readonly;

our $VERSION = '0.02';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Maps each severity to the short bracketed icon shown in text-report lines.
Readonly::Hash my %SEVERITY_ICON => (
	error   => '[X]',    # Something is broken and must be fixed
	warning => '[!]',    # Something is suspicious and should be reviewed
	pass    => '[v]',    # This item is healthy
	info    => '[i]',    # Informational; no action required
);

# Used by new() to reject unknown severity strings before storing them.
# The keys here must exactly match the keys in %SEVERITY_ICON above.
Readonly::Hash my %VALID_SEVERITY => map { $_ => 1 } qw(error warning pass info);

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
	my $class = shift;    # The package name, e.g. 'App::Project::Doctor::Finding'

	# Check 'message' before running validate_strict so the caller gets our
	# descriptive error rather than a generic Params::Validate type error.
	my %raw = @_;
	croak 'message must be a non-empty string'
		unless defined $raw{message} && length $raw{message};

	# validate_strict applies defaults, enforces types, and throws immediately
	# if anything is wrong.  It never returns undef -- it either returns the
	# validated hashref or dies.
	my $args = validate_strict(
		schema => {
			severity   => { type => 'scalar',  optional => 1, default => 'info'    },
			message    => { type => 'scalar'                                        },
			detail     => { type => 'scalar',  optional => 1, default => ''        },
			fix        => { type => 'coderef', optional => 1                       },
			check_name => { type => 'scalar',  optional => 1, default => 'Unknown' },
			file       => { type => 'scalar',  optional => 1, default => ''        },
			line       => { type => 'integer', optional => 1, min => 1             },
		},
		args => Params::Get::get_params(undef, \@_) || {},
	);

	# validate_strict only checks that severity is a scalar; we also need to
	# confirm it is one of our four known values.
	croak "Invalid severity '$args->{severity}'"
		unless $VALID_SEVERITY{ $args->{severity} };

	# Bless the validated args hashref and return the new object.
	return bless $args, $class;
}

# ---------------------------------------------------------------------------
# Accessors  (all read-only -- attributes are set once in new() and never changed)
# ---------------------------------------------------------------------------

# The importance level of this finding: error, warning, pass, or info.
sub severity   { $_[0]->{severity}   }
# The short human-readable description of the problem or result.
sub message    { $_[0]->{message}    }
# An optional longer explanation; empty string when not set.
sub detail     { $_[0]->{detail}     }
# The optional coderef called by Fixer to resolve the issue.
sub fix        { $_[0]->{fix}        }
# The name of the check that produced this finding (e.g. 'Tests').
sub check_name { $_[0]->{check_name} }
# Relative path to the affected file; empty string when not applicable.
sub file       { $_[0]->{file}       }
# Line number in the affected file; undef when not applicable.
sub line       { $_[0]->{line}       }

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

=head2 is_fixable

Returns 1 when this finding carries an automated fix coderef, 0 otherwise.

=cut

# Return exactly 1 or 0 (not just truthy/falsy) so type-checked callers are happy.
sub is_fixable { defined $_[0]->{fix} ? 1 : 0 }

# has_fix is a synonym for is_fixable kept for backward compatibility.
# Both methods are part of the public API and must always agree.
sub has_fix     { defined $_[0]->{fix} ? 1 : 0 }

=head2 icon

Returns the bracketed ASCII status icon for this finding's severity.

=cut

# Severity is always valid here because new() checked it against %VALID_SEVERITY,
# and all valid severities have a matching entry in %SEVERITY_ICON.
sub icon { $SEVERITY_ICON{ $_[0]->{severity} } }

=head2 to_hash

Serialises the finding to a plain hashref for JSON encoding.
The C<fix> coderef is omitted.

=cut

sub to_hash {
	my $self = shift;
	# Build the base hashref with all fields that are always present.
	my %h = (
		severity   => $self->severity,
		message    => $self->message,
		detail     => $self->detail,
		check_name => $self->check_name,
		file       => $self->file,
	);
	# Only include 'line' when it was actually set; absent means "unknown location".
	$h{line} = $self->line if defined $self->line;
	return \%h;
}

1;

__END__

=head1 NAME

App::Project::Doctor::Finding - A single diagnostic finding produced by a check

=head1 VERSION

0.02

=head1 SYNOPSIS

  use App::Project::Doctor::Finding;

  my $f = App::Project::Doctor::Finding->new(
      severity   => 'error',
      message    => 'No test files found under t/',
      check_name => 'Tests',
      fix        => sub {
          my $ctx = shift;
          # scaffold a basic test file
      },
  );

  printf "%s %s\n", $f->icon, $f->message;
  $f->fix->($ctx) if $f->is_fixable;

=head1 DESCRIPTION

A value object representing one diagnostic item emitted by an
C<App::Project::Doctor::Check::*> plugin.  Each finding carries a severity
level, a human-readable message, an optional file/line location, and an
optional automated fix coderef.

=head1 CONSTRUCTOR

=head2 new( %args )

  my $finding = App::Project::Doctor::Finding->new(
      severity   => 'error',   # required: error|warning|pass|info
      message    => 'text',    # required non-empty string
      detail     => '...',     # optional extended explanation
      fix        => sub {...}, # optional coderef ($ctx) -> 1
      check_name => 'Tests',   # optional, default 'Unknown'
      file       => 'lib/F.pm',# optional
      line       => 42,        # optional positive integer
  );

Croaks on invalid severity or empty message.

=head3 API SPECIFICATION

=head4 Input

  severity   : 'error' | 'warning' | 'pass' | 'info'   default 'info'
  message    : non-empty String
  detail     : String                                    default ''
  fix        : CodeRef ($ctx) -> 1                       optional
  check_name : String                                    default 'Unknown'
  file       : String                                    default ''
  line       : positive Integer                          optional

=head4 Output

Blessed hashref of type C<App::Project::Doctor::Finding>.

=head1 ACCESSORS

C<severity>, C<message>, C<detail>, C<fix>, C<check_name>, C<file>, C<line>
-- all read-only.

=head1 METHODS

=head2 is_fixable

Returns 1 when C<fix> is defined, 0 otherwise.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

Integer 1 or 0.

=head2 has_fix

Synonym for C<is_fixable>.  Both are part of the public API.

=head2 icon

Returns the severity icon string: C<[v]> pass, C<[X]> error, C<[!]> warning,
C<[i]> info.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

String -- one of C<[v]>, C<[X]>, C<[!]>, C<[i]>.

=head2 to_hash

Returns a plain hashref suitable for JSON encoding.  C<fix> is excluded.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

HashRef with keys: severity, message, detail, check_name, file, line (if set).

=head3 MESSAGES

  Code | Trigger                       | Resolution
  -----|-------------------------------|----------------------------
  F001 | message is undef or empty     | Provide a non-empty message
  F002 | severity is not a valid value | Use error|warning|pass|info

=head3 FORMAL SPECIFICATION

  Finding == [
    severity   : SEVERITY,
    message    : String,
    detail     : String,
    fix        : (Context -> Bool) | undefined,
    check_name : String,
    file       : String,
    line       : N | undefined
  ]

  SEVERITY ::= error | warning | pass | info

  is_fixable : Finding -> Bool
  is_fixable f == (fix f /= undefined)

=head1 LIMITATIONS

The C<fix> coderef is not serialisable and is omitted from C<to_hash>.

Encapsulation of private helpers is enforced by convention only; a future
migration to C<Sub::Private> in enforce mode is tracked as a TODO.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
