package App::RepoSync::Export;
use 5.10.0;
use warnings;
use strict;
use Cwd qw(realpath getcwd);
use YAML;
use JSON;
use File::Spec;
use File::Find::Rule;
use File::Basename;
use Config::Tiny;
use App::RepoSync::SystemUtil qw(system_or_die chdir_qx);
use Term::ANSIColor;

sub parse_svn_info {
    my $cmd = shift || 'svn info';
    my $info;
    unless( $info = qx(LC_ALL=C $cmd 2> /dev/null ) ) {
        say 'svn: info failed: ' . getcwd;

        # if uprade is needed,
        my $ret = qx(LC_ALL=C $cmd 2>&1);
        if ($cmd eq 'svn info' && $ret =~ /svn upgrade/) {
            say "svn: try upgrading: " . getcwd;
            system_or_die('svn upgrade 2>&1 > /dev/null');
        }
    }

    unless( $info = qx(LC_ALL=C $cmd 2> /dev/null ) ) {
        say "svn: info still failed: " . getcwd;
        return;
    }

    my ($url) = ($info =~ m{URL: (\S+)});
    my ($revision) = ($info =~ m{Revision: (\S+)});
    return { 
        url      => $url,
        revision => $revision,
    };
}

sub traverse_dir {
    my ($dir,$cb) = @_;

    opendir(my $dh, $dir ) || die "can't opendir $dir: $!";

    my @result;
    my @dirs = readdir($dh);
    closedir $dh;
    for my $subdir ( @dirs ) {
        my $abspath = File::Spec->join( $dir, $subdir );
        next if $subdir eq '.' || $subdir eq '..' ;

        if( -d $abspath ) {
            my $path = $cb->( $subdir, $dir );

            next if $path && $path == -1;

            if( $path ) {
                push @result, $path;
            } else {
                push @result, traverse_dir( $abspath , $cb);
            }
        }
    }
    return @result;
}

sub run {
    my ($class,$export_root) = @_;
    my $sync_root = getcwd();

    $export_root = realpath( $export_root );

    my @repos = traverse_dir $export_root, sub { 
        my ($subdir,$parent) = @_;
        my $path = File::Spec->join( $parent, $subdir );
        my $subpath = substr( $path , length( $sync_root ) + 1 );

        return if $subdir =~ /^\./; # do not descent
        return if ! -d $path;
        if( -d File::Spec->join( $path, '.svn' ) ) {

            chdir $path;
            my $info = parse_svn_info;
            unless( $info ) {
                chdir $sync_root;
                return -1;
            }

            my ($name) = basename($path);
            my ($url) = ($info =~ m{URL: (\S+)});
            my ($revision) = ($info =~ m{Revision: (\S+)});
            chdir $sync_root;
            return { 
                type => 'svn',
                path => $subpath,
                name => $name,
                %$info,
            };
        }
        elsif( -d File::Spec->join( $path , '.git' ) ) {
            chdir $path;
            my $remote_string = qx(git remote -v 2> /dev/null);

            unless( $remote_string ) {
                # try to fetch .git/refs/remotes/git-svn
                if( -e File::Spec->join( $path, '.git', 'refs','remotes', 'git-svn' ) ) {
                    my $info = parse_svn_info 'git svn info';
                    chdir $sync_root;
                    return { 
                        type => 'git-svn',
                        %$info,
                    };
                }
            }

            my %remotes = map { 
                        m{(\w+)\s+(\S+)\s+};
                        ($1 => $2);
                    } split /\n/,$remote_string;
            my $url = $remotes{origin};
            chdir $sync_root;
            return {
                type => 'git',
                path => $subpath,
                remotes => \%remotes,
                url => $url,
            };
        }
        elsif( -d File::Spec->join( $path , '.hg' ) ) {
            chdir $path;

            # try to read .hg/hgrc
            my $config_path = File::Spec->join( $path, '.hg', 'hgrc' );
            my $cfg = Config::Tiny->read($config_path);
            my $paths = $cfg->{paths};
            my $branch = qx(hg branch);
            chomp( $branch );
            chdir $sync_root;
            return {
                type     => 'hg',
                path     => $subpath,
                url      => $paths->{default} || $paths->{'default-push'},
                branch   => $branch,
                remotes  => $paths,
            };
        }
        return;
    };

    return @repos;
}

1;
