# Data::Report::Base.pm -- Base class for reporters
# RCS Info        : $Id: Base.pm,v 1.10 2006/06/08 13:11:05 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Dec 28 13:18:40 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Jun  6 22:13:56 2006
# Update Count    : 317
# Status          : Unknown, Use with caution!

package Data::Report::Base;

=head1 NAME

Data::Report::Base - Base class for reporter plugins

=head1 SYNOPSIS

This module implements that basic functionality common to all reporters.

Its documentation still has to be written.

=cut

use strict;
use warnings;
use Carp;

my $style_pat = qr/^[a-zA-Z]\w*$/;

################ User API ################

sub new {
    my ($class, $args) = @_;
    $class = ref($class) || $class;

    my $type = delete($args->{type});
    my $style = delete($args->{style}) || "default";
    my $self = bless { _base_type   => lc($type),
		       _base_fields => [],
		       _base_fdata  => {},
		       _base_style  => $style,
		     }, $class;

    $self->_checkname($style)
      or croak("Invalid style name: \"$style\"");
    foreach my $arg ( keys(%$args) ) {
	my $val = delete($args->{$arg});
	if ( my $c = $self->can("set_$arg") ) {
	    $c->($self, $val);
	}
	else {
	    croak("Unhandled attribute: \"$arg\"");
	}
    }

    # Return object.
    $self;
}

sub start {
    my $self = shift;
    $self->_argcheck(0);
    croak("No layout specified") unless $self->{_base_fdata};
    croak("Reporter already started") if $self->{_base_started};

    $self->{_base_needpre} = 1;
    $self->{_base_needhdr} = 1;
    $self->{_base_needskip} = 0;

    $self->set_output(\*STDOUT) unless $self->{_base_out};
    $self->set_style("default") unless $self->{_base_style};
    $self->set_topheading($self->can("_top_heading"))
      unless $self->{_base_topheading};
    $self->set_heading($self->can("_std_heading"))
      unless $self->{_base_heading};
    $self->set_stylist($self->can("_std_stylist"))
      unless $self->{_base_stylist};
    $self->{_base_close} ||= sub {};

    $self->{_base_started} = 1;
    $self->{_base_used} = 0;
}

sub add {
    my ($self, $data) = @_;
    croak("Reporter not started") unless $self->{_base_started};

    while ( my($k,$v) = each(%$data) ) {
	next if $k =~ /^_/;
	croak("Invalid field: \"$k\"\n")
	  unless defined $self->{_base_fdata}->{$k};
    }

}

sub finish {
    my $self = shift;
    $self->_argcheck(0);
    croak("Reporter not started") unless $self->{_base_started};
    $self->{_base_started} = 0;
}

sub close {
    my $self = shift;
    $self->_argcheck(0);
    croak("Reporter is not finished") if $self->{_base_started};
    $self->{_base_close}->();
}

################ Attributes ################

#### Type

sub get_type { shift->{_base_type} }

#### Style

sub set_style {
    my ($self, $style) = @_;
    $self->_argcheck(1);
    $self->_checkname($style)
      or croak("Invalid style name: \"$style\"");
    $self->{_base_style} = $style;
}

sub get_style {
    my $self = shift;
    $self->_argcheck(0);
    $self->{_base_style};
}

#### Layout

sub set_layout {
    my ($self, $layout) = @_;
    $self->_argcheck(1);
    foreach my $col ( @$layout ) {
	if ( $col->{name} ) {
	    $self->_checkname($col->{name})
	      or croak("Invalid column name: \"$col->{name}\"");
	    my $a = { name     => $col->{name},
		      title    => $col->{title} || ucfirst(lc(_T($a->{name}))),
		      width    => $col->{width} || length($a->{title}),
		      align    => $col->{align} || "<",
		      style    => $col->{style} || $col->{name},
		      truncate => $col->{truncate},
		    };
	    $self->_checkname($a->{style})
	      or croak("Invalid column style: \"$a->{style}\"");
	    $self->{_base_fdata}->{$a->{name}} = $a;
	    push(@{$self->{_base_fields}}, $a);
	}
	else {
	    croak("Missing column name in layout\n");
	}
    }

    # Return object.
    $self;
}

#### Fields (order of)

sub set_fields {
    my ($self, $f) = @_;
    $self->_argcheck(1);

    my @nf;			# new order of fields

    foreach my $fld ( @$f ) {
	my $a = $self->{_base_fdata}->{$fld};
	croak("Unknown field: \"$fld\"\n")
	  unless defined($a);
	push(@nf, $a);
    }
    $self->{_base_fields} = \@nf;

    # PBP: Return nothing sensible.
    return;
}

sub get_fields {
    my $self = shift;
    $self->_argcheck(0);
    [ map { $_->{name} } @{$self->{_base_fields}} ];
}

#### Width (set one or more)

sub set_width {
    my ($self, $w) = @_;

    while ( my($fld,$width) = each(%$w) ) {
	croak("Unknown field: \"$fld\"\n")
	  unless defined($self->{_base_fdata}->{$fld});
	my $ow = $self->{_base_fdata}->{$fld}->{width};
	if ( $width =~ /^\+(\d+)$/ ) {
	    $ow += $1;
	}
	elsif ( $width =~ /^-(\d+)$/ ) {
	    $ow -= $1;
	}
	elsif ( $width =~ /^(\d+)\%$/ ) {
	    $ow *= $1;
	    $ow = int($ow/100);
	}
	elsif ( $width =~ /^\d+$/ ) {
	    $ow = $width;
	}
	else {
	    croak("Invalid width specification \"$width\" for field \"$fld\"\n");
	}
	$self->{_base_fdata}->{$fld}->{width} = $ow;
    }

    # PBP: Return nothing sensible.
    return;
}

#### Width (get all)

sub get_widths {
    my $self = shift;
    $self->_argcheck(0);
    { map { $_ => $self->{_base_fdata}->{$_}->{width} } $self->get_fields }
}

#### Output

sub set_output {
    my ($self, $out) = @_;
    $self->_argcheck(1);
    $self->{_base_close} = sub {};
    if ( ref($out) ) {
	if ( UNIVERSAL::isa($out, 'SCALAR') ) {
	    $self->{_base_out} = sub { $$out .= join("", @_) };
	}
	elsif ( UNIVERSAL::isa($out, 'ARRAY') ) {
	    $self->{_base_out} = sub {
		push(@$out, map { +"$_\n" } split(/\n/, $_)) foreach @_;
	    };
	}
	else {
	    $self->{_base_out}   = sub { print {$out} (@_) };
	    $self->{_base_close} = sub { CORE::close($out) or croak("Close: $!") };
	}
    }
    else {
	open(my $fd, ">", $out)
	  or croak("Cannot create \"$out\": $!");
	$self->{_base_out}   = sub { print {$fd} (@_) };
	$self->{_base_close} = sub { CORE::close($fd) or croak("Close \"$out\": $!") };
    }
}

#### Stylist

sub set_stylist {
    my ($self, $stylist_code) = @_;
    $self->_argcheck(1);
    croak("Stylist must be a function (code ref)")
      if $stylist_code && !UNIVERSAL::isa($stylist_code, 'CODE');
    $self->{_base_stylist} = $stylist_code;
}

sub get_stylist {
    my ($self) = @_;
    $self->_argcheck(0);
    $self->{_base_stylist};
}

#### Heading generator

sub set_heading {
    my ($self, $heading_code) = @_;
    $self->_argcheck(1);
    croak("Header must be a function (code ref)")
      if $heading_code && !UNIVERSAL::isa($heading_code, 'CODE');
    $self->{_base_heading} = $heading_code;
}

sub get_heading {
    my ($self) = @_;
    $self->_argcheck(0);
    $self->{_base_heading};
}

sub set_topheading {
    my ($self, $heading_code) = @_;
    $self->_argcheck(1);
    croak("Header must be a function (code ref)")
      if $heading_code && !UNIVERSAL::isa($heading_code, 'CODE');
    $self->{_base_topheading} = $heading_code;
}

sub get_topheading {
    my ($self) = @_;
    $self->_argcheck(0);
    $self->{_base_topheading} || sub {};
}

################ Friend methods ################

sub _argcheck {
    my ($pkg, $exp) = @_;
    my ($package, $filename, $line, $subroutine) = do { package DB; caller(1) };
    my $got = scalar(@DB::args)-1;
    return if $exp == $got;
    $got ||= "none";
    $Carp::CarpLevel++;
    Carp::croak($subroutine." requires ".
	  ( $exp == 0 ? "no arguments" :
	    $exp == 1 ? " 1 argument" :
	    " $exp arguments" ).
	  " ($got supplied)");
}

sub _get_fields {
    my $self = shift;
    $self->_argcheck(0);
    $self->{_base_fields};
}

sub _get_fdata {
    my $self = shift;
    $self->_argcheck(0);
    $self->{_base_fdata};
}

sub _print {
    my $self = shift;
    $self->{_base_out}->(@_);
    $self->{_base_used}++;
}

sub _started {
    my $self = shift;
    $self->_argcheck(0);
    $self->{_base_started};
}

sub _getstyle {
    my ($self, $row, $cell) = @_;
    $self->_argcheck(defined $cell ? 2 : 1);
    my $stylist = $self->{_base_stylist};
    return unless $stylist;

    return $stylist->($self, $row) unless $cell;

    my $a = $stylist->($self, "*",  $cell) || {};
    my $b = $stylist->($self, $row, $cell) || {};
    return { %$a, %$b };
}

sub _checkhdr {
    my $self = shift;
    $self->_argcheck(0);
    if ( $self->{_base_needhdr} ) {
	$self->{_base_needhdr} = 0;
	$self->_pageskip if $self->can("_pageskip");
	$self->get_topheading->($self);
	$self->get_heading->($self);
    }
}

sub _needhdr {
    my $self = shift;
    $self->_argcheck(1);
    $self->{_base_needhdr}   = shift;
}
sub _does_needhdr {
    my $self = shift;
    $self->_argcheck(0);
    $self->{_base_needhdr};
}

sub _checkname {
    my $self = shift;
    $self->_argcheck(1);
    shift =~ $style_pat;
}

1;

=head1 AUTHOR

Johan Vromans, C<< <jvromans at squirrel.nl> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-report at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Report>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Squirrel Consultancy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
