use Test::More tests => 17;

BEGIN { use_ok( 'Audio::GtkGramofile' ); }
BEGIN { use_ok( 'Audio::GtkGramofile::GUI' ); }
BEGIN { use_ok( 'Audio::GtkGramofile::Logic' ); }
BEGIN { use_ok( 'Audio::GtkGramofile::Settings' ); }
BEGIN { use_ok( 'Audio::GtkGramofile::Signals' ); }

my $gui = Audio::GtkGramofile::GUI->new;         # create an object
ok( defined $gui,              'new() returned something' );
ok( $gui->isa('Audio::GtkGramofile::GUI'),   "and it's the right class" );
can_ok($gui, qw(new set_gtkgramofile create_stock_buttons check_button label_and_entry label_and_entry_and_button separator label_and_spin check_and_button
hbox_label_entry initialise on_setting_finished on_setting_changed connect_signals connect_signal message load_settings_to_interface));

my $logic = Audio::GtkGramofile::Logic->new;         # create an object
ok( defined $logic,              'new() returned something' );
ok( $logic->isa('Audio::GtkGramofile::Logic'),   "and it's the right class" );
can_ok($logic, qw(new set_gtkgramofile tracksplit_watch_callback process_watch_callback tracksplit tracksplit_one process_signal process_one));

my $settings = Audio::GtkGramofile::Settings->new;         # create an object
ok( defined $settings,              'new() returned something' );
ok( $settings->isa('Audio::GtkGramofile::Settings'),   "and it's the right class" );
can_ok($settings, qw(new gui signals callbacks logic load_settings get_value set_value get_defaults get_default 
set_default get_section_keys restore_settings save_settings set_warning_text));

my $signals = Audio::GtkGramofile::Signals->new;         # create an object
ok( defined $signals,              'new() returned something' );
ok( $signals->isa('Audio::GtkGramofile::Signals'),   "and it's the right class" );
can_ok($signals, qw(new set_gtkgramofile get_callback on_quit_clicked quit_gramofile on_record_clicked on_play_clicked
on_generic_browse_clicked on_tracksplit_browse_clicked on_start_tracksplit_clicked on_stop_generic_clicked on_stop_tracksplit_clicked
on_process_infile_clicked on_process_outfile_clicked label_and_spin on_generic_1par_filter_clicked on_simple_median_filter_clicked
on_double_median_filter_clicked on_simple_mean_filter_clicked on_rms_filter_clicked on_cond_median_filter_clicked on_cond_median2_filter_clicked
on_cond_median3_filter_clicked on_simple_normalize_filter_clicked on_start_process_clicked on_stop_process_clicked on_save_clicked));
