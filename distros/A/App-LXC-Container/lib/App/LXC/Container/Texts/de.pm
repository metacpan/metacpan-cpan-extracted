package App::LXC::Container::Texts::de;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Texts::de - German language support of L<App::LXC::Container>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly by the main modules of App::LXC::Container via
    use App::LXC::Container::Texts;

=head1 ABSTRACT

This module contains all German texts of L<App::LXC::Container>.

=head1 DESCRIPTION

The module just provides a hash of texts to be used.

See L<App::LXC::Container::Texts::en> for more details.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.41';

#########################################################################

=head1 EXPORT

=head2 %T - hash of German texts

Note that C<%T> is not exported into the callers name-space, it must always
be fully qualified (as it's only used in two location in C<Texts> anyway).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our %T =
    (
     CP
     => 'originale Datei kopieren (beim LXC Update!)',
     EM
     => 'Datei leer erstellen',
     IG
     => 'Verzeichnis ignorieren',
     NM
     => 'Unterverzeichnisse separiert lassen (nicht verschmelzen)',
     OV
     => 'Dataisystem überlagern (Original verstecken)',
     RW
     => 'lesender und schreibender Zugriff',
     _1_differs_from_standard__2
     => "%s unterscheidet sich vom Standard:\n%s",
     _1_does_not_exist
     => '%s existiert nicht!',
     _1_has_incompatible_state__2
     => '%s hat inkompatible Konfiguration zu %s',
     _1_is_not_a_symbolic_link
     => '%s ist kein symbolischer Link',
     _1_may_be_inaccessible
     => '%s ist eventuell unerreichbar für die root Kennung des LXC Containers',
     __
     => 'nur lesender Zugriff',
     aborting_after_error__1
     => "Abbruch nach folgendem Fehler:\n%s",
     audio
     => 'Audio',
     audio_network_only
     => 'Audio funktioniert nur mit mindestens lokalem Netzwerk',
     bad_call_to__1
     => 'fehlerhafter Aufruf von %s',
     bad_container_name
     => 'Der Name des Containers darf nur Wort-Zeichen enthalten!',
     bad_debug_level__1
     => "unzulässiges Debug Level '%s'",
     bad_directory__1
     => "unzulässiger Verzeichnis '%s'",
     bad_ldd_interpreter__1
     => "unzulässiger Interpreter '%s' nutzt nicht ld-linux.so für dynamische Bibliotheken",
     bad_master__1
     => "unzulässiger MASTER Wert '%s'",
     broken_user_mapping__1
     => "fehlerhafte Benutzerzuordnung - mount-point %s prüfen",
     call_failed__1__2
     => "Fehler beim Aufruf von '%s': %s",
     can_t_copy__1__2
     => "Fehler beim Kopieren von '%s': %s",
     can_t_create__1__2
     => "Fehler beim Erzeugen von '%s': %s",
     can_t_determine_os
     => "Kann OS (Distribution) nicht ermitteln!  Bitte eine Kopie von /etc/os-release an den Autor schicken.",
     can_t_determine_package_in__1__2
     => "Kann Paket nicht ermitteln: %s, Zeile %d",
     can_t_link__1_to__2__3
     => "Kann '%s' nicht als '%s' verknüpfen (Link): %s",
     can_t_open__1__2
     => "Kann '%s' nicht öffnen: %s",
     can_t_remove__1__2
     => "Kann '%s' nicht löschen: %s",
     can_t_run_with__1__2
     => "Kann Befehl <%s> mit <%s> nicht korrekt aufrufen",
     cancel
     => 'Abbruch',
     features
     => 'Features',
     files
     => 'Dateien',
     filter
     => 'Filter',
     full
     => 'global',
     help
     => 'Hilfe',
     ignoring_unknown_item_in__1__2
     => "ignoriere unbekannte Konfiguration in '%s', line %d",
     internal_error__1
     => 'INTERNER FEHLER (bitte Autor benachrichtigen): %s',
     link_to_root_missing
     => '$HOME/.lxc-configuration Link fehlt',
     # apparently local is a reserved word in Perl 5.16:
     local_
     => 'lokal',
     mandatory_package__1_missing
     => 'notwendiges Paket für %s fehlt',
     message__1_missing
     => "text '%s' fehlt",
     message__1_missing_en
     => "text '%s' fehlt, falle auf en zurück",
     missing_directory__1
     => 'Verzeichnis %s fehlt',
     modify__1
     => 'ändere %s',
     modify_file
     => 'ändere Rechte von Datei',
     modify_filter
     => 'ändere Typ des Filters',
     network
     => 'Netzwerk',
     nft_error__1__2
     => "Fehler beim Aufruf von '%s' (benötigt für lokales Netzwerk): %s",
     none
     => 'keines',
     ok
     => 'OK',
     packages
     => 'Pakete',
     quit
     => 'Verlassen',
     screen_to_small__1__2
     => 'Auflösung %dx%d zu klein für Fenster, benötige >= 27x94 für alle UI Varianten',
     select_configuration_directory
     => 'Auswahl oder Eingabe des Konfigurationsverzeichnisses',
     select_files4library_package
     => 'Auswahl der Dateien für abhängige Bibliotheken und deren Pakete',
     select_files4package
     => 'Auswahl der Dateien für Pakete',
     select_files_directory
     => 'Auswahl der Dateien und/oder des Verzeichnisses',
     select_files_directory4filter
     => 'Auswahl der Dateien und/oder des Verzeichnisses für Filter',
     select_root_directory
     => 'Auswahl oder Eingabe des LXC Wurzelverzeichnisses',
     select_users
     => 'Auswahl der Benutzer',
     special_container__1_alone
     => 'Spezieller Container %s darf nicht mit anderen genutzt werden',
     unknown_os__1
     => 'Distribution %s wird noch nicht unterstützt. Bitte eine Kopie von /etc/os-release an den Autor schicken.',
     unsupported_language__1
     => "keine Sprachunterstützung für %s, falle auf en zurück",
     usage__1_container__2
     => 'Aufruf: %s <container>%s',
     users
     => 'Benutzer',
     using_existing_protected__1
     => 'verwende existierende schreibgeschützte Datei %s',
     wrong_singleton__1__2
     => 'Referenz zu Singleton ist fehlerhaft: %s != %s',
     x11
     => 'X11',

     ####################################################################
     # long texts outside of sorted ones:
     help_text
     => "Die erste obere Spalte enthält zu nutzende Pakete für den Container.\n"
     ."'-' entfernt einen ausgewählten Eintrag. '+' öffnet eine Dateiauswahl;\n"
     ."die/das ausgewählte Datei/Verzeichnis ergänzt das zugehörige Paket\n"
     ."(welches installiert sein muß). '*' erlaubt das direkte Ändern eines\n"
     ."ausgewählten Eintrags.  '++' erlaubt schließlich das Hinzufügen von\n"
     ."Paketen mit Bibliotheken, die von der ausgewählten Anwendung (oder\n"
     ."Bibliothek) benötigt werden - dies wird für fremde Anwendungen oder\n"
     ."Pakete mit fehlenden Abhängigkeiten benötigt. (Ansonsten werden die\n"
     ."installierten Abhängigkeiten später automatisch ergänzt.)\n\n"
     ."Die zweite Spalte erlaubt das Hinzufügen einzelner Dateien oder\n"
     ."Verzeichnisse. '-' entfernt wieder den ausgewählten Eintrag. '+' öffnet\n"
     ."eine Dateiauswahl zum Hinzufügen.  Alle neu hinzugefügten Einträge sind\n"
     ."zunächst schreibgeschützt, was mittels '*' geändert werden kann: 'OV'\n"
     ."konfiguriert ein überlagertes Dateisystem, daß das originale verdeckt\n"
     ."(overlay), 'RW' ermöglicht Schreibzugriff und 'EM' erzeugt eine leere\n"
     ."Datei oder ein leeres Verzeichnis.  Üblicherweise ist Schreibzugriff\n"
     ."nur für /tmp sowie einige ausgewählte Geräte und Sockets erlaubt.\n\n"
     ."Die dritte Spalte enthält eine Liste von Dateien oder Verzeichnissen,\n"
     ."die unterdrückt oder besonders behandelt werden sollen: 'IG' ist der\n"
     ."Standard und ignoriert das entsprechende Verzeichnis (bzw. die Datei).\n"
     ."Wie zuvor kann dies mit '*' geändert werden: 'CP' erzeugt eine Kopie\n"
     ."(nützlich für symbolische Links), 'EM' erzeugt das Verzeichnis oder die\n"
     ."Datei leer (empty), 'NM' verhindert für das angegebene Verzeichnis das\n"
     ."Optimieren / Zusammenfassen von Unterverzeichnissen bei der Erstellung\n"
     ." des Containers.\n\n"
     ."Die Netzwerk Box dient zur Auswahl der Art des Netzwerkzugriffs:\n"
     ."keiner, nur auf den lokalen PC oder global\n\n"
     ."Die Features Box konfiguriert zusätzlichen Features des Containers wie\n"
     ."X11 und/oder Audio (letzteres benötigt mindestens lokales Netzwerk).\n\n"
     ."Die letzte Spalte rechts unten erlaubt das Hinzufügen von Benutzern\n"
     ."zwecks Schreibzugriff auf deren originale Benutzerverzeichnisse.",
    );

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<App::LXC::Container>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (AT) cpan.orgE<gt>

=cut
