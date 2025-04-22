package Catalyst::Model::MetaCPAN::Client;
use 5.006; use strict; use warnings; our $VERSION = '0.03';
use MetaCPAN::Client; use HTTP::Tiny::Mech; use WWW::Mechanize::Cached; use CHI;
use base 'Catalyst::Model';

sub new {
	my $self = shift->next::method(@_);
	my $c = shift;
	$self->{client} = MetaCPAN::Client->new(
		ua => HTTP::Tiny::Mech->new(
			mechua => WWW::Mechanize::Cached->new(
				cache => CHI->new(
					driver   => 'File',
					root_dir => '/tmp/metacpan-cache',
				),
			),
		),
	);
	return $self;
}

sub client {
	shift->{client};
}

sub request {
	my ($self, $client, $data, $method, @params) = @_;
	$client ||= $self->client;
	my $res  = eval {
		$client->$method(@params)
	};
	if ($@) {
		return {
			error => $@
		};
	}
	return $data ? $res->{data} : $res;
}

sub resultset_to_array {
	my ($self, $resultset) = @_;
	my @results;
	my $total = $resultset->total;
	while ($total) {
		my $result = $resultset->next;
		push @results, $result->{data};
		$total--;
	}
	return \@results;
}

sub author { shift->request(undef, 1, 'author', @_); }

sub author_releases { 
	my $self = shift;
	my $author = $self->request(undef, 0, 'author', @_);
	return $author if $author->{error};
	my $releases = $self->request($author, 0, 'releases');
	return $releases if $releases->{error};
	return $self->resultset_to_array($releases);
}

sub total_author_releases {
	my $self = shift;
	my $author = $self->request(undef, 0, 'author', @_);
	return $author if $author->{error};
	my $releases = $self->request($author, 0, 'releases');
	return $releases if $releases->{error};
	return $releases->total;
}

sub cover { shift->request(undef, 1, 'cover', @_); }

sub distribution { shift->request(undef, 1, 'distribution', @_); }

sub download_url { shift->request(undef, 1, 'download_url', @_); }

sub favorites { 
	my $self = shift;
	my $favorite = $self->request(undef, 0, 'favorite', @_);
	return $favorite if $favorite->{error};
	return $self->resultset_to_array($favorite);
}

sub module {  shift->request(undef, 1, 'module', @_); }

sub module_pod {
	my $module = shift->request(undef, 0, 'module', @_);
	return $module if $module->{error};
	return $module->pod();
}

sub module_source {
	my $module = shift->request(undef, 0, 'module', @_);
	return $module if $module->{error};
	return $module->source();
}

sub package { shift->request(undef, 1, 'package', @_); }

sub permission { shift->request(undef, 1, 'permission', @_); }

sub pod { 
	my $pod = shift->request(undef, 0, 'pod', @_); 
	return $pod->plain();
}

sub ratings { 
	my $self = shift;
	my $rating = $self->request(undef, 0, 'rating', @_);
	return $rating if $rating->{error};
	return $self->resultset_to_array($rating);
}

sub release { shift->request(undef, 1, 'release', @_); }

sub release_changes { 
	my $release = shift->request(undef, 0, 'release', @_); 
	return $release->changes();
}

1;

__END__

=head1 NAME

Catalyst::Model::MetaCPAN::Client - Catalyst Model for MetaCPAN

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	package TestApp::Model::MetaCPAN;

	use parent "Catalyst::Model::MetaCPAN::Client";

	...


	package TestApp::Controller::MetaCPAN;

	use Moose;
	use namespace::autoclean;
	use JSON;
	BEGIN {
		extends 'Catalyst::Controller';
	}

	sub author :Chained('/') :PathPart('author') :Args(1) {
		my ($self, $c, $arg) = @_;
		my $author = $c->model('MetaCPAN')->author($arg);
		$c->res->body(encode_json($author));
	}


Beta.

=cut

=head1 SUBROUTINES/METHODS

=head2 new

=cut

=head2 client

=cut

=head2 request

=cut

=head2 resultset_to_array

=cut

=head2 author

=cut

=head2 author_releases

=cut

=head2 total_author_releases

=cut

=head2 cover

=cut

=head2 distribution

=cut

=head2 download_url

=cut

=head2 favorites

=cut

=head2 module

=cut

=head2 module_pod

=cut

=head2 module_source

=cut


=head2 package

=cut

=head2 permission

=cut

=head2 pod

=cut

=head2 ratings

=cut

=head2 release

=cut

=head2 release_changes

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-model-metacpan-client at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-MetaCPAN-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::MetaCPAN::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Model-MetaCPAN-Client>

=item * Search CPAN

L<https://metacpan.org/release/Catalyst-Model-MetaCPAN-Client>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Catalyst::Model::MetaCPAN::Client
