package ACME::Error;

use strict;

use vars qw[$VERSION];
$VERSION = '0.03';

sub import {
  my $class = shift;
  if ( my $style = shift ) {
    my $package = qq[ACME::Error::$style];
    my $args    = join q[', '], @_;
    eval qq[use $package '$args'];
    die $@ if $@;
    
    my $nested = -1;

    { no strict 'refs';
      $SIG{__WARN__} = sub {
        local $SIG{__WARN__};
        $nested++;
        my $handler = $package . q[::warn_handler];
        warn &{$handler}(@_) unless $nested;
        warn @_ if $nested;
        $nested--;
      };

      $SIG{__DIE__}  = sub {
        local $SIG{__DIE__};
        $nested++;
        my $handler = $package . q[::die_handler];
        die &{$handler}(@_) unless $nested;
        die @_ if $nested;
        $nested--;
      };
    }

#    $SIG{__WARN__} = sub {
#      my $handler = $package . q[::warn_handler];
#      {
#       no strict 'refs';
#       warn &{$handler} , "\n" if exists &{$handler};
#      }
#    };

#    $SIG{__DIE__}  = sub {
#      my $handler = $package . q[::die_handler];
#      {
#       no strict 'refs';
#       die &{$handler}, "\n" if exists &{$handler};
#      }
#    };
  }
}

1;
__END__

=head1 NAME

ACME::Error - Never have boring errors again!

=head1 SYNOPSIS

  use ACME::Error SHOUT;
  
  warn "Warning"; # WARNING!

=head1 DESCRIPTION

C<ACME::Error> is a front end to Perl error styles.  C<$SIG{__WARN__}> and C<$SIG{__DIE__}>
are intercepted.  Backends are pluggable.  Choose a backend by specifying it when you
C<use ACME::Error SomeStyle>;

=head2 Writing Backends

Writing backends is easy.  See L<ACME::Error::SHOUT> for a simple example.  Basically your
backend needs to be in the C<ACME::Error> namespace and defines just two subroutines, C<warn_handler>
and C<die_handler>.  The arguments passed to your subroutine are the same as those passed to the signal
handlers, see L<perlvar> for more info on that.  You are expected to C<return> what you want to be
C<warn>ed or C<die>d.

You can also run use an C<import> function.  All arguments passed to C<ACME::Error> after
the style to use will be passed to the backend.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 COPYRIGHT

Copyright (c) 2002 Casey R. West <casey@geeknest.com>.  All
rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1).

=cut
