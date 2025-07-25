# -------- Text Interface -----------
## The following subroutines/methods belong to the Text interface class
## the grammar of the command processor is defined in
# grammar_body.pl with subroutines in Grammar.p

package Audio::Nama::Text;
use v5.36; use Carp;
no warnings 'uninitialized';
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Assign qw(:all);

our @ISA = 'Audio::Nama';
our $VERSION = 1.071;

sub hello {"hello world!";}

sub loop {
	package Audio::Nama;
	$text->{tickit}->run;
}

## NO-OP GRAPHIC METHODS 

no warnings qw(redefine);
sub init_gui {}
sub transport_gui {}
sub group_gui {}
sub track_gui {}
sub preview_button {}
sub create_master_and_mix_tracks {}
sub time_gui {}
sub refresh {}
sub refresh_group {}
sub refresh_track {}
sub flash_ready {}
sub update_master_version_button {}
sub update_version_button {}
sub paint_button {}
sub project_label_configure{}
sub length_display{}
sub clock_display {}
sub clock_config {}
sub manifest {}
sub global_version_buttons {}
sub destroy_widgets {}
sub destroy_marker {}
sub restore_time_marks {}
sub show_unit {}
sub add_effect_gui {}
sub remove_effect_gui {}
sub marker {}
sub init_palette {}
sub save_palette {}
sub paint_mute_buttons {}
sub remove_track_gui {}
sub reset_engine_mode_color_display {}
sub set_engine_mode_color_display {}
sub setup_playback_indicator {}

1;
__END__