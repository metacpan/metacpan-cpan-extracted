package App::Actions::I18N::en;

use strict;
use warnings;
use utf8;

our $VERSION = '0.002.0';

# The English catalogue: message key to text, or to a hash that chooses a
# text by gender or plural category; see App::Actions::I18N for the shape.
# Every key here must also be in the English catalogue, with the same
# placeholders, which t/i18n.t checks.
my %MESSAGES = (
	'actions.workflow_file_required' => 'workflow_file is required',
	'actions.workflow_file_missing' => "Workflow file '%(file)s' does not exist",
	'actions.project_dir_required' => 'project_dir is required when the workflow is not inside .github/workflows',
	'actions.project_dir_missing' => "Project directory '%(dir)s' does not exist",
	'actions.document_required' => 'A document name is required',
	'actions.document_unknown' => "Unknown document '%(name)s'; expected %(expected)s",
	'actions.invalid_arguments' => 'Invalid arguments to %(routine)s: %(reason)s',
	'list.or' => '%(head)s or %(last)s',

	'workflow.file_required' => 'No workflow file given',
	'workflow.file_missing' => "Workflow file '%(file)s' does not exist",
	'workflow.parse_failed' => "Unable to parse workflow '%(file)s': %(error)s",
	'workflow.empty' => "Workflow '%(file)s' is empty",
	'workflow.not_mapping' => "Workflow '%(file)s' must contain a YAML mapping",
	'workflow.no_jobs' => "Workflow '%(file)s' has no 'jobs' mapping",
	'workflow.job_not_mapping' => "Job '%(job)s' must be a mapping",
	'workflow.job_no_steps' => "Job '%(job)s' has no 'steps' list",
	'workflow.container_invalid' => "Job '%(job)s' container must be a mapping or a string",
	'workflow.services_invalid' => "Job '%(job)s' services must be a mapping",
	'workflow.runs_on_invalid' => "'runs-on' must be a string or a list",
	'workflow.matrix_not_mapping' => 'strategy.matrix must be a mapping',
	'workflow.matrix_empty' => "Matrix key '%(key)s' must be a list with at least one value",
	'workflow.exclude_invalid' => 'Each matrix exclude entry must be a mapping',
	'workflow.include_invalid' => 'Each matrix include entry must be a mapping',
	'workflow.defaults_run_invalid' => '%(where)s run must be a mapping',

	'action.dir_required' => 'No action directory given',
	'action.dir_missing' => "Action directory '%(dir)s' does not exist",
	'action.no_metadata' => "No action.yml or action.yaml found in '%(dir)s'",
	'action.file_required' => 'No action metadata file given',
	'action.file_missing' => "Action metadata file '%(file)s' does not exist",
	'action.parse_failed' => "Unable to parse action metadata '%(file)s': %(error)s",
	'action.empty' => "Action metadata '%(file)s' is empty",
	'action.not_mapping' => "Action metadata '%(file)s' must contain a YAML mapping",
	'action.no_runs' => "Action metadata '%(file)s' has no 'runs' mapping",
	'action.no_using' => "Action metadata '%(file)s' has no 'runs.using'",
	'action.no_steps' => "Composite action '%(file)s' has no 'runs.steps' list",
	'action.no_main' => "JavaScript action '%(file)s' has no 'runs.main'",
	'action.inputs_invalid' => "The 'inputs' of '%(file)s' must be a mapping",
	'action.input_invalid' => "Input '%(name)s' of '%(file)s' must be a mapping",
	'action.outputs_invalid' => "The 'outputs' of '%(file)s' must be a mapping",
	'action.output_invalid' => "Output '%(name)s' of '%(file)s' must be a mapping",

	'step.not_mapping' => 'A step in %(where)s is not a mapping',
	'step.field_not_string' => "Step field '%(field)s' in %(where)s must be a string",
	'step.no_command' => "A step in %(where)s has neither 'run' nor 'uses'",
	'mapping.invalid' => '%(where)s must be a mapping',

	'where.job' => "job '%(job)s'",
	'where.file' => "'%(file)s'",
	'where.workflow_env' => 'workflow env',
	'where.workflow_defaults' => 'workflow defaults',
	'where.job_env' => "env of job '%(job)s'",
	'where.job_defaults' => "defaults of job '%(job)s'",
	'where.job_strategy' => "strategy of job '%(job)s'",
	'where.step_env' => 'env of a step in %(where)s',
	'where.step_with' => 'with of a step in %(where)s',

	'i18n.unknown_key' => "No message is defined for '%(key)s'",
	'i18n.unknown_language' => "Language '%(language)s' has no catalogue; using English",

	'span.second' => { plural => { one => '%(count)d second', other => '%(count)d seconds' } },
	'span.minute' => { plural => { one => '%(count)d minute', other => '%(count)d minutes' } },
	'span.hour' => { plural => { one => '%(count)d hour', other => '%(count)d hours' } },
	'span.day' => { plural => { one => '%(count)d day', other => '%(count)d days' } },
	'span.month' => { plural => { one => '%(count)d month', other => '%(count)d months' } },
	'span.year' => { plural => { one => '%(count)d year', other => '%(count)d years' } },

	'cache.summary' => { plural => { one => '%(count)d image.', other => '%(count)d images.' } },
	'cache.summary_sized' => {
		plural => {
			one => '%(count)d image, %(size)s on disk.',
			other => '%(count)d images, %(size)s on disk.',
		},
	},
	'cache.missing' => {
		plural => {
			one => '%(count)d image is no longer on the daemon.',
			other => '%(count)d images are no longer on the daemon.',
		},
	},
	'cache.removed' => {
		plural => {
			one => 'Removed %(count)d image, %(size)s freed.',
			other => 'Removed %(count)d images, %(size)s freed.',
		},
	},
	'cache.forgot' => {
		plural => {
			one => 'Forgot %(count)d image no longer on the daemon.',
			other => 'Forgot %(count)d images no longer on the daemon.',
		},
	},
	'cache.remove_failed' => {
		plural => { one => 'Could not remove %(count)d image:', other => 'Could not remove %(count)d images:' },
	},

	'logs.summary' => {
		plural => { one => '%(count)d log, %(size)s on disk.', other => '%(count)d logs, %(size)s on disk.' },
	},
	'logs.removed' => {
		plural => { one => 'Removed %(count)d log, %(size)s freed.', other => 'Removed %(count)d logs, %(size)s freed.' },
	},
	'logs.remove_failed' => {
		plural => { one => 'Could not remove %(count)d run:', other => 'Could not remove %(count)d runs:' },
	},
	# The text listings of the cache and logs commands.  The column headings
	# are padded to the widest entry, so a longer translation still lines up.
	'span.just_now' => 'just now',
	'span.ago' => '%(span)s ago',
	'cache.file' => 'Cache file: %(file)s',
	'cache.empty' => 'No images have been cached yet.',
	'cache.none_older' => 'No cached images are older than %(span)s.',
	'cache.only_older' => 'Only images older than %(span)s.',
	'cache.unreachable' => 'The Docker daemon is not reachable, so the sizes are unknown.',
	'cache.prune_hint' => 'Remove them with "action-run cache --prune".',
	'cache.unknown' => 'unknown',
	'cache.size_missing' => 'missing',
	'cache.heading.image' => 'IMAGE',
	'cache.heading.size' => 'SIZE',
	'cache.heading.last_used' => 'LAST USED',
	'cache.heading.age' => 'AGE',
	'logs.directory' => 'Logs directory: %(directory)s',
	'logs.empty' => 'No job logs have been kept yet.',
	'logs.none_older' => 'No job logs are older than %(span)s.',
	'logs.only_older' => 'Only job logs older than %(span)s.',
	'logs.prune_hint' => 'Remove them with "action-run logs --prune".',
	'logs.heading.run' => 'RUN',
	'logs.heading.log' => 'LOG',
	'logs.heading.size' => 'SIZE',
	'logs.heading.age' => 'AGE',
	# Printed by a child process between fork and exec.
	'process.redirect_failed' => "Unable to redirect %(stream)s to '%(file)s': %(error)s",
	'process.exec_failed' => "Unable to run '%(program)s': %(error)s",
	# The runner and its parts.  A text that begins with "action-run: " is a
	# warning printed as it stands; the others are part of a longer line or
	# are reported by the caller, which adds the prefix.
	'runner.workflow_required' => 'A workflow is required',
	'runner.project_dir_required' => 'A project directory is required',
	'runner.project_dir_missing' => "Project directory '%(dir)s' does not exist",
	'runner.pull_concurrency_invalid' => "pull concurrency must be a positive integer, not '%(value)s'",
	'runner.pull_conflict' => '--pull and --no-pull cannot be used together',
	'runner.interrupted' => 'Interrupted',
	'runner.terminated' => 'Terminated',
	'runner.error' => 'action-run: %(error)s',
	'runner.not_ready' => 'the environment is not ready; fix what the report above asks for, or pass --skip-check to run anyway',
	'runner.no_job_matched' => "No job matched '%(filter)s'",
	'runner.dependency_cycle' => "Dependency cycle involving job '%(job)s'",
	'runner.unknown_job' => "Unknown job '%(job)s'",
	'runner.need_not_selected' => "action-run: job '%(job)s' needs '%(need)s', which was not selected; assuming it succeeded",
	'runner.env_cycle' => "Environment variable '%(name)s' refers to itself, directly or through other variables",
	'runner.env_failed' => "Unable to evaluate environment variable '%(name)s': %(error)s",
	'runner.write_failed' => 'Unable to write %(what)s: %(error)s',
	'runner.file_write_failed' => "Unable to write '%(file)s': %(error)s",
	'runner.file_read_failed' => "Unable to read '%(file)s': %(error)s",
	'runner.network_failed' => "Failed to create Docker network '%(name)s' (exit %(status)s)",
	'runner.input_required' => "Action '%(uses)s' requires the input '%(name)s'",
	'runner.local_action_empty' => "Local action '%(uses)s' does not name a directory inside the project",
	'runner.local_action_escapes' => "Local action '%(uses)s' must not escape the project directory",

	'runner.preflight.buffer_failed' => 'Unable to buffer the preflight report: %(error)s',
	'runner.preflight.remedy_image' => 'check the image name, and that the registry is reachable and the Docker login is valid',
	'runner.preflight.schema_line' => '  schema    version %(version)s (action-run schema preflight)',
	'runner.preflight.schema_mismatch' => 'the action-run preflight --json document does not match App::Actions::Runner->json_schema',
	'runner.preflight.image' => '  image     %(name)s (%(source)s): %(status)s',
	'runner.preflight.deferred' => '  deferred  %(error)s',
	'runner.preflight.unnamed' => '(unnamed)',
	'runner.preflight.workflow' => 'the workflow',

	'runner.source.job' => "job '%(name)s'",
	'runner.source.service' => "service '%(id)s' of job '%(name)s'",
	'runner.source.action' => "action '%(uses)s' in job '%(name)s'",
	'runner.source.nested_action' => "action '%(uses)s' in local action '%(via)s' of job '%(name)s'",

	'runner.image.pulling' => 'Pulling image %(image)s...',
	'runner.image.pull_failed' => "Failed to pull Docker image '%(image)s' (exit %(status)s)",
	'runner.image.unresolved' => "cannot resolve the image '%(expression)s', needed by %(source)s: %(error)s",
	'runner.image.unprepared' => "cannot prepare the image '%(image)s', needed by %(source)s: %(error)s",
	'runner.image.empty' => 'the image name is empty',
	'runner.image.not_local' => "Docker image '%(image)s' is not available locally (--no-pull)",
	'runner.image.checking' => '  image     %(image)s (%(source)s)',
	'runner.image.cache_failed' => 'action-run: could not update the image cache: %(error)s',

	'runner.job.if_failed' => "action-run: unable to evaluate if for '%(name)s': %(error)s",
	'runner.job.skipped' => '==> Job: %(name)s (skipped)',
	'runner.job.fail_fast' => '==> Job: %(name)s (skipped by fail-fast)',
	'runner.job.continue_failed' => "action-run: unable to evaluate continue-on-error for '%(name)s': %(error)s",
	'runner.job.continued' => '!! Job failed but continue-on-error is set: %(name)s',
	'runner.job.not_linux' => "==> Job: %(name)s (skipped: runs-on '%(runs_on)s' is not Linux)",
	'runner.job.unsupported_runner' => 'unsupported runner: %(runs_on)s',
	'runner.job.start' => '==> Job: %(name)s',
	'runner.job.no_image' => "Unable to determine a container image for job '%(name)s'",
	'runner.job.image' => '    image: %(image)s',
	'runner.job.deferred' => '  deferred  %(expression)s (%(source)s)',

	'runner.parallel.did_not_run' => "job '%(name)s' did not run",
	'runner.parallel.dup_failed' => 'Unable to duplicate %(handle)s',
	'runner.parallel.restore_failed' => 'Unable to restore %(handle)s',

	'runner.service.not_mapping' => "Service '%(id)s' must be a mapping",
	'runner.service.no_image' => "Service '%(id)s' has no image",
	'runner.options_invalid' => "Unable to read the container options '%(options)s': a quote is not closed",
	'runner.service.credentials' => "action-run: service '%(id)s' credentials are not supported; using the local Docker login",
	'runner.service.start_failed' => "Failed to start service '%(id)s' (exit %(status)s)",
	'runner.what.service' => "Service '%(id)s'",
	'runner.what.job_container' => "Job container '%(name)s'",
	'runner.what.step_script' => "the step script '%(file)s'",
	'runner.what.step_file' => "the step file '%(file)s'",
	'runner.shared_files' => "action-run: the job runs as '%(user)s', so its runner directory %(dir)s is open to every user of this host, and the step scripts in it hold the workflow's secrets; run the job as your own user or as root to keep it private",
	'runner.what.sudo_shim' => 'the sudo shim',
	'runner.what.apt_shim' => 'the %(name)s shim',

	'runner.container.dead' => '%(what)s is dead',
	'runner.container.restarting' => '%(what)s is restarting',
	'runner.container.with_count' => '%(state)s (restart count %(count)s)',
	'runner.container.count_unknown' => '%(state)s (its restart count could not be read)',
	'runner.container.stopped' => '%(what)s did not stay running (exit %(status)s)',
	'runner.container.stopped_unknown' => '%(what)s did not stay running (its exit status could not be read)',
	'runner.container.start_failed' => '%(what)s could not be started (exit %(status)s)',
	'runner.container.at_fault' => '%(state)s; at fault: %(fault)s',
	'runner.container.silent' => '%(state)s; it printed nothing',
	'runner.container.output' => '%(state)s; its last output was:',
	'runner.container.daemon_silent' => '%(state)s; the daemon said nothing',
	'runner.container.daemon_said' => '%(state)s; the daemon said:',
	'runner.fault.image' => "the image '%(image)s'",
	'runner.fault.port' => 'the published port',
	'runner.fault.entrypoint' => "the entrypoint '%(entrypoint)s'",

	'runner.explain.service' => "Service '%(id)s' of job '%(job)s'",
	'runner.explain.job' => "Job '%(job)s'",
	'runner.explain.action' => "Action '%(uses)s' in job '%(job)s'",
	'runner.explain.title' => '==> %(title)s',
	'runner.explain.container' => '    container  %(name)s',
	'runner.explain.image' => '    image      %(image)s',
	'runner.explain.entrypoint' => '    entrypoint %(entrypoint)s',
	'runner.explain.command' => '    command    %(command)s',
	'runner.explain.image_own' => "(the image's own)",

	'runner.step.env_failed' => "action-run: unable to evaluate environment for step '%(step)s': %(error)s",
	'runner.step.if_failed' => "action-run: unable to evaluate if for step '%(step)s': %(error)s",
	'runner.step.skipped' => '--- Step: %(name)s (skipped)',
	'runner.step.start' => '--- Step: %(name)s',
	'runner.step.summary_header' => '--- Step summary ---',
	'runner.step.continue_failed' => 'action-run: unable to evaluate continue-on-error: %(error)s',
	'runner.step.continued' => '!! Step failed but continue-on-error is set',
	'runner.step.failed_default' => 'step failed',
	'runner.step.failure' => '!! %(message)s',
	'runner.step.exited' => 'step exited with status %(status)s',
	'runner.step.default_name' => 'Step %(number)s',
	'runner.post.if_failed' => "action-run: unable to evaluate the post condition for '%(uses)s': %(error)s",
	'runner.post.start' => '--- Step: Post %(uses)s',
	'runner.post.failed' => "action-run: post step for '%(uses)s' failed: %(error)s",
	'runner.post.exited' => "!! post step for '%(uses)s' exited with status %(status)s",
	'runner.shell.missing' => "Shell '%(shell)s' is not available in the container",
	'runner.script.begin' => '--- script ---',
	'runner.script.end' => '--- end script ---',
	'runner.checkout.path' => "action-run: actions/checkout 'path' is ignored; the repository is mounted at /github/workspace",
	'runner.checkout.submodules' => 'action-run: actions/checkout submodules are not fetched; using the checkout as-is',
	'runner.checkout.ref' => 'action-run: actions/checkout ref/repository is ignored; using the local checkout',
	'runner.noop' => '    (%(message)s)',
	'runner.noop.checkout' => 'repository already mounted at /github/workspace',
	'runner.noop.perl' => 'using container image for Perl',
	'runner.noop.perl_version' => 'using container image for Perl %(version)s',
	'runner.noop.cache' => 'caching, artifacts, and coverage uploads are not implemented',
	'runner.unsupported.remote' => 'remote JavaScript and composite actions are not supported',
	'runner.unsupported.using' => "local actions that use '%(using)s' are not supported",
	'runner.unsupported.skipped' => "action '%(action)s' skipped: %(reason)s",
	'runner.unsupported.note' => '    (skipped: %(reason)s)',
	'runner.docker_action.no_image' => "Docker action '%(uses)s' in job '%(job)s' has no image name; check the expression it uses",
	'runner.docker_action.bad_args' => "Unable to read the args of '%(uses)s' ('%(args)s'): a quote is not closed",
	'runner.docker_action.bad_image' => "Docker action '%(uses)s' in job '%(job)s' resolved to '%(image)s', which is not an image name; check the expression it uses",
	'runner.docker_action.exited' => 'docker action exited with status %(status)s',
	'runner.local_action.missing' => "Local action '%(uses)s' does not exist (looked in %(dir)s)",
	'runner.composite.too_deep' => "Composite action '%(uses)s' is nested more than %(depth)s levels deep",
	'runner.composite.failed' => "composite action '%(uses)s' failed",
	'runner.javascript.no_node' => "JavaScript action '%(uses)s' needs Node.js, but 'node' was not found in the job container",
	'runner.javascript.pre_if_failed' => "action-run: unable to evaluate pre-if for '%(uses)s': %(error)s",
	'runner.javascript.pre_exited' => "pre step of JavaScript action '%(uses)s' exited with status %(status)s",
	'runner.javascript.exited' => "JavaScript action '%(uses)s' exited with status %(status)s",

	'runner.summary.header' => '=== Workflow summary ===',
	'runner.summary.none' => '  No jobs were run.',
	'runner.summary.failed' => 'Workflow FAILED',
	'runner.summary.succeeded' => 'Workflow succeeded',
	'runner.logs.kept' => 'Job logs kept in %(dir)s',
	'runner.logs.keep_failed' => 'action-run: could not keep the job logs: %(error)s',
	'runner.logs.copy_failed' => "cannot copy '%(from)s' to '%(to)s': %(error)s",
	'runner.logs.bad_name' => "'%(name)s' is not a plain file name",
	'runner.kept.header' => 'Kept Docker resources:',
	'runner.kept.container' => '  container %(name)s',
	'runner.kept.network' => '  network %(name)s',
	'runner.kept.temp' => '  temporary directory %(dir)s',
);

# messages
# Purpose:     Hand the catalogue to App::Actions::I18N.
# Entry:       None.
# Exit status: Returns a new hash reference, so the caller may change it.
# Side effects: None.
sub messages {
	return { %MESSAGES };
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::I18N::en - the English message catalogue of App::Actions

=head1 SYNOPSIS

You do not normally use this module directly.  Choose the language through
L<App::Actions::I18N>:

	use App::Actions::I18N;

	my $i18n = App::Actions::I18N->new(language => 'en');
	binmode STDOUT, ':encoding(UTF-8)';
	print $i18n->message('workflow.empty', { file => 'ci.yml' }), "\n";
	# Workflow 'ci.yml' is empty

Or for a whole run of the command:

	ACTION_RUN_LANG=en action-run run .github/workflows/ci.yml

Read the catalogue itself, for example to check a translation:

	use App::Actions::I18N::en;

	my $entries = App::Actions::I18N::en->messages;
	print scalar(keys %{$entries}), " messages\n";

=head1 DESCRIPTION

This module holds the English texts of App::Actions' messages.

Data only: L<App::Actions::I18N> loads it and renders its entries.  Keys,
placeholders and the plural and gender forms are described there.

=head1 METHODS

=head2 messages

Returns a hash reference of message key to entry.

=head3 EXAMPLE

	my $entries = App::Actions::I18N::en->messages;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => q{hashref} }

=head3 MESSAGES

None.

=head1 COMMON PITFALLS

=over 4

=item * B<Do not change the returned hash to translate.>  L</messages>
returns a copy, so changes to it are lost.  Use
L<App::Actions::I18N/add_messages>.

=item * B<Keep the placeholders.>  A translation must use the same
placeholder names as the English text, for example C<%(file)s>.  The test
F<t/i18n.t> checks this.

=item * B<Plurals follow the English rule.>  1 for one thing, anything else for many: C<1 image>, C<2 images>, C<0 images>.

=item * B<C<LANG> does not choose this language.>  Use C<ACTION_RUN_LANG=en>
or the C<language> argument.

=back

=head1 ENCODING

The source file is UTF-8 and uses C<use utf8>, so every text is a Perl
character string.  The texts are plain ASCII today, but may contain any
Unicode character.  Encode the text when you print it, for example with
C<binmode STDOUT, ':encoding(UTF-8)'>, or Perl prints a "Wide character"
warning.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.  It is for readers who want to check exactly what a routine
promises.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞState> means the routine changes
nothing, and C<ΔState> means it can change the state.  The lines below the
rule are the conditions that are always true when the routine returns.

	KEY == { k : seq CHAR | k matches [a-z][a-z0-9_]*(\.[a-z0-9_]+)+ }
	ENTRY ::= text⟨⟨seq CHAR⟩⟩
	        | plural⟨⟨{one, other} ⇸ seq CHAR⟩⟩
	        | gender⟨⟨{female, male, other} ⇸ ENTRY⟩⟩
	MESSAGES : KEY ⇸ ENTRY             the fixed catalogue in this file

=head2 messages

	┌─ Messages ────────────────────────────────────────
	│ r! : KEY ⇸ ENTRY
	├───────────────────────────────────────────────────
	│ r! = MESSAGES
	│ r! is a new hash each call: changing it leaves MESSAGES unchanged
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The catalogue never changes.  This is how one of its texts is used:

	 App::Actions::I18N->new(language => 'en')
	 (or ACTION_RUN_LANG=en, or a country that speaks English)
	        |
	        v
	+---------------------+  message($key, \%args)
	| TRANSLATOR (en)   |------------------------+
	+---------------------+                        |
	                                               v
	                      +-------------------------------------+
	                      | $key in this catalogue?             |
	                      +-------------------------------------+
	                           | yes                     | no
	                           v                         v
	                  +----------------+      +----------------------+
	                  | entry from     |      | English entry        |
	                  | this module    |      | (App::Actions::I18N::|
	                  +----------------+      |  en); none: the key  |
	                           |              +----------------------+
	                           +-----------+-----------+
	                                       v
	                  gender form, then plural form (English rule),
	                  then the %(name)s placeholders filled in
	                                       |
	                                       v
	                               the finished text

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
