package Config::Maker;

use utf8;
use warnings;
use strict;
use 5.006_001;

use Carp;
use Config::Maker::Encode;

require overload;

# DEBUG
sub LOG;
sub DBG;
sub DUMP;

BEGIN {
    if($::QUIET) {
	*LOG = sub {};
	*DBG = sub {};
    } elsif(!$::VERBOSE) {
	*LOG = sub { print STDERR @_, "\n"; };
	*DBG = sub {};
    } else { # VERBOSE
	*LOG = \&Carp::carp;
	*DBG = \&Carp::carp;
    }

    if($::DEBUG) {
	require Data::Dumper;
	*DUMP = sub {
	    print STDERR '>' x 40, ' ', shift, "\n",
		Data::Dumper::Dumper(@_),
		'<' x 40, "\n";
	}
    } else {
	*DUMP = sub {};
    }

    LOG($::ENCODING_LOG) if $::ENCODING_LOG;
    if($::ENCODING) {
	LOG("Selected $::ENCODING as system encoding");
    } else {
	LOG("Charset conversion not available!");
    }
}
# /DEBUG

use Config::Maker::Value; # overloading...
use Config::Maker::Grammar; # Build the parser...

our $parser = Config::Maker::Grammar->new();

our $VERSION = '0.007';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(LOG DBG DUMP);

# This must be after "constants"

require Config::Maker::Config;
require Config::Maker::Driver;
require Config::Maker::Schema;
require Config::Maker::Metaconfig;
require Config::Maker::Eval;

our $fenc = qr/(?:(?:(?:file)?en)coding|fenc)[:=]\s*/;

sub unbackslash {
    eval qq{"\\$_[0]"}
}

sub environment {
    if(defined $ENV{$_[0]}) {
	return $ENV{$_[0]};
    } else {
	warn "Undefined environment variable $_[0] used";
	return '';
    }
}

sub unquote_single {
    local $_ = $_[0];
    s/\A'//;
    s/'\Z//;
    s/\\'/'/g;
    return $_;
}

sub unquote_double {
    local $_ = $_[0];
    s/\A"//;
    s/"\Z//;
    s/\\(			# Backslashed stuff:
	  ["\$\\]		    # Things to escape
	| [tnrfbae]		    # Simple escape codes
	| x[[:xdigit:]]{2}	    # Hex-code
	| x\{[[:xdigit:]]{1,8}\}    # Wide hex-code
	| [0-7]{1,3}		    # Octal-code
	| c[@-_]		    # Control-char
	| N\{\w*\}		    # Named char
      ) |
      \$ (\w+) |		# Undelimited substitution
      \$ \{ (\w+) \}		# Delimited substitution
      / $1 ? unbackslash($1) :
	 $2 ? environment($2) :
	 $3 ? environment($3) : die "This match does not work"/xe;
    return $_;
}

sub truecmp {
    $_[2] ? overload::StrVal($_[1]) cmp overload::StrVal($_[0])
	  : overload::StrVal($_[0]) cmp overload::StrVal($_[1]);
}

sub limit {
    my ($num, $min, $max) = @_;
    return undef if $num < $min;
    return undef if $max && $num > $max;
    return $num;
}

# A non-catching eval...
sub exe {
    no warnings;
    no strict;
    DBG "Evaluating qq{$_[0]} in " . (wantarray ? "list" : (defined wantarray ? "scalar" : "void")) . " context";
    if(wantarray) {
	my @r = eval qq/package Config::Maker::Eval; $_[0]/;
	die $@ if $@;
	return @r;
    } elsif(defined wantarray) {
	my $r = eval qq/package Config::Maker::Eval; $_[0]/;
	die $@ if $@;
	return $r;
    } else {
	eval qq/package Config::Maker::Eval; $_[0]/;
	die $@ if $@;
    }
}

our @path = ('.');

sub locate {
    my ($file) = @_;
    if(File::Spec->file_name_is_absolute($file)) {
	return $file;
    } else {
	for(@path) {
	    my $f = File::Spec->rel2abs($file, $_);
	    DBG "Trying: $f";
	    return $f if -r $f;
	}
	local $" = ', ';
	croak "Can't find $file in @path";
    }
}


$::RD_HINT = 1;

1;

__END__

=head1 NAME

Config::Maker - File (especialy config) generation library.

=head1 SYNOPSIS

  use Config::Maker

  $metaconfig = Config::Maker::Config->new($metaconfigfile)

  $config = Config::Maker::Config->new($configfile)

  open OUT, '>', $outputfile;

  Config::Maker::Driver->process($templatefile, $config, \*OUT);

  close OUT;

=head1 DESCRIPTION

This is the main module for Config::Maker file generation library. It provides
generic rules for the parser and few routines used from them.

For usage description see the L<configit(1)> manpage. For details about varous
parts of the library see respective module's documentation.

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), Config::Maker::Config(3pm), Config::Maker::Driver(3pm),
Config::Maker::Path(3pm), Config::Maker::Type(3pm), Config::Maker::Path(3pm),
perl(1), Parse::RecDescent(3pm).

=cut
# arch-tag: 5adf1fd4-5ed3-40e8-bbb0-acfe5f713b1c
