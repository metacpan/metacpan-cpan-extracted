package Acme::AutoloadAll;
# ABSTRACT: Use every function everywhere.

our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

our $DEBUG = 0;

BEGIN {
    $SIG{__WARN__} = sub {
        warn @_ unless $_[0] =~ m/inherited AUTOLOAD/;
    };
}

sub find_function {
    my $function = shift;
    my $package  = shift || 'main';
    my $seen     = shift || {};
    # remove last ::
    $package =~ s/::$//;

    return undef if (exists($seen->{$package}));

    print STDERR "Searching '$function' in '$package'...\n" if ($DEBUG);

    # check if the current package has the function
    my $sub = $package->can($function);
    print STDERR "Found!\n" if ($DEBUG && (ref($sub) eq 'CODE'));
    return $sub if (ref($sub) eq 'CODE');

    $seen->{$package} = 1;

    # check sub packages
    my $symbols = do { no strict 'refs'; \%{$package . '::'} };
    my @packages = grep { $_ =~ m/::$/ } keys(%$symbols);
    foreach my $pkg (@packages) {
        $pkg = $package . '::' . $pkg unless ($package eq 'main');
        $sub = find_function($function, $pkg, $seen);
        return $sub if (ref($sub) eq 'CODE');
    }

    # not found
    return undef;
}

sub UNIVERSAL::AUTOLOAD {
    (my $function = $UNIVERSAL::AUTOLOAD) =~ s/.*:://;
    my $sub = find_function($function);
    print STDERR "Not found!\n" if ($DEBUG && (ref($sub) ne 'CODE'));
    goto &$sub if (ref($sub) eq 'CODE');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::AutoloadAll - Use every function everywhere.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Scalar::Util ();
  use Acme::AutoloadAll;

  if (looks_like_number(42)) {
      print "yay\n";
  }

=head1 DESCRIPTION

This module allows you to call any function ever seen by your perl instance.
As long as you used/required a module in the past you can now call its functions everywhere.

=head1 HOW IT WORKS

The module puts an AUTOLOAD sub into UNIVERSAL so every package has it.
When it is called (i.e. your current package doesn't have the called sub itself)
it traverses all known packages (it examines main:: and from there on everything else).
The first found function will then be executed.

=head1 LIMITATIONS

Obviously calling 'new' in a package that does not have it is kind of not clever as a lot of packages have that sub.
So you cannot really be sure which one is called...

Also calling subs working on a $self only works, if your package has the guts the called sub expects.

Other than that it might collide with other AUTOLOADs, so use with care ;-)

=head2 WARNING

As calling inherited AUTOLOAD on non member subs is deprecated this module might stop working in the future...

=head1 SEE ALSO

=over 4

=item *

L<Acme::Everything>

=back

=head1 AUTHOR

Felix Bytow <felix.bytow@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Felix Bytow.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
