#! perl

# Data::iRealPro::Output -- pass data to backends

# Author          : Johan Vromans
# Created On      : Tue Sep  6 16:09:10 2016
# Last Modified By: Johan Vromans
# Last Modified On: Tue Nov 13 10:10:20 2018
# Update Count    : 80
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Carp;
use utf8;

package Data::iRealPro::Output;

use Data::iRealPro::Input;
use Encode qw ( decode_utf8 );

sub new {
    my ( $pkg, $options ) = @_;

    my $self = bless( { variant => "irealpro" }, $pkg );
    my $opts;

    $opts->{output} = $options->{output} || "";
    $opts->{transpose} = $options->{transpose} // 0;
    if ( $options->{generate} ) {
	$self->{_backend} = "Data::iRealPro::Output::" . ucfirst($options->{generate});
	eval "require $self->{_backend}";
	die($@) if $@;
	$opts->{output} ||= "-";
    }

    elsif ( $options->{list}
	 || $opts->{output} =~ /\.txt$/i ) {
	require Data::iRealPro::Output::Text;
	$self->{_backend} = Data::iRealPro::Output::Text::;
	$opts->{output} ||= "-";
    }
    elsif ( $opts->{output} =~ /\.jso?n$/i ) {
	require Data::iRealPro::Output::JSON;
	$self->{_backend} = Data::iRealPro::Output::JSON::;
    }
    elsif ( $options->{split}
	    || $opts->{output} =~ /\.html$/i ) {
	require Data::iRealPro::Output::HTML;
	$self->{_backend} = Data::iRealPro::Output::HTML::;
    }
    elsif ( !$self->{_backend} ) {
	require Data::iRealPro::Output::Imager;
	$self->{_backend} = Data::iRealPro::Output::Imager::;
    }

    for ( @{ $self->{_backend}->options } ) {
	$opts->{$_} = $options->{$_} if exists $options->{$_};
    }

    $self->{options} = $opts;
    return $self;
}

sub processfiles {
    my ( $self, @files ) = @_;
    my $opts = $self->{options};

    my $all = Data::iRealPro::Input->new($opts)->parsefiles(@files);
    $self->{_backend}->new($opts)->process( $all, $opts );
}

1;
