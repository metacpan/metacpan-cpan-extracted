use strict;
use warnings;
package Sub::Exporter::GlobExporter;
# ABSTRACT: export shared globs with Sub::Exporter collectors
$Sub::Exporter::GlobExporter::VERSION = '0.005';
use Scalar::Util ();

use Sub::Exporter -setup => [ qw(glob_exporter) ];

#pod =head1 SYNOPSIS
#pod
#pod First, you write something that exports globs:
#pod
#pod   package Shared::Symbol;
#pod
#pod   use Sub::Exporter;
#pod   use Sub::Exporter::GlobExport qw(glob_exporter);
#pod
#pod   use Sub::Exporter -setup => {
#pod     ...
#pod     collectors => { '$Symbol' => glob_exporter(Symbol => \'_shared_globref') },
#pod   };
#pod
#pod   sub _shared_globref { return \*Common }
#pod
#pod Now other code can import C<$Symbol> and get their C<*Symbol> made an alias to
#pod C<*Shared::Symbol::Common>.
#pod
#pod If you don't know what this means or why you'd want to do it, you may want to
#pod stop reading now.
#pod
#pod The other class can do something like this:
#pod
#pod   use Shared::Symbol '$Symbol';
#pod
#pod   print $Symbol; # prints the scalar entry of *Shared::Symbol::Common
#pod
#pod ...or...
#pod
#pod   use Shared::Symbol '$Symbol' => { -as => 'SharedSymbol' };
#pod
#pod   print $SharedSymbol; # prints the scalar entry of *Shared::Symbol::Common
#pod
#pod ...or...
#pod
#pod   my $glob;
#pod   use Shared::Symbol '$Symbol' => { -as => \$glob };
#pod
#pod   print $$glob; # prints the scalar entry of *Shared::Symbol::Common
#pod
#pod =head1 OVERVIEW
#pod
#pod Sub::Exporter::GlobExporter provides only one routine, C<glob_exporter>, which
#pod may be called either by its full name or may be imported on request.
#pod
#pod   my $exporter = glob_exporter( $default_name, $globref_locator );
#pod
#pod The routine returns a L<collection validator|Sub::Exporter/Collector
#pod Configuration> that will export a glob into the importing package.  It will
#pod export it under the name C<$default_name>, unless an alternate name is given
#pod (as shown above).  The glob that is installed is specified by the
#pod C<$globref_locator>, which can be either the globref itself, or a reference to
#pod a string which will be called on the exporter
#pod
#pod For an example, see the L</SYNOPSIS>, in which a method is defined to produce
#pod the globref to share.  This allows the glob-exporting package to be subclassed,
#pod so the subclass may choose to either re-use the same glob when exporting or to
#pod export a new one.
#pod
#pod If there are entries in the arguments to the globref-exporting collector
#pod I<other> than those beginning with a dash, a hashref of them will be passed to
#pod the globref locator.  In other words, if we were to write this:
#pod
#pod   use Shared::Symbol '$Symbol' => { arg => 1, -as => 2 };
#pod
#pod It would result in a call like the following:
#pod
#pod   my $globref = Shared::Symbol->_shared_globref({ arg => 1 });
#pod
#pod =cut

my $is_ref;
BEGIN {
  $is_ref = sub {
    return(
      !  Scalar::Util::blessed($_[0])
      && Scalar::Util::reftype($_[0]) eq $_[1]
    );
  };
}

sub glob_exporter {
  my ($default_name, $globref) = @_;

  my $globref_method = $is_ref->($globref, 'GLOB')   ? sub { $globref }
                     : $is_ref->($globref, 'SCALAR') ? $$globref
                     : Carp::confess("illegal glob locator '$globref'");

  return sub {
    my ($value, $data) = @_;

    my @args = defined $value
      ? ({ map {; $_ => $value->{$_} } grep { ! /^-/ } keys %$value })
      : ();

    my $globref = $data->{class}->$globref_method(@args);

    my $name;
    $name = defined $value->{'-as'} ? $value->{'-as'} : $default_name;

    if (ref $name) {
      $$name = *$globref;
    } else {
      my $sym = "$data->{into}::$name";

      {
        no strict 'refs';
        *{$sym} = *$globref;
      }
    }

    # Why is this line here?  I have no recollection of it. -- rjbs, 2015-11-04
    $_[0] = $globref;

    return 1;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Exporter::GlobExporter - export shared globs with Sub::Exporter collectors

=head1 VERSION

version 0.005

=head1 SYNOPSIS

First, you write something that exports globs:

  package Shared::Symbol;

  use Sub::Exporter;
  use Sub::Exporter::GlobExport qw(glob_exporter);

  use Sub::Exporter -setup => {
    ...
    collectors => { '$Symbol' => glob_exporter(Symbol => \'_shared_globref') },
  };

  sub _shared_globref { return \*Common }

Now other code can import C<$Symbol> and get their C<*Symbol> made an alias to
C<*Shared::Symbol::Common>.

If you don't know what this means or why you'd want to do it, you may want to
stop reading now.

The other class can do something like this:

  use Shared::Symbol '$Symbol';

  print $Symbol; # prints the scalar entry of *Shared::Symbol::Common

...or...

  use Shared::Symbol '$Symbol' => { -as => 'SharedSymbol' };

  print $SharedSymbol; # prints the scalar entry of *Shared::Symbol::Common

...or...

  my $glob;
  use Shared::Symbol '$Symbol' => { -as => \$glob };

  print $$glob; # prints the scalar entry of *Shared::Symbol::Common

=head1 OVERVIEW

Sub::Exporter::GlobExporter provides only one routine, C<glob_exporter>, which
may be called either by its full name or may be imported on request.

  my $exporter = glob_exporter( $default_name, $globref_locator );

The routine returns a L<collection validator|Sub::Exporter/Collector
Configuration> that will export a glob into the importing package.  It will
export it under the name C<$default_name>, unless an alternate name is given
(as shown above).  The glob that is installed is specified by the
C<$globref_locator>, which can be either the globref itself, or a reference to
a string which will be called on the exporter

For an example, see the L</SYNOPSIS>, in which a method is defined to produce
the globref to share.  This allows the glob-exporting package to be subclassed,
so the subclass may choose to either re-use the same glob when exporting or to
export a new one.

If there are entries in the arguments to the globref-exporting collector
I<other> than those beginning with a dash, a hashref of them will be passed to
the globref locator.  In other words, if we were to write this:

  use Shared::Symbol '$Symbol' => { arg => 1, -as => 2 };

It would result in a call like the following:

  my $globref = Shared::Symbol->_shared_globref({ arg => 1 });

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 CONTRIBUTOR

=for stopwords David Steinbrunner

David Steinbrunner <dsteinbrunner@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
