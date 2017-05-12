=head1 NAME

    BoutrosLab::TSVStream:IO::Role::Base::Fixed

=head1 SYNOPSIS

This is a collection of base attributes and methods used internally
by TSVStream reader and writer role modules.  It provides the
common parameters used to define reader and writer methods that
can be imported into a target class.

=cut

package BoutrosLab::TSVStream::IO::Role::Base::Fixed;

# safe Perl
use warnings;
use strict;
use Carp;
use feature 'say';

use Moose::Role;
use namespace::autoclean;
use Try::Tiny;

# Base role for all reader/writer variants
#
# The BUILDARGS wrapper checks wheter a handle was proveded
# and, if not, opens the file provided and sets the handle
# to that newly opened fd.
#
# The class that consumes this role can add two extra entries
# to the arg list:
#     - _open_mode - the mode to be used for an open (usually
#                    one of '<', '>', '>>')
#     - _valid_arg - a hash of arg names to be validated, any
#                    arg key provided which does not match a
#                    key in this hash will cause an error
#                    (the _valid_arg and _open_mode args will not
#                    cause an error - they do not need to be
#                    listed in the _valid_arg hash since they
#                    are provided internally and removed before
#                    validation).

has handle => ( is => 'ro', required => 1, isa => 'FileHandle' );

has file => ( is => 'ro', lazy => 1, isa => 'Str', default => '[Unnamed stream]' );

has class => ( is => 'ro', required => 1, isa => 'Str' );

has [ qw(comment pre_comment pre_header) ] => ( is => 'ro', isa => 'Bool', default => 0 );

has comment_pattern => (
	is      => 'ro',
	isa     => 'RegexpRef',
	default => sub { qr/(?:^\s*#)|(?:^\s*$)/ }
	);

sub _null_header_fix {
	return $_[0];
	}

has header_fix => (
	is      => 'ro',
	isa     => 'CodeRef',
	default => sub { \&_null_header_fix }
	);

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my $arg = ref($_[0]) ? $_[0] : { @_ };

	my $open_mode = delete $arg->{_open_mode} || '<';
	if (my $valid_arg = delete $arg->{_valid_arg}) {
		my @unknowns = grep { !$valid_arg->{$_} } keys %$arg;
		if (@unknowns) {
			my $s = 1 == scalar(@unknowns) ? '' : 's';
			confess "Unknown option$s ("
				. join( ',', @unknowns )
				. "), valid options are ("
				. join( ',', keys %$valid_arg )
				. ")\n";
			}
		}

	unless ($arg->{handle}) {
		if ($arg->{file}) {
			open my $fh, $open_mode, $arg->{file}
				or croak "unable to open $open_mode ", $arg->{file}, ": $!";
			$arg->{handle} = $fh;
			}
		else {
			croak "one of file/handle options must be provided";
			}
		}
	$class->$orig( $arg );
	};

has fields => (
	is       => 'ro',
	lazy     => 1,
	isa      => 'ArrayRef[Str]',
	builder  => '_init_fields',
	init_arg => undef
	);

sub _init_fields {
	my $self = shift;
	$self->class->_fields
	}

has _num_fields => (
	is       => 'rw',
	isa      => 'Int',
	init_arg => undef,
	lazy	 => 1,
	default  => sub { my $self = shift; scalar( @{ $self->fields } ) }
	);

has _field_out_methods => (
	is       => 'ro',
	lazy     => 1,
	isa      => 'Ref',
	builder  => '_init_out_fields',
	init_arg => undef
	);

sub _init_out_fields {
	my $self = shift;
	return [
		map {
			my $o_meth = "_${_}_out";
			$self->can($o_meth) ? $o_meth : $_
			}
		@{ $self->class->_fields }
		];
	}

has _save_lines => (
	is       => 'rw',
	isa      => 'ArrayRef[Str]',
	init_arg => undef,
	default  => sub { [] }
	);

has _at_eof => (
	is => 'rw',
	isa      => 'Bool',
	init_arg => undef,
	default  => undef
	);

has _is_comment => (
	is       => 'ro',
	isa      => 'CodeRef',
	lazy     => 1,
	builder  => '_init_is_comment'
	);

sub _init_is_comment {
	my $self = shift;
	if ($self->comment) {
		my $pat = $self->comment_pattern;
		sub { $_[0] =~ /$pat/ }
		}
	else {
		sub { 0 };
		}
	}

sub _read_config {
	return ();
	}

sub _peek {
	my $self = shift;
	return if $self->_at_eof;
	my $lines = $self->_save_lines;
	unless (@$lines) {
		my $h    = $self->handle;
		my $line = <$h>;
		if (not defined $line) {
			$self->_at_eof(1);
			return;
			}
		chomp $line;
		my $hash = { line => $line };
		$line =~ s/^ *//;
		$line =~ s/ *$//;
		$hash->{fields} = [ split "\t", $line ];
		push @$lines, $hash;
		}
	return $lines->[0];
	}

sub _read {
	my $self = shift;
	return if $self->_at_eof;
	my $line = $self->_peek;
	return unless defined $line;
	shift @{ $self->_save_lines } if defined $line;
	return $line;
	}

sub _unread {
	my $self = shift;
	if (@_) {
		unshift @{ $self->_save_lines }, @_;
		$self->_at_eof(0);
		}
	}

sub _croak {
	my $self = shift;
	my $msg  = shift;

	my $content = '';

	if (@_) {
		my $vals = shift;
		try {
			my @flds = @{ $self->fields };
			push @flds, @{ $self->dyn_fields } if $self->can('dyn_fields') && $self->_has_dyn_fields;
			push @flds, '*extra*' while @flds < @$vals;
			push @$vals, '*MISSING*' while @$vals < @flds;
			$content = "\n  --\> content:";  # --\> without the \ Perl::Critic thinks it is an arrow operator
			while (@flds) {
				my $f = shift @flds;
				my $v = shift @$vals;
				$content .= sprintf "\n           --\> %s(%s)", $f, $v;
			}
		}
		catch {
			$content = "\n  --\> Secondary failure trying to dump fields ($_)";
		}
	}

	my $pos  = $self->handle->input_line_number;
	my $file = $self->file;
	croak "Error: $msg\n  --\>    file: $file\n  --\>    line: $pos,$content\n";
	}

sub _write_fields {
	my $self = shift;
	my $h    = $self->handle;
	print $h join("\t", @_), "\n";
	}

sub _write_lines {
	my $self = shift;
	my $h    = $self->handle;
	my @lines = map { ref($_) ? @$_ : $_ } @_;
	print $h "$_\n" for @lines;
	}

sub _to_fields {
	my $self = shift;
	my $obj  = shift;
	return map { $obj->$_ } @{ $self->_field_out_methods };
	}

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

