#!/usr/bin/env perl
#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Util::Development;
use Carp;
use warnings;
use strict;
use Carp;
use File::Spec;
use Path::Class;
use Path::Class::Dir;
use Path::Class::File;
use File::Find;
use List::MoreUtils qw/any/;
use Cwd;
use Data::Dumper;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(find_files_to_complete filter_files env_add);

sub env_add {
  my $e = shift;

  while ( my ( $k, $v ) = each %$e ) {
    $ENV{$k} = join ":", $v, $ENV{$k};
  }
}

=head1 NAME

Bio::Gonzales::Util::Development - functions handy for general development

=head1 SYNOPSIS

    use Bio::Gonzales::Util::Development qw/find_files_to_complete/;
    my $files = find_files_to_complete({ root => "/path/to/module", exclude_full => [qr/^blib/], exclude_file => [qr/~$/]} );

=head1 EXPORT

=over 4

=item find_files_to_complete

=back

=head1 SUBROUTINES/METHODS

=head2 find_files_to_complete

finds files for vim completion

=cut 

sub find_files_to_complete {
    my ($c) = @_;
    my @target_files;

    $c->{include_file} //= [];
    $c->{exclude_full} //= [];
    $c->{exclude_file} //= [];

    find(
        {
            wanted => sub {

                push @target_files, $_
                    if ( _filter_file( $c, $_ ) );

            },
            no_chdir => 1,
        },
        $c->{root},
    );
    return \@target_files;
}

sub _filter_file {
    my ( $c, $f ) = @_;
    return if ( -d $f );
    my $current_file = file($f)->relative;
    return 1
        if ( any { $current_file->basename =~ /$_/ } @{ $c->{include_file} } );
    return
        if ( any { $current_file =~ /$_/ } @{ $c->{exclude_full} } );
    return
        if ( any { $current_file->basename =~ /$_/ } @{ $c->{exclude_file} } );
    return 1;
}

=head2 filter_files

filter a set of files by given patterns.

=cut
sub filter_files {
    my ( $c, @files ) = @_;
    my @filtered = grep { _filter_file( $c, $_ ) } @files;
    return @filtered;
}

1;
