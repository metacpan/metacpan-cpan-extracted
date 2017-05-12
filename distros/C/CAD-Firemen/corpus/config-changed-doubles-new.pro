! Die folgende Zeile wird automatisch durch das Versionskontrollsystem ausgefüllt
! Stand: $Id: config.pro 18 2011-09-01 08:15:43Z jlan11 $

!KOMMENTAR:_____Festlegung der optionalen Grafikumgebung
graphics OPENGL

!KOMMENTAR:_____Andere Kantenfarbe beim Schattieren ja/nein (Standard)
show_shaded_edges NO

!KOMMENTAR:_____Modelldarstellung, Hiddenvis - Verdeckte Kanten grau anzeigen
display SHADE

!KOMMENTAR:_____Legt die Standardeinheiten für neue Objekte fest
pro_unit_length UNIT_MM

!KOMMENTAR:_____Legt die Standard-Masse-Einheiten für neue Objekte fest
pro_unit_mass UNIT_KILOGRAM

!KOMMENTAR:_____Legt die anfängliche Standardorientierung der Ansicht fest
orientation ISOMETRIC

!KOMMENTAR:_____Farben des Drahtmodells angezeigt im Haupt- oder in allen Fenstern (Standard)
color_windows ALL_WINDOWS

!KOMMENTAR:_____akustische Tastatur-Signal nach Aufforderungen (Standard)
bell NO

!KOMMENTAR:_____Darstellung des kompletten Dateipfades in der Kopfzeile
display_full_object_path YES

!KOMMENTAR:_____Toleranzmodus neu erzeugte Bemaßungen
tol_mode NOMINAL

!KOMMENTAR:_____Bereich für Standardtoleranzen für Linear und Winkelbemaßungen.
linear_tol_0.000 5

!KOMMENTAR:_____Darstellung von Silhouettenkanten nur für die Drahtmodell/Drahtgitteranzeige (Standard)
display_silhouette_edges YES

!KOMMENTAR:_____Legt fest, wie Kanten zwischen tangentialen Flächen angezeigt werden (Standard)
tangent_edge_display SOLID

!KOMMENTAR:_____Im Zeichnungsmodus werden neue Bemaßungen rot hervorgehoben
highlight_new_dims YES

!KOMMENTAR:_____Formatforgabe fuer die Datumsdarstellung
todays_date_note_format %yyyy-%mm-%dd

!KOMMENTAR:_____Pfad für die Vorgabewerte der Optionen der Zeichnungs-Voreinstellungsdatei der Pro/E Sitzung
drawing_setup_file $PRO_DIRECTORY\text\imw_din.dtl

!KOMMENTAR:_____Editor mit dem Beziehungen editiert werden.
relation_file_editor PROTAB

!KOMMENTAR:_____Festlegung ob Objektdateien zum Speichern komprimiert werden
compress_output_files YES

!KOMMENTAR:_____Festlegung ob die Uhr gangezeigt wird während Pro/ENGINEER einen Prozess ausführt
clock yes

!KOMMENTAR:_____Pfad fuer die Standardeinstellungen des Modellbaums
mdl_tree_cfg_file $PRO_DIRECTORY\text\imw_tree.cfg

!KOMMENTAR:_____Pfad fuer die Trailerzeugung
trail_dir C:\Trail

!KOMMENTAR:_____Definition der Std-Farbe zum Hervorheben von Kanten. Die 3 Dezimalwerte geben Prozentsatz des Rot-, Grün- und Blauanteils (in dieser Reihenfolge) der resultierenden Farbe an
system_edge_high_color 60 60 100

!KOMMENTAR:_____Über "part_table_editor" oder "relation_file_editor" kann ein Editor bestimmt werden, der als Alternative zum Systemeditor verwendet wird
pro_editor_command textedit

!KOMMENTAR:_____Pfad zum als Standard-Teilschablone verwendetem Modell
template_solidpart $PRO_DIRECTORY\templates\imw_mmns_part_solid.prt

!KOMMENTAR:_____Pfad zur ausgewiesenen Schablonenbaugruppe
template_designasm $PRO_DIRECTORY\templates\imw_mmns_asm_design.asm

!KOMMENTAR:_____Strichstärke von Stift 1, für elektrostatischen Plotter; die Strichstärke reicht von 1 (dünn) bis 16 (dick)
pen1_line_weight 3

!KOMMENTAR:_____Strichstärke von Stift 2, für elektrostatischen Plotter (Standard)
pen2_line_weight 1

!KOMMENTAR:_____Modul zur Simulation von NC-Materialentfernung
nccheck_type nccheck

!KOMMENTAR:_____Festlegung für Std-Verz für Datei>Öffnen
file_open_default_folder working_directory

!KOMMENTAR:_____Festlegung wie neue Baugruppenkomponenten angezeigt werden (in separaten Fenster angezeigt oder im Hauptfenster)
comp_assemble_start Constrain_in_window

!KOMMENTAR:_____Angabe der Pro/TOOLKIT Registrierungsdatei -- Cadenas
protkdat $CADENAS/iface/proewildfire/win/protkwf5_64.dat

!KOMMENTAR:_____Angabe der Pro/TOOLKIT Registrierungsdatei -- Ansys
protkdat D:\Program Files\ANSYS Inc\v121\AISOL\CAD Integration\$ANSYS_PROEWF_VER121\ProEPages\config\WBPlugInPE.dat
protkdat $PROMIF_ACN121\protk.dat
frt_enabled yes

!KOMMENTAR:_____Stifttabelle zum Drucken
PEN_TABLE_FILE   $PRO_DIRECTORY\text\imw_table.pnt

!KOMMENTAR:_____Auch beim PDF erzeugen, die Stifteinstellungennutzen
pdf_use_pentable YES

!KOMMENTAR:_____Einstellungen für die Formatierung der Graphen (z.B. von Mechanismus)
BMGR_PREF_FILE                $PRO_DIRECTORY\text\imw_graph.pro

!KOMMENTAR:_____Standard Zeichnungsmaßstab
default_draw_scale 1

!KOMMENTAR:_____Geänderte Maße automatisch sperren
sketcher_lock_modified_dims YES

!KOMMENTAR:_____Automatisch die Masse nach jeder Änderung neu berechnen
!               (Wird für die Anzeige auf der Zeichnung benötigt)
MASS_PROPERTY_CALCULATE AUTOMATIC

!KOMMENTAR:_____Auf ISO umgestellt
tolerance_standard ISO

!KOMMENTAR:_____Auf ISO umgestellt
weld_ui_standard ISO

!KOMMENTAR:_____Verzeichnis mit Materialdefinitionen
PRO_MATERIAL_DIR $PRO_DIRECTORY\imw_materials
