package App::Critique::Command::collect;

use strict;
use warnings;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Tiny      ();
use Term::ANSIColor ':constants';

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'root=s',       'directory to start traversal from (default is root of git work tree)' ],
        [],
        [ 'no-violation', 'filter files that contain no Perl::Critic violations ' ],
        [],
        [ 'filter|f=s',   'filter files to remove with this regular expression' ],
        [ 'match|m=s',    'match files to keep with this regular expression' ],
        [],
        [ 'dry-run',      'display list of files, but do not store them' ],
        [],
        $class->SUPER::opt_spec,
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    local $Term::ANSIColor::AUTORESET = 1;

    my $session = $self->cautiously_load_session( $opt, $args );

    info('Session file loaded.');

    my $root = $opt->root
        ? Path::Tiny::path( $opt->root )
        : $session->git_work_tree;

    my @all;
    traverse_filesystem(
        root        => $session->git_work_tree,
        path        => $root,
        predicate   => generate_file_predicate(
            $session => (
                filter       => $opt->filter,
                match        => $opt->match,
                no_violation => $opt->no_violation
            )
        ),
        accumulator => \@all,
        verbose     => $opt->verbose,
    );

    my $num_files = scalar @all;
    info('Collected %d perl file(s) for critique.', $num_files);

    foreach my $file ( @all ) {
        info(
            ITALIC('Including %s'),
            Path::Tiny::path( $file )->relative( $root )
        );
    }

    if ( $opt->verbose && $opt->no_violation ) {
        my $stats = $session->perl_critic->statistics;
        info(HR_DARK);
        info('STATISTICS(Perl::Critic)');
        info(HR_LIGHT);
        info(BOLD(' VIOLATIONS  : %s'), format_number($stats->total_violations));
        info('== PERL '.('=' x (TERM_WIDTH() - 8)));
        info('  modules    : %s', format_number($stats->modules));
        info('  subs       : %s', format_number($stats->subs));
        info('  statements : %s', format_number($stats->statements));
        info('== LINES '.('=' x (TERM_WIDTH() - 9)));
        info(BOLD('TOTAL        : %s'), format_number($stats->lines));
        info('  perl       : %s', format_number($stats->lines_of_perl));
        info('  pod        : %s', format_number($stats->lines_of_pod));
        info('  comments   : %s', format_number($stats->lines_of_comment));
        info('  data       : %s', format_number($stats->lines_of_data));
        info('  blank      : %s', format_number($stats->lines_of_blank));
        info(HR_DARK);
    }

    if ( $opt->dry_run ) {
        info('[dry run] %s file(s) found, 0 files added.', format_number($num_files));
    }
    else {
        $session->set_tracked_files( @all );
        $session->reset_file_idx;
        info('Sucessfully added %s file(s).', format_number($num_files));

        $self->cautiously_store_session( $session, $opt, $args );
        info('Session file stored successfully (%s).', $session->session_file_path);
    }
}

sub traverse_filesystem {
    my %args      = @_;
    my $root      = $args{root};
    my $path      = $args{path};
    my $predicate = $args{predicate};
    my $acc       = $args{accumulator};
    my $verbose   = $args{verbose};

    if ( $path->is_file ) {

        #warn "GOT A FILE: $path";

        # ignore anything but perl files ...
        return unless is_perl_file( $path->stringify );

        #warn "NOT PERL FILE: $path";

        # only accept things that match the path
        if ( $predicate->( $root, $path ) ) {
            info(BOLD('Matched: keeping file (%s)'), $path->relative( $root )) if $verbose;
            push @$acc => $path;
        }
        else {
            info('Not Matched: skipping file (%s)', $path->relative( $root )) if $verbose;
        }
    }
    elsif ( -l $path ) { # Path::Tiny does not have a test for symlinks
        ;
    }
    else {

        #warn "GOT A DIR: $path";

        my @children = $path->children( qr/^[^.]/ );

        # prune the directories we really don't care about
        if ( my $ignore = $App::Critique::CONFIG{'IGNORE'} ) {
            @children = grep !$ignore->{ $_->basename }, @children;
        }

        # recurse ...
         foreach my $child ( @children ) {
            traverse_filesystem(
                root        => $root,
                path        => $child,
                predicate   => $predicate,
                accumulator => $acc,
                verbose     => $verbose,
            );
        }
    }

    return;
}

sub generate_file_predicate {
    my ($session, %args) = @_;

    my $filter       = $args{filter};
    my $match        = $args{match};
    my $no_violation = $args{no_violation};

    my $predicate;

    # ------------------------------#
    # filter | match | no-violation #
    # ------------------------------#
    #    0   |   0   |      0       # collect
    # ------------------------------#
    #    1   |   0   |      0       # collect with filter
    #    1   |   1   |      0       # collect with filter and match
    #    1   |   1   |      1       # collect with filter match and no violations
    #    1   |   0   |      1       # collect with filter and no violations
    # ------------------------------#
    #    0   |   1   |      0       # collect with match
    #    0   |   1   |      1       # collect with match and no violations
    # ------------------------------#
    #    0   |   0   |      1       # collect with no violations
    # ------------------------------#

    # filter only
    if ( $filter && not($match) && not($no_violation) ) {
        $predicate = sub {
            my $root = $_[0];
            my $path = $_[1];
            my $rel  = $path->relative( $root );
            return $rel !~ /$filter/;
        };
    }
    # filter and match
    elsif ( $filter && $match && not($no_violation) ) {
        $predicate = sub {
            my $root = $_[0];
            my $path = $_[1];
            my $rel  = $path->relative( $root );
            return $rel =~ /$match/
                && $rel !~ /$filter/;
        };
    }
    # filter and match and check violations
    elsif ( $filter && $match && $no_violation ) {
        my $c = $session->perl_critic;
        $predicate = sub {
            my $root = $_[0];
            my $path = $_[1];
            my $rel  = $path->relative( $root );
            return $rel =~ /$match/
                && $rel !~ /$filter/
                && scalar $c->critique( $path->stringify );
        };
    }
    # filter and check violations
    elsif ( $filter && not($match) && $no_violation ) {
        my $c = $session->perl_critic;
        $predicate = sub {
            my $root = $_[0];
            my $path = $_[1];
            my $rel  = $path->relative( $root );
            return $rel !~ /$filter/
                && scalar $c->critique( $path->stringify );
        };
    }
    # match only
    elsif ( not($filter) && $match && not($no_violation) ) {
        $predicate = sub {
            my $root = $_[0];
            my $path = $_[1];
            my $rel  = $path->relative( $root );
            return $rel =~ /$match/;
        };
    }
    # match and check violations
    elsif ( not($filter) && $match && $no_violation ) {
        my $c = $session->perl_critic;
        $predicate = sub {
            my $root = $_[0];
            my $path = $_[1];
            my $rel  = $path->relative( $root );
            return $rel =~ /$match/
                && scalar $c->critique( $path->stringify );
        };
    }
    # check violations only
    elsif ( not($filter) && not($match) && $no_violation ) {
        my $c = $session->perl_critic;
        $predicate = sub {
            my $path = $_[1];
            return scalar $c->critique( $path->stringify );
        };
    }
    # none of the above
    else {
        $predicate = sub () { 1 };
    }

    $session->set_file_criteria({
        filter       => $filter,
        match        => $match,
        no_violation => $no_violation
    });

    return $predicate;
}

# NOTE:
# This was mostly taken from the guts of
# Perl::Critic::Util::{_is_perl,_is_backup}
# - SL
sub is_perl_file {
    my ($file) = @_;

    # skip all the backups
    return 0 if $file =~ m{ [.] swp \z}xms;
    return 0 if $file =~ m{ [.] bak \z}xms;
    return 0 if $file =~ m{  ~ \z}xms;
    return 0 if $file =~ m{ \A [#] .+ [#] \z}xms;

    # but grab the perl files
    return 1 if $file =~ m{ [.] PL    \z}xms;
    return 1 if $file =~ m{ [.] p[lm] \z}xms;
    return 1 if $file =~ m{ [.] t     \z}xms;
    return 1 if $file =~ m{ [.] psgi  \z}xms;
    return 1 if $file =~ m{ [.] cgi   \z}xms;

    # if we have to, check for shebang
    my $first;
    {
        open my $fh, '<', $file or return 0;
        $first = <$fh>;
        close $fh;
    }

    return 1 if defined $first && ( $first =~ m{ \A [#]!.*perl }xms );
    return 0;
}

1;

=pod

=head1 NAME

App::Critique::Command::collect - Collect set of files for current critique session

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This command will traverse the critque directory and gather all available Perl
files for critiquing. It will then store this list inside the correct critique
session file for processing during the critique session.

It should be noted that this is a destructive command, meaning that if you have
begun critiquing your files and you re-run this command it will overwrite that
list and you will loose any tracking information you currently have.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Collect set of files for current critique session

