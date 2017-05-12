# term.pm - this file is part of the CGI::Listman distribution
#
# CGI::Listman is Copyright (C) 2002 iScream multimédia <info@iScream.ca>
#
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>

use strict;

package CGI::Listman::dictionary::term;

use Carp;

=pod

=head1 NAME

CGI::Listman::dictionary::term - element of a I<CGI::Listman::dictionary>

=head1 SYNOPSIS

    use CGI::Listman::dictionary::term;

=head1 DESCRIPTION

A I<CGI::Listman::dictionary::term> is what an instance of
I<CGI::Listman::dictionary> is made of. In our terminology, a "term" is
made of a "key" and a "definition". The similarity with the words in a
lingual dictionary is not innocent.

Within a CGI script, you are most certainly receiving and transmitting
variables to a form. A couple of those variables will be of internal use
only while the others will be part of the interactivity with your users.
Generally, those variables will have names that are explicit to you as a
programmer; however they might mean nothing or little to a normal user.

Now, in the context of I<CGI::Listman>, those variables are juste fields
of a database row and it makes even less sense to give them a
user-explicit name (imagine a name such as "Your father's forename"). So
the B<key> of a I<CGI::Listman::dictionary::line> will represent a
database column and the B<definition> will be its user representation.
This is mostly useful when you have to represent those variables in the
sight of your users; for example when validating user input (see
I<CGI::Listman>'s method I<check_params>).

A I<CGI::Listman::dictionary::term> also contains validation information.
Currently it only supports a flag indicating whether the field is
mandatory or not but it will probably contain other flags in a later
release.

=head1 API

=head2 new

This method is to instantiate a term. It optionnally takes arguments for
the term's key, definition and mandatory flag. All the parameters are
optional with this method.

=over

=item Parameters

=over

=item key

A string representing the term's key.

=item definition

A string representing the term's definition.

=item mandatory

A boolean (0 or 1) integer defining whether user input is required or not
for this term.

=back

=item Return values

This method returns a blessed reference to a
I<CGI::Listman::dictionary::term>.

=back

=cut

sub new {
  my $class = shift;

  my $self = {};
  $self->{'key'} = shift;
  $self->{'_definition'} = shift;
  $self->{'mandatory'} = shift || 0;

  bless $self, $class;
}

=pod

=head2 set_key

This method set the term's key to the provided value.

=over

=item Parameters

=over

=item key

A string representing the term's key.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_key {
  my ($self, $key) = @_;

  croak "Bad key name.\n" unless (defined $key && $key ne '');
  croak 'This term already has a key name ("'.$self->{'key'}.")\"\n"
    if (defined $self->{'key'});
  $self->{'key'} = $key;
}

=pod

=head2 set_definition

This method set the term's definition to the provided value.

=over

=item Parameters

=over

=item definition

A string representing the term's definition.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_definition {
  my ($self, $definition) = @_;

  $definition = undef if (defined $definition
			  && ($definition =~ m/^\s+$/));
  $self->{'_definition'} = $definition;
}

=pod

=head2 set_mandatory

This method declares that user input is required for this term.

=over

=item Parameters

This method take no parameter.

=item Return values

This method returns nothing.

=back

=cut

sub set_mandatory {
  my $self = shift;

  $self->{'mandatory'} = 1;
}

=pod

=head2 definition

This method returns the definition for the specified instance of
I<CGI::Listman::dictionary::term>.

=over

=item Parameters

This method take no parameter.

=item Return values

This method returns a string representing either the term's definition.

=back

=cut

sub definition {
  my $self = shift;

  my $definition = $self->{'_definition'};

  return $definition;
}

=pod

=head2 definition_or_key

This method returns the definition for the specified instance of
I<CGI::Listman::dictionary::term>. If the definition is not existing, the
key is returned instead.

=over

=item Parameters

This method take no parameter.

=item Return values

This method returns a string representing either the term's definition or
its key whenever its definition is void.

=back

=cut

sub definition_or_key {
  my $self = shift;

  my $definition = $self->definition () || $self->{'key'};

  return $definition;
}

1;
__END__

=pod

=head1 AUTHOR

Wolfgang Sourdeau, E<lt>Wolfgang@Contre.COME<gt>

=head1 COPYRIGHT

Copyright (C) 2002 iScream multimédia <info@iScream.ca>

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Listman(3)>  L<CGI::Listman::dictionary(3)>

=cut
