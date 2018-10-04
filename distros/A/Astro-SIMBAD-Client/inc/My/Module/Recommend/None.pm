package My::Module::Recommend::None;

use 5.008;

use strict;
use warnings;

use My::Module::Recommend::Any;
our @ISA = qw{ My::Module::Recommend::Any };

use Carp;
use Exporter qw{ import };

our $VERSION = '0.038';

our @EXPORT_OK = qw{ __none };

sub __none {
    my ( @args ) = @_;
    return __PACKAGE__->new( @args );
}

sub check {
    return;
}


1;

__END__

=head1 NAME

My::Module::Recommend::None - Do not recommend an optional module.

=head1 SYNOPSIS

 use My::Module::Recommend::None qw{ __none };
 
 my $rec = __none( Fubar => <<'EOD' );
       This module is only used for testing.
 EOD
 
 my $msg;
 defined $msg = $rec->recommend()
     and print $msg;    # never executed

=head1 DESCRIPTION

This module is private to this package, and may be changed or retracted
without notice. Documentation is for the benefit of the author only.

This module keeps track of one or more optional modules but does not
check to see if they are installed. The idea is to make modules
available to the C<modules()> method without messing with them any other
way.

I am using this rather than the usual install tools' recommendation
machinery for greater flexibility, and because I personally have found
their output rather Draconian, and my correspondence indicates that my
users do too.

=head1 METHODS

This class is a subclass of C<My::Module::Recommend::Any>. It
supports the following methods which override those of the superclass.
These methods are private to this package and can be changed or
retracted without notice.

=head2 __none

 my $rec = __none( Foo => "bar\n" );

This convenience subroutine (B<not> method) wraps L<new()|/new>. It is
not exported by default, but can be requested explicitly.

=head2 check

 $rec->check()
     and warn 'Modules are missing';

This method simply returns.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org/>, or in electronic mail to the author.

=head1 AUTHOR

Tom Wyant (wyant at cpan dot org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
