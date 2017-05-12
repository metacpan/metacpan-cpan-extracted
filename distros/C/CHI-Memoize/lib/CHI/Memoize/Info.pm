package CHI::Memoize::Info;
$CHI::Memoize::Info::VERSION = '0.07';
use Moo;
use strict;
use warnings;

has [ 'orig', 'wrapper', 'cache', 'key_prefix' ] => ( is => 'ro' );

1;

__END__

=pod

=head1 NAME

CHI::Memoize::Info - Information about a memoized function

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use CHI::Memoize qw(:all);
    memoize('func');

    # then

    my $info = memoized('func');
    
    # The CHI cache where memoize results are stored
    #
    my $cache = $info->cache;
    $cache->clear;

    # The original function, and the new wrapped function
    #
    my $orig = $info->orig;
    my $wrapped = $info->wrapped;

=head1 METHODS

=over

=item cache

The CHI cache where memoize results are stored for this function

=item orig

The original code reference when C<memoize> was called

=item wrapped

The wrapped code reference that C<memoize> created

=back

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
