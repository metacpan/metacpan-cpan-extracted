package App::Project::Doctor::Check::Base;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);

our $VERSION = '0.02';

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
	my ($class, %args) = @_;
	return bless {%args}, $class;
}

# ---------------------------------------------------------------------------
# Required interface -- subclasses MUST override these three
# ---------------------------------------------------------------------------

=head2 name (required)

Short label used in the report table, e.g. C<Tests>.

=cut

sub name {
	croak ref(shift) . ' must implement name()';
}

=head2 description (required)

One-sentence description of what the check verifies.

=cut

sub description {
	croak ref(shift) . ' must implement description()';
}

=head2 check( $context ) (required)

Accepts an L<App::Project::Doctor::Context> and returns a list of
L<App::Project::Doctor::Finding> objects (empty list on a clean pass).

=cut

sub check {
	croak ref(shift) . ' must implement check()';
}

# ---------------------------------------------------------------------------
# Optional interface with sensible defaults
# ---------------------------------------------------------------------------

=head2 can_fix

Returns true when this check can produce fixable findings.  Default 0.

=cut

sub can_fix  { 0 }

=head2 category

Grouping label for report presentation.  Default C<general>.

=cut

sub category { 'general' }

=head2 order

Numeric sort key: lower numbers appear first in the report.  Default 50.

=cut

sub order    { 50 }

1;

__END__

=head1 NAME

App::Project::Doctor::Check::Base - Base class for all check plugins

=head1 VERSION

0.02

=head1 SYNOPSIS

  package App::Project::Doctor::Check::MyCheck;

  use strict;
  use warnings;
  use autodie qw(:all);

  use parent -norequire, 'App::Project::Doctor::Check::Base';

  sub name        { 'My Check' }
  sub description { 'Verifies something important.' }
  sub can_fix     { 1 }
  sub order       { 70 }

  sub check {
      my ($self, $ctx) = @_;
      return () if $ctx->has_file('something-good');
      require App::Project::Doctor::Finding;
      return App::Project::Doctor::Finding->new(
          severity   => 'error',
          message    => 'Missing something-good',
          check_name => $self->name,
          fix        => sub { ... },
      );
  }

  1;

=head1 DESCRIPTION

Traditional OO base class that defines the interface every
C<App::Project::Doctor::Check::*> plugin must implement.

Calling C<name>, C<description>, or C<check> on an instance that has not
overridden them will C<croak> at runtime with a clear message.

Subclasses inherit via:

  use parent -norequire, 'App::Project::Doctor::Check::Base';

The C<-norequire> flag is used because C<Base> is always loaded by the
orchestrator before the subclass is instantiated.

=head1 REQUIRED METHODS

Subclasses must implement C<name>, C<description>, and C<check>.
See L</SYNOPSIS> for the expected signatures.

=head1 OPTIONAL METHODS

=head2 can_fix

Boolean -- default 0.

=head2 category

String grouping label -- default C<general>.

=head2 order

Numeric sort key -- default 50.

=head3 MESSAGES

  Code | Trigger                        | Resolution
  -----|--------------------------------|----------------------------
  B001 | name/description/check called  | Override the method in the
       | on base class directly         | subclass

=head3 FORMAL SPECIFICATION

  Check == { name : String, description : String,
             check : Context -> [Finding],
             can_fix : Bool, category : String, order : N }

  run : Check x Context -> [Finding]
  run c ctx == check c ctx

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
