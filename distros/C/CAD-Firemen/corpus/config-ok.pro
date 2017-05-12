!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Changelog
!
! 2011-08-18 jl
!  - Portierung auf Creo Parametric 1.0
!  - Reorganisation der Parameter nach Themenbereichen
!  - Alle eingebundenen und angepassten Dateien haben jetzt ein imw_ prefix, so dass sie einfacher zu
!    identifizieren sind und im Explorer als Block erscheinen
! * Compared proe-jachy-2011-08-04\config.pro against creo-release\config.pro
! * ADDED
!   * MASS_PROPERTY_CALCULATE   AUTOMATIC
!   * PDF_USE_PENTABLE          YES
!   * PEN_TABLE_FILE            $PRO_DIRECTORY\imw_table.pnt
!   * SKETCHER_STARTS_IN_2D     YES
!   * SYSTEM_COLORS_FILE        $PRO_DIRECTORY\imw_syscol.scl
!   * TEMPLATE_DRAWING          $PRO_DIRECTORY\templates\imw_a3_drawing.drw
!   * TEMPLATE_SHEETMETALPART   $PRO_DIRECTORY\templates\imw_mmns_part_sheetmetal.prt
!   * TOLERANCE_STANDARD        ISO
!   * WELD_UI_STANDARD          ISO
! * CHANGED
!   * BMGR_PREF_FILE                $PRO_DIRECTORY\text\graph.pro                  $PRO_DIRECTORY\imw_graph.pro
!   * COMP_ASSEMBLE_START           Constrain_in_window                            CONSTRAIN_IN_WINDOW
!   * DISPLAY                       HIDDENVIS                                      SHADE
!   * DRAWING_SETUP_FILE            $PRO_DIRECTORY\text\din.dtl                    $PRO_DIRECTORY\imw_din.dtl
!   * FILE_OPEN_DEFAULT_FOLDER      working_directory                              WORKING_DIRECTORY
!   * NCCHECK_TYPE                  nccheck                                        NCCHECK
!   * SKETCHER_LOCK_MODIFIED_DIMS   yes                                            YES
!   * TEMPLATE_DESIGNASM            $PRO_DIRECTORY\templates\mmns_asm_design.asm   $PRO_DIRECTORY\templates\imw_mmns_asm_design.asm
!   * TEMPLATE_SOLIDPART            $PRO_DIRECTORY\templates\mmns_part_solid.prt   $PRO_DIRECTORY\templates\imw_mmns_part_solid.prt
! * REMOVED
!   * CLOCK                     yes
!   * COMPRESS_OUTPUT_FILES     YES
!   * DRAWING_FILE_EDITOR       PROTAB
!   * GRAPHICS                  OPENGL
!   * MDL_TREE_CFG_FILE         $PRO_DIRECTORY\text\tree.cfg
!   * PROTKDAT                  d:\Program files\Ansys Inc\v121\AISOL\CAD Integration\ProE\ProEPages\config\WBPlugInPE.dat
!   * PRO_EDITOR_COMMAND        textedit
!   * RELATION_FILE_EDITOR      PROTAB
!   * SHOW_SHADED_EDGES         NO
!   * SKETCHER_INTENT_MANAGER   yes
!   * SPIN_CONTROL              DRAG
!   * SYSTEM_EDGE_HIGH_COLOR    60 60 100
!   * TOL_MODE                  NOMINAL
! 2011-08-04 jl
!  - ADDED
!    - bmgr_pref_file $PRO_DIRECTORY\text\graph.pro   (Legt die Farbkomposition für Diagramme fest (z.B. Mechanismus))
!    - sketcher_lock_modified_dims yes                (Fixiert geänderte Bemaßungen)
!    - default_draw_scale 1                           (Standardmaßstab in Zeichnungen ist 1:1)
! 2011-03-24 jr
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! TODO
!
! 2011-08-05 jl
!  - Ist das Datumsformat so gewünscht?
!  - FORMAT_SETUP_FILE Was bewirkt das?
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Allgemeine Einstellungen
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!KOMMENTAR:_____akustische Tastatur-Signal nach Aufforderungen (Standard)
bell NO

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


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Testing MapKey handling
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !this should be a comment too
mapkey(asdasd) ~ Activate `button``OKButton`;\
   mapkey(blublu) ~ Activate `button``OKButton`;\