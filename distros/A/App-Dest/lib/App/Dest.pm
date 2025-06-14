package App::Dest;
# ABSTRACT: Deployment State Manager

use 5.016;
use exact;

use File::Basename qw( dirname basename );
use File::Copy 'copy';
use File::Copy::Recursive qw( dircopy rcopy );
use File::DirCompare ();
use File::Find 'find';
use File::Path qw( mkpath rmtree );
use IPC::Run 'run';
use Path::Tiny 'path';
use POSIX 'strftime';
use Text::Diff ();

our $VERSION = '1.36'; # VERSION

sub init {
    my $self = _new( shift, 'expect_no_root_dir' );

    mkdir('.dest') or die "Unable to create .dest directory\n";
    open( my $watch, '>', '.dest/watch' ) or die "Unable to create ~/.dest/watch file\n";

    $self = _new();

    if ( -f 'dest.watch' ) {
        open( my $watches, '<', 'dest.watch' ) or die "Unable to read dest.watch file\n";

        my @watches = map { chomp; $_ } <$watches>;

        my @errors;
        for my $watch (@watches) {
            try {
                $self->add($watch);
            }
            catch ($e) {
                push( @errors, $watch . ': ' . $e );
            }
        }

        warn
            "Created new watch list based on dest.watch file:\n" .
            join( "\n", map { '  ' . $_ } @watches ) . "\n" .
            (
                (@errors)
                    ? "With the following errors:\n" . join( '', map { '  ' . $_ } @errors )
                    : ''
            );
    }

    return 0;
}

sub add {
    my $self = _new(shift);
    die "No directory specified; usage: dest add [directory]\n" unless @_;

    my @watches = $self->_watch_list;
    my @adds    = map {
        my $dir = $_;
        die "Directory specified does not exist\n" unless ( -d $dir );

        my $rel_dir = $self->_rel2root($dir);
        die "Directory $dir already added\n" if ( grep { $rel_dir eq $_ } @watches );
        $rel_dir;
    } @_;

    open( my $watch, '>', $self->_rel2dir('.dest/watch') ) or die "Unable to write ~/.dest/watch file\n";
    print $watch $_, "\n" for ( sort @adds, map { $self->_rel2root($_) } @watches );
    mkpath("$self->{root_dir}/.dest/$_") for (@adds);

    return 0;
}

sub rm {
    my $self = _new(shift);
    die "No directory specified; usage: dest rm [directory]\n" unless @_;

    my @watches = $self->_watch_list;
    my @rms     = map {
        my $dir = $_;
        $dir //= '';
        $dir =~ s|/$||;

        die "Directory $dir not currently tracked\n" unless ( grep { $dir eq $_ } @watches );

        $self->_rel2root($dir);
    } @_;

    open( my $watch_file, '>', $self->_rel2dir('.dest/watch') ) or die "Unable to write ~/.dest/watch file\n";
    for my $watch_dir ( map { $self->_rel2root($_) } @watches ) {
        if ( grep { $watch_dir eq $_ } @rms ) {
            rmtree( $self->_rel2dir(".dest/$watch_dir") );
        }
        else {
            print $watch_file $watch_dir, "\n";
        }
    }

    return 0;
}

sub watches {
    my $self = _new(shift);

    my @watches = $self->_watch_list;
    print join( "\n", @watches ), "\n" if @watches;

    return 0;
}

sub putwatch {
    my $self   = _new(shift);
    my ($file) = @_;
    die "File specified does not exist\n" unless ( -f $file );

    open( my $new_watches, '<', $file ) or die "Unable to read specified file\n";

    my @new = map { chomp; $_ } <$new_watches>;
    my @old = $self->_watch_list;

    for my $old (@old) {
        next if ( grep { $_ eq $old } @new );
        $self->rm($old);
    }
    for my $new (@new) {
        next if ( grep { $_ eq $new } @old );
        $self->add($new);
    }

    return 0;
}

sub writewatch {
    my $self = _new(shift);

    copy( $self->_rel2dir('.dest/watch'), $self->_rel2dir('dest.watch') ) or die "$!\n";

    return 0;
}

sub make {
    my ( $self, $path, $ext ) = @_;
    die "No name specified; usage: dest make [path]\n" unless ($path);

    $path = strftime( $path, localtime );

    $ext = '.' . $ext if ( defined $ext );
    $ext //= '';

    try {
        mkpath($path);
        for ( qw( deploy verify revert ) ) {
            open( my $file, '>', "$path/$_$ext" ) or die;
            print $file "\n";
        }
    }
    catch ($e) {
        die "Failed to fully make $path; check permissions or existing files\n";
    }

    $self->expand($path);

    return 0;
}

sub expand {
    my ( $self, $path ) = @_;

    print join( ' ', map { <"$path/$_*"> } qw( deploy verify revert ) ), "\n";

    return 0;
}

sub list {
    my $self     = _new(shift);
    my ($filter) = @_;

    my $tree = $self->_actions_tree($filter);
    for my $path ( sort keys %$tree ) {
        print $path, ( ( @{ $tree->{$path} } ) ? ' actions:' : ' has no actions' ), "\n";
        print '  ', $_, "\n" for ( @{ $tree->{$path} } );
    }

    return 0;
}

sub prereqs {
    my $self = _new(shift);
    my ($filter) = @_;

    for my $action ( @{ $self->_prereq_tree($filter)->{actions} } ) {
        print $action->{action}, ( ( @{ $action->{prereqs} } ) ? ' prereqs:' : ' has no prereqs' ), "\n";
        print '  ', $_, "\n" for ( @{ $action->{prereqs} } );
    }

    return 0;
}

sub status {
    my $self = _new(shift);

    if ( -f $self->_rel2dir('dest.watch') ) {
        my $diff = Text::Diff::diff( $self->_rel2dir('.dest/watch'), $self->_rel2dir('dest.watch') );
        warn "Diff between current watch list and dest.watch file:\n" . $diff . "\n" if ($diff);
    }

    for my $path ( @{ $self->_status_data->{paths} } ) {
        print "$path->{state} - $path->{path}\n";

        for my $action ( @{ $path->{actions} } ) {
            unless ( $action->{modified} ) {
                print '  ' . ( ( $action->{deployed} ) ? '-' : '+' ) . ' ' . $action->{action} . "\n";
            }
            else {
                print "  $action->{action}\n";
                print "    M $action->{file}\n";
            }
        }
    }

    return 0;
}

sub diff {
    my $self   = _new(shift);
    my ($path) = @_;

    if ( not defined $path ) {
        $self->diff($_) for ( $self->_watch_list );
        return 0;
    }

    File::DirCompare->compare( $self->_rel2dir( '.dest/' . $self->_rel2root($path) ), $path, sub {
        my ( $a, $b ) = @_;
        $a ||= '';
        $b ||= '';

        return if ( $a =~ /\/dest.wrap$/ or $b =~ /\/dest.wrap$/ or not -f $a or not -f $b );
        print Text::Diff::diff( $a, $b );
        return;
    } );

    return 0;
}

sub clean {
    my $self = _new(shift);

    if (@_) {
        for (@_) {
            my $dest = $self->_rel2dir(".dest/$_");
            rmtree($dest);
            rcopy( $self->_rel2dir($_), $dest );
        }
    }
    else {
        for ( map { $self->_rel2root($_) } $self->_watch_list ) {
            my $dest = $self->_rel2dir(".dest/$_");
            rmtree($dest);
            dircopy( $self->_rel2dir($_), $dest );
        }
    }

    return 0;
}

sub preinstall {
    my $self = _new(shift);

    if (@_) {
        for (@_) {
            my $dest = $self->_rel2dir(".dest/$_");
            rmtree($dest);
        }
    }
    else {
        for ( map { $self->_rel2root($_) } $self->_watch_list ) {
            my $dest = $self->_rel2dir(".dest/$_");
            rmtree($dest);
            mkdir($dest);
        }
    }

    return 0;
}

sub nuke {
    my $self = _new(shift);
    rmtree( $self->_rel2dir('.dest') );
    return 0;
}

sub deploy {
    my $self = _new(shift);
    my ( $dry_run, $action ) = _dry_check(@_);
    die "File to deploy required; usage: dest deploy file\n" unless ($action);

    my $redeploy = delete $self->{redeploy};
    my $execute_stack = $self->_build_execute_stack( $action, 'deploy', undef, $redeploy );
    die "Action already deployed\n" if (
        not @$execute_stack or
        not scalar( grep { $_->{action} eq $action and $_->{type} eq 'deploy' } @$execute_stack )
    );

    unless ($dry_run) {
        $self->_execute_action($_) for (@$execute_stack);
    }
    else {
        _dry_run_report($execute_stack);
    }

    return 0;
}

sub redeploy {
    my $self = _new(shift);
    $self->{redeploy} = 1;
    return $self->deploy(@_);
}

sub revdeploy {
    my $self = _new(shift);
    my ($action) = @_;

    $self->revert($action);
    return $self->deploy($action);
}

sub verify {
    my $self = _new(shift);
    my ($action) = @_;

    return $self->_execute_action( $self->_build_execute_stack( $action, 'verify' )->[0] );
}

sub revert {
    my $self = _new(shift);
    my ( $dry_run, $action ) = _dry_check(@_);
    die "File to revert required; usage: dest revert file\n" unless ($action);

    my $execute_stack = $self->_build_execute_stack( $action, 'revert' );
    die "Action not deployed\n" if (
        not @$execute_stack or
        not scalar( grep { $_->{action} eq $action and $_->{type} eq 'revert' } @$execute_stack )
    );

    unless ($dry_run) {
        $self->_execute_action($_) for (@$execute_stack);
    }
    else {
        _dry_run_report($execute_stack);
    }

    return 0;
}

sub update {
    my $self = _new(shift);
    my ( $dry_run, @incs ) = _dry_check(@_);

    my $seen_action = {};
    my $execute_stack;

    for (
        sort {
            ( $b->{modified} || 0 ) <=> ( $a->{modified} || 0 ) ||
            $a->{action} cmp $b->{action}
        }
        grep { not $_->{matches} }
        values %{ $self->_status_data->{actions} }
    ) {
        push( @$execute_stack, @{ $self->_build_execute_stack( $_->{action}, 'revert' ) } ) if (
            $_->{modified} or $_->{deployed}
        );
        push( @$execute_stack, @{ $self->_build_execute_stack( $_->{action}, 'deploy', $seen_action ) } );
    }

    $execute_stack = [
        grep {
            my $execution = $_;
            my $match     = 0;

            for (@incs) {
                if ( index( $execution->{file}, $_ ) > -1 ) {
                    $match = 1;
                    last;
                }
            }

            $match;
        }
        @$execute_stack
    ] if (@incs);

    unless ($dry_run) {
        $self->_execute_action($_) for (@$execute_stack);
    }
    else {
        _dry_run_report($execute_stack);
    }

    return 0;
}

sub version {
    print 'dest version ', $__PACKAGE__::VERSION || 0, "\n";
    return 0;
}

sub _new {
    my ( $self, $expect_no_root_dir ) = @_;

    if ( not ref $self ) {
        $self = bless( {}, __PACKAGE__ );

        $self->{root_dir} = Path::Tiny->cwd;

        while ( not $self->{root_dir}->child('.dest')->is_dir ) {
            if ( $self->{root_dir}->is_rootdir ) {
                $self->{root_dir} = '';
                last;
            }
            $self->{root_dir} = $self->{root_dir}->parent;
            $self->{dir_depth}++;
        }

        if ( $expect_no_root_dir ) {
            die "Project already initialized\n" if $self->{root_dir};
        }
        else {
            die "Project not initialized\n" unless $self->{root_dir};
        }
    }

    return $self;
}

sub _dry_check {
    my @clean = grep { $_ ne '-d' } @_;
    return ( @clean != @_ ) ? 1 : 0, @clean;
}

sub _rel2root {
    my ( $self, $dir ) = @_;
    my $path           = path( $dir || '.' );

    try {
        $path = $path->realpath;
    }
    catch ($e) {
        $path = $path->absolute;
    }

    return $path->relative( $self->{root_dir} )->stringify;
}

sub _rel2dir {
    my ( $self, $dir ) = @_;
    return ( '../' x ( $self->{dir_depth} || 0 ) ) . ( $dir || '.' );
}

sub _watch_list {
    my ($self) = @_;
    open( my $watch, '<', $self->_rel2dir('.dest/watch') ) or die "Unable to read ~/.dest/watch file\n";
    return sort map { chomp; $self->_rel2dir($_) } <$watch>;
}

sub _actions_tree {
    my ( $self, $filter ) = @_;

    my $tree;
    for my $path ( $self->_watch_list ) {
        my @actions;

        find( {
            follow   => 1,
            no_chdir => 1,
            wanted   => sub {
                return unless ( m|/deploy(?:\.[^\/]+)?| );
                ( my $action = $_ ) =~ s|/deploy(?:\.[^\/]+)?||;

                push( @actions, $action ) if (
                    not defined $filter or
                    index( $action, $filter ) > -1
                );
            },
        }, $path );

        $tree->{$path} = [ sort @actions ];
    }

    return $tree;
}

sub _prereq_tree {
    my ( $self, $filter ) = @_;
    my $tree              = $self->_actions_tree($filter);

    my @actions;
    for my $path ( sort keys %$tree ) {
        for my $action ( @{ $tree->{$path} } ) {
            my ($file) = <"$action/deploy*">;
            open( my $content, '<', $file ) or die "Unable to read $file\n";

            my $prereqs = [
                map { $self->_rel2dir($_) }
                grep { defined }
                map { /dest\.prereq\b[\s:=-]+(.+?)\s*$/; $1 || undef }
                grep { /dest\.prereq/ } <$content>
            ];

            $action = {
                action  => $action,
                prereqs => $prereqs,
            };

            push( @actions, $action );
        }
    }

    return { tree => $tree, actions => \@actions };
}

sub _status_data {
    my ($self) = @_;

    my $actions;
    my $tree = $self->_actions_tree;
    for my $path ( keys %$tree ) {
        for my $action ( @{ $tree->{$path} } ) {
            $actions->{$action} = {
                action   => $action,
                deployed => 1,
                matches  => 1,
            };
        }
    }

    my @paths;
    for my $path ( $self->_watch_list ) {
        my $printed_path = 0;
        my $data;

        try {
            File::DirCompare->compare(
                $self->_rel2dir( '.dest/' . $self->_rel2root($path) ),
                $path,
                sub {
                    my ( $a, $b ) = @_;
                    return if ( $a and $a =~ /\/dest.wrap$/ or $b and $b =~ /\/dest.wrap$/ );
                    $data->{state} = 'diff' unless ( $printed_path++ );

                    if ( not $b ) {
                        push(
                            @{ $data->{actions} },
                            {
                                action   => $self->_rel2dir( substr( $self->_rel2root($a), 6 ) ),
                                deployed => 1,
                            },
                        );
                    }
                    elsif ( not $a ) {
                        push(
                            @{ $data->{actions} },
                            {
                                action   => $b,
                                deployed => 0,
                            },
                        );
                    }
                    elsif ( $a and $b ) {
                        ( my $action = $b ) =~ s,/(?:deploy|verify|revert)(?:\.[^\/]+)?$,,;
                        push(
                            @{ $data->{actions} },
                            {
                                action   => $action,
                                modified => 1,
                                file     => $b,
                            },
                        );
                    }

                    return;
                },
            )
        }
        catch ($e) {
            $data->{state} = '?' if ( $e =~ /Not a directory/ );
        }
        finally {
            $data->{state} = 'ok' unless $printed_path;
        }

        $data->{path} = $path;
        push( @paths, $data );

        if ( ref $data->{actions} eq 'ARRAY' ) {
            $actions->{ $_->{action} } = $_ for ( @{ $data->{actions} } );
        }
    }

    return { paths => \@paths, actions => $actions };
}

sub _build_execute_stack {
    my ( $self, $name, $type, $seen_action, $redeploy ) = @_;

    my @actions_stack = ($name);
    my $prereqs       = { map { $_->{action} => $_->{prereqs} } @{ $self->_prereq_tree->{actions} } };
    my $state         = $self->_status_data->{actions};

    if ( $type eq 'revert' ) {
        my $postreqs;
        for my $action ( keys %$prereqs ) {
            push( @{ $postreqs->{$_} }, $action ) for ( @{ $prereqs->{$action} } );
        }
        $prereqs = $postreqs;
    }

    my ( @execute_stack, $wraps );
    $seen_action //= {};

    while (@actions_stack) {
        my $action = shift @actions_stack;
        next if ( $seen_action->{$action}++ );
        push( @actions_stack, @{ $prereqs->{$action} || [] } );

        my $location = ( $type ne 'revert' )
            ? $action
            : $self->_rel2dir( '.dest/' . $self->_rel2root($action) );

        my $file = ( <"$location/$type*"> )[0];

        unless ( exists $wraps->{$action} ) {
            $wraps->{$action} = undef;
            my @nodes = split( '/', $self->_rel2root($file) );
            pop @nodes;
            shift @nodes if ( defined $nodes[0] and $nodes[0] eq '.dest' );
            while (@nodes) {
                my $path = $self->_rel2dir( join( '/', @nodes ) . '/dest.wrap' );
                if ( -f $path ) {
                    $wraps->{$action} = $path;
                    last;
                }
                pop @nodes;
            }
        }

        my $add = sub {
            die "Action file does not exist for: $type $action\n" unless ($file);

            my $executable = ( $wraps->{$action} ) ? $wraps->{$action} : $file;
            die 'Execute permission denied for: ' . $executable . "\n" unless ( -x $executable );

            unshift(
                @execute_stack,
                {
                    type   => $type,
                    action => $action,
                    file   => $file,
                    wrap   => $wraps->{$action},
                },
            );

            if ( $type eq 'deploy' ) {
                my $verify_file = ( <"$action/verify*"> )[0];
                die "Action file does not exist for: verify $action\n" unless ($verify_file);

                splice(
                    @execute_stack,
                    1,
                    0,
                    {
                        type   => 'verify',
                        action => $action,
                        file   => $verify_file,
                        wrap   => $wraps->{$action},
                    },
                );
            }
        };

        if ( $type eq 'deploy' ) {
            $add->() unless ( $state->{$action}{deployed} and not $redeploy );
        }
        elsif ( $type eq 'revert' ) {
            $add->() if ( $state->{$action}{deployed} or $state->{$action}{modified} );
        }
        elsif ( $type eq 'verify' ) {
            $add->();
        }
    }

    return \@execute_stack;
}

sub _dry_run_report {
    my ($execute_stack) = @_;
    print '' . ( ( $_->{wrap} ) ? $_->{wrap} . ' ' : '' ) . $_->{file}, "\n" for (@$execute_stack);
}

sub _execute_action {
    my ( $self, $input ) = @_;
    my ( $type, $wrap, $action, $file, $location ) = @$input{ qw( type wrap action file location ) };

    my ( $out, $err, $died );
    my $run = sub {
        try {
            run(
                [ ( grep { defined } $wrap ), $file, $type ],
                \undef, \$out, \$err,
            ) or $died = 1;
        }
        catch ($e) {
            $err = $e;
        }

        if ($err) {
            ( my $err_str = $err ) =~ s/\s*at\s+.*$//;
            chomp($err_str);
            if ($died) {
                die "Failed to execute $file: $err_str\n";
            }
            else {
                warn "Warnings from executed $file: $err_str\n";
            }
        }
    };

    if ( $type eq 'verify' ) {
        $run->();
        chomp($out);
        die "$err\n" if ($err);

        if ($out) {
            print "ok - verify: $action\n";
        }
        else {
            die "not ok - verify: $action\n";
        }
    }
    else {
        print "begin - $type: $action\n";
        $run->();
        print "ok - $type: $action\n";
    }

    my $dest_copy = $self->_rel2dir( '.dest/' . $self->_rel2root($action) );
    rmtree($dest_copy) unless ( $type eq 'verify' );
    dircopy( $action, $dest_copy ) if ( $type eq 'deploy' );

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dest - Deployment State Manager

=head1 VERSION

version 1.36

=for markdown [![test](https://github.com/gryphonshafer/dest/workflows/test/badge.svg)](https://github.com/gryphonshafer/dest/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/dest/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/dest)

=for test_synopsis BEGIN { die "SKIP: skip synopsis check because it's non-Perl\n"; }

=head1 SYNOPSIS

dest COMMAND [OPTIONS]

    dest init               # initialize dest for a project
    dest add DIR            # add a directory to dest tracking list
    dest rm DIR             # remove a directory from dest tracking list

    dest watches            # returns a list of watched directories
    dest putwatch FILE      # set watch list to be what's in a file
    dest writewatch         # creates watch file in project root directory

    dest make NAME [EXT]    # create a named template set (set of 3 files)
    dest expand NAME        # dump a list of the template set (set of 3 files)
    dest list [FILTER]      # list all actions in all watches
    dest prereqs [FILTER]   # like "list" but include report of prereqs

    dest status             # check status of tracked directories
    dest diff [NAME]        # display a diff of any modified actions
    dest clean [NAME]       # reset dest state to match current files/dirs
    dest preinstall [NAME]  # set dest state so an update will deploy everything
    dest nuke               # de-initialize dest; remove all dest stuff

    dest deploy NAME [-d]   # deployment of a specific action
    dest verify [NAME]      # verification of tracked actions or specific action
    dest revert NAME [-d]   # revertion of a specific action
    dest redeploy NAME [-d] # deployment of a specific action
    dest revdeploy NAME     # revert and deployment of a specific action
    dest update [INCS] [-d] # automaticall deploy or revert to cause currency

    dest version            # dest current version
    dest help               # display command synposis
    dest man                # display man page

=head1 DESCRIPTION

C<dest> is a simple "deployment state" change management tool. Inspired by
what Sqitch does for databases, it provides a simple mechanism for writing
deploy, verify, and revert parts of a change action. The typical use of
C<dest> is in a development context because it allows for simplified state
changes when switching between branches (as an example).

Let's say you're working with a group of other software engineers on a
particular software project using your favorite revision control system.
Let's also say that you have a database that undergoes schema changes as
features are developed, and you have various system activities like the
installation of libraries or other applications. Then let's also say the team
branches, works on stuff, shares those branches, reverts, merges, etc. And also
from time to time you want to go back in time a bit so you can reproduce a bug.
Maintaining the database state and the state of the system across all that
activity can be problematic. C<dest> tries to solve this in a very simple way,
letting you be able to deploy, revert, and verify to any point in time in
the development history.

See below for an example scenario that may help illustrate using C<dest> in a
pseudo real world situation.

Note that using C<dest> for production deployment, provisioning, or
configuration management is not advised. Use a full-featured configuration
management tool instead.

=head1 COMMANDS

Typing just C<dest> should bring up the usage instructions, which include a
command list. You should be able to execute C<dest> commands from any directory
at or below your project's root directory once the project has been initiated
in C<dest>.

=head2 init

To start using C<dest>, you need to initialize your project by calling C<init>
while in the root directory of your project. (If you are in a different
directory, C<dest> will assume that is your project's root directory.)

The initialization will result in a C<.dest> directory being created.
You'll almost certainly want to add ".dest" to your C<.gitignore> file or
similar revision control ignore file.

=head2 add DIR

Once a project has been initialized, you need to tell C<dest> what directories
you want to "track". Into these tracked directories you'll place subdirectories
with recognizable names, and into each subdirectory a set of 3 files: deploy,
revert, and verify.

For example, let's say you have a database. So you create C<db> in your
project's root directory. Then call C<dest add db> from your root directory.
Inside C<db>, you might create the directory C<db/schema>. And under that
directory, add the files: deploy, revert, and verify.

The deploy file contains the instructions to create the database schema. The
revert file contains the instructions to revert what the deploy file did. And
the verify file let's you verify the deploy file worked.

=head2 rm DIR

This removes a directory from the C<dest> tracking list.

=head2 watches

Returns a list of tracked or watched directories.

=head2 putwatch FILE

Sets the current list of tracked or watched directories to be what's in a file.
For example, you could do this:

    dest watches > dest.watch
    echo 'new_dir_to_watch' >> dest.watch
    dest putwatch dest.watch

=head2 writewatch

Creates (or overwrites) a watch file in the project root directory with the
contents of the currently watched directories.

=head2 make NAME [EXT]

This is a helper command. Given a directory you've already added, it will create
the subdirectory and deploy, revert, and verify files.

    # given db, creates db/schema and the 3 files
    dest make db/schema

As a nice helper bit, C<make> will list the relative paths of the 3 new files.
So if you want, you can do something like this:

    vi `dest make db/schema`

Optionally, you can specify an extension for the created files. For example:

    vi `dest make db/schema sql`
    # this will create and open in vi:
    #    db/schema/deploy.sql
    #    db/schema/revert.sql
    #    db/schema/verify.sql

And optionally, you can include any date/time format supported by L<POSIX>
C<strftime>.

    dest make db/%s_action sql

=head2 expand NAME

This command lists out the relative paths and names of the 3 files of the
action provided, so you can do stuff like:

    vi `dest expand db/schema`

=head2 list [FILTER]

This command will list all tracked directories and every action within each
directory. If provided a filter, it will limit what's displayed to actions
containing the filter.

=head2 prereqs [FILTER]

This command will list every action within any tracked directory, then for each
action, it will list any prereqs of that action. If provided a filter, it will
limit what's displayed to actions containing the filter.

=head2 status

This command will tell you your current state compared to what the current code
says your state should be. For example, you might see something like this:

    diff - db
      + db/new_function
      - db/lolcats
      M db/schema/deploy
    ok - etc

C<dest> will report for each tracked directory what are new changes that haven't
yet been deployed (marked with a "+"), features that have been deployed in your
current system state but are missing from the code (marked with a "-"), and
changes to previously existing files (marked with an "M").

=head2 diff [NAME]

This will display a diff delta of the differences of any modified action files.
You can specify an optional name parameter that refers to a tracking directory,
action name, or specific sub-action.

    dest diff
    dest diff db/schema
    dest diff db/schema/deploy

=head2 clean [NAME]

Let's say that for some reason you have a delta between what C<dest> thinks your
system is and what your code says it ought to be, and you really believe your
code is right. You can call C<clean> to tell C<dest> to just assume that what
the code says is right.

You can optionally provide a specific action or even a step of an action to
C<clean>. For example:

    dest clean db/schema
    dest clean db/schema/deploy

=head2 preinstall [NAME]

Let's say you're setting up a new system or installing the project/application,
so you start by creating yourself a working directory. At some point, you'll
want to deploy all the deploy actions. You'll need to C<init> and C<add> the
directories/paths you need. But C<dest> will have a cache that matches the
current working directory. At this point, you need to C<preinstall> to remove
that cache and be in a state where you can C<update>.

Here's an example of what you might want:

    dest init
    dest add path_to/stuff
    dest add path_to/other_stuff
    dest preinstall
    dest update

You can optionally provide a specific action or even a step of an action to
C<preinstall> similar to C<clean>.

=head2 nuke

Completely remove all traces of C<dest>. In effect, this is a de-initialization
of C<dest>, like an un-C<init> command. It's like C<preinstall>, but it reverses
all initializations and watches.

=head2 deploy NAME [-d]

This tells C<dest> to deploy a specific action. For example, if you called
C<status> and got back results like in the status example above, you might then
want to:

    dest deploy db/new_function

Note that you shouldn't add "/deploy" to the end of that. Also note that a
C<deploy> call will automatically call C<verify> when complete.

Adding a "-d" flag to the command will cause a "dry run" to run, which will
not perform any actions but will instead report what actions would happen.

=head2 verify [NAME]

This will run the verify step on any given action, or if no action name is
provided, all actions under directories that are tracked.

Unlike deploy and revert files, which can run the user through all sorts of
user input/output, verify files must return some value that is either true
or false. C<dest> will assume that if it sees a true value, verification is
confirmed. If it receives a false value, verification is assumed to have failed.

=head2 revert NAME [-d]

This tells C<dest> to revert a specific action. For example, if you deployed
C<db/new_function> but then you wanted to revert it, you'd:

    dest revert db/new_function

Adding a "-d" flag to the command will cause a "dry run" to run, which will
not perform any actions but will instead report what actions would happen.

=head2 redeploy NAME [-d]

This is exactly the same as deploy, except that if you've already deployed an
action, "redeploy" will let you deploy the action again, whereas "deploy"
shouldn't.

Adding a "-d" flag to the command will cause a "dry run" to run, which will
not perform any actions but will instead report what actions would happen.

=head2 revdeploy NAME

This is exactly the same as conducting a revert of an action followed by a
deploy of the same action.

=head2 update [INCS] [-d]

This will automatically deploy or revert as appropriate to make your system
match the code. This will likely be the most common command you run.

If there are actions in the code that have not been deployed, these will be
deployed. If there are actions that have been deployed that are no longer in
the code, they will be reverted.

If there are actions that are in the code that have been deployed, but the
"deploy" file has changed, then C<update> will revert the previously deployed
"deploy" file then deploy the new "deploy" file. (And note that the deployment
will automatically call C<verify>.)

You can optionally add one or more "INCS" strings to the update command to
restrict the update to only perform operations that include one of the "INCS" in
its action file. So for example, let's say you have a "db/changes" directory
with some actions and a "etc/changes" directory with some actions. If you were
to specify "db/changes" as one of your "INCS", this would only  update actions
from that directory tree.

Adding a "-d" flag to the command will cause a "dry run" to run, which will
not perform any actions but will instead report what actions would happen.

=head2 version

Displays the current C<dest> version.

=head2 help

Displays a synposis of commands and their usage.

=head2 man

Displays the man page for C<dest>.

=head1 DEPENDENCIES

Sometimes you may have deployments that have dependencies on other deployments.
For example, if you want to add a column to a table in a database, that table
(and the database) have to exist already.

To define a dependency, place the action's name after a C<dest.prereq> marker in
the deploy action file. This will likely need to be in the form of a comment.
(The comment marker can be whatever the language of the deployment file is.) For
example, in a SQL file that adds a column, you might have:

    -- dest.prereq: db/schema

Dependencies are defined only in deploy actions. Reverting infers its dependency
tree from the  dependencies defined in deploy actions, just in reverse.

=head1 WRAPPERS

Unless a "wrapper" is used (and thus, by default), C<dest> will assume that the
action files (those 3 files under each action name) are self-contained
executable files. Often if not almost always the action sub-files would be a
lot simpler and contain less code duplication if they were executed through
some sort of wrapper.

Given our database example, we'd likely want each of the action sub-files to be
pure SQL. In that case, we'll need to write some wrapper program that C<dest>
will run that will then consume and run the SQL files as appropriate.

C<dest> looks for wrapper files up the chain from the location of the action
file. Specifically, it'll assume a file is a wrapper if the filename is
"dest.wrap". If such a file is found, then that file is called, and the name of
the action sub-file is passed as its only argument.

As an example, let's say I created an action set that looked like this

    example/
        ls/
            deploy
            revert
            verify

Let's then also say that the C<example/ls/deploy> file contains: C<ls>

I could create a deployment file C<example/dest.wrap> that looked like this:

    #!/bin/sh
    /bin/sh "$1"

Wrappers will only ever be run from the current code. For example, if you have
a revert file for some action and you checkout your working directory to a
point in time prior to the revert file existing, C<dest> maintains a copy of the
original revert file so it can revert the action. However, it will always rely
on whatever wrapper is in the current working directory.

The C<dest.wrap> is called with two parameters: first, the name of the change
program, and second, the action type ("deploy", "revert", "verify").

=head1 WATCH FILE

Optionally, you can elect to use a watch file that can be committed to your
favorite revision control system. In the root directory of your project, create
a filed called "dest.watch" and list therein the directories (relative to the
root directory of the project) to watch.

If this "dest.watch" file exists in the root directory of your project, C<dest>
will add the following behavior:

During an "init" action, the C<dest.watch> file will be read to setup all
watched directories (as though you manually called the "add" action on each).

During a "status" action, C<dest> will report any differences between your
current watch list and the C<dest.watch> file.

During an "update" action, C<dest> will automatically add (as if you manually
called the "add" action) each directory in the C<dest.watch> file that is
currently not watched by C<dest> prior to executing the update action.

=head1 EXAMPLE SCENARIO

To help illustrate what C<dest> can do, consider the following example scenario.
You start a new project that requires the use of a typical database. You want to
control the schema of that database with progressively executed SQL files. You
also have data operations that require more functionality than what SQL can
provide, so you'd like to have data operations handled by progressively executed
Perl programs.

=head2 Project Initiation

You could setup your changes and C<dest> as follows (starting in your project's
root directory):

    mkdir db data     # create the directories
    dest init         # initiate dest for your project
    dest add db data  # add the directories to the dest watch list
    dest writewatch   # write the watch list (so others can init without adding)
    dest status       # show the current status (which is everything is OK)

=head2 Create Schema Action

The next step would probably be to create your database schema as a C<dest>
action. Actions include deploy, verify, and revert files. You can use the "make"
command to create these files for you. The command will return the list of files
created, so you can wrap the command to your favorite editor.

    dest make db/schema sql       # create "schema" action as ".sql" files
    vi `dest list db/schema`      # list the "schema" files into vi
    vi `dest make db/schema sql`  # the previous 2 commands as 1 command

Your deploy file will be the SQL required to create your schema. The revert file
reverts what the deploy file deploys. The verify file needs to return some
positive value if and only if the deploy action worked.

Since your local CLI shell probably doesn't know how to execute SQL files
natively, you'll likely need to create a C<dest.wrap> file.

    touch db/dest.wrap && chmod u+x db/dest.wrap && vi db/dest.wrap

This file if it exists will get executed instead of the deploy, verify, and
revert files, and it will be passed the action file being executed.

=head2 Status and Deploying

Now, check the project's C<dest> status:

    dest s  # short for "dest status"

You should see:

    ok - data
    diff - db
      + db/schema

This indicates that the "schema" action exists in your code but has not been
executed on your environment. To execute, you have a couple options:

    dest deploy db/schema  # explicitly deploy the "schema" action
    dest update            # make dest do whatever status says needs to be done

If you run C<dest update> and there's nothing to do, C<dest> will happily do
nothing. If you run C<dest deploy db/schema> after having already deployed
"schema", C<dest> will complain that "schema" has already been deployed. If you
really, really want to run a deploy of "schema" again:

    dest redeploy db/schema  # deploy "schema" even if you already did

=head2 Changing a Deployed Action

If you discover you made a mistake in a table definition inside your "schema"
deploy action file, you could either create a second action to change that table
or change the "schema" deploy and "revdeploy" to revert the old "schema" deploy
action and deploy the new "schema" deploy action. Let's alter the deploy action
already created, then check status.

    vi db/schema/deploy.sql  # fix the table definition
    dest status

You should see something like:

    ok - data
    diff - db
      db/schema/deploy.sql
        M db/schema/deploy.sql

This indicates that the C<schema/deploy> action is different than what was
deployed. You can revert the action and deploy it with the "revert" and "deploy"
actions, or do it in a single "revdeploy" command:

    dest revert db/schema     # revert old action
    dest deploy db/schema     # deploy new action
    dest revdeploy db/schema  # revert old action and deploy new action

=head2 Action with a Dependency

Now let's create a data action, a Perl program that will do things and stuff
to insert data into the database. To work, this action obviously will require
the schema action to have already been deployed.

    vi `dest make data/stuff pl`  # create the action and edit the files

Inside the C<data/stuff/deploy.pl> file, include the following line:

    # dest.prereq: db/schema

=head2 Other Developers

Now let's say you invite a friend or coworker to the project. That person might
do something like this:

    git clone https://example.com/example_scenario project
    cd project
    dest init    # initiates dest and sets up watches from the watch file
    dest update  # brings the local environment

With the "update" command, C<dest> will notice that the "db/schema" and
"data/stuff" actions haven't been deployed. It'll also notice that "data/stuff"
depends on "db/schema", so it'll deploy the schema before it deploys the data.

What's especially fun now is that this other developer can branch and do all
sorts of work requiring C<dest> actions in parallel to you doing other C<dest>
actions in parallel on different branches. If this new developer wants you to
help test some changes, you just checkout the developer's branch and run a
C<dest update>. C<dest> will revert whatever changes you have in your
environment that don't exist in the other developer's environment, and will
then deploy the other developer's new actions.

    git checkout other_branch && dest update
    prove t
    git checkout my_branch && dest update

=head1 SEE ALSO

L<App::Sqitch>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/dest>

=item *

L<MetaCPAN|https://metacpan.org/pod/App::Dest>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/dest/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/dest>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/App-Dest>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/A/App-Dest.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
