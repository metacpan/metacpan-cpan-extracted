#! perl

use strict;
use warnings;

=head1 NAME

Sigmund - Fully commented plugin for Comics.

=head1 SYNOPSIS

Please read the comments in the source.

=head1 DESCRIPTION

This plugin handles the Sigmund comics from http://www.sigmund.nl .

It is also a commented example of how to write your own plugins.

=cut

# All plugins fall under the Comics::Plugin hierarchy.
#
# Please choose a descriptive name for the plugin.
#
# Some examples:
#
#   Comics::Plugin::9ChickweedLane
#   Comics::Plugin::CalvinAndHobbes
#   Comics::Plugin::FokkeEnSukke
#   Comics::Plugin::LeastICouldDo
#   Comics::Plugin::SMBC (Saturday Morning Breakfast Cerial)

package Comics::Plugin::Sigmund;

# Plugins inherit from a Fetcher and must set a number of package
# variables.
#
# Currently the following Fetchers are implemented:
#
#   Comics::Fetcher::Direct
#
#      Requires '$path' and performs a direct fetch of the
#      specified URI.
#
#      See Comics::Plugin::LeastICouldDo for an example.
#
#   Comics::Fetcher::Single
#
#      Requires '$patterm'. The fetcher fetches the main page and uses
#      this pattern to find the URL of the actual image.
#
#   Comics::Fetcher::GoComics
#
#      A special Fetcher for comics that reside on GoComics.com.
#
#      Only the starting URL '$url' is required.
#
#      See Comics::Plugin::Garfield for an example.
#
#   Comics::Fetcher::Cascade
#
#      Requires an array '@patterns'. The fetcher fetches the main
#      page and uses the first pattern to find the URL of the next
#      page, applies the next pattern, and so on, until the last
#      pattern yields the url of the desired image.
#
#      Fetchers Direct, Single and GoComics are tiny wrappers around
#      the Cascade Fetcher. It is, however, advised to always use the
#      wrappers for administration purposes.

# This plugin uses the Simple Fetcher.

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

# Mandatory variables:
#
# $name : the full name of this comic, e.g. "Fokke en Sukke"
# $url  : the base url of this comic

our $name    = "Sigmund";
our $url     = "http://www.sigmund.nl/";

# Optional variables:
#
# $ondemand : This plugin is initially disabled, but can be
#             enabled via the command line.
# $disabled : Permanently disables this plugin. It cannot be
#             re-enabled via the command line.
#             Useful if a plugin doesn't work (yet/anymore),
#	      or the site has ceased to exist.

# Other variables depend on the Fetcher.
#
# For the Direct Fetcher:
#
# $path : the path, relative to the url, to the image
#
# For the Single Fetcher:
#
# $pattern : a pattern to locate the image URI.
#           When the pattern matches it must define at least
#           the following named captures:
#             url    : the (relative) url of the image
#             image  : the image name within the url
#
#           Optionally it may define:
#
#             title  : the image title
#             alt    : the alternative text
#
# For the Cascade Fetcher:
#
# @patterns : an array of patterns to locate the image URI.
#
# For the GoComics Fetcher:
#
# No extra variables are needed.
#
# Notes on patterns:
#
# URLs ususally start with http:// or https://, so always use
# https?:// .
# Images are usually jpg, gif or png, so for the image use
# (?<image> ... (?:jpg|gif|png) ) .

our $pattern =
  qr{ <img \s+
       src="?(?<url>strips/(?<image>sig.+\.\w+))"? \s+
                    width  = "\d+" \s+
                    height = "\d+" \s+
                    border = "\d+" \s* >
    }x;

# Important: Return the package name!
__PACKAGE__;
