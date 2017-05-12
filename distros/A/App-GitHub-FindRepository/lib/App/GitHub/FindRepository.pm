package App::GitHub::FindRepository;

use warnings;
use strict;

=head1 NAME

App::GitHub::FindRepository - Determine the right case for a GitHub repository

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    github-find-repository git://github.com/robertkrimen/Doc-Simply.git
    # git://github.com/robertkrimen/doc-simply.git

    github-find-repository robertkrimen,Doc-Simply
    # git://github.com/robertkrimen/doc-simply.git

    github-find-repository --pinger=./bin/git-ls-remote ...

    # ... or ...

    use App::GitHub::FindRepository

    my $url = App::GitHub::FindRepository->find( robertkrimen/Doc-Simply )
    # git://github.com/robertkrimen/doc-simply.git

=head1 DESCRIPTION

GitHub recently made a change that now allows mixed-case repository names. Unfortunately, their git daemon
will not find the right repository given the wrong case.

L<App::GitHub::FindRepository> (C<github-find-repository>) will interrogate the repository home page (HTML),
looking for the "right" repository name in a case insensitive manner

If LWP is not installed and curl is not available, then the finder will fallback to using the git protocol (via git-ls-remote or git-peek-remote).
It will first attempt to ping the mixed-case version, and, failing that, will attempt to ping the lowercase version.

In either case, it will return/print the valid repository url, if any

=head1 CAVEAT

When finding via the git protocol, the following applies:

Given a mixed-case repository, the find routine will try the mixed-case once, then the lowercase. It will not find anything
else

    github-find-repository --git-protocol robertkrimen/Doc-Simply

...will work, as long as the real repository is C<robertkrimen/Doc-Simply.git> or C<robertkrimen/doc-simply.git>

If the real repository is C<robertkrimen/dOc-sImPlY.git> then the finder will NOT see it

=head1 INSTALL

You can install L<App::GitHub::FindRepository> by using L<CPAN>:

    cpan -i App::GitHub::FindRepository

If that doesn't work properly, you can find help at:

    http://sial.org/howto/perl/life-with-cpan/
    http://sial.org/howto/perl/life-with-cpan/macosx/ # Help on Mac OS X
    http://sial.org/howto/perl/life-with-cpan/non-root/ # Help with a non-root account

=head1 CONTRIBUTE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/App-GitHub-FindRepository/tree/master>

    git clone git://github.com/robertkrimen/App-GitHub-FindRepository.git

=cut

=head1 USAGE

=head2 github-find-repository

A commandline application that will print out the the repository with the right casing

    Usage: github-find-repository [...] <repository>

        --pinger <pinger>   The pinger to use (default is either git-ls-remote or git-peek-remote)

        --getter <getter>   The getter to use (default is LWP then curl)

        --git-protocol      Don't try to determine the repository by sniffing HTML, just use git://
                            NOTE: This mode will only check the given casing then lowercase

        --output <output>   One of (case insensitive):

                            Given "http://github.com/robertkrimen/aPp-giTHub-findRepoSitory.git"

                            URL      http://github.com/robertkrimen/App-GitHub-FindRepository.git
                            public   git://github.com/robertkrimen/App-GitHub-FindRepository.git
                            private  git@github.com:robertkrimen/App-GitHub-FindRepository.git
                            base     robertkrimen/App-GitHub-FindRepository
                            name     App-GitHub-FindRepository
                            home     http://github.com/robertkrimen/App-GitHub-FindRepository

        --help, -h, -?      This help

        <repository>        The repository to test, can be like:

                            git://github.com/robertkrimen/App-GitHub-FindRepository.git
                            robertkrimen/App-GitHub-FindRepository.git
                            robertkrimen,App-GitHub-FindRepository

    For example:

        github-find-repository --getter curl robertkrimen,aPp-giTHuB-findRepOsitory

=head2 $repository = AppGitHub::FindRepository->find( <repository> [, ...] )

Given a mixed-case repository URI, it will return the version with the right case

    getter  The method to use to access the repository home page (HTML)
    pinger  The pinger to use to access the repository via the git protocol

=head2 $repository = AppGitHub::FindRepository->find_by_git( <repository> [, ...] )
 
    pinger  The pinger to use to access the repository via the git protocol

Given a mixed-case repository URI, it will return the version with the right case, but only using the git protocol

NOTE: This method will only check the given casing then lowercase. See CAVEAT

=head1 ::Repository

The repository object that C<< ->find >> and C<< ->find_by_git >> return

The object will stringify via the C<< ->url >> method

=head2 $repository->url

The URL (URI) of the repository (depends on what the object was instantiated with)

=head2 $repository->public

The public github clone URL:

    git://github.com/<base>.git

=head2 $repository->private

The private github clone URL:

    git@github.com:<base>.git

=head2 $repository->base

The user/project part of the repository path (WITHOUT the .git suffix): 

    robertkrimen/App-GitHub-FindRepository

=head2 $repository->name

The name of the project:

    App-GitHub-FindRepository

=head2 $repository->home

The home page of the project on GitHub:

    http://github.com/<base> # Will redirect to .../tree/master

=head1 A bash function as an alternative

If you do not want to install App::GitHub::FindRepository, here is a bash equivalent (using the git protocol, see CAVEAT):

    #!/bin/bash

    function github-find-repository() {
        local pinger=`which git-ls-remote`
        if [ "$pinger" == "" ]; then pinger=`which git-peek-remote`; fi
        if [ "$pinger" == "" ]; then echo "Couldn't find pinger (git-ls-remote or git-peek-remote)"; return -1; fi
        local repository=$1
        if [ "`$pinger $repository 2>/dev/null`" ]; then echo $repository; return 0; fi
        repository=`echo $repository | tr "[:upper:]" "[:lower:]" `
        if [ "`$pinger $repository 2>/dev/null`" ]; then echo $repository; return 0; fi
        return -1
    }

    github-find-repository $*

=head1 SEE ALSO

L<App::GitHub::FixRepositoryName>

=cut

use App::GitHub::FindRepository::Repository;

use Getopt::Long;
use Env::Path qw/PATH/;

if (Env::Path->MSWIN) {
    require Cwd;
    (my $cwd = Cwd::getcwd()) =~ s{/}{\\}g;
    PATH->Remove($cwd);
    PATH->Prepend($cwd);
}

sub _find_in_path ($) {

    for ( PATH->Whence( shift ) ) {
        return $_ if -f && -r _ && -x _;
    }

    return undef;
}

sub do_usage (;$) {
    my $error = shift;
    warn $error if $error;
    warn <<_END_;

Usage: github-find-repository [...] <repository>

    --pinger <pinger>   The pinger to use (default is either git-ls-remote or git-peek-remote)

    --getter <getter>   The getter to use (default is LWP then curl)

    --git-protocol      Don't try to determine the repository by sniffing HTML, just use git://
                        NOTE: This mode will only check the given casing then lowercase

    --output <output>   One of (case insensitive):

                        Given "http://github.com/robertkrimen/aPp-giTHub-findRepoSitory.git"

                        URL      http://github.com/robertkrimen/App-GitHub-FindRepository.git
                        public   git://github.com/robertkrimen/App-GitHub-FindRepository.git
                        private  git\@github.com:robertkrimen/App-GitHub-FindRepository.git
                        base     robertkrimen/App-GitHub-FindRepository
                        name     App-GitHub-FindRepository
                        home     http://github.com/robertkrimen/App-GitHub-FindRepository

    --help, -h, -?      This help

    <repository>        The repository to test, can be like:

                        git://github.com/robertkrimen/App-GitHub-FindRepository.git
                        robertkrimen/App-GitHub-FindRepository.git
                        robertkrimen,App-GitHub-FindRepository

For example:

    github-find-repository --getter curl robertkrimen,aPp-giTHuB-findRepOsitory

_END_

    exit -1 if $error;
}

sub do_found ($$) {
    my $output = shift;
    my $repository = shift;
    if ($output) {
        print $repository->$output, "\n";
    }
    else {
        print "$repository\n";
    }
    exit 0;
}

sub do_not_found ($) {
    my $repository = shift;
    warn <<_END_;
$0: Repository \"$repository\" not found
_END_
    exit -1;
}

sub pinger {
    my $self = shift;
    return $ENV{GH_FR_PINGER} || _find_in_path 'git-ls-remote' || _find_in_path 'git-peek-remote';
}

sub _get_by_LWP {
    my $self = shift;
    return sub {
        my $url = shift;
        my $agent = LWP::UserAgent->new;
        my $response = $agent->get( $url );
        die $response->status_line, "\n" unless $response->is_success;
        return $response->decoded_content;
    };
}

sub _get_by_curl {
    my $self = shift;
    my $curl = shift;
    return sub {
        my $url = shift;
        return `$curl -s -L $url`;
    };
}
sub getter {
    my $self = shift;
    my $getter = shift;

    return $getter if ref $getter eq 'CODE';

    $getter = 'LWP' unless $getter;
        
    die "Oh my god no!\n" if $getter eq '^';

    my $command;
    if ($getter =~ m/^LWP$/i && eval "require LWP::UserAgent") {
        return $self->_get_by_LWP;
    }
    elsif ($command = _find_in_path 'curl') {
        return $self->_get_by_curl( $command );
    }

    return undef;
}

sub parse_repository {
    my $self = shift;
    return App::GitHub::FindRepository::Repository->parse( @_ );
}

sub find {
    my $self = shift;
    my $repository = $self->parse_repository( shift );
    my %given = @_;
    my $getter = $self->getter( $given{getter} );
    my $pinger = $given{pinger};

    die "No repository given\n" unless $repository;
    if (! $getter ) {
        warn "Unable to use/find LWP or curl\n";
        warn "Falling back to git protocol\n";
        return $self->find_by_git( $repository, pinger => $pinger );
    }

    my $url = $repository->home;
    my $base = $repository->base;

    my $content;
    eval {
        $content = $getter->( $url );
    };
    unless ($content) {
        my $error = $@ || "Unknown error";
        chomp $error;
        warn "Failed GET $url since: $error\n";
        warn "Falling back to git protocol\n";
        return $self->find_by_git( $repository, pinger => $pinger );
    }

    my ($canonical) = $content =~ m/\/($base)\//i;

    unless ($canonical) {
        warn "Failed to find \"/$base/\" in content of size ", length $content, "\n";
        warn "Falling back to git protocol\n";
        return $self->find_by_git( $repository, pinger => $pinger );
    }

    $repository->base( $canonical );

    return $repository;
}

sub find_by_git {
    my $self = shift;
    my $repository = $self->parse_repository( shift );
    my %given = @_;
    my $pinger = $given{pinger} || $self->pinger;

    die "No or invalid repository given\n" unless $repository;
    die "No pinger!\n" unless $pinger;

    my $test_repository = $repository->test;

    return $repository if !system( "$pinger $test_repository 1>/dev/null 2>/dev/null" );
    
    if ($repository->base =~ m/[A-Z]/) {
        $repository->base( lc $repository->base );
        my $test_repository = $repository->test;
        return $repository if !system( "$pinger $test_repository 1>/dev/null 2>/dev/null" );
    }

    return undef;
}

sub run {
    my $self = shift;
    
    my ($getter, $pinger, $git_protocol, $output, $help);
    GetOptions(
        'help|h|?' => \$help,
        'getter=s' => \$getter,
        'pinger=s' => \$pinger,
        'output=s' => \$output,
        'git-protocol' => \$git_protocol,
    );

    if ($help) {
        do_usage;
        exit 0;
    }

    $pinger = $self->pinger unless $pinger;

    my $repository = join '', @ARGV;

    do_usage <<_END_ unless $repository;
$0: You need to specify a repository
_END_

    if ($output) {
        $output = lc $output;
        $output =~ m/^(base|public|private|url|name|home)$/ or do_usage <<_END_;
$0: Unrecogonized output option "$output"
_END_
    }

    eval {
        my $repository = $repository;
        if ($git_protocol) {
            $repository = $self->find_by_git( $repository, pinger => $pinger );
        }
        else {
            $repository = $self->find( $repository, getter => $getter, pinger => $pinger );
        }

        do_found $output, $repository if $repository;
    };
    if ($@ =~ m/No pinger!/) {
        do_usage <<_END_;
$0: No pinger given and couldn't find git-ls-remote or git-peek-remote in \$PATH
_END_
    }
    elsif ($@) {
        my $error = $@;
        chomp $error;
        do_usage <<_END_;
$0: There was an error: $error
_END_
    }

    do_not_found $repository;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-github-findrepository at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-GitHub-FindRepository>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::GitHub::FindRepository


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-GitHub-FindRepository>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-GitHub-FindRepository>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-GitHub-FindRepository>

=item * Search CPAN

L<http://search.cpan.org/dist/App-GitHub-FindRepository/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

__PACKAGE__; # End of App::GitHub::FindRepository
