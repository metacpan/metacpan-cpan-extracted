package Carp::Always::DieOnly;

our $DATE = '2015-01-05'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.006;

use Carp ();

sub _die {
    die @_ if ref($_[0]);
    if ($_[-1] =~ /\n$/s) {
        my $arg = pop @_;
        $arg =~ s/(.*)( at .*? line .*?\n$)/$1/s;
        push @_, $arg;
    }
    die &Carp::longmess;
}

my %OLD_SIG;

BEGIN {
  @OLD_SIG{qw(__DIE__)} = @SIG{qw(__DIE__)};
  $SIG{__DIE__} = \&_die;
}

END {
  @SIG{qw(__DIE__)} = @OLD_SIG{qw(__DIE__)};
}

1;
# ABSTRACT: Like Carp::Always, but only print stacktrace on die()

__END__

=pod

=encoding UTF-8

=head1 NAME

Carp::Always::DieOnly - Like Carp::Always, but only print stacktrace on die()

=head1 VERSION

This document describes version 0.01 of Carp::Always::DieOnly (from Perl distribution Carp-Always-DieOnly), released on 2015-01-05.

=head1 SYNOPSIS

 % perl -MCarp::Always::DieOnly script.pl

=head1 SEE ALSO

L<Carp::Always>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Carp-Always-DieOnly>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Carp-Always-DieOnly>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Always-DieOnly>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
