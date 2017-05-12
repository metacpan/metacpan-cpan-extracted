package Array::AllUtils;

our $DATE = '2016-04-13'; # DATE
our $VERSION = '0.002'; # VERSION

#IFUNBUILT
# use strict 'vars', 'subs';
# use warnings;
#END IFUNBUILT

require Exporter;
our @EXPORT_OK = qw(
                       first
                       firstidx
               );

sub import {
  my $pkg = caller;

  # (RT88848) Touch the caller's $a and $b, to avoid the warning of
  #   Name "main::a" used only once: possible typo" warning
  #no strict 'refs';
  #${"${pkg}::a"} = ${"${pkg}::a"};
  #${"${pkg}::b"} = ${"${pkg}::b"};

  goto &Exporter::import;
}

# BEGIN_BLOCK: first
sub first(&$) {
    my $code = shift;
    for (@{$_[0]}) {
        return $_ if $code->($_);
    }
    undef;
}
# END_BLOCK: first

# BEGIN_BLOCK: firstidx
sub firstidx(&$) {
    my $code = shift;
    my $i = 0;
    for (@{$_[0]}) {
        return $i if $code->($_);
        $i++;
    }
    -1;
}
# END_BLOCK: firstidx

1;
# ABSTRACT: Like List::Util & List::MoreUtils but for array(ref)

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::AllUtils - Like List::Util & List::MoreUtils but for array(ref)

=head1 VERSION

This document describes version 0.002 of Array::AllUtils (from Perl distribution Array-AllUtils), released on 2016-04-13.

=head1 SYNOPSIS

 use Array::AllUtils qw(first);

 my @ary = (1..20);

 $elem = first { defined and $_ % 2 } $ary;

=head1 DESCRIPTION

B<PURELY EXPERIMENTAL AND CURRENTLY INCOMPLETE.>

This module provides functions like those provided by L<List::Util> and
L<List::MoreUtils> but the list is passed as arrayref, to avoid the cost of
argument copying which can be significant when the size of the list is large.
See an illustration in L<Bencher::Scenario::PERLANCAR::In>.

=head1 FUNCTIONS

=head2 first

=head2 firstidx

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-AllUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-AllUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-AllUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<List::Util>, L<List::MoreUtils>, L<List::AllUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
