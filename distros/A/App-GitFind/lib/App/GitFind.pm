package App::GitFind;

use 5.010;
use strict;
use warnings;

use App::GitFind::Base;

use parent 'App::GitFind::Class';
use Class::Tiny _qwc <<'EOT';
    argv    # the args we parse
    _expr   # the expression (AST from parsing)
    _revs   # the revs in the search scope, or ']]' for filesystem
    _repo   # The Git::Raw::Repository of the superproject we are in
    _repotop            # The working directory of _repo.  Path::Class::Dir.
    _searchbase         # Path::Class::Dir with respect to which results
                        # are reported.
    _searcher           # App::GitFind::Searcher subclass that finds entries
    _scan_submodules    # If truthy, scan submodules.
EOT

use App::GitFind::Actions;
use App::GitFind::cmdline;
use App::GitFind::FileProcessor;
use Getopt::Long 2.34 ();
use Git::Raw;
use IO::Handle;
use Iterator::Simple qw(ichain iflatten igrep imap iter iterator);
#use Path::Class;   # TODO see if we can do without Path::Class for speed
use App::GitFind::PathClassMicro;

our $VERSION = '0.000002';

# === Documentation === {{{1

=head1 NAME

App::GitFind - Find files anywhere in a Git repository

=head1 SYNOPSIS

This is the implementation of the L<git-find> command (q.v.).  To use it
from Perl code:

    use App::GitFind;
    exit App::GitFind->new(\@ARGV)->run;

=head1 SUBROUTINES/METHODS

=cut

# }}}1

# Later items:
# TODO add an option to report absolute paths instead of relative
# TODO skip .git and .gitignored files unless -u
# TODO optimization: if possible, add a filter function
#       (e.g., for a top-level -type filter)

=head2 BUILD

Process the arguments.  Usage:

    my $gf = App::GitFind->new(-argv => \@ARGV, -searchbase => Cwd::getcwd);

May modify the provided array.  May C<exit()>, e.g., on C<--help>.

=cut

sub BUILD {
    my ($self, $hrArgs) = @_;
    croak "Need a -argv arrayref" unless ref $hrArgs->{argv} eq 'ARRAY';
    croak "Need a -searchbase" unless defined $hrArgs->{searchbase};

    my $details = _process_options($hrArgs->{argv});

    # Handle default -print
    if(!$details->{expr}) {             # Default: -print
        $details->{expr} = App::GitFind::Actions::argdetails('print');

    } elsif(!$details->{saw_nonprune_action}) {      # With an expr: -print unless an action
                                        # other than -prune was given
        $details->{expr} = +{
            AND => [ $details->{expr}, App::GitFind::Actions::argdetails('print') ]
        };
    }

    # Add default for missing revs
    unless($details->{revs}) {
        $details->{revs} = [undef];
        $details->{saw_non_rr} ||= true;
    }
    if(@{$details->{revs}} > 1) {
        require List::SomeUtils;
        $details->{revs} = [List::SomeUtils::uniq(@{$details->{revs}})];
    }

    vlog { "Options:", ddc $details } 2;

    # Check the scope.  TODO permit searching both ]] and non-]] in one run
    if($details->{saw_rr} && $details->{saw_non_rr}) {
        die "I don't know how to search both ']]' and a Git rev at once."
    }

    # Copy information into our instance fields
    $self->_expr($details->{expr});
    $self->_revs($details->{revs});
    $self->_searchbase(
        App::GitFind::PathClassMicro::Dir->new($hrArgs->{searchbase})
    );

    $self->_find_repo;

} #BUILD()

# Initialize _repo and _repotop.  Dies on error.
sub _find_repo {
    my $self = shift;
    # Find the repo we're in.  If we're in a submodule, that will be the
    # repo of that submodule.
    my $repo = eval { Git::Raw::Repository->discover('.'); };
    die "Not in a Git repository: $@\n" if $@;
    $self->_repo($repo);

    $self->_repotop( App::GitFind::PathClassMicro::Dir->new($self->_repo->workdir) );
        # $repo->path is .git/
    vlog {
        "Repository:", $self->_repo->path,
        "\nWorking dir:", $self->_repotop,
        "\nSearch base:", $self->_searchbase,
    };

    # Are we in a submodule?  If so, move outward to the parent
    if($self->_repo->path =~ qr{^(.+?[\\\/]\.git)[\\\/]modules[\\\/]}) {
        my $parent_path = $1;
        $repo = eval { Git::Raw::Repository->open($parent_path); };
        die "Could not open parent Git repository in $parent_path: $@\n" if $@;
        $self->_repo($repo);
        vlog { 'Moved to outer repo', $parent_path };
    }
} #_find_repo()

=head2 run

Does the work.  Call as C<< exit($obj->run()) >>.  Returns a shell exit code.

=cut

sub run {
    my $self = shift;
    my $runner = App::GitFind::FileProcessor->new(-expr => $self->_expr);
    my $callback = $runner->callback($VERBOSE>=3);

    if($VERBOSE) {
        STDOUT->autoflush(true);
        STDERR->autoflush(true);
    }

    for my $rev (@{$self->_revs}) {
        my $searcher = $self->_make_searcher($rev, $self->_repo);
        # TODO? deduplicate?
        $searcher->run($callback);
        # TODO? early stop?
    }

    return 0;   # TODO? return 1 if any -exec failed?
} #run()

=head1 INTERNALS

=head2 _make_searcher

Create an iterator for the entries to be processed.  Returns an
L<App::GitFind::Searcher>.  Usage:

    my $searcher = $self->_make_searcher('rev', -in => $repo);

=cut

sub _make_searcher {
    my ($self, %args) = getparameters('self', [qw(rev in)], @_);
    my $rev = $args{rev};
    my $repo = $args{in};

    # TODO find files in scope $self->_revs, repo $repo

    if(!defined $rev) {     # The index of the current repo
        require App::GitFind::Searcher::Git;
        return App::GitFind::Searcher::Git->new(
            -repo => $repo,
            -searchbase=>$self->_searchbase
        );

    } elsif($rev eq ']]') { # The current working directory
        require App::GitFind::Searcher::FileSystem;
        return App::GitFind::Searcher::FileSystem->new(
            -repo => $repo,
            -searchbase=>$self->_searchbase
        );

    } else {
        die "I don't yet know how to search through rev $_";
    }

} #_make_searcher

=head2 _process_options

Process the options and return a hashref.  Any remaining arguments are
stored under key C<_>.

=cut

sub _process_options {
    my $lrArgv = shift // [];
    my $hrOpts;
    local *have = sub { $hrOpts->{switches}->{$_[0] // $_} };

    $hrOpts = App::GitFind::cmdline::Parse($lrArgv)
        or die 'Could not parse options successfully';

    $VERBOSE = scalar @{$hrOpts->{switches}->{v} // []};
    $QUIET = scalar @{$hrOpts->{switches}->{q} // []};

    Getopt::Long::HelpMessage(-exitval => 0, -verbose => 2) if have('man');
    Getopt::Long::HelpMessage(-exitval => 0, -verbose => 1)
        if have('h') || have('help');
    Getopt::Long::HelpMessage(-exitval => 0) if have('?') || have('usage');
    Getopt::Long::VersionMessage(-exitval => 0) if have('V')||have('version');

    return $hrOpts;
} #_process_options

1; # End of App::GitFind
__END__

# === Rest of the docs === {{{1

=head1 AUTHOR

Christopher White, C<< <cxw at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Christopher White.
Portions copyright 2019 D3 Engineering, LLC.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

# }}}1
# vi: set fdm=marker fdl=0: #
