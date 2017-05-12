#
# This file is part of App-CPAN2Pkg
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package App::CPAN2Pkg::Utils;
# ABSTRACT: various utilities for cpan2pkg
$App::CPAN2Pkg::Utils::VERSION = '3.004';
use Devel::Platform::Info::Linux;
use Exporter::Lite;
use File::ShareDir::PathClass qw{ dist_dir };
use FindBin                   qw{ $Bin };
use Path::Class;
 
our @EXPORT_OK = qw{ $LINUX_FLAVOUR $SHAREDIR $WORKER_TYPE };

my $root = dir($Bin)->parent;
our $IS_DEVEL  = -e $root->file("dist.ini" );
our $SHAREDIR  = $IS_DEVEL ? $root->subdir("share") : dist_dir("App-CPAN2Pkg");
our $LINUX_FLAVOUR = Devel::Platform::Info::Linux->new->get_info->{oslabel};
our $WORKER_TYPE   = "App::CPAN2Pkg::Worker::$LINUX_FLAVOUR";

1;

__END__

=pod

=head1 NAME

App::CPAN2Pkg::Utils - various utilities for cpan2pkg

=head1 VERSION

version 3.004

=head1 DESCRIPTION

This module provides some helper variables and subs, to be used on
various occasions throughout the code.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
