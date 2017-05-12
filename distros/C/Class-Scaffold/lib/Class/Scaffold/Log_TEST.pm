use 5.008;
use warnings;
use strict;

package Class::Scaffold::Log_TEST;
BEGIN {
  $Class::Scaffold::Log_TEST::VERSION = '1.102280';
}
# ABSTRACT: Companion test class for the log class
use Test::More;
use parent 'Class::Scaffold::Test';
use constant PLAN => 2;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    # Use different ways of accessing the log: via the singleton object, or by
    # using the feature of turning a class method call into an instance call.
    my $log = $self->make_real_object->instance;
    isa_ok($log, $self->package);

    # manually turn off test mode so that the log won't output to STDERR; after
    # all, that's exactly what we want to test.
    $log->delegate->test_mode(0);
    $log->info('Hello');
    Class::Scaffold::Log->debug('a debug message that should not appear');
    $log->max_level(2);
    Class::Scaffold::Log->debug('a debug message that should appear');
    $log->set_pid;
    Class::Scaffold::Log->info('a message with %s and %s', qw/pid timestamp/);
    $log->clear_timestamp;
    $log->info('a message with pid but without timestamp');
    Class::Scaffold::Log->instance->clear_pid;
    Class::Scaffold::Log->instance->info('a message without pid or timestamp');
    (my $out = $log->output) =~ s/^\d{8}\.\d{6}\.\d\d/[timestamp]/mg;
    my $pid = sprintf '%08d', $$;
    is($out, <<EXPECT, 'log output');
[timestamp] Hello
[timestamp] a debug message that should appear
[timestamp] ($pid) a message with pid and timestamp
($pid) a message with pid but without timestamp
a message without pid or timestamp
EXPECT
}
1;

__END__
=pod

=head1 NAME

Class::Scaffold::Log_TEST - Companion test class for the log class

=head1 VERSION

version 1.102280

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

