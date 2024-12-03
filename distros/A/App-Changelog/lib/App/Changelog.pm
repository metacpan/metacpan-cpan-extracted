package App::Changelog;

use strict;
use warnings;

use feature 'say';

our $VERSION = '1.0.2';

sub new {
    my ( $class, %args ) = @_;
    my $self = {
        output_file  => $args{output_file} || 'CHANGELOG.md',
        compact      => $args{compact} // 1,
        filter_tag   => $args{filter_tag} || '',
        conventional => $args{conventional} // 0,
    };
    bless $self, $class;
    return $self;
}

sub generate_changelog {
    my ($self) = @_;

    say "Generating changelog from Git history...";

    my $git_log_format =
      $self->{compact} ? '--pretty=format:"%h %s"' : '--pretty=fuller';
    if ( $self->{conventional} ) {
        $git_log_format = '--pretty=format:"%h %s (%an)"';
    }

    my $git_log =
      $self->_run_git_command("git log $git_log_format --abbrev-commit");
    if ( !$git_log ) {
        die
"Error: Could not retrieve Git history. Are you in a Git repository?\n";
    }

    my @tags = $self->_get_tags();
    my $changelog_content =
      $self->_build_changelog_content( \@tags, $git_log_format );

    $self->_write_to_file($changelog_content);
    say "Changelog generated successfully in $self->{output_file}.";
}

sub _build_changelog_content {
    my ( $self, $tags, $format ) = @_;
    my $content = "# Changelog\n\n";

    for my $i ( 0 .. $#$tags ) {
        my $current_tag  = $tags->[$i];
        my $previous_tag = $i == $#$tags ? '' : $tags->[ $i + 1 ];

        my $log_command =
          $previous_tag
          ? "git log $previous_tag..$current_tag $format"
          : "git log $current_tag $format";

        my $logs = $self->_run_git_command($log_command);
        $logs = $self->_filter_conventional_commits($logs)
          if $self->{conventional};

        my $date =
          $self->_run_git_command("git log -1 --format=%ai $current_tag");
        $date =~ s/\s.*$//;

        $content .= "## [$current_tag] - $date\n\n";

        unless ( $self->{conventional} ) {
            $content .= "$logs\n" if $logs;
        }
        else {
            my %grouped_commits;
            my @log_lines = split( "\n", $logs );

            for my $log (@log_lines) {
                if ( $log =~ /^[a-f0-9]+\s([a-z]+):\s*(.*)$/ ) {
                    my $type    = $1;
                    my $message = $2;

                    push @{ $grouped_commits{$type} }, $message;
                }
            }

            for my $type ( sort keys %grouped_commits ) {
                $content .= "### " . ucfirst($type) . "\n";
                for my $message ( @{ $grouped_commits{$type} } ) {
                    $content .= "- $type: $message\n";
                }
                $content .= "\n";
            }
        }
    }

    return $content;
}

sub _filter_conventional_commits {
    my ( $self, $logs ) = @_;
    my @lines = split( /\n/, $logs );
    my @filtered;

    foreach my $line (@lines) {
        if ( $line =~
/^feat|fix|chore|docs|style|refactor|test|perf|ci|build|revert\(.*?\): /
          )
        {
            push @filtered, $line;
        }
    }

    return join( "\n", @filtered );
}

sub _get_tags {
    my ($self)   = @_;
    my $git_tags = $self->_run_git_command('git tag --sort=creatordate');
    my @tags     = split( /\n/, $git_tags );
    if ( !@tags ) {
        die
"Error: No Git tags found. Use 'git tag' to create version tags first.\n";
    }

    if ( $self->{filter_tag} ) {
        @tags = grep { /^$self->{filter_tag}/ } @tags;
        if ( !@tags ) {
            die "Error: No tags matching the filter '$self->{filter_tag}'.\n";
        }
    }
    return @tags;
}

sub _run_git_command {
    my ( $self, $command ) = @_;
    my $output = `$command`;
    chomp $output;
    return $output;
}

sub _write_to_file {
    my ( $self, $content ) = @_;
    open( my $fh, '>', $self->{output_file} )
      or die "Could not open $self->{output_file}: $!";
    print $fh $content;
    close($fh);
}

1;
__END__

=encoding utf-8

=head1 NAME

changelog - Simple command-line CHANGELOG.md generator written in Perl

=head1 SYNOPSIS

    changelog [options]

=head1 DESCRIPTION

This command-line tool written in Perl for automatically generating changelogs based on Git commit history. It allows you to create detailed or compact logs, filter specific tags, and save the changelog to a file.

=head1 EXAMPLES

To generate a changelog in compact mode (default):

    changelog

To save the changelog to a specific file:

    changelog --output changelog.md

To generate detailed logs:

    changelog --no-compact

To filter commits by tags starting with "v":

    changelog --filter v

=head1 ERRORS

If there is an error during any operation (such as adding, editing, or removing passwords), an error message will be displayed indicating the issue.

=head1 AUTHOR

Luiz Felipe de Castro Vilas Boas <luizfelipecastrovb@gmail.com>

=head1 LICENSE

This module is released under the MIT License. See the LICENSE file for more details.

=cut

