package CPAN::Digger::Index::Projects;
use Moose;

our $VERSION = '0.08';

extends 'CPAN::Digger::Index';

has 'projects'      => ( is => 'ro', isa => 'Str' );
has 'projects_data' => ( is => 'rw', isa => 'ArrayRef' );

use CPAN::Digger::Tools;
use CPAN::Digger::DB;

use Data::Dumper qw(Dumper);
use YAML qw(LoadFile);

# stupid duplicate from Index.pm
my $dbx;

sub db {
	if ( not $dbx ) {
		$dbx = CPAN::Digger::DB->new;
		$dbx->setup;
	}
	return $dbx;
}

sub get_projects {
	my ($self) = @_;
	if ( not $self->projects_data ) {
		my $d = LoadFile $self->projects;
		$self->projects_data( $d->{projects} );
	}
	return $self->projects_data;
}

sub update_from_whois {
	my ($self) = @_;

	LOG('start adding project authors');

	# my $projects = $self->get_projects;
	# #die Dumper $p;
	#
	# db->dbh->begin_work;
	# foreach my $p (@$projects) {
	# my $have = db->get_author($p->{author});
	# if (not $have) {
	# LOG("add_author $p->{author}");
	# db->add_author({}, $p->{author});
	# }
	# }
	# db->dbh->commit;
	#
	LOG('done adding project authors');

	return;
}

sub collect_distributions {
	my ($self) = @_;

	LOG('start inserting project names');

	my $projects = $self->get_projects;

	my $now = time;
	db->dbh->begin_work;
	foreach my $p (@$projects) {

		#my @args = ($p->{author}, $p->{name}, $p->{version}, "$p->{name}/$p->{version}", $now, $now);
		#LOG("insert_distr @args");
		#db->insert_distro(@args);
		db->insert_project( $p->{name}, $p->{version}, $p->{path}, $now );
	}

	db->dbh->commit;

	LOG('done inserting project names');

	return;
}

sub process_all_distros {
	my ($self) = @_;

	LOG('start processing projects');

	my $projects = $self->get_projects;

	my $now = time;
	db->dbh->begin_work;

	foreach my $p (@$projects) {

	}

	db->dbh->commit;

	LOG('done processing projects');

	return;
}

sub prepare_src {
	my ( $self, $d, $src_dir, $path ) = @_;

	my $source_dir;
	LOG("Source directory $source_dir");

	# just copy the files
	foreach my $file ( File::Find::Rule->file->relative->in($source_dir) ) {
		next if $file =~ /\.svn|\.git|CVS|blib/;
		my $from = File::Spec->catfile( $source_dir,     $file );
		my $to   = File::Spec->catfile( $d->{distvname}, $file );

		#LOG("Copy $from to $to");
		mkpath dirname $to;
		copy $from, $to or die "Could not copy from '$from' to '$to' while in " . cwd() . " $!";
	}

	return;
}

#sub generate_central_files {
#	return;
#}

sub collect_meta_data {
}

1;

