package App::gist;
$App::gist::VERSION = '0.16';
use strict;
use warnings;

use base qw(App::Cmd::Simple);

use Pithub::Gists;
use File::Basename;
use Class::Load qw(try_load_class);

BEGIN {
	package App::gist::Auth;
$App::gist::Auth::VERSION = '0.16';
use Moo::Role;
	use Pithub::Base;

	around _request_for => sub {
		my ($orig, $self, @args) = @_;
		my $req = $self -> $orig(@args);

		my ($login, $passwd) = App::gist::_get_credentials();

		$req -> headers -> remove_header('Authorization');
		$req -> headers -> authorization_basic($login, $passwd);

		return $req;
	};

	'Moo::Role' -> apply_roles_to_package(
		'Pithub::Base',
		'App::gist::Auth'
	);
};

=head1 NAME

App::gist - Gist command-line tool

=head1 VERSION

version 0.16

=head1 SYNOPSIS

   $ gist script.pl

=cut

sub opt_spec {
	return (
		['description|d=s', 'set the description for the gist'         ],
		['name|n=s',        'specify the name of the file'             ],
		['update|u=s',      'update the given gist with the given file'],
		['private|p',       'create a private gist'                    ],
		['web|w',           'only output the web url'                  ]
	);
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	$self -> usage_error("Too few arguments.")
		unless %$opt || @$args || ! -t STDIN;
}

sub execute {
	my ($self, $opt, $args) = @_;

	my $id		= $opt -> {'update'};
	my $file	= $args -> [0];
	my $description	= $opt -> {'description'};
	my $public	= $opt -> {'private'} ? 0 : 1;
	my $web		= $opt -> {'web'} ? 1 : 0;

	my ($name, $data);

	if ($file) {
		open my $fh, '<', $file or die "Err: Enter a valid file name.\n";
		$data = join('', <$fh>);
		close $fh;

		$name = basename($file);
	} else {
		$name = $opt -> {'name'} || 'gistfile.txt';
		$data = join('', <STDIN>);
	}

	my $gist = Pithub::Gists -> new;

	my $info = $id					?
		_edit_gist($gist, $id, $name, $data)	:
		_create_gist($gist, $name, $data, $description, $public);

	die "Err: " . $info -> content -> {'message'} . ".\n"
		unless $info -> success;

	my $gist_id  = $info -> content -> {'id'};
	my $html_url = $info -> content -> {'html_url'};
	my $pull_url = $info -> content -> {'git_pull_url'};
	my $push_url = $info -> content -> {'git_push_url'};

	if ($web) {
		print "$html_url\n";
	} else {
		print "Gist '$gist_id' successfully created/updated.\n";
		print "Web URL: $html_url\n";
		print "Public Clone URL: $pull_url\n" if $public;
		print "Private Clone URL: $push_url\n";
	}
}

sub _create_gist {
	my ($gist, $name, $data, $description, $public) = @_;

	return $gist -> create(data => {
		description => $description,
		public      => $public,
		files       => {
			$name => { content => $data }
		}
	});
}

sub _edit_gist {
	my ($gist, $id, $name, $data) = @_;

	my $info = $gist -> get(gist_id => $id);

	die "Err: " . $info -> content -> {'message'} . ".\n"
		unless $info -> success;

	return $gist -> update(
		gist_id => $id,
		data    => {
			description => $info -> content -> {'description'},
			files       => {
				$name => { content => $data }
			}
		}
	);
}

sub _get_credentials {
	my ($login, $pass, $token);

	my %identity = Config::Identity::GitHub -> load
		if try_load_class('Config::Identity::GitHub');

	if (%identity) {
		$login = $identity{'login'};
	} else {
		$login = `git config github.user`;  chomp $login;
	}

	if (!$login) {
		my $error = %identity ?
			"Err: missing value 'user' in ~/.github" :
			"Err: Missing value 'github.user' in git config";

		die "$error.\n";
	}

	if (%identity) {
		$token = $identity{'token'};
		$pass  = $identity{'password'};
	} else {
		$token = `git config github.token`;    chomp $token;
		$pass  = `git config github.password`; chomp $pass;
	}

	if ($token) {
		die "Err: Login with GitHub token is deprecated.\n";
	} elsif (!$pass) {
		require Term::ReadKey;

		print STDERR "Enter password for '$login': ";
		Term::ReadKey::ReadMode('noecho');
		chop($pass = <STDIN>);
		Term::ReadKey::ReadMode('normal');
		print "\n";
	}

	return ($login, $pass);
}

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of App::gist
