use 5.008;
use strict;
use warnings;

package Carp::Source::Always;
BEGIN {
  $Carp::Source::Always::VERSION = '1.101420';
}
# ABSTRACT: Warns and dies with stack backtraces and source code context
use Carp::Source;
our %options;

sub import {
    shift;
    %options = @_;
}

sub _warn {
    if ($_[-1] =~ /\n$/s) {
        my $arg = pop @_;
        $arg =~ s/ at .*? line .*?\n$//s;
        push @_, $arg;
    }
    $Carp::Source::CarpLevel = 1;
    warn Carp::Source::longmess_heavy(join('', grep { defined } @_), %options);
}

sub _die {
    if ($_[-1] =~ /\n$/s) {
        my $arg = pop @_;
        $arg =~ s/ at .*? line .*?\n$//s;
        push @_, $arg;
    }
    $Carp::Source::CarpLevel = 1;
    die Carp::Source::longmess_heavy(join('', grep { defined } @_), %options);
}
my %OLD_SIG;

BEGIN {
    @OLD_SIG{qw(__DIE__ __WARN__)} = @SIG{qw(__DIE__ __WARN__)};
    $SIG{__DIE__}                  = \&_die;
    $SIG{__WARN__}                 = \&_warn;
}

END {
    no warnings 'uninitialized';
    @SIG{qw(__DIE__ __WARN__)} = @OLD_SIG{qw(__DIE__ __WARN__)};
}
1;


__END__
=pod

=head1 NAME

Carp::Source::Always - Warns and dies with stack backtraces and source code context

=head1 VERSION

version 1.101420

=head1 DESCRIPTION

This module is meant as a debugging aid.

  use Carp::Source::Always;

makes every C<warn()> and C<die()> complain loudly, with stack traces and
source code context like L<Carp::Source>, in the calling package and
elsewhere. It can also be used on the command line:

  perl -MCarp::Source::Always script.pl

You can specify the same options as L<Carp::Source>'s C<source_cluck()> takes,
separated by commas. For example:

    perl -MCarp::Source::Always=lines,5,color,'yellow on_blue' script.pl

It does not work for one-liners because there is no file from which to load
source code.

This module does not play well with other modules which modify with
C<warn>, C<die>, C<$SIG{__WARN__}>, or C<$SIG{__DIE__}>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Source>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Carp-Source/>.

The development version lives at
L<http://github.com/hanekomu/Carp-Source/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

