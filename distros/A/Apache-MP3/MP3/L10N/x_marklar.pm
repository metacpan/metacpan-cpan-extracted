
package Apache::MP3::L10N::x_marklar;  # Marklar
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);

# Translators, in no particular order:
#  sburke@cpan.org

sub language_tag {__PACKAGE__->SUPER::language_tag}

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Play all marklars",
 'Shuffle All' => 'Shuffle all marklars',
 'Stream All' => 'Stream all marklars',

 # This one in just button text
 'Play Selected' => 'Play all selected marklars',
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "In this marklar, marklar is limited to approximately [quant,_1,marklar].",
 
 # Headings:
 'CD Directories ([_1])' => 'Marklar marklars ([_1])',
 'Playlists ([_1])' => 'Marklars ([_1])',        # .m3u files
 'Song List ([_1])' => 'Marklar marklars ([_1])', # i.e., file list

 'Playlist' => 'Marklar',
 'Select' => 'Select',
 
 'fetch'  => 'fetch',
 'stream' => 'stream',
 
 'Shuffle'  => 'Shuffle',
 'Stream'   => 'Stream',
 
 # Label for a link to "http://[servername]/"
 'Home' => 'Marklar',

 # Credits
 "_CREDITS_before_author" => "Apache::MP3 was written by ",
 "_CREDITS_author"        => "Marklar M. Marklar", 
 "_CREDITS_after_author"  => ".",


 'unknown' => 'unknown',

 # Metadata fields:
 'Artist' => "Marklar",
 'Comment' => "Marklar",
 'Duration' => "Marklar",
 'Filename' => "Marklar",
 'Genre' => "Marklar",
 'Album' => "Marklar",
 'Min' => "Mar.",
 'Track' => "Mar.",
 'Samplerate' => "Marklar",
 'Bitrate' => "Marklar",
 'Sec' => "Mar.",
 'Seconds' => "Marklars",
 'Title' => "Marklar",
 'Year' => "Marklar",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Quick Marklar Marklar",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Stream all marklars.",
 "= Shuffle-play all Songs" => "= Shuffle-play all marklars.",
 "= Go to earlier directory" => "= Go to earlier marklar.",
 "= Stream contents" => "= Stream marklar.",
 "= Enter directory" => "= Enter marklar.",
 "= Stream this song" => "= Stream this marklar.",
 "= Select for streaming" => "= Select for marklar.",
 "= Download this song" => "= Download this marklar.",
 "= Stream this song" => "= Stream this marklar.",
 "= Sort by field" => "= Sort by marklar.",

);

1;

