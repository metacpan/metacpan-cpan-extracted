#!/usr/bin/perl
use strict;

use POE qw(Component::Client::HTTP);
use HTTP::Request::Common 'GET';

use lib '../lib';
use Acme::CPANAuthors;

my $a = Acme::CPANAuthors->new(shift || 'Russian');

POE::Component::Client::HTTP->spawn(Alias => 'HTTP_CLIENT', FollowRedirects => 0);

POE::Session->create(
	inline_states => {
		_start => sub {
			for ($a->id) {
				my($id) = $a->avatar_url($_) =~ m{avatar/(.*)};
				$_[KERNEL]->post(
					'HTTP_CLIENT' => 'request', 'result',
					GET(($id ? "http://www.gravatar.com/avatar.php?gravatar_id=$id" : $a->avatar_url($_)).'&default=http%3A%2F%2Fst.pimg.net%2Ftucs%2Fimg%2Fwho.png'),
					$_
				);
				$_[HEAP]->{'count'}++;
			}
		},
		result => sub {
			my $name     = $_[ARG0]->[1];
			my $response = $_[ARG1]->[0];
			
			unless ($response->is_redirect) {
				# print qq{<a href="http://search.cpan.org/~$name/"  title="@{[$a->name($name)]}"><img src="@{[$a->avatar_url($name)]}"></a>\n};
				warn qq({id => '$name', name => '@{[$a->name($name)]}', avatar => '@{[$a->avatar_url($name)]}'},\n);
			}
			
			$_[KERNEL]->stop unless --$_[HEAP]->{'count'};
		},
	}
);

POE::Kernel->run;


__END__

=head1 NAME

cpan-faces.pl - script for building CPAN faces of Acme::CPANAuthors

=head1 SYNOPSIS

	./cpan-faces.pl Russian

=head1 DESCRIPTION

You can build CPAN faces for others Acme::CPANAuthors sets.

This script based on L<POE>.

See source code :)

=head1 AUTHOR

Anatoly Sharifulin, E<lt>sharifulin at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
