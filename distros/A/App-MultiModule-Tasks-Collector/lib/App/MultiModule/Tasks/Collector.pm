package App::MultiModule::Tasks::Collector;
$App::MultiModule::Tasks::Collector::VERSION = '1.143110';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use App::MultiModule::Collector;

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::Collector - collector base class

=cut

=head2 message

=cut

sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    my $state = $self->{state};

    return unless my $collectors = $config->{collectors};
    return unless ref $collectors eq 'HASH';
    if($config->{collectors_path}) {
        my $eval = "use lib \"$config->{collectors_path}\"";
        $self->debug("collector path eval: $eval") if $self->{debug};
        eval $eval;
        $self->error("collector path eval failed: $@") if $@;
    }
    while(my($collector_name, $collector_info) = each %{$config->{collectors}}) {
        {   my $eval = "use $collector_info->{class};";
            $self->debug("($collector_name): collector eval: $eval") if $self->{debug};
            eval $eval;
            $self->error("($collector_name): collector eval failed: $@") if $@;
        }
        my $collector;
        {
            my $eval = "\$collector = $collector_info->{class}->new(collector_name => \$collector_name);";
            $self->debug("($collector_name): collector new eval: $eval") if $self->{debug};
            eval $eval;
            $self->error("($collector_name): collector new eval failed: $@") if $@;
        }
        my $repeat_interval = $collector_info->{interval} || 5;
        my $timeout = $collector_info->{timeout} || 1;
        $self->named_recur(
                recur_name => "collector_$collector_name",
                repeat_interval => $repeat_interval,
                work => sub {
                    my $pid = fork();
                    return unless defined $pid; #failed
                    return if $pid; #parent
                    eval {
                        local $SIG{ALRM} = sub { die "timed out\n"; };
                        alarm $timeout;
                        $collector->collect($collector_info, all_collector_config => $config, state => $state);
#                        print STDERR Data::Dumper::Dumper $collector;
                    };
                    alarm 0;
                    exit;
                },
        );
    }
}

=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-Collector/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::Collector


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-Collector/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-Collector>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-Collector>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::Collector>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::MultiModule::Tasks::Collector
