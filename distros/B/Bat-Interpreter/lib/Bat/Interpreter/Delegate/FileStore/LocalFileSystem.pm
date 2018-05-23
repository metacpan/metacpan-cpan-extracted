package Bat::Interpreter::Delegate::FileStore::LocalFileSystem;

use utf8;

use Moose;
use Path::Tiny;
use namespace::autoclean;

with 'Bat::Interpreter::Role::FileStore';

our $VERSION = '0.008';    # VERSION

sub get_contents {
    my $self     = shift();
    my $filename = shift();
    $filename = Path::Tiny::path($filename);
    return $filename->slurp;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bat::Interpreter::Delegate::FileStore::LocalFileSystem

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use Bat::Interpreter;
    use Bat::Interpreter::Delegate::FileStore::LocalFileSystem;

    my $local_filesystem = Bat::Interpreter::Delegate::FileStore::LocalFileSystem->new;

    my $interpreter = Bat::Interpreter->new(batfilestore => $local_filesystem);
    $interpreter->run('/var/cmd_storage/my.cmd'); 

=head1 DESCRIPTION

Accessing bat/cmd files via local file system

=head1 NAME

Bat::Interpreter::Delegate::FileStore::LocalFileSystem - 

=head1 METHODS

=head2 get_contents

Returns the contents of the filename

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
