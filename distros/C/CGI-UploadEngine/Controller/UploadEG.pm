package MBC::Controller::UploadEG;
use Moose;
use namespace::autoclean;
use CGI::UploadEngine;
use YAML::Any qw(LoadFile);

# Sets the actions in this controller to be registered with this prefix
__PACKAGE__->config->{namespace} = 'upload';

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

MBC::Controller::UploadEG - Catalyst Controller

=head1 DESCRIPTION

Working sample of CGI::UE developer application.

=head1 METHODS

=over 4

=item * form_eg

Uses CGI::UE I<upload_prepare()> to inject AJAX supported file select box.

=item * handler_eg

Uses CGI::UE I<upload_retrieve()> to get info on a successful upload.

=back

=cut
our $config_file = '/var/www/.uploadeg';

sub form_eg : Local {
        my ( $self, $c ) = @_;

	# Get configuration
	my $config = LoadFile($config_file);

	# Create engine
        my $upload = CGI::UploadEngine->new();

	# Prepare upload 
	$c->stash->{file_upload} = $upload->upload_prepare({ file_path        => $config->{file_path},
							     max_size         => $config->{max_size},
							     min_size         => $config->{min_size},
							     allowed_types    => $config->{allowed_types},
							     disallowed_types => $config->{disallowed_types} });

	# Munge template
	$c->stash->{action_url}  = $c->config->{root_url} . 'upload/handler_eg';
	$c->stash->{template}    = 'upload/form_eg.tt2';
}

sub handler_eg : Local {
        my ( $self, $c ) = @_;

	# Parse form data
	my $token  = $c->request->param('token');
	my $other  = $c->request->param('other');

	# Retrieve file info with token
        my $upload = CGI::UploadEngine->new();
	my $file   = $upload->upload_retrieve({ token => $token });

	# Munge template
	$c->stash->{path_name}   = $file->{file_path} . $file->{file_name};
	$c->stash->{other}       = $other;
	$c->stash->{template}    = 'upload/handler_eg.tt2';
}


=head1 AUTHORS

    Roger A Hall  C<< <rogerhall@cpan.org> >>
    Michael A Bauer  C<< <mbkodos@cpan.org> >>
    Kyle D Bolton  C<< <kdbolton@ualr.edu> >>
    Aleksandra A Markovets  C<< <aamarkovets@ualr.edu> >>


=head1 LICENSE AND COPYRIGHT

Copyleft (c) 2010, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights pre-served.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
