!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Different cases at option_names is wanted!
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! testing error hier
asd

!KOMMENTAR:_____akustische Tastatur-Signal nach Aufforderungen (Standard)
bell NO

!KOMMENTAR:_____Darstellung des kompletten Dateipfades in der Kopfzeile
display_full_object_path YES

!KOMMENTAR:_____Legt die Standardeinheiten für neue Objekte fest
PRO_UNIT_LENGTH UNIT_M

!KOMMENTAR:_____Festlegung für Std-Verz für Datei>Öffnen
file_open_default_folder working_directory

!KOMMENTAR:_____Startseite des Webbrowser beim start
web_browser_homepage d:\Program Files\BLA\Common Files\F000\templates\webseite\index.html

!KOMMENTAR:_____Beim Beenden fragen, ob nicht gespeicherte Dateien gespeichert werden sollen
!               (Gilt aber leider auch für nicht veränderte Dateien)
PROMPT_ON_EXIT NO

!KOMMENTAR:_____Bereich für Standardtoleranzen für Linear und Winkelbemaßungen.
linear_tol_0.000 5

!KOMMENTAR:_____Vorlagen für verschiedene Dateitypen
TEMPLATE_DESIGNASM $PRO_DIRECTORY\templates\imw_mmns_asm_design.asm

!KOMMENTAR:_____Formatforgabe fuer die Datumsdarstellung
todays_date_note_format %yyyy-%mm-%dd