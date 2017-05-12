#
# This file is part of Config-Model-Approx
#
# This software is Copyright (c) 2013 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::Approx ;
{
  $Config::Model::Backend::Approx::VERSION = '1.009';
}

use Mouse ;
use Log::Log4perl qw(get_logger :levels);
use Carp ;
use File::Copy ;
use File::Path ;
use 5.010 ;


extends 'Config::Model::Backend::Any';

# optional
sub suffix { 
   return '.conf';
}

sub annotation {
    return 1 ; 
}


my $logger = Log::Log4perl::get_logger('Backend::Approx');

sub read {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    die "Cannot read $args{config_dir}$args{file}\n" unless defined $args{io_handle} ;

    $logger->info("loading config file $args{file}") if defined $args{file};
    my @lines = $args{io_handle}->getlines ;
    my $global = $self->read_global_comments(\@lines, '#') ;
    $self->node->annotation($global) ;
    
    my @data = $self->associates_comments_with_data(\@lines, '#') ;

    foreach my $item (@data) {
        my ($line,$note) = @$item ;

        my ($k,$v) = split /\s+/,$line,2 ;

	my $step = ($k =~ s/^\$//) ? $k 
                 : ($v =~ m!://!)  ? "distributions:".$k
                 :                 $k ; # old style parameter
	my $leaf = $self->node->grab(step => $step) ;
	$leaf->store($v) ;
	$leaf->annotation($note) ;
    }

    return 1;
}

sub write {
    my $self = shift ;
    my %args = @_ ;

    $logger->info("writing config file $args{file}");
    my $node = $args{object} ;
    my $ioh  = $args{io_handle} ;

    $ioh->print("## This file was written by 'cme edit approx'\n");
    $ioh->print("## You may modify the content of this file.\n\n");

    $ioh->printf("# %s\n", $node->annotation) if $node->annotation;

    # Using Config::Model::ObjTreeScanner would be overkill
    foreach my $elt ($node->get_element_name) {
	next if $elt eq 'distributions';

	# write value
	my $obj = $node->grab($elt) ;
        my $v = $obj->fetch ;

        if (defined $v) {
            $ioh->printf("# %s\n", $obj->annotation) if $obj->annotation;
            $ioh->printf("\$%-10s %s\n\n",$elt,$v) ;
        }
    }

    my $h = $node->fetch_element('distributions') ;
    foreach my $dname ($h->fetch_all_indexes) {
        my $d = $node->grab("distributions:$dname") ;

        my $note = $d->annotation;
        $ioh->print("# $note\n") if $note;
	$ioh->printf("%-10s %s\n",$dname,$d->fetch) ;
    }
    return 1;

}

1;

=head1 NAME

Config::Model::Backend::Approx - Approx configuration file editor

=head1 SYNOPSIS

 # This backend is loaded by Config::Model::Node

=head1 DESCRIPTION

This module provides a backend to read and write configuration files for Approx.


=head1 Methods

=head2 read (object => approx_root, io_handle => ...)

Read F<approx.conf> and load the data in the C<approx_root>
configuration tree.

=head2 write (object => approx_root, io_handle => ...)

Write data from the C<approx_root> configuration tree into
F<approx.conf>.

=head1 SEE ALSO

L<cme>, L<Config::Model::Backend::Any>,
