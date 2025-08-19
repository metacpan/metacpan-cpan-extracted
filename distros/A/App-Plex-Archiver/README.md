<!-- markdownlint-disable MD025 -->

# NAME

App::Plex::Archiver - A group of perl modules and scripts for archiving movie files into a directory structure preferred by the Plex Media Server.

# DESCRIPTION

App::Plex::Archiver - A group of perl modules and scripts for archiving movie files into a directory structure preferred by the [Plex Media Server](https://support.plex.tv/articles/naming-and-organizing-your-movie-media-files/).

This set of modules and scripts archive every movie files (.mp4, .mkc, .avi, .mov) into a directory structure preferred by the Plex Media Server.

For each file found, the script:

+ Prompts the user for the movie's title
+ Uses the TMDB API to provide the user with a list of possible movies
+ Uses the TMDB information to intelligently name the new file
+ Copies or moves the file to the new directory and filename

# VERSION

Version 0.01

# NOTES

## TMDB API Key

You will need an API key from  The Movie DB. Please look at the [TMDB FAQ](https://developer.themoviedb.org/docs/faq) for
details on how to obtain an API key.

Once you have an API key, if you place it in a file named '.tmdb-api-key' in your home directory, the script will
automatically find the file. If you store the key elswhere, make sure you provide the full path to the file using
the '--api-key' command line option.

Make sure you use your TMDB "API Key" and *not* the "API Read Access Token" in the API key file.
