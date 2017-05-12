package App::Critique::Session;

use strict;
use warnings;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util        ();
use Carp                ();

use Path::Tiny          ();

use Git::Wrapper        ();
use Perl::Critic        ();
use Perl::Critic::Utils ();

use App::Critique;
use App::Critique::Session::File;

sub new {
    my ($class, %args) = @_;

    Carp::confess('You must specify a git_work_tree')
        unless $args{git_work_tree} && -d $args{git_work_tree};

    # setup the perl critic instance
    my $critic = $class->_initialize_perl_critic( %args );

    # auto-discover the current git repo and branch
    my ($git, $git_branch) = $class->_initialize_git_repo( %args );

    # now that we have worked out all the details,
    # we need to determine the path to the actual
    # critique file.
    my $path = $class->_generate_critique_file_path( $git->dir, $git_branch );

    my $self = bless {
        # user supplied ...
        perl_critic_profile => $args{perl_critic_profile},
        perl_critic_theme   => $args{perl_critic_theme},
        perl_critic_policy  => $args{perl_critic_policy},

        # auto-discovered
        git_work_tree       => Path::Tiny::path( $git->dir ),
        git_branch          => $git_branch,

        # local storage
        current_file_idx    => 0,
        tracked_files       => [],
        file_criteria       => {},

        # Do Not Serialize
        _path   => $path,
        _critic => $critic,
        _git    => $git,
    } => $class;

    # handle adding tracked files
    $self->set_tracked_files( @{ $args{tracked_files} } )
        if exists $args{tracked_files};

    $self->set_file_criteria( $args{file_criteria} )
        if exists $args{file_criteria};

    $self->{current_file_idx} = $args{current_file_idx}
        if exists $args{current_file_idx};

    return $self;
}

sub locate_session_file {
    my ($class, $git_work_tree) = @_;

    Carp::confess('Cannot call locate_session_file with an instance')
        if Scalar::Util::blessed( $class );

    Carp::confess('You must specify a git-work-tree')
        unless $git_work_tree && -d $git_work_tree;

    my ($git, $git_branch) = $class->_initialize_git_repo( git_work_tree => $git_work_tree );

    my $session_file = $class->_generate_critique_file_path(
        Path::Tiny::path( $git->dir ),
        $git_branch
    );

    return $session_file;
}

# accessors

sub git_work_tree       { $_[0]->{git_work_tree}       }
sub git_branch          { $_[0]->{git_branch}          }
sub perl_critic_profile { $_[0]->{perl_critic_profile} }
sub perl_critic_theme   { $_[0]->{perl_critic_theme}   }
sub perl_critic_policy  { $_[0]->{perl_critic_policy}  }

sub tracked_files     { @{ $_[0]->{tracked_files} } }
sub file_criteria     { $_[0]->{file_criteria} }

sub current_file_idx { $_[0]->{current_file_idx}   }
sub inc_file_idx     { $_[0]->{current_file_idx}++ }
sub dec_file_idx     { $_[0]->{current_file_idx}-- }
sub reset_file_idx   { $_[0]->{current_file_idx}=0 }

sub session_file_path { $_[0]->{_path} }
sub git_wrapper       { $_[0]->{_git}  }
sub perl_critic       { $_[0]->{_critic} }

# Instance Methods

sub session_file_exists {
    my ($self) = @_;
    return !! -e $self->{_path};
}

sub set_tracked_files {
    my ($self, @files) = @_;
    @{ $self->{tracked_files} } = map {
        (Scalar::Util::blessed($_) && $_->isa('App::Critique::Session::File')
            ? $_
            : ((ref $_ eq 'HASH')
                ? App::Critique::Session::File->new( %$_ )
                : App::Critique::Session::File->new( path => $_ )))
    } @files;
}

sub set_file_criteria {
    my ($self, $filters_used) = @_;
    $self->{file_criteria}->{ $_ } = $filters_used->{ $_ }
        foreach keys %$filters_used;
}

# ...

sub pack {
    my ($self) = @_;
    return +{
        perl_critic_profile => ($self->{perl_critic_profile} ? $self->{perl_critic_profile}->stringify : undef),
        perl_critic_theme   => $self->{perl_critic_theme},
        perl_critic_policy  => $self->{perl_critic_policy},

        git_work_tree       => ($self->{git_work_tree} ? $self->{git_work_tree}->stringify : undef),
        git_branch          => $self->{git_branch},

        current_file_idx    => $self->{current_file_idx},
        tracked_files       => [ map $_->pack, @{ $self->{tracked_files} } ],
        file_criteria       => $self->{file_criteria}
    };
}

sub unpack {
    my ($class, $data) = @_;
    return $class->new( %$data );
}

# ...

sub load {
    my ($class, $path) = @_;

    Carp::confess('Invalid path: ' . $path)
        unless $path->exists && $path->is_file;

    my $file = Path::Tiny::path( $path );
    my $json = $file->slurp;
    my $data = $App::Critique::JSON->decode( $json );

    return $class->unpack( $data );
}

sub store {
    my ($self) = @_;

    my $file = $self->{_path};
    my $data = $self->pack;

    eval {
        # JSON might die here ...
        my $json = $App::Critique::JSON->encode( $data );

        # if the file does not exist
        # then we should try and make
        # the path, just in case ...
        $file->parent->mkpath unless -e $file;

        # now try and write out the JSON
        my $fh = $file->openw;
        $fh->print( $json );
        $fh->close;

        1;
    } or do {
        Carp::confess('Unable to store critique session file because: ' . $@);
    };
}

# ...

sub _generate_critique_dir_path {
    my ($class, $git_work_tree, $git_branch) = @_;

    my $root = Path::Tiny::path( $App::Critique::CONFIG{'HOME'} );
    my $git  = Path::Tiny::path( $git_work_tree );

    # ~/.critique/<git-repo-name>/<git-branch-name>/session.json

    $root->child( '.critique' )
         ->child( $git->basename )
         ->child( $git_branch );
}

sub _generate_critique_file_path {
    my ($class, $git_work_tree, $git_branch) = @_;
    $class->_generate_critique_dir_path(
        $git_work_tree,
        $git_branch
    )->child(
        'session.json'
    );
}

sub _initialize_git_repo {
    my ($class, %args) = @_;

    my $git = Git::Wrapper->new( $args{git_work_tree} );

    # auto-discover the current git branch
    my ($git_branch) = map /^\*\s(.*)$/, grep /^\*/, $git->branch;

    Carp::confess('Unable to determine git branch, looks like your repository is bare')
        unless $git_branch;

    # make sure the branch we are on is the
    # same one we are being asked to load,
    # this is very much unlikely to happen
    # but something we should die about none
    # the less.
    Carp::confess('Attempting to inflate session for branch ('.$args{git_branch}.') but branch ('.$git_branch.') is currently active')
        if exists $args{git_branch} && $args{git_branch} ne $git_branch;

    # if all is well, return ...
    return ($git, $git_branch);
}

sub _initialize_perl_critic {
    my ($class, %args) = @_;

    my $critic;
    if ( $args{perl_critic_policy} ) {
        $critic = Perl::Critic->new( '-single-policy' => $args{perl_critic_policy} );
    }
    else {
        $critic = Perl::Critic->new(
            ($args{perl_critic_profile} ? ('-profile' => $args{perl_critic_profile}) : ()),
            ($args{perl_critic_theme}   ? ('-theme'   => $args{perl_critic_theme})   : ()),
        );

        # inflate this as needed
        $args{perl_critic_profile} = Path::Tiny::path( $args{perl_critic_profile} )
            if $args{perl_critic_profile};
    }

    return $critic;
}

1;

=pod

=head1 NAME

App::Critique::Session - Session interface for App::Critique

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This is the main interace to the L<App::Critique> session file
and contains no real user serviceable parts.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Session interface for App::Critique

