use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Defaults;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Query);

=pod

=head1 NAME

Apache::Wyrd::Defaults - Default data for a Form Wyrd

=head1 SYNOPSIS

  <BASENAME::SQLForm index="user_id" table="users">
    <BASENAME::Form::Template name="password">
    <BASENAME::Form::Preload>
      <BASENAME::Defaults>
        select 'root' as user_id;
      </BASENAME::Defaults>
      <BASENAME::Query>
        select user_id from users where name='Groucho'
      </BASENAME::Query>
    </BASENAME::Form::Preload>
    <b>Enter Password:</b><br>
    <BASENAME::Input name="password" type="password" />
    <BASENAME::Input name="user_id" type="hidden" />
    </BASENAME::Form::Template>
    <BASENAME::Form::Template name="result">
    <H1>Status: $:_status</H1>
    <HR>
    <P>$:_message</P>
    </BASENAME::Form::Template>
  </BASENAME::SQLForm>
  
=head1 DESCRIPTION

Provide default values to a parent object.  The parent must have a
C<register_defaults> method to which Defaults passes itself.  The
defaults are given in the form of a query, and the C<sh> method accesses
the statement handle of that query.  This Wyrd was designed to
be used with an C<Apache::Wyrd::Form::Preload> object.

=head2 HTML ATTRIBUTES

See C<Apache::Wyrd::Query>.

=head2 PERL METHODS

See C<Apache::Wyrd::Query>.

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the C<_setup>, C<_format_output>, and C<_generate_output> methods.

=cut

sub _generate_output {
	my ($self) = @_;
	if ($self->{'_parent'}->can('register_defaults')) {
		$self->activate;
		$self->{'_parent'}->register_defaults($self);
	} else {
		$self->_warn("Defaults '" . $self->{'query'} . "' called, but not used.  Parent should register_defaults.");
	}
	return;
};


=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Form

Build complex HTML forms from Wyrds

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut
