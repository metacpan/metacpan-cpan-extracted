package App::GHPT::WorkSubmitter::ChangedFilesFactory;

use App::GHPT::Wrapper::OurMoose;

our $VERSION = '1.000012';

use IPC::Run3 qw( run3 );
use App::GHPT::Types qw( ArrayRef HashRef Str );
use App::GHPT::WorkSubmitter::ChangedFiles;

has changed_files_class => (
    is      => 'ro',
    isa     => Str,
    default => 'App::GHPT::WorkSubmitter::ChangedFiles',
);

has merge_to_branch_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has current_branch_name => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_current_branch_name',
);

sub _build_current_branch_name {
    my $branch;

    my @command = (
        'git',
        'rev-parse',
        '--abbrev-ref',
        'HEAD',
    );

    run3 \@command, \undef, \$branch, \my $error;
    if ( $error || $? ) {
        die join q{ }, 'Problem running git rev-parse:', @command, $error, $?;
    }

    chomp $branch;
    return $branch;
}

has merge_base => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_merge_base',
);

sub _build_merge_base ( $self, @ ) {
    my $merge_base;

    my @command = (
        'git',
        'merge-base',
        $self->current_branch_name,
        $self->merge_to_branch_name,
    );

    run3 \@command, \undef, \$merge_base, \my $error;
    if ( $error || $? ) {
        die join q{ }, 'Problem running git merge-base:', @command, $error,
            $?;
    }

    chomp $merge_base;
    return $merge_base;
}

has _git_diff_file_list => (
    is      => 'ro',
    isa     => HashRef [ ArrayRef [Str] ],
    lazy    => 1,
    builder => '_build_git_diff_file_list',
);

sub _build_git_diff_file_list ($self) {
    my %return_value;

    my @command = (
        'git',
        'diff',
        '--name-status',
        $self->merge_base,
        $self->current_branch_name,
    );

    run3 \@command, \undef, sub ($line) {
        chomp $line;
        my ( $code, $filename ) = split /\s+/, $line, 2;
        $return_value{$code} ||= [];
        push $return_value{$code}->@*, $filename;
    }, \my $error;

    if ( $error || $? ) {
        die join q{ }, 'Problem running git diff:', @command, $error, $?;
    }

    return \%return_value;
}

has _all_files => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_all_files',
);

sub _build_all_files ($self) {
    my @files;

    my @command = (
        'git',
        'ls-tree',
        '-r',
        'HEAD:',
    );

    run3 \@command, \undef, sub ($line) {
        chomp $line;
        my ( undef, undef, undef, $filename ) = split /\s+/, $line, 4;
        push @files, $filename;
    }, \my $error;

    if ( $error || $? ) {
        die join q{ }, 'Problem running git ls-tree:', @command,
            $error, $?;
    }

    return \@files;
}

has changed_files => (
    is      => 'ro',
    isa     => 'App::GHPT::WorkSubmitter::ChangedFiles',
    lazy    => 1,
    builder => '_build_changed_files',
);

sub _build_changed_files ( $self, @ ) {
    return $self->changed_files_class->new(
        added_files    => $self->_git_diff_file_list->{A} || [],
        modified_files => $self->_git_diff_file_list->{M} || [],
        deleted_files  => $self->_git_diff_file_list->{D} || [],
        all_files      => $self->_all_files,
    );
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Work out what files have changed in the git branch

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GHPT::WorkSubmitter::ChangedFilesFactory - Work out what files have changed in the git branch

=head1 VERSION

version 1.000012

=head1 SYNOPSIS

=head1 DESCRIPTION

Builds a L<App::GHPT::WorkSubmitter::ChangedFiles> from the git repo.  Only concerns
itself with things that have been committed, doesn't care about what's in the
working directory at all.

Used by L<App::GHPT::WorkSubmitter::AskPullRequestQuestions>.

=for test_synopsis use v5.20;

  my $factory = App::GHPT::WorkSubmitter::ChangedFilesFactory->new(
      merge_to_branch_name => 'master',
  );

  my $changed_files = $factory->changed_files;

  say 'The files that were added or modified since branching are:';
  say for $changed_files->changed_files;

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/App-GHPT/issues>.

=head1 AUTHORS

=over 4

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
