package App::GitHooks::Test;

use strict;
use warnings;

# Parent class.
use base 'Exporter';

# External dependencies.
use Capture::Tiny;
use Carp;
use Cwd;
use Data::Section -setup;
use Data::Validate::Type;
use File::Spec;
use File::Temp;
use Path::Tiny qw();
use Test::Exception;
use Test::Git;
use Test::Requires::Git -nocheck;
use Test::More;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


## no critic (RegularExpressions::RequireExtendedFormatting)

=head1 NAME

App::GitHooks::Test - Shared test functions for App::GitHooks.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';

our @EXPORT_OK = qw(
	ok_add_file
	ok_add_files
	ok_setup_repository
);


=head1 FUNCTIONS

=head2 ok_add_file()

Create a file and add it to the git index.

	ok_add_file(
		repository => $repository,
		path       => $path,
		content    => $content,
	);

Arguments:

=over 4

=item * repository I<(mandatory)>

A C<Git::Repository> object.

=item * path I<(mandatory)>

The path of the file to write, relative to the root of the git repository
passed.

=item * content I<(optional)>

The content of the file to write.

=back

=cut

sub ok_add_file
{
	my ( %args ) = @_;
	my $repository = delete( $args{'repository'} );
	my $path = delete( $args{'path'} );
	my $content = delete( $args{'content'} );
	croak 'Invalid argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	return
		subtest(
			"Add file >$path<.",
			sub
			{
				plan( tests => 2 );

				lives_ok(
					sub
					{
						Path::Tiny::path( $repository->work_tree(), $path )
							->spew( $content );
					},
					'Write file.',
				);

				lives_ok(
					sub
					{
						$repository->run( 'add', $path );
					},
					'Add the file to the git index.',
				);
			}
		);
}


=head2 ok_add_files()

Create files and add them to the git index.

	ok_add_files(
		repository => $repository,
		files      =>
		{
			$file_name => $file_content,
			...
		},
	);

Arguments:

=over 4

=item * repository I<(mandatory)>

A C<Git::Repository> object.

=item * files I<(optional)>

A hashref with file names as keys and the content of each file as the
corresponding value.

=back

=cut

sub ok_add_files
{
	my ( %args ) = @_;
	my $repository = delete( $args{'repository'} );
	my $files = delete( $args{'files'} ) // {};
	croak 'Unknown argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	return
		subtest(
			'Set up test files.',
			sub
			{
				plan( tests => scalar( keys %$files ) );

				foreach my $filename ( keys %$files )
				{
					ok_add_file(
						repository => $repository,
						path       => $filename,
						content    => $files->{ $filename },
					);
				}
			}
		);
}


=head2 ok_setup_repository()

Set up a test repository.

	ok_setup_repository(
		cleanup_test_repository => $cleanup_test_repository, # default 1
		config                  => $config,                  # default ''
		hooks                   => \@hooks,                  # default []
		plugins                 => \@plugins,                # default []
	);

Arguments:

=over 4

=item * cleanup_test_repository

Whether the test repository created in order to run a test should be destroyed
at the end of the test (default: 1).

=item * config

Elements to add to the C<.githooksrc> file set up at the root of the test
repository.

=item * hooks

An arrayref of the names of the hooks to set up for this test (for example,
C<commit-msg>).

=item * plugins

An arrayref of the module names of the plugins to run for this test (for
example, C<App::GitHooks::Plugins::Test::CustomReply>).

=back

=cut

sub ok_setup_repository
{
	my ( %args ) = @_;
	my $cleanup_test_repository = delete( $args{'cleanup_test_repository'} ) // 1;
	my $config = delete( $args{'config'} ) // '';
	my $hooks = delete( $args{'hooks'} ) // [];
	my $plugins = delete( $args{'plugins'} ) // [];

	# Validate the parameters.
	croak "The 'plugins' argument must be an arrayref"
		if !Data::Validate::Type::is_arrayref( $plugins );
	croak "The 'hooks' argument must be an arrayref"
		if !Data::Validate::Type::is_arrayref( $hooks );
	croak 'Unknown argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Check if we need to propagate test coverage checks to the hooks.
	my $test_coverage = ( ( $ENV{'HARNESS_PERL_SWITCHES'} // '' ) =~ /Devel::Cover/ )
		|| ( ( $ENV{'PERL5OPT'} // '' ) =~ /Devel::Cover/ )
			? 1
			: 0;

	my $repository;
	subtest(
		'Set up temporary test repository.',
		sub
		{
			plan( tests => 10 + scalar( @$hooks ) );

			# Create a temporary repository.
			ok(
				defined(
					$repository = Test::Git::test_repository(
						temp => [ CLEANUP => $cleanup_test_repository ],
					)
				),
				'Create the test repository.',
			);
			note( 'Using test repository ' . $repository->work_tree() );

			lives_ok(
				sub
				{
					$repository->run( 'config', 'user.email', 'author1@example.com' );
				},
				'Set the test author\'s email.',
			);

			lives_ok(
				sub
				{
					$repository->run( 'config', 'user.name', 'Test Author' );
				},
				'Set the test author\'s name.',
			);

			# Make sure we have a hook template available.
			my $hook_template_ref = __PACKAGE__->section_data(
				$test_coverage
					? 'devel_cover'
					: 'default'
			);
			my $hook_template = defined( $hook_template_ref )
				? $$hook_template_ref
				: undef;
			ok(
				defined( $hook_template )
				&& ( $hook_template =~ /\w/ ),
				'The hook template exists.',
			) || diag( explain( $hook_template_ref ) );

			# The hooks are perl processes instantiated by git, so they will not have the
			# same @INC necessarily, which is a problem for testing in particular when
			# specific libs are included on the command line of the test. To that effect,
			# we hardcode the current @INC into the hook startup files.
			my $libs = join(
				' ',
				map { File::Spec->rel2abs( $_ ) } @INC
			);
			$hook_template =~ s/\Q{libs}\E/$libs/g;

			# Template replacements.
			$hook_template =~ s/\Q{interpreter_path}\E/$^X/g;

			# Specific actions for when test coverage is enabled.
			my $cover_db_path;
			SKIP:
			{
				skip(
					'Test coverage not enabled.',
					5,
				) if !$test_coverage;

				# Find out in which directory the coverage database should be stored.
				SKIP:
				{
					skip(
						'The COVER_DB_PATH environment variable is not set.',
						1,
					) if ( $ENV{'COVER_DB_PATH'} // '' ) eq '';

					my $is_valid =
						ok(
							-e $ENV{'COVER_DB_PATH'},
							'The coverage database directory specified in the COVER_DB_PATH environment variable is valid.',
						);

					$cover_db_path = $ENV{'COVER_DB_PATH'}
						if $is_valid;
				};

				# Use File::Spec->catfile() for portability.
				ok(
					defined(
						$cover_db_path //= File::Spec->catfile( Cwd::getcwd(), 'cover_db' )
					),
					'The coverage database directory is set.',
				);
				note( "Using the coverage database directory >$cover_db_path<." );
				$hook_template =~ s/\Q{cover_db_path}\E/$cover_db_path/g
					if defined( $cover_db_path );

				# Note: this is required because Devel::Coverage only analyzes the coverage
				# for files in -dir, which defaults to the current directory. It can be changed
				# to '/home' or '/' to make it cover both the test repository and the main lib/
				# directory in which the code for the hooks lives, but this wouldn't be portable.
				# Instead, we symlink the lib directory into the test repository, and the
				# coverage-specific version of the test githook template will use that symlink as
				# the source for the App::GitHooks modules. As long as the target system supports
				# symlinks, it then allows for coverage testing.
				# Note: lib/ is necessary for testing coverage via 'prove', but
				# blib/lib/ is necessary for testing coverage via 'cover'.
				ok(
					symlink( Cwd::getcwd() . '/lib', $repository->work_tree() . '/lib' ),
					'Symlink lib/ into the test repository to allow proper merging of coverage databases (with "prove").',
				);
				ok(
					mkdir( $repository->work_tree() . '/blib' ),
					'Create a blib/ directory in the test repository.',
				);
				ok(
					symlink( Cwd::getcwd() . '/lib', $repository->work_tree() . '/blib/lib' ),
					'Symlink blib/lib/ into the test repository to allow proper merging of coverage databases (with "cover").',
				);
			};

			# Set up the hooks.
			foreach my $hook_name ( @$hooks )
			{
				subtest(
					"Set up the $hook_name hook.",
					sub
					{
						plan( tests => 2 );

						my $hook_path = $repository->work_tree() . '/.git/hooks/' . $hook_name;
						lives_ok(
							sub
							{
								Path::Tiny::path( $hook_path )
									->spew( $hook_template );
							},
							'Write the hook.',
						);

						ok(
							chmod( 0755, $hook_path ),
							"Make the $hook_name hook executable.",
						);
					}
				);
			}

			# Set up a .githooksrc config.
			lives_ok(
				sub
				{
					my $content = "";

					# Main section.
					{
						# Only run specific plugins.
						$content .= "force_plugins = " . join( ', ', @$plugins ) . "\n"
							if defined( $plugins );
					}

					# Testing section.
					{
						$content .= "[testing]\n";

						# Pretend we're in an interactive terminal even if we're doing automated testing.
						$content .= "force_interactive = 1\n";

						# Disable color, to make it easier to match output.
						$content .= "force_use_colors = 0\n";

						# Disable utf-8 characters, to make it easier to match output.
						$content .= "force_is_utf8 = 0\n";

						# Just have commit-msg exit with the result of the checks, instead
						# of forcing to correct the issue.
						$content .= "commit_msg_no_edit = 1\n";
					}

					# Add any custom config passed.
					$content .= $config;

					# Write the file.
					Path::Tiny::path( $repository->work_tree(), '.githooksrc' )
						->spew( $content );
				},
				'Write a .githooksrc config file.',
			);
		}
	);

	return $repository;
}


=head2 ok_reset_githooksrc()

Ensures that an empty C<.githooksrc> is used.

	ok_reset_githooksrc();

Arguments:

=over 4

=item * content I<(optional)>

Content for the C<.githooksrc> file.

By default, this function generates an empty C<.githooksrc> file, which has the
effect of using the defaults of L<App::GitHooks>.

=back

=cut

sub ok_reset_githooksrc
{
	my ( %args ) = @_;
	my $content = delete( $args{'content'} ) // '';

	croak 'Invalid argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	subtest(
		'Set up .githooksrc file.',
		sub
		{
			plan( tests => 4 );

			ok(
				my ( $file_handle, $filename ) = File::Temp::tempfile(),
				'Create a temporary file to store the githooks config.',
			);

			ok(
				( print $file_handle $content ),
				'Write the githooks config.',
			);

			ok(
				close( $file_handle ),
				'Close githooks config.',
			);

			note( "GITHOOKSRC_FORCE will be set to $filename." );

			# Note: we need to make a global change to %ENV here, so that it
			# propagates to the caller's scope.
			ok(
				$ENV{'GITHOOKSRC_FORCE'} = $filename, ## no critic (Variables::RequireLocalizedPunctuationVars)
				'Set the environment variable GITHOOKSRC_FORCE to point to the new config.',
			);
		}
	);

	return;
}


=head2 test_hook()

Test a git hook.

	App::GitHooks::Test::test_hook(
		tests                   => \@tests,
		hook_name               => $hook_name,
		plugins                 => \@plugins,
		cleanup_test_repository => $cleanup_test_repository, # default 1
	);

Mandatory arguments:

=over 4

=item * tests

A set of tests to run.

# TODO: document tests format.

=item * hook_name

The name of the git hook to test (for example, C<commit-msg>).

=item * plugins

An arrayref of the module names of the plugins to run for this test (for
example, C<App::GitHooks::Plugins::Test::CustomReply>).

=back

Optional arguments:

=over 4

=item * cleanup_test_repository

Whether the test repository created in order to run a test should be destroyed
at the end of the test (default: 1).

=back

=cut

sub test_hook
{
	my ( %args ) = @_;
	my $tests = delete( $args{'tests'} );
	my $hook_name = delete( $args{'hook_name'} );
	my $plugins = delete( $args{'plugins'} );
	my $cleanup_test_repository = delete( $args{'cleanup_test_repository'} ) // 1;
	croak "Invalid arguments passed: " . join( ', ', keys %args )
		if scalar( keys %args ) != 0;
	croak "A hook name must be specified"
		if !defined( $hook_name );
	croak "The hook name is not valid"
		if $hook_name !~ /^[\w-]+$/;

	# Bail out if Git isn't available.
	Test::Requires::Git::test_requires_git( '1.7.4.1' );
	plan( tests => scalar( @$tests ) );

	foreach my $test ( @$tests )
	{
		subtest(
			$test->{'name'},
			sub
			{
				plan( tests => 5 );

				my $repository = ok_setup_repository(
					cleanup_test_repository => $cleanup_test_repository,
					config                  => $test->{'config'},
					hooks                   => [ $hook_name ],
					plugins                 => $plugins,
				);

				# Set up a test file.
				ok_add_file(
					repository => $repository,
					path       => 'test.pl',
					content    => "#!perl\n\nuse strict;\nbareword;\n",
				);

				# Try to commit.
				my $stderr;
				my $exit_status;
				lives_ok(
					sub
					{
						$stderr = Capture::Tiny::capture_stderr(
							sub
							{
								$repository->run( 'commit', '-m', 'Test message.' );
								$exit_status = $? >> 8;
							}
						);
						note( $stderr );
					},
					'Commit the changes.',
				);

				like(
					$stderr,
					$test->{'expected'},
					"The output matches expected results.",
				);

				is(
					$exit_status,
					$test->{'exit_status'},
					'The exit status is correct.',
				);
			}
		);
	}

	return;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Test


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2013-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;


__DATA__

__[ default ]__
#!{interpreter_path}

use strict;
use warnings;

use lib qw( {libs} );

use App::GitHooks;


App::GitHooks->run(
    name      => $0,
    arguments => \@ARGV,
);

__[ devel_cover ]__
#!{interpreter_path}

use strict;
use warnings;

use lib qw( {libs} );

use Devel::Cover qw(
	-summary 0
	-silent 1
	-db {cover_db_path}
	+ignore .git
	-merge 1
);
use App::GitHooks;


App::GitHooks->run(
    name      => $0,
    arguments => \@ARGV,
);
