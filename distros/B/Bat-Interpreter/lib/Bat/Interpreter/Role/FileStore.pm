package Bat::Interpreter::Role::FileStore;

use utf8;

use Moo::Role;
use namespace::autoclean;

our $VERSION = '0.019';    # VERSION

requires 'get_contents';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bat::Interpreter::Role::FileStore

=head1 VERSION

version 0.019

=head1 SYNOPSIS

=head1 DESCRIPTION

Role for accessing bat files. With this role is easy to read the bat files
from local filesystem, Hadoop File System, MogileFS, ...

=head1 NAME

Bat::Interpreter::Role::FileStore - Role for accessing bat files

=head1 METHODS

=head2 get_contents

Returns the contents of the filename

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
