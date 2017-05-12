package <tmpl_var main_module>::<tmpl_var sub_module>;

use warnings;
use strict;
use base '<tmpl_var main_module>';

=head1 NAME

Template controller subclass for CGI::Application::Structured apps.

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

Provide an overview of functionality and purpose of
web application controller here.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by <tmpl_var main_module>::cgiapp_init.

TODO: change all these values to ones more appropriate for your application.

=cut

sub setup {
    my ($self) = @_;

}

=pod

TODO: Other methods inherited from CGI::Application go here.

=head2 RUN MODES

=head3 index

  * Purpose
  * Expected parameters
  * Function on success
  * Function on failure

TODO: Describe index1 here. 

=cut

sub index: StartRunmode {
    my ($c) = @_;
    $c->tt_params({
	message => 'Hello world!',
	title   => '<tmpl_var sub_module>'
		  });
    return $c->tt_process();
    
}

=head3 example

An example stub for adding a controller runmode. Runmodes are declared with the ': Runmode' modifier.
NOTE: Only one method can be marked as 'StartRunmode'.

=cut

#sub example: Runmode{
#	my $c = shift;
#	# do something
#	# set $c->tt_params
#	# return $c->tt_process();
#}




# TODO: Private methods go here. Start their names with an _ so they are skipped
# by Pod::Coverage.

#
#sub _non_runmode_util_subroutine{
#	# no self = shift!
#	...
#}
#
#sub _non_runmode_util_method{
#	my $c = shift;
#	...
#}
#


=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests to
C<bug-<tmpl_var rtname> at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=<tmpl_var distro>>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<CGI::Application::Plugin::DBIC::Schema>, L<DBIx::Class>, L<CGI::Application::Structured>, L<CGI::Application::Structured::Tools>

=head1 AUTHOR

<tmpl_var author>, C<< <<tmpl_var email_obfuscated>> >>

=head1 LICENSE AND COPYRIGHT

Copyright <tmpl_var year> <tmpl_var author>, all rights reserved.

<tmpl_var license_blurb>

=cut

1;    # End of <tmpl_var module>

__END__
