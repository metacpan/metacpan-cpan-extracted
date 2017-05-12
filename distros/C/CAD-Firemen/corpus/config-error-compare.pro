!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Allgemeine Einstellungen
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!KOMMENTAR:_____akustische Tastatur-Signal nach Aufforderungen (Standard)
bello NO

!KOMMENTAR:_____Darstellung des kompletten Dateipfades in der Kopfzeile
display_full_object_path YES

!KOMMENTAR:_____Legt die Standardeinheiten für neue Objekte fest
pro_unit_length UNIT_MM
!KOMMENTAR:_____Legt die Standard-Masse-Einheiten für neue Objekte fest
pro_unit_mass UNIT_KILOGRAM

!KOMMENTAR:_____Legt die anfängliche Standardorientierung der Ansicht fest
orientation ISOMETRIC

!KOMMENTAR:_____Pfad fuer die Trailerzeugung
trail_dir C:\Trail

!KOMMENTAR:_____Festlegung für Std-Verz für Datei>Öffnen
file_open_default_folder WORKING_DIRECTORY

!KOMMENTAR:_____Festlegung wie neue Baugruppenkomponenten angezeigt werden (in separaten Fenster angezeigt oder im Hauptfenster)
comp_assemble_start CONSTRAIN_IN_WINDOW

!KOMMENTAR:_____Modul zur Simulation von NC-Materialentfernung
nccheck_type NCCHECK

!KOMMENTAR:_____Beim Beenden fragen, ob nicht gespeicherte Dateien gespeichert werden sollen
!               (Gilt aber leider auch für nicht veränderte Dateien)
!PROMPT_ON_EXIT NO

!KOMMENTAR:_____Automatisch die Masse nach jeder Änderung neu berechnen
!               (Wird für die Anzeige auf der Zeichnung benötigt)
MASS_PROPERTY_CALCULATE AUTOMATIC


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Skizzierer
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!KOMMENTAR:_____Im Skizzierer werden geänderte Maße gesperrt
sketcher_lock_modified_dims YES
!KOMMENTAR:_____Nach der Definition der Skizze, wird in Skizzenorientierung gewechselt.
sketcher_starts_in_2d YES


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Darstellung
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!KOMMENTAR:_____Farben des Drahtmodells angezeigt im Haupt- oder in allen Fenstern (Standard)
color_windows ALL_WINDOWS
!KOMMENTAR:_____Darstellung von Silhouettenkanten nur für die Drahtmodell/Drahtgitteranzeige (Standard)
display_silhouette_edges YES
!KOMMENTAR:_____Legt fest, wie Kanten zwischen tangentialen Flächen angezeigt werden (Standard)
tangent_edge_display SOLID
!KOMMENTAR:_____Im Zeichnungsmodus werden neue Bemaßungen rot hervorgehoben
highlight_new_dims YES
!KOMMENTAR:_____Modelldarstellung beim Start von ProE
display SHADE


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Toleranzen
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!KOMMENTAR:_____Auf ISO umgestellt
tolerance_standard ISO
!KOMMENTAR:_____Auf ISO umgestellt
weld_ui_standard ISO
!KOMMENTAR:_____Bereich für Standardtoleranzen für Linear und Winkelbemaßungen.
linear_tol_0.000 5


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Eingebundene Dateien (Templates, andere Configs, ...)
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!KOMMENTAR:_____Farbschema
system_colors_file $PRO_DIRECTORY\text\imw_syscol.scl
!KOMMENTAR:_____Pfad für die Vorgabewerte der Optionen der Zeichnungs-Voreinstellungsdatei der Pro/E Sitzung
drawing_setup_file $PRO_DIRECTORY\text\imw_din.dtl
!KOMMENTAR:_____Was ist das? (Assigns a specified setup file to each drawing format. To assign the drawings parameter values to the format, you must retrieve the drawings setup file into the format.)
!format_setup_file $PRO_DIRECTORY\text\prodetail.dtl
!KOMMENTAR:_____Einstellungen für die Formatierung der Graphen (z.B. von Mechanismus)
bmgr_pref_file $PRO_DIRECTORY\text\imw_graph.pro

!KOMMENTAR:_____Vorlagen für verschiedene Dateitypen
template_designasm $PRO_DIRECTORY\templates\imw_mmns_asm_design.asm
!template_drawing $PRO_DIRECTORY\templates\imw_a3_drawing.drw
template_sheetmetalpart $PRO_DIRECTORY\templates\imw_mmns_part_sheetmetal.prt
template_solidpart $PRO_DIRECTORY\templates\imw_mmns_part_solid.prt


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Optionen für Zeichnungen
! @TODO Prüfen ob die nicht auch in din.dtl (oder entsprechender Zeichnungskonfig.) eingestellt werden können
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!KOMMENTAR:_____Standard Zeichnungsmaßstab
default_draw_scale 1

!KOMMENTAR:_____Strichstärke von Stift 1, für elektrostatischen Plotter; die Strichstärke reicht von 1 (dünn) bis 16 (dick)
pen1_line_weight 3

!KOMMENTAR:_____Strichstärke von Stift 2, für elektrostatischen Plotter (Standard)
pen2_line_weight 1

!KOMMENTAR:_____Auch beim PDF erzeugen, die Stifteinstellungennutzen
pdf_use_pentable YES

!KOMMENTAR:_____Pfad zur Stifttabelle (gilt nur für neue Zeichnungen)
pen_table_file $PRO_DIRECTORY\text\imw_table.pnt

!KOMMENTAR:_____Formatforgabe fuer die Datumsdarstellung
todays_date_note_format %yyyy-%mm-%dd
