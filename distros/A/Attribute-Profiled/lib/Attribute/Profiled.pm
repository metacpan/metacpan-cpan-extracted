package Attribute::Profiled;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

use Attribute::Handlers;
use Hook::LexWrap;

our $_Profiler;

sub UNIVERSAL::Profiled : ATTR(CODE) {
    my($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my $meth = *{$symbol}{NAME};
    no warnings 'redefine';

    wrap $symbol,
	pre  => sub {
	    unless ($_Profiler) {
		$_Profiler = Benchmark::Timer::ReportOnDestroy->new;
	    }
	    $_Profiler->start("$package\::$meth");
	},
	post => sub {
	    $_Profiler->stop("$package\::$meth");
	};
}

package Benchmark::Timer::ReportOnDestroy;
use base qw(Benchmark::Timer);

sub DESTROY {
    my $self = shift;
    $self->report;
}


1;
__END__

=head1 NAME

Attribute::Profiled - Profiles specific methods in class

=head1 SYNOPSIS

  package SomeClass;
  use Attribute::Profiled;

  sub long_running_method : Profiled { }

=head1 DESCRIPTION

Attribute::Profiled provides a way to profile specific methods with
attributes. This module uses Benchmark::Timer to profile elapsed times
for your calls to the methods with Profiled attribute on.

Profiling report will be printed to STDERR at the end of program
execution.

=head1 TODO

=over 4

=item *

Options where to print profiling report.

=item *

Allows public way to get reports in any timing other than the end of
execution. Currently you can do it by explicitly calling report() on
C<$Attribute::Profiled::_Profiler>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Attribute::Handlers>, L<Benchmark::Timer>

=cut
