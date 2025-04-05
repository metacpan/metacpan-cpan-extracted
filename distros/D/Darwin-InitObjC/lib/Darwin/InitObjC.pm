package Darwin::InitObjC;
use strict;
use warnings;

use Config ();

our $VERSION = '0.001';

sub init {
    require DynaLoader;
    DynaLoader::dl_load_file("/System/Library/Frameworks/Foundation.framework/Foundation");
}

my $maybe_init;

sub maybe_init {
    return if $maybe_init;
    if ($^O eq "darwin" && $Config::Config{perlpath} eq "/usr/bin/perl") {
        init();
    }
    $maybe_init = 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Darwin::InitObjC - initializes Objective-C runtime

=head1 SYNOPSIS

  use Darwin::InitObjC;

  Darwin::InitObjC::maybe_init();

  my $pid = fork // die;
  if ($pid == 0) {
    do_something();
    exit;
  }
  wait;

=head1 DESCRIPTION

Darwin::InitObjC initializes Objective-C runtime.

In macOS 13+, initialising Objective-C APIs in forked processes are treated as errors.
So you may see the following errors when executing your scripts:

  objc[80048]: +[NSString initialize] may have been in progress in another thread when fork() was called.
  objc[80048]: +[NSString initialize] may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug.

A workaround is to initilize Objective-C runtime before calling fork(2).

=head1 SEE ALSO

https://bugs.ruby-lang.org/issues/14009

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
