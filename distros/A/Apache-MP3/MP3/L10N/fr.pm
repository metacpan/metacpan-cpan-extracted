
#---------------------------------------------------------------------------
package Apache::MP3::L10N::fr;  # French
use strict;
use Apache::MP3::L10N;
use vars qw($VERSION @ISA %Lexicon);
@ISA = qw(Apache::MP3::L10N);
sub language_tag {__PACKAGE__->SUPER::language_tag}

# Translators, in no particular order:
#  lucst@sympatico.ca
#  william@netymology.com
#  leolo@pied.nu
#  sburke@cpan.org
#
# [If you are using this module as a template for another language,
#  delete the above addresses and put in your own.]

sub encoding { "iso-8859-1" }   # Latin-1
  # Change as necessary if you use a different encoding.
  # I advise using whatever encoding is most widely supported
  # in web browsers.

# Below I use a lot of &foo; codes, but you don't have to.

%Lexicon = (
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020612'), # Last-modified date
    #
    # If you're a translator, put today's date there in the form
    #  year-month-day, but with no dashes.  Example: Jan 02, 2003
    #  would be '20030102'

 # Note: Basically, "stream" means "play" for this system.

 # These are links as well as button text:
 'Play All' => "Jouer tout",
 'Shuffle All' => "Jouer tout m&eacute;lang&eacute;",  # Stream all in random order
 'Stream All' => "Jouer tout",

 # This one in just button text
 'Play Selected' => "Jouer les s&eacute;lections",
 
 "In this demo, streaming is limited to approximately [quant,_1,second,seconds]."
  => "Dans cette demonstration, le jeu est limit&eacute; &agrave; quasi [quant,_1,seconde,secondes].",
  # In [quant,_1,seconde,secondes], the seconde is the singular form, and the secondes is the plural.
 
 # Headings:
 'CD Directories ([_1])' => "R&eacute;pertoires des albums ([_1])",
 'Playlists ([_1])' => "Programmes ([_1])",        # .m3u files
 'Song List ([_1])' => "Liste de chansons ([_1])", # i.e., file list


 'Playlist' => "Programme",
 'Select' => "S&eacute;lectionner",
 
 'fetch'  => "t&eacute;l&eacute;charger", # Send/download/save this file
 'stream' => "jouer",    # this file
 
 'Shuffle'  => "Jouer m&eacute;lang&eacute;",  # a subdirectory, recursively
 'Stream'   => "Jouer",            # a subdirectory, recursively
 
 # Label for a link to "http://[servername]/"
 'Home' => "Racine",


 'unknown' => "?",
   # Used when a file doesn't specify its album name, artist name,
   # year of release, etc.


 # Metadata fields:
 'Artist' => "Artiste",
 'Comment' => "Notes",
 'Duration' => "Dur&eacute;e",
 'Filename' => "Fichier",
 'Genre' => "Genre",  # i.e., what kind of music
 'Album' => "Album",
 'Min' => "Min",  # abbreviation for "minutes"
 'Track' => "N&ordm;",  # just the track number (not the track name)
 'Sec' => "Sec",  # abbreviation for "seconds"
 'Seconds' => "Secondes",
 'Title' => "Titre",
 'Year' => "Ann&eacute;e",

 'Samplerate' => "Taux d'&eacute;chantillonnage",
 'Bitrate' => "Taux comprim&eacute;",
   # The sample rate is basically a number reflecting the audio quality
   # of the audio file before compression.  The bitrate is basically
   # a number reflecting the audio quality of the file after compression.
   # I think you can feel free to translate these as "Original sound quality"
   # and "Sound quality", or "Source fidelity" and "Fidelity", etc.


 # Now the stuff for the help page:

 'Quick Help Summary' => "Sommaire des fonctions",
  # page title as well as the text we use for linking to that page

 "= Stream all songs" => "= Jouer toutes les chansons",
 "= Shuffle-play all Songs" => "= M&eacute;langer et jouer toutes les chansons",
 "= Go to earlier directory" => "= Aller &agrave; un r&eacute;pertoire plus haut",
       # i.e., just a link to ../ or higher
 "= Stream contents" => "= Jouer le contenu",
 "= Enter directory" => "= Entrer dans ce r&eacute;pertoire",
 "= Stream this song" => "= Jouer cette chanson",
 "= Select for streaming" => "= S&eacute;lectionner cette chanson",
 "= Download this song" => "= T&eacute;l&eacute;charger cette chanson",
 "= Stream this song" => "= Jouer cette chanson",
 "= Sort by field" => "= Trier par attribut",
    # "sort" in the sense of ordering, not separating out.


 # The following three phrases are used for composing the sentence that
 # means, in your language, "Apache::MP3 was written by Lincoln D. Stein."
 #
 # For example, some laguages express this as
 #   "Apache::MP3 by Lincoln D. Stein is written."
 # In that case, _CREDITS_before_author would be "Apache::MP3 by",
 # _CREDITS_author would be "Lincoln. D. Stein", and
 # _CREDITS_after_author would be "was written."
 #
 # If you're not sure how to do this, then just tell me the translation
 # for the whole sentence, and I'll take care of it.

 "_CREDITS_before_author" => "Apache::MP3 fut &eacute;crit par",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  ".",

);

1;

