# Album

![Version](https://img.shields.io/github/v/release/sciurius/album)
![GitHub issues](https://img.shields.io/github/issues/sciurius/album)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http:/makeapullrequest.com)
![Language Perl](https://img.shields.io/badge/Language-Perl-blue)

`album` is a tool to create and maintain a browser based photo album.

The photo albums are intended to be the digital equivalents of paper
albums, but easier to create and maintain. Although you can publish a
photo album on the Web, this tool is not specifically targeted at
creating Web shows.

**Disclaimer** This program was initially written in 2002. Nowadays
better alternatives may exist.

# Details

A photo album consists of a number of (large) pictures, small thumbnail
images, and index pages. Optionally, medium sized images can be
generated as well. The album will be organised as follows:

    index/           index pages and thumbnails
    icons/           directory with navigation icons
    large/           original (large) images, with HTML pages
    medium/          optional medium sized images, with HTML pages

Each image can be labeled with a description, a tag (applies to a
group of images, e.g. a date), the image name, and some
characteristics (size and dimensions).

Images can be handled 'in situ', or imported from e.g. a CD-ROM or
digital camera. Optionally, EXIF information from digital camera files
can be taken into account.

Web site: https://www.squirrel.nl/people/jvromans/Album/index.html

# Helper programs

This program requires some helper programs for certain tasks.

*  `jpegtran`    will be used to rotate JPEG files loslessly.
	      If missing, JPEG files will be rotated by ImageMagick,
	      with possible loss of information.
*  `mencoder`    is needed to manipulate MPEG files.
	      If missing, MPEG files will be copied without
	      processing. They cannot be rotated, and may not be
	      playable on your mpeg player.
*  `mplayer`     is needed to extract a still from MPEG movies, and to 
	      extract audio from VOICE files.
	      If missing, no stills will be produced, and VOICE files
	      will remain silent.

# Migrating from Version 1

The structure and content of the files have changed from version 1 in
an INCOMPATIBLE way. Hopefully, the version 2 approach will be
flexible enough to last longer.

If you didn't change any style sheets, migration is easy:

   - remove all `index*.html` files
   - remove the `css` directory, with contents
   - rename the `thumbnails` directory to `index`

If you did change style sheets:

   - remove all `index*.html` files
   - move the `css` directory, with contents, to a backup location
   - rename the `thumbnails` directory to `index`
   - run `album` with `--extcss` once
   - apply your style sheet changes to the new style sheets


