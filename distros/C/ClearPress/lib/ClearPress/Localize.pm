#!/usr/bin/env perl
# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package ClearPress::Localize;
use strict;
use warnings;
use base qw(Locale::Maketext);
use HTTP::ClientDetect::Language;
use Locale::Maketext::Lexicon {
    _auto  => 1,
    _style => 'gettext',
  };
use Carp;

our $VERSION = q[476.4.2];

sub init {
  my ($class, $locales) = @_;
  Locale::Maketext::Lexicon->import($locales);
  return 1;
}

sub lang {
  my $lang_detect = HTTP::ClientDetect::Language->new(server_default => 'en_GB');
  my $req = {
	     accept_language => $ENV{HTTP_ACCEPT_LANGUAGE},
	    };

  my $sym = \%ClearPress::request::;
  if(!exists $sym->{accept_language}) {
    *ClearPress::request::accept_language = sub { my $self = shift; return $self->{accept_language}; };
  }

  bless $req, 'ClearPress::request';
  my $lang = $lang_detect->language($req);

#  if($lang) {
#    carp qq[Detected $lang from $ENV{HTTP_ACCEPT_LANGUAGE}];
#  }
  return $lang;
}

sub localizer {
  my ($class, $lang) = @_;

  my $lh = __PACKAGE__->get_handle($lang || __PACKAGE__->lang());
  if(!$lh) {
    carp qq[Could not construct localizer for $lang];
  }
  return $lh;
}

1;
__END__

=head1 NAME

ClearPress::Localizer

=head1 VERSION

$Revision: 0.1 $

=head1 SYNOPSIS

  ClearPress::Localize->localizer->maketext($string);
  ClearPress::Localize->localizer('de')->maketext($string);

=head1 DESCRIPTION

Localization utility

=head1 SUBROUTINES/METHODS

=head2 init

=head2 lang

=head2 localizer

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item Locale::Maketext

=item HTTP::ClientDetect::Language

=item Locale::Maketext::Lexicon

=item Carp

=back

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTIONS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
