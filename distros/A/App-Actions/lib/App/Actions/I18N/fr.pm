package App::Actions::I18N::fr;

use strict;
use warnings;
use utf8;

our $VERSION = '0.002.0';

# The French catalogue: message key to text, or to a hash that chooses a
# text by gender or plural category; see App::Actions::I18N for the shape.
# Every key here must also be in the English catalogue, with the same
# placeholders, which t/i18n.t checks.
my %MESSAGES = (
	'actions.workflow_file_required' => 'workflow_file est obligatoire',
	'actions.workflow_file_missing' => "Le fichier de workflow '%(file)s' n'existe pas",
	'actions.project_dir_required' => "project_dir est obligatoire quand le workflow n'est pas dans .github/workflows",
	'actions.project_dir_missing' => "Le répertoire de projet '%(dir)s' n'existe pas",
	'actions.document_required' => 'Un nom de document est obligatoire',
	'actions.document_unknown' => "Document inconnu '%(name)s' ; attendu : %(expected)s",
	'actions.invalid_arguments' => 'Arguments invalides pour %(routine)s : %(reason)s',
	'list.or' => '%(head)s ou %(last)s',

	'workflow.file_required' => 'Aucun fichier de workflow fourni',
	'workflow.file_missing' => "Le fichier de workflow '%(file)s' n'existe pas",
	'workflow.parse_failed' => "Impossible d'analyser le workflow '%(file)s' : %(error)s",
	'workflow.empty' => "Le workflow '%(file)s' est vide",
	'workflow.not_mapping' => "Le workflow '%(file)s' doit contenir un mapping YAML",
	'workflow.no_jobs' => "Le workflow '%(file)s' n'a pas de mapping 'jobs'",
	'workflow.job_not_mapping' => "Le job '%(job)s' doit être un mapping",
	'workflow.job_no_steps' => "Le job '%(job)s' n'a pas de liste 'steps'",
	'workflow.container_invalid' => "Le container du job '%(job)s' doit être un mapping ou une chaîne",
	'workflow.services_invalid' => "Les services du job '%(job)s' doivent être un mapping",
	'workflow.runs_on_invalid' => "'runs-on' doit être une chaîne ou une liste",
	'workflow.matrix_not_mapping' => 'strategy.matrix doit être un mapping',
	'workflow.matrix_empty' => "La clé de matrice '%(key)s' doit être une liste d'au moins une valeur",
	'workflow.exclude_invalid' => "Chaque entrée 'exclude' de la matrice doit être un mapping",
	'workflow.include_invalid' => "Chaque entrée 'include' de la matrice doit être un mapping",
	'workflow.defaults_run_invalid' => '%(where)s : run doit être un mapping',

	'action.dir_required' => "Aucun répertoire d'action fourni",
	'action.dir_missing' => "Le répertoire d'action '%(dir)s' n'existe pas",
	'action.no_metadata' => "Aucun action.yml ni action.yaml trouvé dans '%(dir)s'",
	'action.file_required' => "Aucun fichier de métadonnées d'action fourni",
	'action.file_missing' => "Le fichier de métadonnées d'action '%(file)s' n'existe pas",
	'action.parse_failed' => "Impossible d'analyser les métadonnées d'action '%(file)s' : %(error)s",
	'action.empty' => "Les métadonnées d'action '%(file)s' sont vides",
	'action.not_mapping' => "Les métadonnées d'action '%(file)s' doivent contenir un mapping YAML",
	'action.no_runs' => "Les métadonnées d'action '%(file)s' n'ont pas de mapping 'runs'",
	'action.no_using' => "Les métadonnées d'action '%(file)s' n'ont pas de 'runs.using'",
	'action.no_steps' => "L'action composite '%(file)s' n'a pas de liste 'runs.steps'",
	'action.no_main' => "L'action JavaScript '%(file)s' n'a pas de 'runs.main'",
	'action.inputs_invalid' => "Les 'inputs' de '%(file)s' doivent être un mapping",
	'action.input_invalid' => "L'entrée '%(name)s' de '%(file)s' doit être un mapping",
	'action.outputs_invalid' => "Les 'outputs' de '%(file)s' doivent être un mapping",
	'action.output_invalid' => "La sortie '%(name)s' de '%(file)s' doit être un mapping",

	'step.not_mapping' => "Une étape dans %(where)s n'est pas un mapping",
	'step.field_not_string' => "Le champ d'étape '%(field)s' dans %(where)s doit être une chaîne",
	'step.no_command' => "Une étape dans %(where)s n'a ni 'run' ni 'uses'",
	'mapping.invalid' => '%(where)s doit être un mapping',

	'where.job' => "le job '%(job)s'",
	'where.file' => "'%(file)s'",
	'where.workflow_env' => 'env du workflow',
	'where.workflow_defaults' => 'defaults du workflow',
	'where.job_env' => "env du job '%(job)s'",
	'where.job_defaults' => "defaults du job '%(job)s'",
	'where.job_strategy' => "strategy du job '%(job)s'",
	'where.step_env' => "env d'une étape dans %(where)s",
	'where.step_with' => "with d'une étape dans %(where)s",

	'i18n.unknown_key' => "Aucun message n'est défini pour '%(key)s'",
	'i18n.unknown_language' => "La langue '%(language)s' n'a pas de catalogue ; utilisation de l'anglais",

	'span.second' => { plural => { one => '%(count)d seconde', other => '%(count)d secondes' } },
	'span.minute' => { plural => { one => '%(count)d minute', other => '%(count)d minutes' } },
	'span.hour' => { plural => { one => '%(count)d heure', other => '%(count)d heures' } },
	'span.day' => { plural => { one => '%(count)d jour', other => '%(count)d jours' } },
	'span.month' => { plural => { one => '%(count)d mois', other => '%(count)d mois' } },
	'span.year' => { plural => { one => '%(count)d an', other => '%(count)d ans' } },

	'cache.summary' => { plural => { one => '%(count)d image.', other => '%(count)d images.' } },
	'cache.summary_sized' => {
		plural => {
			one => '%(count)d image, %(size)s sur le disque.',
			other => '%(count)d images, %(size)s sur le disque.',
		},
	},
	'cache.missing' => {
		plural => {
			one => "%(count)d image n'est plus sur le démon.",
			other => '%(count)d images ne sont plus sur le démon.',
		},
	},
	'cache.removed' => {
		plural => {
			one => '%(count)d image supprimée, %(size)s libérés.',
			other => '%(count)d images supprimées, %(size)s libérés.',
		},
	},
	'cache.forgot' => {
		plural => {
			one => "%(count)d image oubliée, elle n'est plus sur le démon.",
			other => "%(count)d images oubliées, elles ne sont plus sur le démon.",
		},
	},
	'cache.remove_failed' => {
		plural => {
			one => 'Impossible de supprimer %(count)d image :',
			other => 'Impossible de supprimer %(count)d images :',
		},
	},

	'logs.summary' => {
		plural => {
			one => '%(count)d journal, %(size)s sur le disque.',
			other => '%(count)d journaux, %(size)s sur le disque.',
		},
	},
	'logs.removed' => {
		plural => {
			one => '%(count)d journal supprimé, %(size)s libérés.',
			other => '%(count)d journaux supprimés, %(size)s libérés.',
		},
	},
	'logs.remove_failed' => {
		plural => {
			one => "Impossible de supprimer %(count)d exécution :",
			other => "Impossible de supprimer %(count)d exécutions :",
		},
	},
	# The text listings of the cache and logs commands.
	'span.just_now' => "à l'instant",
	'span.ago' => 'il y a %(span)s',
	'cache.file' => 'Fichier du cache : %(file)s',
	'cache.empty' => "Aucune image n'a encore été mise en cache.",
	'cache.none_older' => "Aucune image en cache n'est plus ancienne que %(span)s.",
	'cache.only_older' => 'Seulement les images plus anciennes que %(span)s.',
	'cache.unreachable' => 'Le démon Docker est injoignable, les tailles sont donc inconnues.',
	'cache.prune_hint' => 'Supprimez-les avec "action-run cache --prune".',
	'cache.unknown' => 'inconnu',
	'cache.size_missing' => 'absente',
	'cache.heading.image' => 'IMAGE',
	'cache.heading.size' => 'TAILLE',
	'cache.heading.last_used' => 'DERNIÈRE UTILISATION',
	'cache.heading.age' => 'ÂGE',
	'logs.directory' => 'Répertoire des journaux : %(directory)s',
	'logs.empty' => "Aucun journal de job n'a encore été conservé.",
	'logs.none_older' => "Aucun journal de job n'est plus ancien que %(span)s.",
	'logs.only_older' => 'Seulement les journaux de jobs plus anciens que %(span)s.',
	'logs.prune_hint' => 'Supprimez-les avec "action-run logs --prune".',
	'logs.heading.run' => 'EXÉCUTION',
	'logs.heading.log' => 'JOURNAL',
	'logs.heading.size' => 'TAILLE',
	'logs.heading.age' => 'ÂGE',
	'process.redirect_failed' => "Impossible de rediriger %(stream)s vers '%(file)s' : %(error)s",
	'process.exec_failed' => "Impossible d'exécuter '%(program)s' : %(error)s",
	# The runner and its parts.  "action-run: " is the program's name and is
	# not translated; the line markers (==>, ---, !!) are kept too.
	'runner.workflow_required' => 'Un workflow est obligatoire',
	'runner.project_dir_required' => 'Un répertoire de projet est obligatoire',
	'runner.project_dir_missing' => "Le répertoire de projet '%(dir)s' n'existe pas",
	'runner.pull_concurrency_invalid' => "la concurrence des téléchargements doit être un entier positif, pas '%(value)s'",
	'runner.pull_conflict' => '--pull et --no-pull ne peuvent pas être utilisés ensemble',
	'runner.interrupted' => 'Interrompu',
	'runner.terminated' => 'Terminé',
	'runner.error' => 'action-run: %(error)s',
	'runner.not_ready' => "l'environnement n'est pas prêt ; corrigez ce que demande le rapport ci-dessus, ou passez --skip-check pour lancer quand même",
	'runner.no_job_matched' => "Aucun job ne correspond à '%(filter)s'",
	'runner.dependency_cycle' => "Cycle de dépendances impliquant le job '%(job)s'",
	'runner.unknown_job' => "Job inconnu '%(job)s'",
	'runner.need_not_selected' => "action-run: le job '%(job)s' dépend de '%(need)s', qui n'est pas sélectionné ; on suppose qu'il a réussi",
	'runner.env_cycle' => "La variable d'environnement '%(name)s' fait référence à elle-même, directement ou par d'autres variables",
	'runner.env_failed' => "Impossible d'évaluer la variable d'environnement '%(name)s' : %(error)s",
	'runner.write_failed' => "Impossible d'écrire %(what)s : %(error)s",
	'runner.file_write_failed' => "Impossible d'écrire '%(file)s' : %(error)s",
	'runner.file_read_failed' => "Impossible de lire '%(file)s' : %(error)s",
	'runner.network_failed' => "Échec de la création du réseau Docker '%(name)s' (code %(status)s)",
	'runner.input_required' => "L'action '%(uses)s' exige l'entrée '%(name)s'",
	'runner.local_action_empty' => "L'action locale '%(uses)s' ne désigne aucun répertoire du projet",
	'runner.local_action_escapes' => "L'action locale '%(uses)s' ne doit pas sortir du répertoire du projet",

	'runner.preflight.buffer_failed' => 'Impossible de mettre en tampon le rapport de prévol : %(error)s',
	'runner.preflight.remedy_image' => "vérifiez le nom de l'image, que le registre est joignable et que la connexion Docker est valide",
	'runner.preflight.schema_line' => '  schéma    version %(version)s (action-run schema preflight)',
	'runner.preflight.schema_mismatch' => 'le document action-run preflight --json ne correspond pas à App::Actions::Runner->json_schema',
	'runner.preflight.image' => '  image     %(name)s (%(source)s) : %(status)s',
	'runner.preflight.deferred' => '  différée  %(error)s',
	'runner.preflight.unnamed' => '(sans nom)',
	'runner.preflight.workflow' => 'le workflow',

	'runner.source.job' => "le job '%(name)s'",
	'runner.source.service' => "le service '%(id)s' du job '%(name)s'",
	'runner.source.action' => "l'action '%(uses)s' du job '%(name)s'",
	'runner.source.nested_action' => "l'action '%(uses)s' de l'action locale '%(via)s' du job '%(name)s'",

	'runner.image.pulling' => "Téléchargement de l'image %(image)s...",
	'runner.image.pull_failed' => "Échec du téléchargement de l'image Docker '%(image)s' (code %(status)s)",
	'runner.image.unresolved' => "impossible de résoudre l'image '%(expression)s', requise par %(source)s : %(error)s",
	'runner.image.unprepared' => "impossible de préparer l'image '%(image)s', requise par %(source)s : %(error)s",
	'runner.image.empty' => "le nom de l'image est vide",
	'runner.image.not_local' => "L'image Docker '%(image)s' n'est pas disponible localement (--no-pull)",
	'runner.image.checking' => '  image     %(image)s (%(source)s)',
	'runner.image.cache_failed' => "action-run: impossible de mettre à jour le cache d'images : %(error)s",

	'runner.job.if_failed' => "action-run: impossible d'évaluer if pour '%(name)s' : %(error)s",
	'runner.job.skipped' => '==> Job : %(name)s (ignoré)',
	'runner.job.fail_fast' => '==> Job : %(name)s (ignoré par fail-fast)',
	'runner.job.continue_failed' => "action-run: impossible d'évaluer continue-on-error pour '%(name)s' : %(error)s",
	'runner.job.continued' => '!! Le job a échoué mais continue-on-error est activé : %(name)s',
	'runner.job.not_linux' => "==> Job : %(name)s (ignoré : runs-on '%(runs_on)s' n'est pas Linux)",
	'runner.job.unsupported_runner' => 'runner non pris en charge : %(runs_on)s',
	'runner.job.start' => '==> Job : %(name)s',
	'runner.job.no_image' => "Impossible de déterminer une image de conteneur pour le job '%(name)s'",
	'runner.job.image' => '    image : %(image)s',
	'runner.job.deferred' => '  différée  %(expression)s (%(source)s)',

	'runner.parallel.did_not_run' => "le job '%(name)s' ne s'est pas exécuté",
	'runner.parallel.dup_failed' => 'Impossible de dupliquer %(handle)s',
	'runner.parallel.restore_failed' => 'Impossible de restaurer %(handle)s',

	'runner.service.not_mapping' => "Le service '%(id)s' doit être un mapping",
	'runner.service.no_image' => "Le service '%(id)s' n'a pas d'image",
	'runner.options_invalid' => "Impossible de lire les options du conteneur '%(options)s' : un guillemet n'est pas fermé",
	'runner.service.credentials' => "action-run: les identifiants du service '%(id)s' ne sont pas pris en charge ; la connexion Docker locale est utilisée",
	'runner.service.start_failed' => "Échec du démarrage du service '%(id)s' (code %(status)s)",
	'runner.what.service' => "Le service '%(id)s'",
	'runner.what.job_container' => "Le conteneur de job '%(name)s'",
	'runner.what.step_script' => "le script d'étape '%(file)s'",
	'runner.what.step_file' => "le fichier d'étape '%(file)s'",
	'runner.shared_files' => "action-run: le job s'exécute en tant que '%(user)s', donc son répertoire de runner %(dir)s est ouvert à tous les utilisateurs de cette machine, et les scripts d'étape qu'il contient renferment les secrets du workflow ; exécutez le job sous votre propre utilisateur ou en root pour le garder privé",
	'runner.what.sudo_shim' => 'le substitut de sudo',
	'runner.what.apt_shim' => 'le substitut de %(name)s',

	'runner.container.dead' => '%(what)s est mort',
	'runner.container.restarting' => '%(what)s redémarre',
	'runner.container.with_count' => '%(state)s (redémarrages : %(count)s)',
	'runner.container.count_unknown' => "%(state)s (le nombre de redémarrages n'a pas pu être lu)",
	'runner.container.stopped' => "%(what)s ne s'est pas maintenu (code %(status)s)",
	'runner.container.stopped_unknown' => "%(what)s ne s'est pas maintenu (son code de sortie n'a pas pu être lu)",
	'runner.container.start_failed' => "%(what)s n'a pas pu démarrer (code %(status)s)",
	'runner.container.at_fault' => '%(state)s ; en cause : %(fault)s',
	'runner.container.silent' => "%(state)s ; il n'a rien affiché",
	'runner.container.output' => '%(state)s ; ses dernières lignes :',
	'runner.container.daemon_silent' => "%(state)s ; le démon n'a rien dit",
	'runner.container.daemon_said' => '%(state)s ; le démon a dit :',
	'runner.fault.image' => "l'image '%(image)s'",
	'runner.fault.port' => 'le port publié',
	'runner.fault.entrypoint' => "le point d'entrée '%(entrypoint)s'",

	'runner.explain.service' => "Service '%(id)s' du job '%(job)s'",
	'runner.explain.job' => "Job '%(job)s'",
	'runner.explain.action' => "Action '%(uses)s' du job '%(job)s'",
	'runner.explain.title' => '==> %(title)s',
	'runner.explain.container' => '    conteneur  %(name)s',
	'runner.explain.image' => '    image      %(image)s',
	'runner.explain.entrypoint' => "    entrée     %(entrypoint)s",
	'runner.explain.command' => '    commande   %(command)s',
	'runner.explain.image_own' => "(celui de l'image)",

	'runner.step.env_failed' => "action-run: impossible d'évaluer l'environnement de l'étape '%(step)s' : %(error)s",
	'runner.step.if_failed' => "action-run: impossible d'évaluer if pour l'étape '%(step)s' : %(error)s",
	'runner.step.skipped' => '--- Étape : %(name)s (ignorée)',
	'runner.step.start' => '--- Étape : %(name)s',
	'runner.step.summary_header' => "--- Résumé de l'étape ---",
	'runner.step.continue_failed' => "action-run: impossible d'évaluer continue-on-error : %(error)s",
	'runner.step.continued' => "!! L'étape a échoué mais continue-on-error est activé",
	'runner.step.failed_default' => "l'étape a échoué",
	'runner.step.failure' => '!! %(message)s',
	'runner.step.exited' => "l'étape s'est terminée avec le code %(status)s",
	'runner.step.default_name' => 'Étape %(number)s',
	'runner.post.if_failed' => "action-run: impossible d'évaluer la condition post pour '%(uses)s' : %(error)s",
	'runner.post.start' => '--- Étape : Post %(uses)s',
	'runner.post.failed' => "action-run: l'étape post de '%(uses)s' a échoué : %(error)s",
	'runner.post.exited' => "!! l'étape post de '%(uses)s' s'est terminée avec le code %(status)s",
	'runner.shell.missing' => "Le shell '%(shell)s' n'est pas disponible dans le conteneur",
	'runner.script.begin' => '--- script ---',
	'runner.script.end' => '--- fin du script ---',
	'runner.checkout.path' => "action-run: l'option 'path' d'actions/checkout est ignorée ; le dépôt est monté sur /github/workspace",
	'runner.checkout.submodules' => "action-run: les sous-modules d'actions/checkout ne sont pas récupérés ; la copie locale est utilisée telle quelle",
	'runner.checkout.ref' => "action-run: ref/repository d'actions/checkout est ignoré ; la copie locale est utilisée",
	'runner.noop' => '    (%(message)s)',
	'runner.noop.checkout' => 'dépôt déjà monté sur /github/workspace',
	'runner.noop.perl' => "utilisation de l'image du conteneur pour Perl",
	'runner.noop.perl_version' => "utilisation de l'image du conteneur pour Perl %(version)s",
	'runner.noop.cache' => "le cache, les artefacts et l'envoi de la couverture ne sont pas implémentés",
	'runner.unsupported.remote' => 'les actions JavaScript et composites distantes ne sont pas prises en charge',
	'runner.unsupported.using' => "les actions locales qui utilisent '%(using)s' ne sont pas prises en charge",
	'runner.unsupported.skipped' => "action '%(action)s' ignorée : %(reason)s",
	'runner.unsupported.note' => '    (ignorée : %(reason)s)',
	'runner.docker_action.no_image' => "L'action Docker '%(uses)s' du job '%(job)s' n'a pas de nom d'image ; vérifiez l'expression qu'elle utilise",
	'runner.docker_action.bad_args' => "Impossible de lire les args de '%(uses)s' ('%(args)s') : un guillemet n'est pas fermé",
	'runner.docker_action.bad_image' => "L'action Docker '%(uses)s' du job '%(job)s' donne '%(image)s', qui n'est pas un nom d'image ; vérifiez l'expression qu'elle utilise",
	'runner.docker_action.exited' => "l'action Docker s'est terminée avec le code %(status)s",
	'runner.local_action.missing' => "L'action locale '%(uses)s' n'existe pas (cherchée dans %(dir)s)",
	'runner.composite.too_deep' => "L'action composite '%(uses)s' est imbriquée sur plus de %(depth)s niveaux",
	'runner.composite.failed' => "l'action composite '%(uses)s' a échoué",
	'runner.javascript.no_node' => "L'action JavaScript '%(uses)s' a besoin de Node.js, mais 'node' est introuvable dans le conteneur du job",
	'runner.javascript.pre_if_failed' => "action-run: impossible d'évaluer pre-if pour '%(uses)s' : %(error)s",
	'runner.javascript.pre_exited' => "l'étape pre de l'action JavaScript '%(uses)s' s'est terminée avec le code %(status)s",
	'runner.javascript.exited' => "l'action JavaScript '%(uses)s' s'est terminée avec le code %(status)s",

	'runner.summary.header' => '=== Résumé du workflow ===',
	'runner.summary.none' => "  Aucun job n'a été exécuté.",
	'runner.summary.failed' => 'Workflow ÉCHOUÉ',
	'runner.summary.succeeded' => 'Workflow réussi',
	'runner.logs.kept' => 'Journaux des jobs conservés dans %(dir)s',
	'runner.logs.keep_failed' => 'action-run: impossible de conserver les journaux des jobs : %(error)s',
	'runner.logs.copy_failed' => "impossible de copier '%(from)s' vers '%(to)s' : %(error)s",
	'runner.logs.bad_name' => "'%(name)s' n'est pas un simple nom de fichier",
	'runner.kept.header' => 'Ressources Docker conservées :',
	'runner.kept.container' => '  conteneur %(name)s',
	'runner.kept.network' => '  réseau %(name)s',
	'runner.kept.temp' => '  répertoire temporaire %(dir)s',
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

App::Actions::I18N::fr - the French message catalogue of App::Actions

=head1 SYNOPSIS

You do not normally use this module directly.  Choose the language through
L<App::Actions::I18N>:

	use App::Actions::I18N;

	my $i18n = App::Actions::I18N->new(language => 'fr');
	binmode STDOUT, ':encoding(UTF-8)';
	print $i18n->message('workflow.empty', { file => 'ci.yml' }), "\n";
	# Le workflow 'ci.yml' est vide

Or for a whole run of the command:

	ACTION_RUN_LANG=fr action-run run .github/workflows/ci.yml

Read the catalogue itself, for example to check a translation:

	use App::Actions::I18N::fr;

	my $entries = App::Actions::I18N::fr->messages;
	print scalar(keys %{$entries}), " messages\n";

=head1 DESCRIPTION

This module holds the French texts of App::Actions' messages.  A key that is missing here is shown in English
instead.

Data only: L<App::Actions::I18N> loads it and renders its entries.  Keys,
placeholders and the plural and gender forms are described there.

=head1 METHODS

=head2 messages

Returns a hash reference of message key to entry.

=head3 EXAMPLE

	my $entries = App::Actions::I18N::fr->messages;

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

=item * B<Plurals follow the French rule.>  0 and 1 use the C<one> form (C<0 image>, C<1 image>), 2 and more the C<other> form (C<2 images>).

=item * B<C<LANG> does not choose this language.>  Use C<ACTION_RUN_LANG=fr>
or the C<language> argument.

=back

=head1 ENCODING

The source file is UTF-8 and uses C<use utf8>, so every text is a Perl
character string.  The texts contain non-ASCII characters (accented letters
such as C<E<eacute>>), and may contain any Unicode character.  Encode the
text when you print it, for example with C<binmode STDOUT,
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

	 App::Actions::I18N->new(language => 'fr')
	 (or ACTION_RUN_LANG=fr, or a country that speaks French)
	        |
	        v
	+---------------------+  message($key, \%args)
	| TRANSLATOR (fr)   |------------------------+
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
	                  gender form, then plural form (French rule),
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
