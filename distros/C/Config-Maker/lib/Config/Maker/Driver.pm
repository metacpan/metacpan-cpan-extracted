package Config::Maker::Driver;

use utf8;
use warnings;
use strict;

use Carp;
use Parse::RecDescent;

use Config::Maker;
use Config::Maker::Encode;
use Config::Maker::Option;
use Config::Maker::Path;
use Config::Maker::Tee;

my $parser = $Config::Maker::parser;

sub apply {
    for my $e (@_) {
	if(ref $e eq 'CODE') {
	    $e->();
	} elsif(ref $e) {
	    $e->do();
	} else {
	    print $e;
	}
    }
}

sub process {
    my ($class, $file, $config, $outfh, $outenc) = @_;

    croak "Invalid config!"
	unless UNIVERSAL::isa($config, 'Config::Maker::Config');

    local $Config::Maker::Eval::config = $config;
    local $_ = $config->{root};

    my ($code, $enc) = $class->load($file);
    
    $outenc ||= $enc;
    encmode($outfh, $outenc);

    LOG("Processing the template with output in $outenc");
    my $old = select;
    select $outfh;
    eval { $code->() };
    select $old;
    die $@ if $@;
}

our %cache;

sub load {
    my ($class, $file) = @_;
    my ($fh, $text);
    my $enc = 'system';

    $file = Config::Maker::locate($file);

    if($cache{$file}) {
	DBG "Getting template $file from cache";
	return wantarray ? @{$cache{$file}} : $cache{$file}[0];
    }

    open($fh, '<', $file)
	or croak "Failed to open $file: $!";
    {
	local $/;
	$text = <$fh>;
    }
    close $fh;

    if((substr($text, 0, 250) =~ /\[#[^#]*$Config::Maker::fenc([[:alnum:]_-]+)/) ||
       (substr($text, -250)   =~ /\[#[^#]*$Config::Maker::fenc([[:alnum:]_-]+)/)) {
       $enc = $1;
    }
    $text = decode($enc, $text);

    LOG("Loading template $file encoded $enc");
    my $out = $parser->template($text);
    croak "Template file $file contained errors"
	unless defined $out;

    my $code = sub { apply(@$out); };
    $cache{$file} = [$code, $enc];
    return wantarray ? ($code, $enc) : $code;
}

1;

__END__

=head1 NAME

Config::Maker::Driver - Template processor

=head1 SYNOPSIS

  # This is normaly only used from Config::Maker::Metaconfig->do

=head1 DESCRIPTION

This processes a template. Much of it's work is actualy done by the
C<Config::Maker::Grammar> parser. It has two methods, C<apply> and C<process>.
C<process> method is just a wrapper that appropriately opens files, sets up
encodings and runs the parser using starting rule C<template>. The C<apply>
method is used to print out the tree of closures and text snippets built by the
parser. The closures are reponsible to call C<apply> for their enclosed
subtrees.

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: 6a447a76-79d0-4b62-a624-f3e9e615f261
