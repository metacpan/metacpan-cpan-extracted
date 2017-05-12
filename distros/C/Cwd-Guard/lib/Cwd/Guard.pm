package Cwd::Guard;

use strict;
use warnings;
use parent 'Exporter';

our @EXPORT_OK = qw/cwd_guard/;
our $Error;

our $VERSION = '0.05';

use constant USE_FCHDIR => eval { opendir my $dh, '.'; chdir $dh; 1 };
use if !USE_FCHDIR, Cwd => qw/getcwd/;

sub cwd_guard {
    my $dir = shift;
    __PACKAGE__->new($dir);
}

sub new {
    my $class = shift;
    my $dir = shift;
    my $cwd;
    if (USE_FCHDIR) { opendir $cwd, '.' } else { $cwd = getcwd() }
    my $callback = sub {
        chdir $cwd;
    };
    my $result = defined $dir ? chdir($dir) : chdir();
    $Error = $!;
    return unless $result;
    bless $callback, $class;
}

sub DESTROY {
    $_[0]->();
}


1;
__END__

=head1 NAME

Cwd::Guard - Temporary changing working directory (chdir)

=head1 SYNOPSIS

  use Cwd::Guard qw/cwd_guard/;
  use Cwd;

  my $dir = getcwd;
  MYBLOCK: {
      my $guard = cwd_guard('/tmp/xxxxx') or die "failed chdir: $Cwd::Guard::Error";
      # chdir to /tmp/xxxxx
  }
  # back to $dir


=head1 DESCRIPTION

CORE::chdir Cwd:: Guard can change the current directory (chdir) using a limited scope.

=head1 FUNCTIONS

=over 4

=item cwd_guard($dir);

chdir to $dir and returns Cwd::Guard object. return to current working directory, if this object destroyed.
if failed to chdir, cwd_guard return undefined value. You can get error messages with $Gwd::Guard::Error.

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<File::chdir>, L<File::pushd>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
