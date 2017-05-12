package TestLib;
use strict;
use warnings;
use File::Temp qw( tempdir );

sub new {
    my ( $class ) = @_;
    my $self = {
        repos_uri => 'svn://localhost/',     # Eeek, default port?   
    };
    return bless $self, $class;
}

sub create_svn_repos {
    my ( $self ) = @_;
    $self->{tempdir} = tempdir();
    warn('Created temp directory at ' . $self->{tempdir}) if $ENV{DEBUG_TEST};

    chdir($self->{tempdir}) || die 'Could not change to temp directory';

    die('svnadmin failed to create repository') 
        if (system('svnadmin create repos') != 0);

    # Re-write config to make RW repos
    {
        my $CONF;
        open($CONF, '>', 'repos/conf/svnserve.conf') || die;
        print $CONF "[general]\nanon-access = read\nanon-access = write\n";
        close $CONF;
    };

    my $svnserve = `which svnserve`;
    chomp($svnserve);
    die('Cannot locate svnserve') unless $svnserve;
    warn("Created repository, svnserve is $svnserve") if $ENV{DEBUG_TEST};
    # Nasty hackery here :(
    if ($self->{svnserve_pid} = fork) {
    	# Parent, continue!
        warn("svnserve PID is " . $self->{svnserve_pid});
        sleep 3; # Nasty hack to wait for svnserve to start
    } 
    else {
    	die "cannot fork: $!" unless defined $self->{svnserve_pid};
    	$|++;
	my @cmd = ($svnserve, '-r', 'repos', '-d', '--foreground');
    	warn("Running " . join(" ", @cmd)) if $ENV{DEBUG_TEST};
	exec(@cmd) or die("Could not exec $svnserve");
    	exit;
    }
    
    my $cmd = 'svn co ' . $self->{repos_uri} . ' checkout';
    warn("Running $cmd") if $ENV{DEBUG_TEST};
    die('first checkout did not work: ' . $cmd)
        if (system($cmd));

    chdir('checkout') || die;
    mkdir('subdir') || die;

    # Revision 1
    die('Adding first subdir failed')
        if (system('svn add subdir && svn commit -m"make subdir, revision 1" subdir'));

    mkdir('subdir/s2');
    mkdir('subdir/s3');

    {
        my $F;
        open($F, '>', 'f1') || die;
        print $F "  File 1, rev 1\n  ";
        close $F;
    };

    {
        my $F;
        open($F, '>', 'subdir/f2') || die;
        print $F "File 2, rev 1\n";
        close $F;
    };

    # Revision 2
    die('Adding second subdir and 2 files failed')
        if (system('svn add subdir/s2 && svn add subdir/s3 && svn add f1 && svn add subdir/f2 && svn commit -m"make 2 more subdirs, and 2 files revision 2"'));

    # Revision 3
    die('Propset on a file failed')
        if (system('svn propset svn:mime-type "text/plain" f1 && svn commit -m"Do a propset"'));

    # Revision 4
    die('Move file failed')
        if (system('svn move subdir/f2 subdir/f2.moved && svn commit -m"Do a move"'));

    # Revision 5
    die('Move dir failed')
        if (system('svn move subdir/s3 subdir/s3.moved && svn commit -m"Do another move"'));

    warn("Finished creating repositry, returning " . $self->{repos_uri}) if $ENV{DEBUG_TEST};

    return $self->{repos_uri};
}

sub DESTROY {
    my ( $self ) = @_;
    system('kill ' . $self->{svnserve_pid});
    system('rm -rf ' . $self->{tempdir});
}

1;
