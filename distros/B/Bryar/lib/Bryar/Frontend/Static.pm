package Bryar::Frontend::Static;
use base 'Bryar::Frontend::Base';
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.1';

=head1 NAME

Bryar::Frontend::Static - Static renderer for Bryar

=head1 DESCRIPTION

This is a frontend to Bryar which is used when Bryar is being used to create
static HTML pages.

=head1 SYNOPSIS

    my $frontend = Bryar::Frontend::Static->new(
        url   => "http://your.blog.site/base/",
        path  => "id_1234",
        fh    => \*file
    );
    $bryar->config->frontend($frontend);
    $bryar->go;

=cut

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub obtain_url { shift->{url} }
sub obtain_path_info { shift->{path} }
sub obtain_params { () }
sub get_header { "" }
sub send_data { my $fh = shift->{fh}; print $fh "\n",@_ }
sub send_header { }

1;

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>
