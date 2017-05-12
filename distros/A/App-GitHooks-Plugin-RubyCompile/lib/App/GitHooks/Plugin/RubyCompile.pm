package App::GitHooks::Plugin::RubyCompile;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use System::Command;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::RubyCompile - Verify that staged Ruby files compile.


=head1 DESCRIPTION

Verify that staged Ruby files compile by running ruby -c against them.

Warnings are suppressed with -W0.


=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

    my $file_pattern = App::GitHooks::Plugin::RubyCompile->get_file_pattern(
        app => $app,
    );

=cut

sub get_file_pattern
{
    return qr/\.(?:rb)$/x;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

    my $description = App::GitHooks::Plugin::RubyCompile->get_file_check_description();

=cut

sub get_file_check_description
{
    return 'The file passes ruby -c';
}


=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

  my $success = App::GitHooks::Plugin::RubyCompile->run_pre_commit_file();

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

    # Execute ruby -c.
    my $path = $repository->work_tree() . '/' . $file;
    my ( $pid, $stdin, $stdout, $stderr ) = System::Command->spawn( 'ruby', '-W0', '-c', $path );

    # Retrieve the output.
    chomp( my $message_out = do { local $/ = undef; <$stdout> } );

    # Raise an exception if we didn't get "syntax OK".
    if ( $message_out !~ /^Syntax\ OK$/x ) {
            my @warnings = <$stderr>;
            foreach my $warning ( @warnings ) {
                    chomp( $warning );
                    $warning =~ s/^\Q$path\E:/Line /;
            }
            die join( "\n", @warnings ) . "\n";
    }

    return $PLUGIN_RETURN_PASSED;
}

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/jacobmaurer/App-GitHooks-Plugin-RubyCompile/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Big thanks to Guillaume Aubert!

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::GitHooks::Plugin::RubyCompile


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/jacobmaurer/App-GitHooks-Plugin-RubyCompile/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-RubyCompile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-RubyCompile>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-RubyCompile>

=back


=head1 AUTHOR

L<Jacob Maurer|https://metacpan.org/author/JMAURER>,
C<< <jmaurer at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2013-2014 Jacob Maurer.

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
