package App::GitHooks::Plugin::PreventTrailingWhitespace;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use File::Slurp;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::PreventTrailingWhitespace - Prevent trailing whitespace from being committed.


=head1 DESCRIPTION

Prevent pesky trailing whitespace from being committed.

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

    my $file_pattern = App::GitHooks::Plugin::PreventTrailingWhitespace->get_file_pattern(
        app => $app,
    );

=cut

sub get_file_pattern
{
    return qr/\.(?:pl|pm|t|cgi|js|tt|css|html|rb)$/x;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

    my $description = App::GitHooks::Plugin::PreventTrailingWhitespace->get_file_check_description();

=cut

sub get_file_check_description
{
    return 'The file has no lines with trailing white space.';
}


=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

This is where the magic happens.

  my $success = App::GitHooks::Plugin::PreventTrailingWhitespace->run_pre_commit_file();

=cut

sub run_pre_commit_file
{
    my ( $class, %args ) = @_;
    my $file = delete( $args{'file'} );
    my $git_action = delete( $args{'git_action'} );
    my $app = delete( $args{'app'} );
    my $staged_changes = $app->get_staged_changes();
    my $repository = $app->get_repository();

    # Ignore deleted files.
    return $PLUGIN_RETURN_SKIPPED
        if $git_action eq 'D';

    # Ignore merges, since they correspond mostly to code written by other people.
    return $PLUGIN_RETURN_SKIPPED
        if $staged_changes->is_merge();

    # Ignore revert commits.
    return $PLUGIN_RETURN_SKIPPED
        if $staged_changes->is_revert();

    # Determine what lines were written by the current user.
    my @review_lines = ();
    if ( $git_action eq 'A' )
    {
        # "git blame" fails on new files, so we need to add the entire file
        # separately.
        my @lines = File::Slurp::read_file( $file );
        foreach my $i ( 0 .. scalar( @lines ) - 1 )
        {
            chomp( $lines[$i] );
            push(
                @review_lines,
                {
                    line_number => $i,
                    code        => $lines[$i],
                }
            );
        }
    }
    else
    {
        # Find uncommitted lines only.
        my $blame_lines = $repository->blame(
            $file,
            use_cache => 1,
        );

        foreach my $blame_line ( @$blame_lines )
        {
            my $commit_attributes = $blame_line->get_commit_attributes();
            next unless $commit_attributes->{'author-mail'} eq 'not.committed.yet';
            push(
                @review_lines,
                {
                    line_number => $blame_line->get_line_number(),
                    code        => $blame_line->get_line(),
                }
            );
        }
    }

    # Inspect uncommitted lines for trailing white space
    my @whitespace_violations = ();
    foreach my $line ( @review_lines )
    {
        my $code = $line->{'code'};
        my ( $trailing_whitespace ) = $code =~ m/(\s+)$/;
        next if !defined( $trailing_whitespace );

        my $redspace = '';
        $redspace .= $app->color('on_red', $_) foreach (split //, $trailing_whitespace);
        ( my $badline = $code ) =~ s/\s+$/$redspace/;
        push(
            @whitespace_violations,
            sprintf( "line #%d:   %s\n", $line->{'line_number'}, $badline )
        );
    }

    die "Trailing white space found:\n" . join( '', @whitespace_violations ) . "\n"
        if scalar( @whitespace_violations ) != 0;

    return $PLUGIN_RETURN_PASSED;
}

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/barwin/App-GitHooks-Plugin-PreventTrailingWhitespace/issues/new>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

        perldoc App::GitHooks::Plugin::PreventTrailingWhitespace


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/barwin/App-GitHooks-Plugin-PreventTrailingWhitespace/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-preventtrailingwhitespace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-preventtrailingwhitespace>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-PreventTrailingWhitespace>

=back


=head1 AUTHOR

L<Ben Arwin|https://metacpan.org/author/BARWIN>,
C<< <barwin at cpan.org> >>.

=head1 ACKNOWLEDGEMENTS

For guidance on this module and for creating App::GitHooks, big thanks to:

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.

=head1 COPYRIGHT & LICENSE

Copyright 2013-2014 Ben Arwin.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/

=cut

1;
