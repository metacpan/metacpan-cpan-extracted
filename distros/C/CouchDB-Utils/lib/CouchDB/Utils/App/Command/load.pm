use utf8;
use strict;
use warnings;
package CouchDB::Utils::App::Command::load;

use App::Cmd::Setup -command;

use JSON;
use MIME::Base64;
use File::Basename;
use File::Slurp qw(read_file);
use File::Spec::Functions qw(rel2abs catdir catfile);
use File::MimeInfo::Simple;
use AnyEvent::CouchDB;
use Data::Dump 'pp';

sub description {
	'load a db from the filesystem to couch';
}

sub abstract {
	'load a db from the filesystem to couch';
}

sub usage_desc {
	'load %o <directory> [database]'
}

sub opt_spec {
	['https'=> 'secure' ],
	['server|s=s'=> 'server to connect to', { default => 'localhost' } ],
	['port|p=i'=> 'port to connect to', { default => 5984 } ],
	['url|l=s' => 'full database url'],
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	$self->usage_error('missing directory path') unless @$args;
}

sub execute {
	my ($self, $opt, $args) = @_;

	my $path = rel2abs($args->[0]); ## directory path
	## unspecified database name will default to the path name
	my $name = $args->[1] || basename($path);

	my $uri = URI->new($opt->{url}); ## easier to handle default values
	unless ($opt->{url}) {
		$uri->scheme($opt->{https} ? 'https' : 'http');
		$uri->host($opt->{server});
		$uri->port($opt->{port});
		$uri->path($name);
	}

	my $db = couchdb($uri->as_string);
	my $json = JSON->new->allow_nonref->pretty;

	my @docs;
	opendir (my $dh, $path) || die $!;
	while (my $f = readdir $dh) {
		next if $f eq '.' || $f eq '..';

		my $doc;
		if ($f eq '_design') {
			opendir (my $views, catdir($path,'_design')) || die $!;
			while (readdir $views) {
				next if $_ eq '.' || $_ eq '..';
				push @docs, _load_doc($db, $path, "_design/$_");
			}
			closedir $views;
		} else {
			push @docs, _load_doc($db, $path, $_);
		}
	}
	closedir $dh;

	my $bulk = $db->bulk_docs(\@docs, {new_edits => 'false'})->recv;
	foreach my $load (@$bulk) {
		if ($load->{ok}) {
			my $id = $load->{id};
			my $doc = $db->open_doc($id, {revs_info => 'true'})->recv;

			delete $doc->{'views'} if $id =~ m/^_design\//;
			delete $doc->{'_attachments'};

			if (my $revs_info = delete $doc->{_revs_info}) {
				my ($start, @ids);
				foreach my $revision (@$revs_info) {
					my ($rev_start,$rev_id) = split /-/, $revision->{rev}, 2;
					$start ||= int($rev_start ||= 1);
					push @ids, $rev_id;
				}
				$doc->{_revisions} = { start => $start, ids => \@ids };
			}

			my $doc_path = catfile($path, $id, 'doc');
			open DOC, ">$doc_path" or die $!;
			print DOC $json->encode($doc);
			close DOC;

		} elsif ($load->{error}) {
			warn "$load->{id} $load->{error}: $load->{reason}\n" ;
		} else {
			pp($load);
		}

	}
}

sub _load_doc {
	my ($db, $path, $id) = @_;

	my $doc;
	my $doc_path = catfile($path, $id, 'doc');
	if (-f $doc_path) {
		$doc = decode_json(read_file($doc_path));
	} else {
		die "Can't find $doc_path\n";
	}

	if (-d (my $views_path = catdir($path, $id, 'views'))) {
		opendir (my $views, $views_path) || die $!;
		while (readdir $views) {
			my $name = $_;
			my $view_path = catdir($views_path, $name);
			next if $_ eq '.' || $_ eq '..' || ! -d $view_path;

			opendir (my $view, $view_path) or die $!;
			while (readdir $view) {
				next if $_ eq '.' || $_ eq '..';
				my $func_path = catdir($view_path, $_);
				my $text = read_file($func_path);
				$doc->{views}->{$name}->{$_} = $text;
			}
			closedir $view;
		}
		closedir $views;
	}
	
	if (-d (my $atts_path = catdir($path, $id, '_attachments'))) {
		opendir (my $atts, $atts_path) || die $!;
		while (readdir $atts) {
			next if $_ eq '.' || $_ eq '..';
			my $file_path = catfile($atts_path, $_);
			my $mime_type = mimetype($file_path);
			my $content = read_file($file_path);

			$doc->{_attachments}->{$_} = {
				content_type => $mime_type,
				data => encode_base64($content),
			};

		}
		closedir $atts;
	}

	return $doc;
}

1;

__END__

=pod

=head1 NAME

CouchDB::Utils::App::Command::load

=head1 VERSION

version 0.3

=head1 AUTHOR

Maroun NAJM <mnajm@cinemoz.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Cinemoz Inc.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
