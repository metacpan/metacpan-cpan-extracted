package Daje::Tools::Filechanged;
use Mojo::Base -base, -signatures;

use Digest::SHA qw(sha256_hex);
use Mojo::File;

# Daje::Tools::Filechanged - It's new $module
#
# SYNOPSIS
# ========
#
#  use Daje::Tools::Filechanged;
#
#  my $changes = Daje::Tools::Filechanged->new(
#
#  )->is_file_changed(
#
#      $file_path_name, $old_hash
#  ):
#
# DESCRIPTION
# ===========
#
# Daje::Tools::Filechanged is a tool to check if two hashes are equal
#
#
# METHODS
# =======
#
#  my $changed = $self->is_file_changed($file_path_name, $old_hash);
#
# Is the hashes different ?
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 janeskil1525@gmail.com
#

our $VERSION = "0.02";

# Is the hashes different ?
sub is_file_changed($self, $file_path_name, $old_hash) {
    my $result = 0;
    my $path = Mojo::File->new($file_path_name);
    my $new_hash = $self->load_new_hash($path);
    $old_hash = "" unless defined $old_hash;
    if ($new_hash ne $old_hash) {
        $result = 1;
    }
    return $result;
}

# Load new hash
sub load_new_hash($self, $path) {
    my $file_content = $path->slurp;
    my $hash = sha256_hex($file_content);
    return $hash;
}

1;

__END__





#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Daje::Tools::Filechanged


=head1 SYNOPSIS


 use Daje::Tools::Filechanged;

 my $changes = Daje::Tools::Filechanged->new(

 )->is_file_changed(

     $file_path_name, $old_hash
 ):



=head1 DESCRIPTION

Daje::Tools::Filechanged - It's new $module


Daje::Tools::Filechanged is a tool to check if two hashes are equal




=head1 REQUIRES

L<Mojo::File> 

L<Digest::SHA> 

L<Mojo::Base> 


=head1 METHODS


 my $changed = $self->is_file_changed($file_path_name, $old_hash);

Is the hashes different ?


=head1 AUTHOR


janeskil1525 janeskil1525@gmail.com



=head1 LICENSE


Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

