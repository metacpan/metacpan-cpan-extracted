package App::ansiecho;

our $VERSION = "0.03";

use v5.14;
use warnings;

use utf8;
use Encode;
use charnames ':full';
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}
use open IO => 'utf8', ':std';
use Pod::Usage;

use Getopt::EX::Hashed;

has debug      => spec => "      " ;
has no_newline => spec => " n !  " ;
has join       => spec => " j !  " ;
has escape     => spec => " e !  " , default => 1;
has rgb24      => spec => "   !  " ;
has separate   => spec => "   =s " , default => " ";
has help       => spec => " h    " ;
has version    => spec => " v    " ;

has '+help' => action => sub {
    pod2usage
	-verbose  => 99,
	-sections => [ qw(SYNOPSIS VERSION) ];
};

has '+version' => action => sub {
    say "Version: $VERSION";
    exit;
};

has terminate  => default => "\n";
has params     => default => [];

no Getopt::EX::Hashed;

use App::ansiecho::Util;
use Getopt::EX v1.24.1;
use Text::ANSI::Printf 2.01 qw(ansi_sprintf);

use List::Util qw(sum);

sub run {
    my $app = shift;
    local @ARGV = decode_argv @_;

    use Getopt::EX::Long qw(GetOptions Configure ExConfigure);
    ExConfigure BASECLASS => [ __PACKAGE__, "Getopt::EX" ];
    Configure qw(bundling no_getopt_compat pass_through);
    $app->getopt || pod2usage();
    $app->initialize();
    $app->{params} = \@ARGV;
    print join($app->{separate}, $app->retrieve()), $app->{terminate};
}

sub initialize {
    my $app = shift;
    $app->{terminate} = '' if $app->{no_newline};
    $app->{separate} = '' if $app->{join};
    if ($app->{separate}) {
	$app->{separate} = safe_backslash($app->{separate});
    }
    if (defined $app->{rgb24}) {
	$Getopt::EX::Colormap::RGB24 = !!$app->{rgb24};
    }
}

use Getopt::EX::Colormap qw(colorize ansi_code);

sub retrieve {
    my $app = shift;
    my $count = shift;
    my $in = $app->{params};
    my @out;
    my @pending;
    my(@style, @effect);

    my $append = sub {
	push @out, join '', splice(@pending), @_;
    };

    while (@$in) {
	my $arg = shift @$in;

	# -S
	if ($arg =~ /^-S$/) {
	    unshift @style, [ \&ansi_code ];
	    next;
	}
	# -c, -C
	if ($arg =~ /^-([cC])(.+)?$/) {
	    my $target = $1 eq 'c' ? \@effect : \@style;
	    my($color) = defined $2 ? safe_backslash($2) : $app->retrieve(1);
	    unshift @$target, [ \&colorize, $color ];
	    next;
	}
	# -F
	if ($arg =~ /^-(F)(.+)?$/) {
	    my($format) = defined $2 ? safe_backslash($2) : $app->retrieve(1);
	    unshift @style, [ \&ansi_sprintf, $format ];
	    next;
	}
	# -E
	if ($arg =~ /^-E$/) {
	    @style = ();
	    next;
	}

	#
	# -s, -i, -a : ANSI sequence
	#
	if ($arg =~ /^-([sia])(.+)?$/) {
	    my $opt = $1;
	    my $text = $2 // shift(@$in) // die "Not enough argument.\n";
	    my $code = ansi_code($text);
	    if ($opt eq 's') {
		$arg = $code;
	    } else {
		if (@out == 0 or $opt eq 'i') {
		    push @pending, $code;
		} else {
		    $out[-1] .= $code;
		}
		next;
	    }
	}
	#
	# -f : format
	#
	elsif ($arg =~ /^-f(.+)?$/) {
	    my($format) = defined $1 ? safe_backslash($1) : $app->retrieve(1);
	    my $n = sum map {
		{ '%' => 0, '*' => 2, '*.*' => 3 }->{$_} // 1
	    } $format =~ /(?| %(%) | %[-+ #0]*+(\*(?:\.\*)?|.) )/xg;
	    $arg = ansi_sprintf($format, $app->retrieve($n));
	}
	#
	# normal string argument
	#
	else {
	    if ($app->{escape}) {
		$arg = safe_backslash($arg);
	    }
	}

	#
	# apply @effect and @style
	#
	for (splice(@effect), @style) {
	    my($func, @opts) = @$_;
	    $arg = $func->(@opts, $arg);
	}

	$append->($arg);

	if ($count) {
	    my $out = @out + !!@pending;
	    die "Unexpected behavior.\n" if $out > $count;
	    last if $out == $count;
	}
    }
    @pending and $append->();
    die "Not enough argument.\n" if $count and @out < $count;
    return @out;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::ansiecho - Command to produce ANSI terminal code

=head1 SYNOPSIS

    ansiecho [ options ] color-spec

=head1 DESCRIPTION

B<ansiecho> is a small command interface to produce ANSI terminal
code using L<Getopt::EX::Colormap> module.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
