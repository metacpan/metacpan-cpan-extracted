use Object::Pad qw(:experimental(:all));

package App::BS;

use constant VERSION => "0.01";

class App::BS : does(App::BS::Common);

use utf8;
use v5.40;

use TOML::Tiny 'from_toml';
use Const::Fast;
use Const::Fast::Exporter;
use Syntax::Keyword::Try;

our $VERSION = VERSION;

method $import : common (@args) {
    use utf8;
    use v5.40;
};

ADJUSTPARAMS($params) {
    __CLASS__->$import($params)
};

try {
    use BS::Common;
    use App::BS::Common;
    my ( $toml, $error ) => from_toml($App::BS::defaultconfig_inline);
    die $error if $error;
    const our $config_default => $toml
}
catch ($e) {
    BS::Common::dmsg { err => $e }
}

const our $defaultconfig_inline => <<'...';
#
# Default/Test Configuration Schema
#

[example_document]
  # This is a TOML document
  title = "TOML Example"

  [owner]
    name = "Tom Preston-Werner"
    dob = 1979-05-27T07:32:00-08:00

  [database]
      enabled = true
      ports = [ 8000, 8001, 8002 ]
      data = [ ["delta", "phi"], [3.14] ]
      temp_targets = { cpu = 79.5, case = 72.0 }

  [servers]

  [servers.alpha]
    ip = "10.0.0.1"
    role = "frontend"

  [servers.beta]
    ip =   "10.0.0.2"
    role = "backend"

[bs] # The "bs" section heading can be omitted for global/top-level options
    root = "/bs"
    user = "bu"
    group = "alpm"
    targets = [
      "thanksmom-mba52", "cincotuf"
    ]

[targets.thanksmom-mba52]
    carch = "x86_64"
    ip = "192.168.86.152"
    domain = "lan"

[pkgbase]
    resolution_order = [ 'local', 'repo' ]
    resolution_order.repo = [ 'pacman.conf' ]

[pkgbuild]
    root = "/bs" # You can (re-)configure many top-level options for each section
                # idividually
    debug = 1
    clean_chroot = 1
    makepkg_clean_all = 1 # Equivalent to adding C,c to makepkg_args for now
    chroot => "$root/"

[repo]
    [universe]
        target_arch = [ "x86_64", "x86_64_v3", "aarch64" ]
        siglevel = [ 'DatabaseOptional', 'PackageTrustedOnly' ]

        # There are plently of helper preset variables to keep your config
        # consise, and easy to parse/decontstruct progmatically
        server = "file://$sroot/repo/$repo/os/$arch"
...

__END__

=encoding utf-8

=head1 NAME

App::BS - Build system for PKGBUILD based Linux distributions

=head1 SYNOPSIS

Using BS in your own script:

	use ut8;
	use v5.40;

	use BS;
	...

Update and rebuild your entire toolchain recursively. This is expected to
perform each operation such that the conditions outlined i
https://wiki.archlinux.org/title/DeveloperWiki:Toolchain_maintenance are properly met:

	$ pkgbuild -r gcc llvm clang lld rustc go
	pkgbuild queue: linux-api-headers glibc binutils gcc glibc binutils gcc llvm clang lld rustc go
	...

=head1 DESCRIPTION

App::BS is a Perl distribution providing a set of integrated build tools and helpers for already existing tools on Arch Linux and closely-related distributions. It aids creating installable package files for any repository or directory containing a valid PKGBUILD, whether sourced from AUR, Arch Linux or your distribution's official package repositories, or a local path. Simply provide a package name or some sort of identifier such as a file within or a provided shared object to `bs` with your operation of choice or one of the operation specific scripts such as `pkgbuild`, `pkgdepends`, `pkgprovides` `srcinfo`, etc. and it will search for a matching package base in every enabled source, with priority determined order defined from your configuration file(s), environment or CLI arguments. Before any serious operation, the user is presented each relevant PKGBUILD in a pager (`vfim`) for review if updated or being viewed for the first time, and packages are built in a clean CHROOT by default unless configured otherwise (see: `--keep-clean`, `--start-clean`, `--makepkg-cleanall`, `--makechrootpkg-clean`)

=head1 LICENSE

Copyright (C) Ian P Bradley.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ian P Bradley E<lt>ian.bradley@studiocrabapple.comE<gt>

=cut
