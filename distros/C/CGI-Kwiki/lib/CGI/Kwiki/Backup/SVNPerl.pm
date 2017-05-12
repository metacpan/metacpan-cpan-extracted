package CGI::Kwiki::Backup::SVNPerl;
$VERSION = '0.01';

use strict;
use base 'CGI::Kwiki::Backup::SVN';
use File::Spec;
use SVN::Core '0.28';
use SVN::Repos;
use SVN::Fs;
use SVN::Delta;
use SVN::Simple::Edit;
use Text::Diff ();

use constant SVN_DIR => 'metabase/svn';

my $user_name = '';

my ($repos, $fs, $pool, $init);

sub init {
    my $self = shift;
    $pool = SVN::Pool->new_default;
    if (-d SVN_DIR) {
	$repos = SVN::Repos::open (SVN_DIR);
    }
    else {
	$repos = SVN::Repos::create(SVN_DIR, undef, undef,
				    undef, undef);
	my $edit = $self->_get_edit ('kwiki-install', 'kwiki install');

	$edit->open_root (0);

        for my $page_id ($self->database->pages) {
	    $edit->add_file ($page_id);
	    open my $fh, $self->database->file_path($page_id);
	    $edit->modify_file ($page_id, $fh)
	}
	$edit->close_edit;
    }
    $fs = $repos->fs;
    ++$init;
}

sub new {
    my ($class) = shift;
    my $self = $class->SUPER::new(@_);
    $self->init unless $init;
    $self->{pool} = SVN::Pool->new_default_sub();

    $self->{headrev} = $fs->youngest_rev;

    return $self;
}

sub _get_edit {
    my ($self, $author, $comment, $pool) = @_;
    SVN::Simple::Edit->new (_editor => [SVN::Repos::get_commit_editor
					($repos, '', '/', $author,
					 $comment, sub {})],
			    pool => $pool || SVN::Pool->new ($pool));

}

sub commit {
    my ($self, $page_id) = @_;
    my $edit = $self->_get_edit ($user_name || $self->metadata->edit_by, '',
				 $self->{pool});
    $edit->open_root ($self->{headrev});
    if ($self->database->exists ($page_id)) {
	open my $fh, $self->database->file_path ($page_id);
	$edit->modify_file ($self->has_history ($page_id) ?
			    $edit->open_file ($page_id) :
			    $edit->add_file ($page_id),
			    $fh);
    }
    else {
	$edit->delete_entry ($page_id);
    }

    $edit->close_edit();
}

sub has_history {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    my $root = $fs->revision_root($self->{headrev});

    SVN::Fs::check_path($root, $page_id) == $SVN::Core::node_file;
}

sub history {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    return [] unless $page_id;

    my $revs = SVN::Repos::revisions_changed ($fs, $page_id, 0,
					      $self->{headrev}, 0);

    my $history = [map {
	{ revision => $_,
	  edit_by => $fs->revision_prop($_, 'svn:author'),
	  date => $fs->revision_prop($_, 'svn:date')}} @$revs];

    return $self->_build_history($history);
}

sub fetch {
    my ($self, $page_id, $revision) = @_;
    my $root = $fs->revision_root($revision || $self->{headrev});

    my $stream = SVN::Fs::file_contents($root, $page_id);
    local $/;
    return <$stream>;
}

sub diff {
    my ($self, $page_id, $r1, $r2, $context) = @_;

    my $root1 = $fs->revision_root ($r1);
    my $root2 = $fs->revision_root ($r2);

    Text::Diff::diff(SVN::Fs::file_contents($root1, $page_id),
		     SVN::Fs::file_contents($root2, $page_id),
		     { STYLE => "Unified" });
}

1;
