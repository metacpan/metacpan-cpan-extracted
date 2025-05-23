# pending tasks and loose ideas

## flexible patterns

* add option to generate either minimal or maximal pattern
  * minimal: shortest coverage decisive of one or more objects.
  * distinct: shortest coverage to disambiguate from unrelated objects
    and objects it depends on,
    and large enough for dependent objects to disambiguate from it.
  * successive: minimal or distinct + surplus up until next ambiguation point
  * maximal: full coverage


## file regimes

Allow setting options only for a subset of processed files -
a "regime" of files.
E.g. a subproject (all files below some dir)
or scattered by pattern (like "autotools files except below foo/").

  * introduce setting regime
    * parse option --licensecheck-regime
    * parse environment variable LICENSECHECK_REGIME
    * parse environment variable LICENSECHECK_DEFAULTS


## git integration

  * Maybe implement all this as a git module?


## environment defaults

  * implement environment variable LICENSECHECK_DEFAULTS


## scripts

  * implement licensefind
    * parse options and arguments like GNU find (or busybox find?)
    * fail on any option supported by find but unsupported here
    * parse new options --licensecheck-*
      and setting=value pairs in env vars LICENSECHECK LICENSECHECK_FIND
    * by default output filenames (i.e. all with any license by default)
  * implement licensegrep
    * parse options and arguments like grep (or busybox/git grep?)
    * fail on any option supported by diff but unsupported here
    * parse new options --licensecheck-*
      and setting=value pairs in env vars LICENSECHECK LICENSECHECK_GREP
    * parse settings from env variables LICENSECHECK LICENSECHECK_GREP
      (treated as fallback for --licensecheck-* options without prefix)
    * by default output verbatim text, with filename prefixed if multiple
  * maybe implement licensegreple
    * like licensegrep, but with syntax matching greple
      <https://metacpan.org/pod/greple>
  * implement licensediff
    * parse options and arguments like diff (or git diff?)
    * fail on any option supported by diff but unsupported here
    * parse new options --licensecheck-*
      and setting=value pairs in env vars LICENSECHECK LICENSECHECK_DIFF
    * by default output unified diff
    * if file B omitted, compute from file A
      (with minimal changes by default, or optionally optimized)
  * implement licensesort
    * parse options and arguments like sort
    * fail on any option supported by sort but unsupported here
    * parse new options --licensecheck-*
      and setting=value pairs in env vars LICENSECHECK LICENSECHECK_DIFF
      + file1-format - debian spdx (default: guess from passed file1)
      + paths-debian - with format=debian try debian/copyright:copyright)
      + merge-copyright-years
      + merge-copyright-holders
      + merge-license-expressions
      + merge-license-parts
      + sort-copyright-years
      + sort-copyright-holders
      + sort-copyright-sections
      + sort-license-expressions
      + sort-license-parts
      + sort-license-sections
    * if file B omitted, compute from file A + licensegrep
    * if file A omitted, try default file for used format, or fail
      (i.e. with format=debian try debian/copyright:copyright)


## relaxed copyright reporting

  * support omitting copyright holders when permited by license


## media-type handling

  * Implement media-type handling:
    * --accept
      comma-separated list of media ranges to process
      default: */*
      set to "text/*" to skip binary files,
      or set to "application/postscript;q=0.2;mbx=1024, text/*"
      to process plaintext and small Postscript files
      takes a string of same syntax as value part of HTTP Accept Header
      (see <HTTP::Negotiate#ACCEPT-HEADERS>)
    * map MIME types to comment styles
      * Regexp::Common::comment
      * Padre::Comment
      * Syntax::Highlight::Engine::Kate
      * licenseutils
    * maybe use HTTP::Negotiate to resolve decoders and parsers to apply


## decode by media-type

  * Implement decoding options:
    * --decode-html
      regular expression for paths to parse as html.
      Pass empty regexp to only enable support (see --decode-magic).
    * --decode-xml
      regular expression for paths to parse as xml.
      Pass empty regexp to only enable support (see --decode-magic).
      * test detection of both metadata and comments
        e.g. in Darktable 3.6.0 appdata in-file
    * --decode-svg
      regular expression for paths to parse as svg.
      Pass empty regexp to only enable support (see --decode-magic).
      * test detection of both RDF metadata and comments
    * --decode-exif
      regular expression for paths to extract EXIF and other metadata from
      (see exiftool and Image::ExifTool).
      Pass empty regexp to only enable support (see --decode-magic).
    * --decode-skip
      regular expression for paths to read as-is.
    * --decode-magic
      Determine needed decoding using libmagic.
      If needed decoding method is not enabled, then that file is skipped.
      (see File::LibMagic).
    * --decode-auto
      enable all --decode-* options for common file extensions.
    * Optionally (i.e. if available) consult File::Extension on failure
  * Move detection code to separate module(s).
    * Maybe extend Software::License.


## option parsing

  * Fail when passed unknown options


## file selection

  * Implement search options:
    * --traversal-type
      Algorithm used to walk directories passed as arguments.
      * Values: one any
      * Default: one
    * --match-type
      Algorithm used for --include and --exclude options.
      * Values: regex glob_deb
      * Default: regex


## strictness modes

  * Implement strictness options:
    * --strict implies...
      * --machine (or --machine-deb if enabled)
      * --strict-select - which implies...
        * --include .*
        * --include * --match-type glob_deb
      * (does not affect --include which is instead tied to --context)
      * --traversal-type any
    * --fast implies...
      * --exclude-common
      * --decode-none
    * script applies --strict and --fast in order
    * library treats --strict and --fast as incompatible


## alternative scanner backends

  * implement option --backend
    + ugrep
      <https://github.com/Genivia/ugrep/issues/34>
      <https://github.com/Genivia/ugrep/issues/35>
      <https://github.com/Genivia/ugrep/issues/40>
      Make sure to provide feedback as promised at above issue #35
  * implement option --auto-backend
      - use ugrep when equivalent to perl
        (e.g. together with some option --no-strict-matching)


## misc

  * Implement extensibility through YAML/JSON file
    Similar to license-reconsile, but adding/overriding DefHash objects:
    * http://git.hands.com/?p=freeswitch.git;a=blob;f=debian/license-reconcile.yml;h=0e40cba01eeb67f82d18ca8f11210271848d0549;hb=refs/heads/copyright2
    * https://lists.debian.org/87efl0kvzu.fsf@hands.com
  * Implement smarter processing:
    * Optionally spawn "workers" for a boost on multi-core systems,
      e.g. using Parallel::ForkManager
    * Gather statistics on files processed and objects detected,
      and emit progress during long-running scans,
      e.g. using Progress::Any or Time::Progress (see SeeAlso of Time::Progress).
  * Inspect RDF content
    * Check for cc:morePermissions and try decode surrounding RDF data.


## See also

  * Compare against competitors
    + ripper
    + https://salsa.debian.org/stuart/package-license-checker
    + r-base /share/licenses/license.db
    + license-reconcile
    + https://wiki.debian.org/CopyrightReviewTools
    + https://docs.clearlydefined.io/clearly#licensed
    + http://copyfree.org/standard/licenses
    + https://wiki.debian.org/DFSGLicenses
    + http://voag.linkedmodel.org/2.0/doc/2015/REFDATA_voag-licenses-v2.0.html
    + https://github.com/hierynomus/license-gradle-plugin
    + ruby-licensee - http://ben.balter.com/licensee/
    + flict - https://github.com/vinland-technology/flict


## misc

  * Warn about licensing conflicts
    + See %license_conflicts in tool adequate
      <https://salsa.debian.org/debian/adequate/-/blob/master/adequate>
  * Sort Files sections to list common over exotic:
    + prefix of leftmost truncate wildcard (*)
    + suffix of leftmost truncate wildcard (*)
    + filecount when containing character wildcard (?)
    + filecount
    + License-shortnames
    + License-Grant
    + License inlined
    + Copyright
    + Filenames
  * Test against challenging projects
    + ghostpdl
    + chromium
    + fpc
    + lazarus
    + boost
    + picolibc <https://keithp.com/cgit/picolibc.git/>

  * Maybe use libdata-binary-perl
  * Maybe use String::Tagged (or else perhaps Text::Locus) to track (and emit in verbose/debug mode) where patterns are detected?

  * Quality flagging
    + ambiguous: license ref pointing to multiple license fulltexts (e.g. "MIT" or "GNU" or "GPL"
    + unlicensed: copyright holder(s) but no licensing
    + ungranted: license fullref requiring explicit grant, but no corresponding license grant
    + incomplete: fractions of license fullref, but no complete fullref
    + alien: license label but no license name
    + unowned: license but no copyright holder
    + uncertain: license ref and more unknown text in same sentence/paragraph/section
    + buried: license or copyright not at top of file
    + unstructured: license/copyright not at ideal place of data structure
      (e.g. in commend field of EXIF data, or in content or comment of html)
    + unaligned: license/copyright out of sync between layers of structure
      (e.g. ICC data and EXIF data of PNG, or content and metadata of PDF/HTML)
    + imperfect: license ref not following format documented in license fulltext
    + conflict: incompatible licenses (e.g. GPL-3+ and GPL-2-only, or OpenSSL and GPL)

  * use nano-style configurable wordchars/punct/brackets/matchbrackets chars and quotestr regex
    e.g. to determine sentences
    (see "paragraphs" and "justify" in "man nanorc")
