package Bat::Interpreter::Delegate::FileStore::LocalFileSystem;

use utf8;

use Moose;
use Path::Tiny;
use namespace::autoclean;

with 'Bat::Interpreter::Role::FileStore';

our $VERSION = '0.001';    # VERSION

=encoding utf-8

=head1 NAME

Bat::Interpreter::Delegate::FileStore::LocalFileSystem - 

=head1 SYNOPSIS

    use Bat::Interpreter;
    use Bat::Interpreter::Delegate::FileStore::LocalFileSystem;

    my $local_filesystem = Bat::Interpreter::Delegate::FileStore::LocalFileSystem->new;

    my $interpreter = Bat::Interpreter->new(batfilestore => $local_filesystem);
    $interpreter->run('/var/cmd_storage/my.cmd'); 

     
=head1 DESCRIPTION

Accessing bat/cmd files via local file system

=head1 METHODS

=cut

=head2 get_contents

Returns the contents of the filename

=cut

sub get_contents {
    my $self     = shift();
    my $filename = shift();
    $filename = Path::Tiny::path($filename);
    return $filename->slurp;
}

1;
