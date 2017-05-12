package App::FileDedup;
$App::FileDedup::VERSION = '0.001';
# ABSTRACT: Command wrapper around L<FileDedup> using MooseX::App::Simple
use strict;
use warnings;

use File::Dedup;
use MooseX::App::Simple;
use MooseX::Types::Moose qw/Bool Str/;

option 'nonrecursive' => (
   is            => 'ro',
   isa           => Bool,
   default       => 0,
   cmd_aliases   => [qw(f)],
   cmd_flag      => 'non-recursive',
   documentation => 'Only do a top-level search',
);

option 'dontask' => (
   is            => 'ro',
   isa           => Bool,
   default       => 0,
   cmd_aliases   => [qw(n)],
   cmd_flag      => 'dont-ask',
   documentation => 'Purge files without an interactive prompt; off by default',
);

option 'group' => (
   is            => 'ro',
   isa           => Bool,
   default       => 0,
   cmd_aliases   => [qw(g)],
   documentation => 'Group duplicate files into subfolders instead of deleting',
);

parameter 'directory' => (
   is            => 'ro',
   isa           => Str,
   required      => 1,
   documentation => 'Directory to begin searching for duplicates',
);

sub run {
   my ($self) = @_;

   my $deduper = File::Dedup->new(
      directory => $self->directory,
      ask       => !$self->dontask,
      recursive => !$self->nonrecursive,
      group     => $self->group,
   );
   $deduper->dedup;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileDedup - Command wrapper around L<FileDedup> using MooseX::App::Simple

=head1 VERSION

version 0.001

=head1 AUTHOR

Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Hunter McMillen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
