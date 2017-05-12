use strict;
use warnings;

package Cogit::Util;
$Cogit::Util::VERSION = '0.001001';
use Sub::Exporter::Progressive -setup => {
   exports => [qw( current_git_dir find_git_dir is_git_dir )],
   groups  => {default => [qw( current_git_dir )],},
};
use Path::Class qw( dir );



sub is_git_dir {
   my ($dir) = @_;
   return if not -e $dir->subdir('objects');
   return if not -e $dir->subdir('refs');
   return if not -e $dir->file('HEAD');
   return 1;
}


sub find_git_dir {
   my $start = shift;

   return $start if is_git_dir($start);

   my $repodir = $start->subdir('.git');

   return $repodir if -e $repodir and is_git_dir($repodir);

   return find_git_dir($start->parent)
     if $start->parent->absolute ne $start->absolute;

   return undef;
}


sub current_git_dir {
   return find_git_dir(dir('.'));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Util

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

    use Cogit::Util;
    use Cogit;

    my $repo = Cogit->new(
        gitdir => current_git_dir(),
    );

=head1 FUNCTIONS

=head2 is_git_dir

Determines if the given C<$dir> has the basic requirements of a Git repository dir.

( ie: either a checkouts C<.git> folder, or a bare repository )

    if ( is_git_dir( $dir ) ) {
        ...
    }

=head2 find_git_dir

    my $dir = find_git_dir( $subdir );

Finds the closest C<.git> or bare tree that is either at C<$subdir> or somewhere above C<$subdir>

If C<$subdir> is inside a 'bare' repo, returns the path to that repo.

If C<$subdir> is inside a checkout, returns the path to the checkouts C<.git> dir.

If C<$subdir> is not inside a git repo, returns a false value.

=head2 current_git_dir

Finds the closest C<.git> or bare tree by walking up parents.

    my $git_dir = current_git_dir();

If C<$CWD> is inside a bare repo somewhere, it will return the path to the bare repo root directory.

If C<$CWD> is inside a git checkout, it will return the path to the C<.git> folder of that checkout.

If C<$CWD> is not inside any recognisable git repo, will return a false value.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
