use utf8;
use strict;
use warnings;
package CouchDB::Utils::App::Command::dump;

use App::Cmd::Setup -command;

use URI;
use JSON::XS;
use File::Path qw(mkpath);
use File::Spec::Functions qw(rel2abs catdir catfile);
use AnyEvent::CouchDB;

sub description {
	'dump a couchdb database to filesystem';
}

sub abstract {
	'dump a couchdb database to filesystem';
}

sub usage_desc {
	'dump %o <database> [directory]'
}

sub opt_spec {
	['all|a'=> 'dump all documents' ],
	['https'=> 'secure' ],
	['server|s=s'=> 'server to connect to', { default => 'localhost' } ],
	['port|p=i'=> 'port to connect to', { default => 5984 } ],
	['url|l=s' => 'full database url'],
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	$self->usage_error('missing database name') unless @$args;
}

sub execute {
	my ($self, $opt, $args) = @_;

	## this will be used to pretty format json
        my $json = JSON->new->allow_nonref->pretty;

	my $name = $args->[0]; ## database name
	## unspecified dump dir name will default to database name
	my $dir = rel2abs($args->[1] || $name); 
	mkpath($dir); ##  make sure it exists, create it otherwise

	my $uri = URI->new($opt->{url}); ## easier to handle default values
	unless ($opt->{url}) {
		$uri->scheme($opt->{https} ? 'https' : 'http');
		$uri->host($opt->{server});
		$uri->port($opt->{port});
		$uri->path($name);
	}

	my $db = couchdb($uri->as_string);
	my $docs_opts = {};

	unless (exists $opt->{all}) {
		$docs_opts->{startkey} = '_design';
		$docs_opts->{endkey} = '_design0';
	}

	my $docs = $db->all_docs($docs_opts)->recv;
	my $rows = $docs->{rows};
	foreach my $row (@$rows) {
		my $id = $row->{id}; ## document id, really
		mkpath (my $doc_dir = catdir($dir,$id));

		## views & attachments are stored separately of docs:
		## so we cut them out of the doc for later processing
		my $doc = $db->open_doc($id, {revs_info => 'true'})->recv;
		my $views = delete $doc->{views};
		my $attachments = delete $doc->{_attachments};

		if (my $revs_info = delete $doc->{_revs_info}) {
			my ($start, @ids);
			foreach my $revision (@$revs_info) {
				my ($rev_start,$rev_id) = split /-/, $revision->{rev}, 2;
				$start ||= int($rev_start ||= 1);
				push @ids, $rev_id;
			}
			$doc->{_revisions} = { start => $start, ids => \@ids };
		}

		## pretty json formating makes it easier to edit the docs once
		## they are on the file system
		my $pretty_doc = $json->encode($doc); 
		_dump(catfile($doc_dir,'doc')=> $pretty_doc);

		if (defined $views) {
			mkpath(my $views_dir = catdir($doc_dir,'views'));
			while (my ($view, $value) = each %$views) {
				mkpath(my $view_dir = catdir($views_dir,$view));
				foreach (keys %$value) {
					my $v = $value->{$_};
					_dump(catfile($view_dir,$_) => $v);
				}
			}
		}

		if (defined $attachments) {
			my $attachments_dir = catdir($doc_dir,'_attachments');
			mkpath $attachments_dir;
			foreach (keys %$attachments) {
				my($body) = $db->open_attachment($doc,$_)->recv;
				_dump(catdir($attachments_dir,$_) => $body);
			}
		}

	}

}

sub _dump {
	my ($file, $content)= @_;
	open FILE, ">$file";
	print FILE $content;
	close FILE;
}

1;

__END__

=pod

=head1 NAME

CouchDB::Utils::App::Command::dump

=head1 VERSION

version 0.3

=head1 AUTHOR

Maroun NAJM <mnajm@cinemoz.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Cinemoz Inc.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
