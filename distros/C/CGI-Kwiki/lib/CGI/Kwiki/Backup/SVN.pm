package CGI::Kwiki::Backup::SVN;
$VERSION = '0.01';

use strict;
use base 'CGI::Kwiki::Backup';
use File::Spec;

use constant SVN_DIR => 'metabase/svn';
use constant LOCAL_DIR => 'database/.svn/text-base';

my $svn = can_run('svn') or die "Cannot find svn in PATH!";
my $svnadmin = can_run('svnadmin') or die "Cannot find svnadmin in PATH!";

# check if we can run some command
sub can_run {
    my ($cmd) = @_;

    require Config;
    require File::Spec;
    require ExtUtils::MakeMaker;

    my $_cmd = $cmd;
    return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

    for my $dir (
        (split /$Config::Config{path_sep}/, $ENV{PATH}),
        ('c:/progra~1/subversion', '/usr/local/bin', '/opt/bin', '/sw/bin', '.')
    ) {
        my $abs = File::Spec->catfile($dir, $_[0]);
        return $abs if (-x $abs or $abs = MM->maybe_command($abs));
    }

    return;
}

sub file_path {
    my ($self, $page_id) = @_;
    LOCAL_DIR . '/' . $self->escape($page_id) . '.svn-base';
}

my $user_name = '';
sub new {
    my ($class) = shift;
    my $self = $class->SUPER::new(@_);

    return $self if $class ne __PACKAGE__;
    return $self if -d SVN_DIR;

    $self->shell("$svnadmin create " . SVN_DIR);
    umask 0000;
    chmod 0777, SVN_DIR;
    my $url = File::Spec->rel2abs( SVN_DIR );
    $url =~ s{\\}{/}g;
    $url =~ s{\w:}{};
    $self->shell("$svn co -q file://$url " . $self->database->file_path(''));
    $user_name = 'kwiki-install';
    for my $page_id ($self->database->pages) {
	$self->add($page_id);
    }
    $self->commit_all;

    return $self;
}
    
sub add {
    my ($self, $page_id) = @_;
    my $msg = $user_name || $self->metadata->edit_by;
    my $page_file_path = $self->database->file_path($page_id);
    $self->shell(qq{$svn add -q $page_file_path})
        unless $self->has_history($page_id);
}

sub commit {
    my ($self, $page_id) = @_;
    my $msg = $self->escape($user_name || $self->metadata->edit_by);
    my $page_file_path = $self->database->file_path($page_id);
    $self->shell(qq{$svn add -q $page_file_path})
        unless $self->has_history($page_id);
    $self->shell(qq{$svn ci -q -m"$msg" $page_file_path});
}

sub commit_all {
    my ($self) = @_;
    my $msg = $self->escape($user_name || $self->metadata->edit_by);
    my $page_file_path = $self->database->file_path('');
    $self->shell(qq{$svn ci -q -m"$msg" $page_file_path});
}

sub has_history {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    -f $self->file_path($page_id);
}

sub history {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    my $svn_file_path = $self->database->file_path($page_id);
    open RLOG, "$svn log $svn_file_path |"
      or DIE $!; 
    binmode(RLOG, ':utf8') if $self->use_utf8;
    my $history = [];
    while (<RLOG>) {
        /^rev\s+(\d+):\s+(\S+)\s+\|\s+(.+?)\s+\(/ or next;
        my $entry = {
            revision => $1,
            edit_by => $2,
            date => $3,
        };
        while (<RLOG>) {
            /^(.+)$/ or next;
            $entry->{edit_by} = $self->unescape($1);
            last;
        }
        push @$history, $entry;
    }

    return $self->_build_history($history);
}

sub _build_history {
    my ($self, $history) = @_;
    my $count = @$history;
    $self->{revisions} = {};
    for (@$history) {
	$_->{file_rev} = $count--;
	$self->{revisions}{$_->{revision}} = $_->{file_rev};
    }
    return $history;
}

sub file_rev {
    my ($self, $page_id, $revision) = @_;
    $self->history unless $self->{revisions};
    return $self->{revisions}{$revision};
}

sub fetch {
    my ($self, $page_id, $revision) = @_;
    my $svn_file_path = $self->database->file_path($page_id);
    
    local($/, *CO);
    open CO, qq{$svn -r $revision cat $svn_file_path |}
      or die $!;
    binmode(CO, ':utf8') if $self->use_utf8;
    <CO>;
}

sub diff {
    my ($self, $page_id, $r1, $r2, $context) = @_;
    $context ||= 1000000;
    my $svn_file_path = $self->database->file_path($page_id);

    use Cwd;
    local(*SVNDIFF);
    my $kluge = ((-w '.') ? '' : '../');
    chdir('metabase') if $kluge;
    open SVNDIFF, qq{$svn diff -r $r1:$r2 $kluge$svn_file_path |}
      or die "svndiff failed:\n$!";
    chdir('..') if $kluge;
    binmode(SVNDIFF, ':utf8') if $self->use_utf8;
    <SVNDIFF>; <SVNDIFF>;
    my $line1 = <SVNDIFF>;
    my $line2 = <SVNDIFF>;
    $line2 =~ s/\+/%2B/g; # counter ->unescape
    local $/;
    return($self->unescape($line1) . $self->unescape($line2) . <SVNDIFF>);
}

sub shell {
    my ($self, $command) = @_;
    use Cwd;
    $! = undef;
    system($command) == 0 
      or die "$command failed: $! | " . Cwd::cwd();
}

1;
