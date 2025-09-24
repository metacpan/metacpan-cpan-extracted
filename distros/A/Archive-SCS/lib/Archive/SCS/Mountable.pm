use v5.28;
use warnings;
use Object::Pad 0.73;

class Archive::SCS::Mountable 1.08;


sub handles_path ($class, $path, $header) {
  warnings::warnif deprecated => sprintf
    "%s->handles_file() is deprecated; please implement %s->handles_path()", ($class) x 2;
  $class->handles_file($path->openr_raw, $header);
}


method path () {
  warnings::warnif deprecated => sprintf
    "%s->file() is deprecated; please implement %s->path()", (__CLASS__) x 2;
  $self->file;
}

1;


=head1 NAME

Archive::SCS::Mountable - Something that can be mounted by Archive::SCS

=head1 DESCRIPTION

Represents an SCS archive file or a similarly mountable entity.

This may become a role in future.

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2025 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
