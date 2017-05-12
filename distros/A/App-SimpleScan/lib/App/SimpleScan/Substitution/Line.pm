package App::SimpleScan::Substitution::Line;
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

use base qw(Class::Accessor::Fast Clone);
__PACKAGE__->mk_accessors( qw(line) );

use overload
  '""' => sub { $_[0]->line };

sub new {
  my ($class, $line) = @_;
  my $self = {};
  bless $self, $class;

  croak "No line supplied" unless defined $line;

  $self->line($line);
  $self->no_fixed;

  return $self;
}

sub no_fixed {
  my($self) = @_;
  $self->{fixed} = {};
}

sub fix {
  my ($self, $var, $value) = @_;
  croak "No variable supplied" unless defined $var;
  croak "No value supplied" unless defined $value;

  $self->{fixed}->{$var} = $value;
}

sub unfix {
  my ($self, $var) = @_;
  croak "No variable supplied" unless defined $var;
  croak "Variable $var is not fixed" unless exists $self->{fixed}->{$var};
  delete $self->{fixed}->{$var};
}

sub fixed {
  my ($self, $var) = @_;
  if (defined $var) {
    return $self->{fixed}->{$var};
  }
  else {
    return %{ $self->{fixed} };
  }
}

1;

__END__

=head1 NAME

App::SimpleScan::Substitution::Line - a line with optional fixed variable values

=head1 SYNOPSIS

  my $line = 
    App::SimpleScan::Substitution::Line->new("<substitute> this <too>");

  # Use only this value when substituting "<substitute>".
  $line->fix('substituite' => 'change');

  # what vars are fixed?
  my @fixed_ones = $line->fixed();

  # Forget about <substitute> now.
  $line->unfix('substitute');

  # Forget all fixed variables.
  $line->no_fixed

  # Get the line back as a string.
  print "$line";

=head1 DESCRIPTION

App::SimpleScan::Substitution::Line allows us to associate fixed substitution
values with a specific string. This allows us to re-substituted the same value
if, during string substitution, we find the variable reappearing as the result
of substituting some other variable. This eliminates the "cross-product" bug
that appeared in some complex nest substitions.

=head1 INTERFACE

=head2 new($line)

Creates a new object. The line is required.

=head2 no_fixed

Deletes all fixed variables for this object.

=head2 fix($var, $value)

Fixes the given variable to the specified value.

=head2 unfix($var, $value)

Drops the fixed variable value for the given variable.

=head2 fixed

With no argument, returns a list of variable with fixed values associated with the object. With an argument, returns the fixed value (if any) for the variable
specified.

=head1 DIAGNOSTICS

=over 4

=item C<< No line supplied >>
You must supply a line to be substituted in new().

=back

=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan::Substitution::Line requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to "bug-app-simplescan@rt.cpan.org", or through the web interface at <http://rt.cpan.org>.

=head1 AUTHOR

Joe McMahon C<< <mcmahon@yahoo-inc.com > >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Joe McMahon C<< mcmahon@yahoo-inc.com >>. All rights reserved.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

