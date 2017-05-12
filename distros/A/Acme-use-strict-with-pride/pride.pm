package Acme::use::strict::with::pride;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.04';

our $script;

sub import {
  # OK. This is a big hack. I'm going to ignore any arguments.
  unshift @INC, sub {
    my ($self, $file) = @_;
    foreach my $dir (@INC) {
      next if ref $dir;
      my $full = "$dir/$file";
      if (open my $fh, "<", $full) {
	# Dave made us do this too:
	my @lines = ("use strict; use warnings;\n", "#line 1 \"$full\"\n");
	# You didn't see this:
	return ($fh, sub {
	  # We really ought to (a) document or rescind this feature
	  # (b) if we document it, change the implementation to use filter
	  # simple
	  # (c) if so, check whether it falls foul of the subtle trap of
	  # caller-filter leaves some data in the buffer, and filter gets to see
	  # it in $_ for a second time.
	  if (@lines) {
	    push @lines, $_;
	    $_ = shift @lines;
	    return length $_;
	  }
	  return 0;
	});
      }
    }
    return;
  }
};

1;
__END__

=head1 NAME

Acme::use::strict::with::pride - enforce bondage and discipline on very
naughty modules.

=head1 SYNOPSIS

  use Acme::use::strict::with::pride;
  # now all your naughty modules get to use strict; and use warnings;

=head1 ABSTRACT

using Acme::use::strict::with::pride causes all modules to run with
C<use strict;> and C<use warnings;>

B<Whether they like it or not> :-)

=head1 DESCRIPTION

Acme::use::strict::with::pride installs a code reference into C<@INC> that
intercepts all future C<use> and C<require> requests.  (code references in
C<@INC> were in 5.6.x, but were not documented until 5.8.0, which extends the
feature to allow objects in C<@INC>).

The subroutine in C<@INC> then finds the module using the normal C<@INC> path,
opens the file, and attaches a source filter that adds
"use strict; use warnings;" to the start of every file. This is naughty - it's
not a documented feature, it may be changed or removed with no notice, and the
current implementation is slightly buggy in subtle cases.

=head2 EXPORT

Nothing. There's no unimport method, so using strict with pride is a one way
trip. This could be construed as a bug or a feature, depending on your point
of view.

=head1 SEE ALSO

L<strict> L<warnings> L<Acme::USIG>

=head1 BUGS

There's no unimport. There's no way to specify an import list to
C<use strict;> or C<use warnings;>. There's no way to exclude specific
modules (eg C<Exporter>) from the clutches C<Acme::use::strict:with::pride>.
The error and warning handling is global, rather than being chained, and it
won't play nicely with error objects. The source filter in coderef C<@INC> is
undocumented, so I shouldn't be using it.

=head1 AUTHOR

Nicholas Clark, E<lt>nick@talking.bollo.cxE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002,2003 by Nicholas Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
