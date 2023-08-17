package Code::Style::Kit::Parts::Common;
use strict;
use warnings;
our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: commonly used features


use Import::Into;

# use strict
sub feature_strict_default { 1 }
sub feature_strict_export { strict->import() }
sub feature_strict_order { 1 }  # export this first

# try {} catch {} finally {};
sub feature_try_tiny_default { 1 }
sub feature_try_tiny_export_list { 'Try::Tiny' }

# croak, confess, etc.
sub feature_carp_default { 1 }
sub feature_carp_export_list { 'Carp' }

# No need to finish modules with 1;
sub feature_true_default { 1 }
sub feature_true_export {
    require true;
    true->import({ into => $_[1] });
}

# This must come after anything else that might change warning
# levels in the caller (e.g. Moose)
sub feature_fatal_warnings_default { 1 }
sub feature_fatal_warnings_export {
    warnings->import( FATAL => 'all' );
    # see L<< C<strictures> >>
    my @NONFATAL = grep { exists $warnings::Offsets{$_} }
        qw( exec
            recursion
            internal
            malloc
            newline
            experimental
            deprecated
            portable );
    warnings->unimport( FATAL => @NONFATAL );
    warnings->import( NONFATAL => @NONFATAL );
    warnings->unimport('once');
}
sub feature_fatal_warnings_order { 900 } # so we set its order value high

# Auto-clean up imported symbols
sub feature_namespace_autoclean_default { 1 }
sub feature_namespace_autoclean_export {
    require namespace::autoclean;
    namespace::autoclean->import(-cleanee=>$_[1]);
}
sub feature_namespace_autoclean_order { 910 } # more-or-less last thing

sub feature_log_any_default { 1 }
sub feature_log_any_export {
    require Log::Any;
    Log::Any->import::into($_[1],'$log');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Style::Kit::Parts::Common - commonly used features

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Common);
  1;

Then:

  package My::Module;
  use My::Kit;

  # you have strict, fatal warnings, Try::Tiny, Carp, true,
  # namespace::autoclean, Log::Any

=head1 DESCRIPTION

This part defines a bunch of the features, all enabled by default:

=over

=item C<strict>

imports L<< C<strict> >>

=item C<try_tiny>

imports L<< C<Try::Tiny> >>

=item C<carp>

imports L<< C<Carp> >>

=item C<true>

imports L<< C<true> >>

=item C<fatal_warnings>

fatalizes the same warnings as C<use strictures 2;>

=item C<log_any>

imports the C<$log> variable from L<< C<Log::Any> >>.

=back

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
