[![Actions Status](https://github.com/marlencrabapple/App-bs/actions/workflows/test.yml/badge.svg)](https://github.com/marlencrabapple/App-bs/actions)
# NAME

App::BS - Build system for PKGBUILD based Linux distributions

# SYNOPSIS

Using BS in your own script:

        use ut8;
        use v5.40;

        use BS;
        ...

Update and rebuild your entire toolchain recursively. This is expected to
perform each operation such that the conditions outlined i
https://wiki.archlinux.org/title/DeveloperWiki:Toolchain\_maintenance are properly met:

        $ pkgbuild -r gcc llvm clang lld rustc go
        pkgbuild queue: linux-api-headers glibc binutils gcc glibc binutils gcc llvm clang lld rustc go
        ...

# DESCRIPTION

App::BS is a Perl distribution providing a set of integrated build tools and helpers for already existing tools on Arch Linux and closely-related distributions. It aids creating installable package files for any repository or directory containing a valid PKGBUILD, whether sourced from AUR, Arch Linux or your distribution's official package repositories, or a local path. Simply provide a package name or some sort of identifier such as a file within or a provided shared object to \`bs\` with your operation of choice or one of the operation specific scripts such as \`pkgbuild\`, \`pkgdepends\`, \`pkgprovides\` \`srcinfo\`, etc. and it will search for a matching package base in every enabled source, with priority determined order defined from your configuration file(s), environment or CLI arguments. Before any serious operation, the user is presented each relevant PKGBUILD in a pager (\`vfim\`) for review if updated or being viewed for the first time, and packages are built in a clean CHROOT by default unless configured otherwise (see: \`--keep-clean\`, \`--start-clean\`, \`--makepkg-cleanall\`, \`--makechrootpkg-clean\`)

# LICENSE

Copyright (C) Ian P Bradley.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ian P Bradley <ian.bradley@studiocrabapple.com>
