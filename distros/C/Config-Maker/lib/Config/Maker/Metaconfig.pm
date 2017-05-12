package Config::Maker::Metaconfig;

use utf8;
use warnings;
use strict;

use Carp;
use File::Spec;
use File::Basename;
use File::Temp qw(tempfile);

use Config::Maker;
use Config::Maker::Type;
use Config::Maker::Config;
use Config::Maker::Driver;

sub type {
    Config::Maker::Type->new(@_);
}

# Top-level element "search-path"

my $search = type(
    name => 'search-path',
    format => [simple => [zero_list => 'string']],
    contexts => [opt => '/'],
);

# Top-level element "output-dir"

my $output = type(
    name => 'output-dir',
    format => [simple => ['string']],
    contexts => [opt => '/'],
);

# Top-level element "cache-dir"

my $cached = type(
    name => 'cache-dir',
    format => [simple => ['string']],
    contexts => [opt => '/'],
);

# Top-level element "config"

my $config = type(
    name => 'config',
    format => ['named_group' => ['string']],
    contexts => [any => '/'],
);

# The template element

my $template = type(
    name => 'template',
    format => ['anon_group'],
    contexts => [any => $config],
);

my $src = type(
    name => 'src',
    format => [simple => ['string']],
    contexts => [one => $template],
);

my $out = type(
    name => 'out',
    format => [simple => ['string']],
    contexts => [opt => $template],
);

my $command = type(
    name => 'command',
    format => [simple => ['string']],
    contexts => [opt => $template],
);
$template->addchecks(mand => 'out|command');

my $cache = type(
    name => 'cache',
    format => [simple => ['string']],
    contexts => [opt => $template],
);

my $enc = type(
    name => 'enc',
    format => [simple => ['string']],
    contexts => [opt => $template],
);

# Metatypes...

sub metatype {
    my ($name) = @_;
    type(
	name => $name,
	format => [simple => ['string']],
	contexts => [opt => '//'],
    );
}

metatype('meta');
metatype('template');
metatype('output');

# And now the real code...

sub _qual($$) {
    my ($file, $dir) = @_;
    return unless $file;
    if(File::Spec->file_name_is_absolute($file)) {
	return $file;
    } else {
	return File::Spec->rel2abs($file, $dir);
    }
}

sub _get_cfg {
    Config::Maker::Config->new(@_);
}

our @unlink;

sub do {
    my ($class, $metaname, $noinst, $force) = @_;
    
    my $meta = Config::Maker::Config->new($metaname)->{root};

    local @Config::Maker::path = @{$meta->getval('search-path', ['/etc/'])};
    { local $"=', '; DBG "Search path: @Config::Maker::path"; }

    my $outdir = $meta->getval('output-dir', '/etc/');
    DBG "Output-dir: $outdir";

    my $cachedir = $meta->getval('cache-dir', '/var/cache/configit/');
    DBG "Cache-dir: $cachedir";

    # For each config file and each template...
    for my $cfg ($meta->get('config')) {
	LOG "Processing config $cfg";
	my $conf = _get_cfg($cfg->{-value});
	for my $tmpl ($cfg->get('template')) {
	    my ($fh, $name, $cache, $output);

	    # Find output name...
	    $output = $tmpl->get('out');
	    if($output) {
		$output = _qual($output, $outdir);
		($fh, $name) = tempfile(
		    basename($output, qr/\..*/) . ".cmXXXXXX",
		    DIR => dirname($output));
	    } else {
		$output = '';
		($fh, $name) = tempfile(
		    basename($tmpl->get1('src'), qr/\..*/) . ".cmXXXXXXXX",
		    DIR => File::Spec->tmpdir);
	    }
	    DBG "Using $name as temporary for $tmpl output";
	    push @unlink, $name;

	    # Find cache name...
	    $cache = $tmpl->get('cache');
	    if($cache) {
		$cache = _qual($cache, $cachedir);
		$fh = Config::Maker::Tee->new($fh, $cache);
	    }

	    # Set up the magical elements for the config...
	    $conf->set_meta(meta => $meta);
	    $conf->set_meta(template => $tmpl);
	    $conf->set_meta(output => $output);
	    # Process the thing...
	    Config::Maker::Driver->process(
		$tmpl->get1('src'),
		$conf, $fh, $tmpl->get('enc'),
	    );

	    $tmpl->{-data} = [$fh, $name, $cache];
	    close $fh;
	}
    }

    # Now, for each template install the temporary file...
    if($noinst) {
	for my $tmpl ($meta->get('config/template')) {
	    my ($fh, $name, $cache) = @{$tmpl->{-data}};
	    if($cache && $fh->cmpcache) {
		LOG "Output of ".$tmpl->get('src')." unchanged";
		next unless $force;
	    }
	    @unlink = grep { $_ ne $name } @unlink;
	    my $dest;
	    if($dest = _qual($tmpl->get('out'), $outdir)) {
		print STDOUT "Install: $name $dest\n";
	    }
	    if($dest = $tmpl->get('command')) {
		print STDOUT "Invoke: $dest < $name\n";
	    }
	}
    } else {
	for my $tmpl ($meta->get('config/template')) {
	    my ($fh, $name, $cache) = @{$tmpl->{-data}};
	    if($cache && $fh->cmpcache) {
		LOG "Output of ".$tmpl->get('src')." unchanged";
		next unless $force;
	    }
	    my $dest;
	    if($dest = _qual($tmpl->get('out'), $outdir)) {
		LOG "Installing $dest";
		rename $name, $dest
		    or croak "Failed to install $dest: $!";
		@unlink = grep { $_ ne $name } @unlink;
		$name = $dest;
	    }
	    if($dest = $tmpl->get('command')) {
		LOG "Invoking $dest";
		my $pid = fork;
		croak "Failed to fork: $!" unless defined $pid;
		unless($pid) { # The child...
		    open STDIN, '<', $name;
		    exec $dest;
		    die "Failed to exec $dest: $!";
		}
		# The parent...
		waitpid($pid, 0) != -1
		    or croak "Wait failed: $!";
		croak "Command failed: $?" if "$?";
	    }
	    if($cache) {
		$fh->savecache;
	    }
	}
    }
    # should be done...(!)
}

END {
    foreach(@unlink) {
	unlink $_ or warn "Unlinking `$_' failed: $!";
    }
}

1;

__END__

=head1 NAME

Config::Maker::Metaconfig - Definies and processes the metaconfig directives.

=head1 SYNOPSIS

  use Config::Maker

  Config::Maker::Metaconfig->do($metafile);

=head1 DESCRIPTION

This module defines types for the C<config> directive and their subdirectives,
that are used in the metaconfig. It has only one public method, C<do>, which
loads metaconfig from a file.

Note: The metaconfig can only be read from a file.

See L<configit(1)> for description of metaconfig directives.

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm), Config::Maker::Schema(3pm).

=cut
# arch-tag: a49cb2b5-850a-4724-bd4f-707f66c90277
