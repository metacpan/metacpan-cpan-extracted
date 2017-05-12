package Application::Pipeline::Services::Template;
$VERSION = '0.1';

#-- pragmas ---------------------------- 
 use strict;
 use warnings;

#-- modules ---------------------------- 
 use Template;

=head1 Application::Pipeline::Services::Template

This plugin for Application::Pipeline makes available a template object,
which is simply a Template Toolkit instance. To access it from the application:

$pipeline->loadPlugin( 'Template' ( template constructor arguments ) );

$template = $pipeline->template;

note that the parameters being sent to the Template constructor is not a hash
ref (as TT does), but rather a hash.  It will be correctly passed to the
Template constructor as a hash ref.

=cut

#===============================================================================

sub load {
    my( $class, $pipeline, %args ) = @_;
    my $template = Template->new( \%args );

    $pipeline->addServices( template => $template );
    return $template
}

#========
1;

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut
