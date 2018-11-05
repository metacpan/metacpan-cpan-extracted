package My::Module::Recommend::All;

use 5.006002;

use strict;
use warnings;

use My::Module::Recommend::Any;
our @ISA = qw{ My::Module::Recommend::Any };

use Carp;
use Exporter qw{ import };

our $VERSION = '0.103';

our @EXPORT_OK = qw{ __all };

sub __all {
    my ( @args ) = @_;
    return __PACKAGE__->new( @args );
}

sub check {
    my ( $self ) = @_;
    my @missing;
    foreach my $m ( $self->modules() ) {
	eval "require $m; 1"
	    or push @missing, $m;
    }
    return @missing;
}


1;

__END__

=head1 NAME

My::Module::Recommend::All - Recommend unless all of a list of modules is installed.

=head1 SYNOPSIS

 use My::Module::Recommend::All qw{ __all };
 
 my $rec = __all( Fubar => <<'EOD' );
       All these modules are needed to frozz a gaberbucket. If your
       gaberbucket does not need frozzing you do not need this module.
 EOD
 
 print $rec->recommend();

=head1 DESCRIPTION

This module is private to this package, and may be changed or retracted
without notice. Documentation is for the benefit of the author only.

This module checks whether B<all> modules in given list are installed.
If not, it is capable of generating an explanatory message.

I am using this rather than the usual install tools' recommendation
machinery for greater flexibility, and because I personally have found
their output rather Draconian, and my correspondance indicates that my
users do too.

=head1 METHODS

This class is a subclass of C<My::Module::Recommend::Any>. It
supports the following methods which override those of the superclass.
These methods are private to this package and can be changed or
retracted without notice.

=head2 __all

 my $rec = __all( Foo => "bar\n" );

This convenience subroutine (B<not> method) wraps L<new()|/new>. It is
not exported by default, but can be requested explicitly.

=head2 check

 $rec->check()
     and warn 'Modules are missing';

This method checks to see if all of the given modules are installed. The
check is by C<eval "require $module_name; 1"> on each module. If all of
the modules are installed it returns nothing. If not, it returns the
names of the missing modules in list context, and the number of missing
modules in scalar context.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

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
