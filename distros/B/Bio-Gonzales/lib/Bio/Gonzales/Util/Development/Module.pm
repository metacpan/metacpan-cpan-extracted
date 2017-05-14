#!/usr/bin/env perl
#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Util::Development::Module;
use Carp;

use File::Spec;
use Path::Class;
use Path::Class::Dir;
use Path::Class::File;
use Bio::Gonzales::Util::Development::File qw/find_root/;
use File::Find;
use List::MoreUtils qw/any/;
use Cwd;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(find_module_root);

=head1 NAME

Bio::Gonzales::Util::Development::Module - functions handy for module development

=head1 SYNOPSIS

    use Bio::Gonzales::Util::Development::Module qw/find_module_root/;
    my $module_path = find_module_root("/path/under/module/file");

=head1 EXPORT

=over 4

=item find_module_root

=back

=head1 SUBROUTINES/METHODS

=head2 find_module_root

tires to find a module root for a given file or dir. returns undef, if not successfull

=cut 
sub find_module_root {
    find_root( { location => $_[0], files => [], dirs => [ 'lib', 't' ] } );
}

1;
