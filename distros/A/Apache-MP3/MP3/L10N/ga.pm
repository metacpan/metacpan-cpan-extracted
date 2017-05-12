
package Apache::MP3::L10N::ga;  # Irish (Irish Gaelic)
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translator for this module:
#  mgunn@egt.ie Marion Gunn

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last modified

 # These are links as well as button text:
 'Play All' => "Seinn Uile",
 'Shuffle All' => 'Suaith Uile',  # Stream all in random order
 'Stream All' => 'Seinn Uile',

 # This one in just button text
 'Play Selected' => 'Seinn a bhfuil roghnaithe',

 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "Tá teora ama leis an eiseamláir seo, mar atá: [quant,_1,soicind,soicind].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.

 # Headings:
 'CD Directories ([_1])' => 'Eolairí Albam ([_1])',
 'Playlists ([_1])' => 'Cláracha Seanma ([_1])',        # .m3u files
 'Song List ([_1])' => 'Clár na nAmhrán ([_1])', # i.e., file list


 'Playlist' => 'Clár Seanma',
 'Select' => 'Roghnaigh',

 'fetch'  => 'faigh',   # this file
 'stream' => 'seinn',    # this file

 'Shuffle'  => 'Suaith',  # a subdirectory, recursively
 'Stream'   => 'Seinn',   # a subdirectory, recursively

 # Label for a link to "http://[servername]/"
 'Home' => 'Abhaile',

 # Credits
 "_CREDITS_before_author" => "",
 "_CREDITS_author"        => "Lincoln D. Stein", 
 "_CREDITS_after_author"  => " a chruthaigh Apache::MP3.",

 'unknown' => '?',

 # Metadata fields:
 'Artist' => "Lucht Seanma",
 'Comment' => "Nótaí",
 'Duration' => "Achar Ama",
 'Filename' => "Comhad",
 'Genre' => "Aicme",
 'Album' => "Albam",
 'Min' => "Neom.",
 'Track' => "Rian",  # just the track number (not the track name)
 'Samplerate' => "Ráta eiseamláire",
 'Bitrate' => " Ráta giotán;",
 'Sec' => "Soic.",
 'Seconds' => "Soicindí",
 'Title' => "Teideal",
 'Year' => "Bliain",


 # Now the stuff for the help page:

 'Quick Help Summary' => "Ré-Threoir",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Seinn na hamhráin uile go léir",
 "= Shuffle-play all Songs" => "= Suaith agus ansin seinn na hamhráin uile go léir",
 "= Go to earlier directory" => "= Fill ar an eolaire roimis",
 "= Stream contents" => "= Seinn a bhfuil ann",
 "= Enter directory" => "= Oscail an t-eolaire",
 "= Stream this song" => "= Seinn an t-amhrán seo",
 "= Select for streaming" => "= Roghnaigh le seinm ",
 "= Download this song" => "= Luchtaigh an t-amhrán seo go dtí do ríomhaire",
 "= Stream this song" => "= Seinn an t-amhrán seo",
 "= Sort by field" => "= Sórtáil de réir réimsí",

);

1;

