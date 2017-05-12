package Audio::Nama::Globals;
use Modern::Perl;

# set aliases for common indices
*bn = \%Audio::Nama::Bus::by_name;
*tn = \%Audio::Nama::Track::by_name;
*ti = \%Audio::Nama::Track::by_index;
*mn = \%Audio::Nama::Mark::by_name;
*en = \%Audio::Nama::Engine::by_name;
*fi = \%Audio::Nama::Effect::by_id;

# and the graph

*g = \$Audio::Nama::ChainSetup::g;

use Exporter;
use constant {
	REC	=> 'REC',
	PLAY => 'PLAY',
	MON => 'MON',
	OFF => 'OFF',
};
our @ISA = 'Exporter';
our @EXPORT_OK = qw(

$this_track
$this_bus
$this_bus_o
$this_mark
$this_edit
$this_sequence
$this_engine
$this_user
$prompt
%tn
%ti
%bn
%mn
%en
%fi
$g
$debug
$debug2
$quiet
REC
MON
PLAY
OFF
$ui
$mode
$file
$graph
$setup
$config
$jack
$fx
$fx_cache
$text
$gui
$midi
$help
$mastering
$project
@tracks_data
@bus_data
@groups_data
@marks_data
@fade_data
@edit_data
@inserts_data
@effects_data
@global_effect_chain_vars
@global_effect_chain_data
@project_effect_chain_data
$this_track_name
%track_comments
%track_version_comments
@tracked_vars
@persistent_vars

);

our %EXPORT_TAGS = 
(
	trackrw => [qw(REC PLAY MON OFF)],
	singletons => [qw( 	

$ui
$mode
$file
$graph
$setup
$config
$jack
$fx
$fx_cache
$text
$gui
$midi
$help
$mastering
$project


	)],

	var_lists => [qw(

						@tracked_vars
						@persistent_vars
						@global_effect_chain_vars
	)],

	pronouns => [qw( 

$this_track
$this_bus
$this_bus_o
$this_mark
$this_edit
$this_sequence
$this_engine
$this_user
$prompt
%tn
%ti
%bn
%mn
%en
%fi
$g
$debug
$debug2
$quiet
REC
MON
PLAY
OFF


	)],

	serialize =>  [qw(

@tracks_data
@bus_data
@groups_data
@marks_data
@fade_data
@edit_data
@inserts_data
@effects_data
@global_effect_chain_vars
@global_effect_chain_data
@project_effect_chain_data
$this_track_name
%track_comments
%track_version_comments
@tracked_vars
@persistent_vars


	)],
);
our $ui = 'bullwinkle';  # for testing
{
	my %seen;
	push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach
keys %EXPORT_TAGS;
}


1;
__END__

=head1 Nama Variables

Variables are listed in multiple files in the source.

=head2 Exported

L<Audio::Nama::Globals> exports Nama globals, 
which it gets by merging the contents
of the following files:

=over

=item F<var_pronouns>

Pronouns (e.g. C<$this_track>) and 
indices (e.g. C<%tn>, get track by name)

=item F<var_serialize>

Marshalling variables for serializing/deserializing (e.g. C<@tracks_data>)

=item F<var_singletons> 

Simple hash structures (such as C<$config>) or objects such
as F<$file> that aggregate data.  The hashes can be invested
with object properties as need be.

=back

=head2 Other lists

=over

=item F<var_config>

Maps keys in F<.namarc> (e.g. I<mix_to_disk_format>) to the
corresponding Nama internal scalar (e.g. C<$config-E<gt>{mix_to_disk_format}>

=item F<var_keys>

List of allowed singleton hash keys. 

Keys of variables appearing in ./var_singletons 
should be listed in var_keys or in var_config.
Undeclared keys will trigger warnings during build.

=head2 F<var_lists>

Declares lists of variables used in
serializing/deserializing.

=item C<@global_effect_chain_vars>

Mainly user defined and system-wide effect chains,
stored in F<global_effect_chains.json> in the 
Nama project root directory.

=item C<@tracked_vars>

These variables are saved to F<State.json> in the project
directory and placed under version control.

=item C<@persistent_vars>

These Variables saved to F<Aux.json>, I<not> under version control.
including project-specific effect-chain definitions,
and track/version comments.

=back

=cut