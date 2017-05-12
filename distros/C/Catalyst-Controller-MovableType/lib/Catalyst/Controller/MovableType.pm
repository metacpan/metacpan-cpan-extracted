package Catalyst::Controller::MovableType;
use Moose;
BEGIN { extends 'Catalyst::Controller::WrapCGI'; }
use utf8;
use namespace::autoclean;

our $VERSION = 0.004;

has 'perl' => (is => 'rw', default => 'perl');

has 'mt_home' => (is => 'rw'); # /my/app/root/mt/

# Use chaining here, so that Catalyst::Controller::WrapCGI::wrap_cgi can properly
# populate $ENV{SCRIPT_NAME} with $c->uri_for($c->action, $c->req->captures)->path,
# so that MovableType can then extract the correct path of location.
sub capture_mt_script :Chained('/') :PathPart('mt') :CaptureArgs(1) { }
 
sub run_mt_script :Chained('capture_mt_script') :PathPart('') :Args {
    my ($self, $c) = @_;
    my $captures = $c->req->captures;
    my $cgi_script = $captures->[0];

    my %mt_scripts
        = map +($_ => 1),
        qw( mt-add-notify.cgi
            mt-atom.cgi
            mt.cgi
            mt-comments.cgi
            mt-feed.cgi
            mt-ftsearch.cgi
            mt-search.cgi
            mt-tb.cgi
            mt-testbg.cgi
            mt-upgrade.cgi
            mt-wizard.cgi
            mt-xmlrpc.cgi
        ) # mt-config.cgi intentionally left out
    ;

    # http://www.movabletype.org/documentation/installation/install-movable-type.html#start-blogging states:
    # Warning: because the mt-check.cgi script displays server details which could be useful to a hacker, it
    # is recommended that this script be removed or renamed.
    #
    # Allow it only in debug mode.
    $mt_scripts{'mt_check.cgi'} = 1 if ($c->debug());

    $self->not_found($c) unless ($mt_scripts{$cgi_script});

    $ENV{MT_HOME} = $self->mt_home;

    $self->cgi_to_response($c, sub { 
        system($self->perl, $self->mt_home.$cgi_script);
    });
}

sub not_found :Private {
    my ($self, $c) = @_;
    $c->response->status(404);
    $c->response->body('Not found!');
    $c->detach();
}
 
1;

__END__

=head1 NAME

Catalyst::Controller::MovableType - Run Movable Type through Catalyst

=head1 DESCRIPTION

Runs Movable Type 5 through Catalyst.
Download Movable Type 5 from http://www.movabletype.org/

=head1 SYNOPSIS

 package MyApp::Controller::Mt;

 use Moose;
 BEGIN {extends 'Catalyst::Controller::MovableType'; }
 use utf8;

 1;

=head1 INSTALLATION

Install Movable Type by extracting the zip into your template root directory.
Move mt-static to root/static/mt. See Synopsis on how to inherit the Controller
in your app. Presuming you installed Movable Type into root/mt, in your App's
config add:

 <Controller::Root>
     cgi_root_path mt/
     cgi_dir mt/
 </Controller::Root>
 <Controller::Mt>
     mt_home = /full/path/to/MyApp/root/mt/
     <actions>
         <capture_mt_script>
             PathPart = mt
         </capture_mt_script>
     </actions>
 </Controller::Mt>

The cgi_* directives are always given for the Root controller, no matter what
the Root controller is.

You can modify the path where the script matches by configuring the PathPart as
shown above. This controller defaults to match on the path "/mt".

Finally, make sure that the Static::Simple doesn't affect the Movable Type's
installation directory. An example:

 __PACKAGE__->config(
     name => 'MyApp',
     static => {
         # first ignore all extensions, then specify static directories!
         'ignore_extensions' => [ qr/.*/ ],
         'dirs' => [ qw/static/ ]
     }
 );

=head1 METHODS

=head2 capture_mt_script

Captures the path of the Movable Type.

=head2 run_mt_script

Runs the requested Movable Type .cgi script transparently with cgi_to_response.

=head2 not_found

Sets the response to a simple 404 Not found page. You can override this method
with your own.

=head1 BUGS

None known.

=head1 SEE ALSO

L<Catalyst::Controller::WrapCGI>

=head1 AUTHOR

Oskari 'Okko' Ojala <perl@okko.net>

=head1 CONTRIBUTORS

Matt S. Trout <mst@shadowcatsystems.co.uk>

=head1 COPYRIGHT & LICENSE

Copyright 2010 the above author(s).

This sofware is free software, and is licensed under the same terms as Perl itself.

=cut

