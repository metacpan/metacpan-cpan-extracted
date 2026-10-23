package App::Actions::I18N::de;

use strict;
use warnings;
use utf8;

our $VERSION = '0.001.0';

# The German catalogue: message key to text, or to a hash that chooses a
# text by gender or plural category; see App::Actions::I18N for the shape.
# Every key here must also be in the English catalogue, with the same
# placeholders, which t/i18n.t checks.
my %MESSAGES = (
	'actions.workflow_file_required' => 'workflow_file ist erforderlich',
	'actions.workflow_file_missing' => "Die Workflow-Datei '%(file)s' existiert nicht",
	'actions.project_dir_required' => 'project_dir ist erforderlich, wenn der Workflow nicht in .github/workflows liegt',
	'actions.project_dir_missing' => "Das Projektverzeichnis '%(dir)s' existiert nicht",
	'actions.document_required' => 'Ein Dokumentname ist erforderlich',
	'actions.document_unknown' => "Unbekanntes Dokument '%(name)s'; erwartet: %(expected)s",
	'actions.invalid_arguments' => 'Ungültige Argumente für %(routine)s: %(reason)s',
	'list.or' => '%(head)s oder %(last)s',

	'workflow.file_required' => 'Keine Workflow-Datei angegeben',
	'workflow.file_missing' => "Die Workflow-Datei '%(file)s' existiert nicht",
	'workflow.parse_failed' => "Der Workflow '%(file)s' kann nicht gelesen werden: %(error)s",
	'workflow.empty' => "Der Workflow '%(file)s' ist leer",
	'workflow.not_mapping' => "Der Workflow '%(file)s' muss ein YAML-Mapping enthalten",
	'workflow.no_jobs' => "Der Workflow '%(file)s' hat kein 'jobs'-Mapping",
	'workflow.job_not_mapping' => "Der Job '%(job)s' muss ein Mapping sein",
	'workflow.job_no_steps' => "Der Job '%(job)s' hat keine 'steps'-Liste",
	'workflow.container_invalid' => "Der Container des Jobs '%(job)s' muss ein Mapping oder eine Zeichenkette sein",
	'workflow.services_invalid' => "Die Services des Jobs '%(job)s' müssen ein Mapping sein",
	'workflow.runs_on_invalid' => "'runs-on' muss eine Zeichenkette oder eine Liste sein",
	'workflow.matrix_not_mapping' => 'strategy.matrix muss ein Mapping sein',
	'workflow.matrix_empty' => "Der Matrix-Schlüssel '%(key)s' muss eine Liste mit mindestens einem Wert sein",
	'workflow.exclude_invalid' => "Jeder 'exclude'-Eintrag der Matrix muss ein Mapping sein",
	'workflow.include_invalid' => "Jeder 'include'-Eintrag der Matrix muss ein Mapping sein",
	'workflow.defaults_run_invalid' => '%(where)s: run muss ein Mapping sein',

	'action.dir_required' => 'Kein Action-Verzeichnis angegeben',
	'action.dir_missing' => "Das Action-Verzeichnis '%(dir)s' existiert nicht",
	'action.no_metadata' => "Keine action.yml oder action.yaml in '%(dir)s' gefunden",
	'action.file_required' => 'Keine Action-Metadatendatei angegeben',
	'action.file_missing' => "Die Action-Metadatendatei '%(file)s' existiert nicht",
	'action.parse_failed' => "Die Action-Metadaten '%(file)s' können nicht gelesen werden: %(error)s",
	'action.empty' => "Die Action-Metadaten '%(file)s' sind leer",
	'action.not_mapping' => "Die Action-Metadaten '%(file)s' müssen ein YAML-Mapping enthalten",
	'action.no_runs' => "Die Action-Metadaten '%(file)s' haben kein 'runs'-Mapping",
	'action.no_using' => "Die Action-Metadaten '%(file)s' haben kein 'runs.using'",
	'action.no_steps' => "Die Composite-Action '%(file)s' hat keine 'runs.steps'-Liste",
	'action.no_main' => "Die JavaScript-Action '%(file)s' hat kein 'runs.main'",
	'action.inputs_invalid' => "Die 'inputs' von '%(file)s' müssen ein Mapping sein",
	'action.input_invalid' => "Die Eingabe '%(name)s' von '%(file)s' muss ein Mapping sein",
	'action.outputs_invalid' => "Die 'outputs' von '%(file)s' müssen ein Mapping sein",
	'action.output_invalid' => "Die Ausgabe '%(name)s' von '%(file)s' muss ein Mapping sein",

	'step.not_mapping' => 'Ein Schritt in %(where)s ist kein Mapping',
	'step.field_not_string' => "Das Schrittfeld '%(field)s' in %(where)s muss eine Zeichenkette sein",
	'step.no_command' => "Ein Schritt in %(where)s hat weder 'run' noch 'uses'",
	'mapping.invalid' => '%(where)s muss ein Mapping sein',

	'where.job' => "Job '%(job)s'",
	'where.file' => "'%(file)s'",
	'where.workflow_env' => 'env des Workflows',
	'where.workflow_defaults' => 'defaults des Workflows',
	'where.job_env' => "env des Jobs '%(job)s'",
	'where.job_defaults' => "defaults des Jobs '%(job)s'",
	'where.job_strategy' => "strategy des Jobs '%(job)s'",
	'where.step_env' => 'env eines Schritts in %(where)s',
	'where.step_with' => 'with eines Schritts in %(where)s',

	'i18n.unknown_key' => "Für '%(key)s' ist keine Meldung definiert",
	'i18n.unknown_language' => "Für die Sprache '%(language)s' gibt es keinen Katalog; Englisch wird verwendet",

	'span.second' => { plural => { one => '%(count)d Sekunde', other => '%(count)d Sekunden' } },
	'span.minute' => { plural => { one => '%(count)d Minute', other => '%(count)d Minuten' } },
	'span.hour' => { plural => { one => '%(count)d Stunde', other => '%(count)d Stunden' } },
	'span.day' => { plural => { one => '%(count)d Tag', other => '%(count)d Tage' } },
	'span.month' => { plural => { one => '%(count)d Monat', other => '%(count)d Monate' } },
	'span.year' => { plural => { one => '%(count)d Jahr', other => '%(count)d Jahre' } },

	'cache.summary' => { plural => { one => '%(count)d Image.', other => '%(count)d Images.' } },
	'cache.summary_sized' => {
		plural => {
			one => '%(count)d Image, %(size)s auf der Festplatte.',
			other => '%(count)d Images, %(size)s auf der Festplatte.',
		},
	},
	'cache.missing' => {
		plural => {
			one => '%(count)d Image ist nicht mehr auf dem Daemon.',
			other => '%(count)d Images sind nicht mehr auf dem Daemon.',
		},
	},
	'cache.removed' => {
		plural => {
			one => '%(count)d Image entfernt, %(size)s freigegeben.',
			other => '%(count)d Images entfernt, %(size)s freigegeben.',
		},
	},
	'cache.forgot' => {
		plural => {
			one => '%(count)d Image vergessen, das nicht mehr auf dem Daemon ist.',
			other => '%(count)d Images vergessen, die nicht mehr auf dem Daemon sind.',
		},
	},
	'cache.remove_failed' => {
		plural => {
			one => '%(count)d Image konnte nicht entfernt werden:',
			other => '%(count)d Images konnten nicht entfernt werden:',
		},
	},

	'logs.summary' => {
		plural => {
			one => '%(count)d Log, %(size)s auf der Festplatte.',
			other => '%(count)d Logs, %(size)s auf der Festplatte.',
		},
	},
	'logs.removed' => {
		plural => {
			one => '%(count)d Log entfernt, %(size)s freigegeben.',
			other => '%(count)d Logs entfernt, %(size)s freigegeben.',
		},
	},
	'logs.remove_failed' => {
		plural => {
			one => '%(count)d Lauf konnte nicht entfernt werden:',
			other => '%(count)d Läufe konnten nicht entfernt werden:',
		},
	},
	# The runner and its parts.  "action-run: " is the program's name and is
	# not translated; the line markers (==>, ---, !!) are kept too.
	'runner.workflow_required' => 'Ein Workflow ist erforderlich',
	'runner.project_dir_required' => 'Ein Projektverzeichnis ist erforderlich',
	'runner.project_dir_missing' => "Das Projektverzeichnis '%(dir)s' existiert nicht",
	'runner.pull_concurrency_invalid' => "Die Download-Parallelität muss eine positive ganze Zahl sein, nicht '%(value)s'",
	'runner.pull_conflict' => '--pull und --no-pull können nicht zusammen verwendet werden',
	'runner.interrupted' => 'Unterbrochen',
	'runner.terminated' => 'Beendet',
	'runner.error' => 'action-run: %(error)s',
	'runner.not_ready' => 'Die Umgebung ist nicht bereit; beheben Sie, was der Bericht oben verlangt, oder geben Sie --skip-check an, um trotzdem zu starten',
	'runner.no_job_matched' => "Kein Job passt zu '%(filter)s'",
	'runner.dependency_cycle' => "Abhängigkeitszyklus mit Job '%(job)s'",
	'runner.unknown_job' => "Unbekannter Job '%(job)s'",
	'runner.need_not_selected' => "action-run: Job '%(job)s' braucht '%(need)s', der nicht ausgewählt ist; er gilt als erfolgreich",
	'runner.env_failed' => "Die Umgebungsvariable '%(name)s' kann nicht ausgewertet werden: %(error)s",
	'runner.write_failed' => '%(what)s kann nicht geschrieben werden: %(error)s',
	'runner.file_write_failed' => "'%(file)s' kann nicht geschrieben werden: %(error)s",
	'runner.file_read_failed' => "'%(file)s' kann nicht gelesen werden: %(error)s",
	'runner.network_failed' => "Das Docker-Netzwerk '%(name)s' konnte nicht angelegt werden (Status %(status)s)",
	'runner.input_required' => "Die Action '%(uses)s' erfordert die Eingabe '%(name)s'",
	'runner.local_action_empty' => "Die lokale Action '%(uses)s' bezeichnet kein Verzeichnis im Projekt",
	'runner.local_action_escapes' => "Die lokale Action '%(uses)s' darf das Projektverzeichnis nicht verlassen",

	'runner.preflight.buffer_failed' => 'Der Preflight-Bericht kann nicht gepuffert werden: %(error)s',
	'runner.preflight.remedy_image' => 'Prüfen Sie den Image-Namen, ob die Registry erreichbar ist und ob die Docker-Anmeldung gültig ist',
	'runner.preflight.schema_line' => '  Schema    Version %(version)s (action-run schema preflight)',
	'runner.preflight.schema_mismatch' => 'Das Dokument von action-run preflight --json entspricht nicht App::Actions::Runner->json_schema',
	'runner.preflight.image' => '  Image     %(name)s (%(source)s): %(status)s',
	'runner.preflight.deferred' => '  später    %(error)s',
	'runner.preflight.unnamed' => '(unbenannt)',
	'runner.preflight.workflow' => 'der Workflow',

	'runner.source.job' => "Job '%(name)s'",
	'runner.source.service' => "Dienst '%(id)s' von Job '%(name)s'",
	'runner.source.action' => "Action '%(uses)s' in Job '%(name)s'",
	'runner.source.nested_action' => "Action '%(uses)s' in der lokalen Action '%(via)s' von Job '%(name)s'",

	'runner.image.pulling' => 'Lade Image %(image)s...',
	'runner.image.pull_failed' => "Das Docker-Image '%(image)s' konnte nicht geladen werden (Status %(status)s)",
	'runner.image.unresolved' => "Das Image '%(expression)s', benötigt von %(source)s, kann nicht aufgelöst werden: %(error)s",
	'runner.image.unprepared' => "Das Image '%(image)s', benötigt von %(source)s, kann nicht bereitgestellt werden: %(error)s",
	'runner.image.empty' => 'der Image-Name ist leer',
	'runner.image.not_local' => "Das Docker-Image '%(image)s' ist lokal nicht vorhanden (--no-pull)",
	'runner.image.checking' => '  Image     %(image)s (%(source)s)',
	'runner.image.cache_failed' => 'action-run: Der Image-Cache konnte nicht aktualisiert werden: %(error)s',

	'runner.job.if_failed' => "action-run: if für '%(name)s' kann nicht ausgewertet werden: %(error)s",
	'runner.job.skipped' => '==> Job: %(name)s (übersprungen)',
	'runner.job.fail_fast' => '==> Job: %(name)s (wegen fail-fast übersprungen)',
	'runner.job.no_result' => 'der Job hat kein Ergebnis gemeldet',
	'runner.job.continue_failed' => "action-run: continue-on-error für '%(name)s' kann nicht ausgewertet werden: %(error)s",
	'runner.job.continued' => '!! Job fehlgeschlagen, aber continue-on-error ist gesetzt: %(name)s',
	'runner.job.not_linux' => "==> Job: %(name)s (übersprungen: runs-on '%(runs_on)s' ist nicht Linux)",
	'runner.job.unsupported_runner' => 'nicht unterstützter Runner: %(runs_on)s',
	'runner.job.start' => '==> Job: %(name)s',
	'runner.job.no_image' => "Für Job '%(name)s' lässt sich kein Container-Image bestimmen",
	'runner.job.image' => '    Image: %(image)s',
	'runner.job.deferred' => '  später    %(expression)s (%(source)s)',
	'runner.job.did_not_run' => 'der Job ist nicht gelaufen',

	'runner.parallel.did_not_run' => "Job '%(name)s' ist nicht gelaufen",
	'runner.parallel.dup_failed' => '%(handle)s kann nicht dupliziert werden',
	'runner.parallel.restore_failed' => '%(handle)s kann nicht wiederhergestellt werden',

	'runner.service.not_mapping' => "Der Dienst '%(id)s' muss ein Mapping sein",
	'runner.service.no_image' => "Der Dienst '%(id)s' hat kein Image",
	'runner.service.credentials' => "action-run: Zugangsdaten für den Dienst '%(id)s' werden nicht unterstützt; die lokale Docker-Anmeldung wird verwendet",
	'runner.service.start_failed' => "Der Dienst '%(id)s' konnte nicht gestartet werden (Status %(status)s)",
	'runner.what.service' => "Dienst '%(id)s'",
	'runner.what.job_container' => "Job-Container '%(name)s'",
	'runner.what.step_script' => "das Schrittskript '%(file)s'",
	'runner.what.step_file' => "die Schrittdatei '%(file)s'",
	'runner.shared_files' => "action-run: Der Job läuft als '%(user)s', daher ist sein Runner-Verzeichnis %(dir)s für alle Benutzer dieses Rechners offen, und die Schrittskripte darin enthalten die Secrets des Workflows; führen Sie den Job als Ihr eigener Benutzer oder als root aus, um es privat zu halten",
	'runner.what.sudo_shim' => 'der sudo-Ersatz',
	'runner.what.apt_shim' => 'der %(name)s-Ersatz',

	'runner.container.dead' => '%(what)s ist tot',
	'runner.container.restarting' => '%(what)s wird neu gestartet',
	'runner.container.with_count' => '%(state)s (Neustarts: %(count)s)',
	'runner.container.count_unknown' => '%(state)s (die Zahl der Neustarts war nicht lesbar)',
	'runner.container.stopped' => '%(what)s lief nicht weiter (Status %(status)s)',
	'runner.container.stopped_unknown' => '%(what)s lief nicht weiter (der Exit-Status war nicht lesbar)',
	'runner.container.start_failed' => '%(what)s konnte nicht gestartet werden (Status %(status)s)',
	'runner.container.at_fault' => '%(state)s; Ursache: %(fault)s',
	'runner.container.silent' => '%(state)s; er hat nichts ausgegeben',
	'runner.container.output' => '%(state)s; seine letzte Ausgabe war:',
	'runner.container.daemon_silent' => '%(state)s; der Daemon hat nichts gemeldet',
	'runner.container.daemon_said' => '%(state)s; der Daemon meldete:',
	'runner.fault.image' => "das Image '%(image)s'",
	'runner.fault.image_unnamed' => 'das Image',
	'runner.fault.port' => 'der veröffentlichte Port',
	'runner.fault.entrypoint' => "der Entrypoint '%(entrypoint)s'",

	'runner.explain.service' => "Dienst '%(id)s' von Job '%(job)s'",
	'runner.explain.job' => "Job '%(job)s'",
	'runner.explain.action' => "Action '%(uses)s' in Job '%(job)s'",
	'runner.explain.title' => '==> %(title)s',
	'runner.explain.container' => '    Container  %(name)s',
	'runner.explain.image' => '    Image      %(image)s',
	'runner.explain.entrypoint' => '    Entrypoint %(entrypoint)s',
	'runner.explain.command' => '    Befehl     %(command)s',
	'runner.explain.image_own' => '(der des Images)',

	'runner.step.env_failed' => "action-run: Die Umgebung für Schritt '%(step)s' kann nicht ausgewertet werden: %(error)s",
	'runner.step.if_failed' => "action-run: if für Schritt '%(step)s' kann nicht ausgewertet werden: %(error)s",
	'runner.step.skipped' => '--- Schritt: %(name)s (übersprungen)',
	'runner.step.start' => '--- Schritt: %(name)s',
	'runner.step.summary_header' => '--- Zusammenfassung des Schritts ---',
	'runner.step.continue_failed' => 'action-run: continue-on-error kann nicht ausgewertet werden: %(error)s',
	'runner.step.continued' => '!! Schritt fehlgeschlagen, aber continue-on-error ist gesetzt',
	'runner.step.failed_default' => 'Schritt fehlgeschlagen',
	'runner.step.failure' => '!! %(message)s',
	'runner.step.exited' => 'der Schritt endete mit Status %(status)s',
	'runner.step.default_name' => 'Schritt %(number)s',
	'runner.post.if_failed' => "action-run: Die Post-Bedingung für '%(uses)s' kann nicht ausgewertet werden: %(error)s",
	'runner.post.start' => '--- Schritt: Post %(uses)s',
	'runner.post.failed' => "action-run: Der Post-Schritt für '%(uses)s' ist fehlgeschlagen: %(error)s",
	'runner.post.exited' => "!! Der Post-Schritt für '%(uses)s' endete mit Status %(status)s",
	'runner.shell.missing' => "Die Shell '%(shell)s' ist im Container nicht verfügbar",
	'runner.script.begin' => '--- Skript ---',
	'runner.script.end' => '--- Ende des Skripts ---',
	'runner.checkout.path' => "action-run: 'path' von actions/checkout wird ignoriert; das Repository ist unter /github/workspace eingehängt",
	'runner.checkout.submodules' => 'action-run: Submodule von actions/checkout werden nicht geholt; der Checkout wird unverändert verwendet',
	'runner.checkout.ref' => 'action-run: ref/repository von actions/checkout wird ignoriert; der lokale Checkout wird verwendet',
	'runner.noop' => '    (%(message)s)',
	'runner.noop.checkout' => 'Repository ist bereits unter /github/workspace eingehängt',
	'runner.noop.perl' => 'Container-Image wird für Perl verwendet',
	'runner.noop.perl_version' => 'Container-Image wird für Perl %(version)s verwendet',
	'runner.noop.cache' => 'Caching, Artefakte und Coverage-Uploads sind nicht implementiert',
	'runner.unsupported.remote' => 'entfernte JavaScript- und Composite-Actions werden nicht unterstützt',
	'runner.unsupported.using' => "lokale Actions mit '%(using)s' werden nicht unterstützt",
	'runner.unsupported.skipped' => "Action '%(action)s' übersprungen: %(reason)s",
	'runner.unsupported.note' => '    (übersprungen: %(reason)s)',
	'runner.docker_action.no_image' => "Die Docker-Action '%(uses)s' in Job '%(job)s' hat keinen Image-Namen; prüfen Sie den verwendeten Ausdruck",
	'runner.docker_action.bad_image' => "Die Docker-Action '%(uses)s' in Job '%(job)s' ergibt '%(image)s', was kein Image-Name ist; prüfen Sie den verwendeten Ausdruck",
	'runner.docker_action.exited' => 'die Docker-Action endete mit Status %(status)s',
	'runner.local_action.missing' => "Die lokale Action '%(uses)s' existiert nicht (gesucht in %(dir)s)",
	'runner.composite.too_deep' => "Die Composite-Action '%(uses)s' ist mehr als %(depth)s Ebenen tief verschachtelt",
	'runner.composite.failed' => "Die Composite-Action '%(uses)s' ist fehlgeschlagen",
	'runner.javascript.no_node' => "Die JavaScript-Action '%(uses)s' braucht Node.js, aber 'node' wurde im Job-Container nicht gefunden",
	'runner.javascript.pre_if_failed' => "action-run: pre-if für '%(uses)s' kann nicht ausgewertet werden: %(error)s",
	'runner.javascript.pre_exited' => "Der Pre-Schritt der JavaScript-Action '%(uses)s' endete mit Status %(status)s",
	'runner.javascript.exited' => "Die JavaScript-Action '%(uses)s' endete mit Status %(status)s",

	'runner.summary.header' => '=== Zusammenfassung des Workflows ===',
	'runner.summary.none' => '  Es wurden keine Jobs ausgeführt.',
	'runner.summary.failed' => 'Workflow FEHLGESCHLAGEN',
	'runner.summary.succeeded' => 'Workflow erfolgreich',
	'runner.logs.kept' => 'Job-Protokolle aufbewahrt in %(dir)s',
	'runner.logs.keep_failed' => 'action-run: Die Job-Protokolle konnten nicht aufbewahrt werden: %(error)s',
	'runner.logs.copy_failed' => "'%(from)s' kann nicht nach '%(to)s' kopiert werden: %(error)s",
	'runner.kept.header' => 'Aufbewahrte Docker-Ressourcen:',
	'runner.kept.container' => '  Container %(name)s',
	'runner.kept.network' => '  Netzwerk %(name)s',
	'runner.kept.temp' => '  temporäres Verzeichnis %(dir)s',
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

App::Actions::I18N::de - the German message catalogue of App::Actions

=head1 SYNOPSIS

You do not normally use this module directly.  Choose the language through
L<App::Actions::I18N>:

	use App::Actions::I18N;

	my $i18n = App::Actions::I18N->new(language => 'de');
	binmode STDOUT, ':encoding(UTF-8)';
	print $i18n->message('workflow.empty', { file => 'ci.yml' }), "\n";
	# Der Workflow 'ci.yml' ist leer

Or for a whole run of the command:

	ACTION_RUN_LANG=de action-run run .github/workflows/ci.yml

Read the catalogue itself, for example to check a translation:

	use App::Actions::I18N::de;

	my $entries = App::Actions::I18N::de->messages;
	print scalar(keys %{$entries}), " messages\n";

=head1 DESCRIPTION

This module holds the German texts of App::Actions' messages.  A key that is missing here is shown in English
instead.

Data only: L<App::Actions::I18N> loads it and renders its entries.  Keys,
placeholders and the plural and gender forms are described there.

=head1 METHODS

=head2 messages

Returns a hash reference of message key to entry.

=head3 EXAMPLE

	my $entries = App::Actions::I18N::de->messages;

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

=item * B<Plurals follow the German rule.>  1 uses the C<one> form (C<1 Image>), every other number the C<other> form (C<2 Images>).

=item * B<C<LANG> does not choose this language.>  Use C<ACTION_RUN_LANG=de>
or the C<language> argument.

=back

=head1 ENCODING

The source file is UTF-8 and uses C<use utf8>, so every text is a Perl
character string.  The texts contain non-ASCII characters (letters such as
C<E<uuml>> and C<E<szlig>>), and may contain any Unicode character.  Encode
the text when you print it, for example with C<binmode STDOUT,
':encoding(UTF-8)'>, or Perl prints a "Wide character" warning.

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

	 App::Actions::I18N->new(language => 'de')
	 (or ACTION_RUN_LANG=de, or a country that speaks German)
	        |
	        v
	+---------------------+  message($key, \%args)
	| TRANSLATOR (de)   |------------------------+
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
	                  gender form, then plural form (German rule),
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
