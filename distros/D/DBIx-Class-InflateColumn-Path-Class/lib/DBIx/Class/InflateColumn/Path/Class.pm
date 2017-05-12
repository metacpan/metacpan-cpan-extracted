package DBIx::Class::InflateColumn::Path::Class;

use strict;
use warnings;
use Path::Class;

our $VERSION = '0.001001';

sub register_column {
  my ($self, $column, $info, @rest) = @_;
  $self->next::method($column, $info, @rest);

  my $inflate;
  if( exists $info->{'is_file'} || $info->{'is_file'} ){
    $inflate = sub { return Path::Class::file(shift) };
  } elsif( exists $info->{'is_dir'} || $info->{'is_dir'} ){
    $inflate = sub { return Path::Class::dir(shift) };
  } else {
    return;
  }

  $self->inflate_column
    (
     $column => {
                 inflate => $inflate,
                 deflate => sub { return shift->stringify },
                }
    );
}

1;

__END__;

=head1 NAME

DBIx::Class::InflateColumn::Path::Class
inflate / deflate values into Path::Class::File or Path::Class::Dir objects

=head1 SYNOPSIS

  __PACKAGE__->load_components(qw/InflateColumn::Path::Class Core/);
  __PACKAGE__->add_columns(
      file_path => {
          datatype => 'TEXT',
          size     => 65535,
          is_nullable => 1,
          is_file => 1, #or is_dir => 1
      },
  )
   
  #...
   
   $obj->file_path->basename;

=head1 DESCRIPTION

This module inflates/deflates designated columns into L<Path::Class::File> or
L<Path::Class::Dir> objects.

=head1 METHODS

=head2 register_column

Extends the original method to setup inflators and deflators for the column.
This is an internal method and you should never really have to use it.

=head1 SEE ALSO

L<Path::Class>
L<DBIx::Class>
L<DBIx::Class::InflateColumn>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Guillermo Roditi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
