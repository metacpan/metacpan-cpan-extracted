#
#    Localizer.pm - iNcom module responsible for localization.
#
#    This file is part of Apache::iNcom.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package Apache::iNcom::Localizer;

require 5.005;

use strict;

use Symbol;
use File::Basename;
use I18N::LangTags 0.12;

=pod

=head1 NAME

Apache::iNcom::Localizer - Object responsible for the localization of the
generated request.

=head1 SYNOPSIS

    my $file	= $Localizer->find_localized_file( $filename );
    my $bundle	= $Localizer->get_handle( "Site_L10N" );

=head1 DESCRIPTION

This module is used for localization in the Apache::iNcom framework.
It should be used for operation which are locale sensitive. (Messages
display, currency and date formatting, etc.)

=head1 INITIALIZATION

An object is automatically initialized on each request by the
Apache::iNcom framework. The list of preferred languages is determined
by using the Accept-Language HHTP header. The default language is set
to the one specified in the configuration. It is accessible through
the $Localizer gobal variable in the Apache::iNcom pages.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $default = shift;
    $default = "en" unless I18N::LangTags::is_language_tag( $default );
    bless {
	   default   => $default,
	   preferred => [ grep { I18N::LangTags::is_language_tag( $_ ) } @_ ],
	  }, $class;
}

=pod

=head1 METHODS

=head2 default_lang

Get or set the default language.

=cut

sub default_lang {
    my ( $self, $default ) = @_;

    if ( $default ) {
	$self->{default} = $default;
    }
    $self->{default};
}

=pod 

=head2 preferred_lang

Get or set the user's preferred language.

=cut

sub preferred_lang {
    my ( $self ) = shift;

    $self->{preferred}[0] = [ $_[0] ] if ( $_[0] );

    # Use default if there is no preferred
    $self->{preferred}[0] || $self->{default};
}

=pod

=head2 preferred_langs

Get or set the user's preferred languages in order of preferences.

=cut

sub preferred_langs {
    my ( $self) = shift;

    $self->{preferred} = [ grep { I18N::LangTags::is_language_tag( $_ ) } @_ ]
      if ( @_ );

    return @{$self->{preferred}};
}

=pod

=head2 get_handle ( $base_package )

This method will initialize a Locale::Maketext object of the
$base_package using the user's list of preferred languages. This
object should be used for localization of messages and such. See that
module documentation for details (or the article about it The Perl
Journal #8).

=cut

sub get_handle {
    my ($self, $base_package) = @_;

    eval "use $base_package";
    die $@ if $@;
    {
	no strict 'refs';
	$base_package->get_handle( @{ $self->{preferred} },
				   $self->{default} );
    }

}

=pod

=head2 find_localized_file ( $filename )

This method will try to find a properly localized version of the
$filename. Localized version of the file name should have the same
name with the language extension appended. If the file without
extension exists, it is assumed to be in the default language.

    Ex: file.txt	-> English
	file.txt.fr	-> French
	file.txt.es	-> Spanish
	file.txt.fr-CA	-> French Canadian

=cut

sub find_localized_file {
    my ($self, $file) = @_;

    my $default = $self->{default};
    my %representation = (
			  I18N::LangTags::encode_language_tag( $default ) =>
			  $file
			 );
    my ($name,$dir) = File::Basename::fileparse( $file );
    return $file unless -d $dir;

    my $dh = gensym;
    return $file unless opendir $dh, $dir;

    my $rx = qr/^\Q$name\E\.([-\w]+)$/;
    my $var;
    while ( $var = readdir $dh) {
	next unless $var =~ /$rx/;
	my $key = I18N::LangTags::encode_language_tag( $1 );
	next unless $key;
	$representation{ $key } = $dir . "/" . $var;
    }
    closedir $dh;

    # Find best match
    foreach my $lang ( @{ $self->{preferred} } ) {
	my $key  = I18N::LangTags::encode_language_tag( $lang );
	next unless $key;
	return $representation{$key} if exists $representation{$key};
    }

    # Well that will have to do
    return $file;
}


1;

__END__

=pod

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Locale::Maketext(3) Apache::iNcom(3)
Apache::iNcom::Request(3) I18N::LangTags(3)

=cut
