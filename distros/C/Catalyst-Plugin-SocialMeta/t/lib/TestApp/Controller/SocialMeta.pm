package TestApp::Controller::SocialMeta;
 
use Moose;
use namespace::autoclean;
BEGIN { 
        extends 'Catalyst::Controller'; 
}
 
sub sm :Chained('/') :PathPart('sm') :Args(0) {
        my ($self, $c) = @_;
        $c->res->body($c->stash->{socialmeta});
}

sub base :Chained('/') :PathPart('') :CaptureArgs(0) {
	my ($self, $c) = @_;

	$c->socialmeta(
		title => 'Changed Title',
		description => 'Demo UI for Changed::Title',
	);
}

sub smm :Chained('base') :PathPart('smm') :Args(0) {
        my ($self, $c) = @_;
        $c->res->body($c->stash->{socialmeta});
}


1;
