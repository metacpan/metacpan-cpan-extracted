package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => q{});

sub base : Chained('/') PathPart('') CaptureArgs(0) {}

# your actions replace this one
sub main : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my $reqs = $c->req->params;
    foreach my $hdr (qw( ETag Expires Last-Modified )) {
	if (exists $reqs->{$hdr}) {
	    $c->res->header( $hdr => $reqs->{$hdr} );
	}
    }

    if ($reqs->{Status}) {
	$c->res->code($reqs->{Status});
    }

    my %options = ( );

    foreach my $key (qw( no_etag no_expires no_last_modified strong no_preempt_head )) {
	if (exists $reqs->{$key}) {
	    $options{$key} = $reqs->{$key};
	}
    }

    if ($c->not_cached(\%options)) {
	$c->res->body('<p>Content Ok</p>');
    }
}

__PACKAGE__->meta->make_immutable;
