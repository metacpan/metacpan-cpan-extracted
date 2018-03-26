package Bat::Interpreter::Role::FileStore;

use utf8;

use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.003';    # VERSION

=encoding utf-8

=head1 NAME

Bat::Interpreter::Role::FileStore - Role for accessing bat files

=head1 SYNOPSIS


     
=head1 DESCRIPTION

Role for accessing bat files. With this role is easy to read the bat files
from local filesystem, Hadoop File System, MogileFS, ...

=head1 METHODS

=cut

=head2 get_contents

Returns the contents of the filename

=cut

requires 'get_contents';

1;
