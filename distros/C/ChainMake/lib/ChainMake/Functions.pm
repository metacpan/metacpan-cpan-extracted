package ChainMake::Functions;

use strict;
use Config;
use ChainMake;
use Exporter 'import';

our $VERSION = $ChainMake::VERSION;

our @EXPORT_OK = qw(
    configure
    targets
    target
    chainmake
    execute_perl
    execute_system
    unlink_timestamps
    delete_timestamp
);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
 
my $cm=new ChainMake();

if ($Config{useithreads}) {
    eval "require ChainMake::Parallel";
    $cm=new ChainMake::Parallel();
}

sub configure { $cm->configure(@_) };
sub target { $cm->targets(@_) };
sub targets { $cm->targets(@_) };
sub chainmake { $cm->chainmake(@_) };
sub execute_perl { $cm->execute_perl(@_) };
sub execute_system { $cm->execute_system(@_) };
sub unlink_timestamps { $cm->unlink_timestamps(@_) };
sub delete_timestamp { $cm->delete_timestamp(@_) };

1;

__END__

=head1 NAME

ChainMake::Functions - Function-oriented interface to ChainMake

=head1 SYNOPSIS

See the synopsis in L<ChainMake|ChainMake>.

=head1 DESCRIPTION

This module provides a function-oriented interface to L<ChainMake|ChainMake>.
All methods are available as functions. When running a parallel perl,
L<ChainMake::Parallel|ChainMake::Parallel> is used.

=head1 CAVEATS/BUGS

None known.

=head1 AUTHOR/COPYRIGHT

This is $Id: Functions.pm 1233 2009-03-15 21:37:21Z schroeer $.

Copyright 2008-2009 Daniel Schröer (L<schroeer@cpan.org>). Any feedback is appreciated.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut  
