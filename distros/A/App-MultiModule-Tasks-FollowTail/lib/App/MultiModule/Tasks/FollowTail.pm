package App::MultiModule::Tasks::FollowTail;
$App::MultiModule::Tasks::FollowTail::VERSION = '1.161190';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use POE qw(Wheel::FollowTail);
use Message::Transform qw(mtransform);

use parent 'App::MultiModule::Task';
=head1 NAME

App::MultiModule::Tasks::FollowTail - File following task for App::MultiModule

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use App::MultiModule::Tasks::FollowTail;

    my $foo = App::MultiModule::Tasks::FollowTail->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 message

=cut

sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
}

sub _got_log_line {
    my ($logfile, $line) = @_;
    my @follow_names = keys %{$App::MultiModule::Tasks::FollowTail::logfile_map->{$logfile}};
    foreach my $follow_name (@follow_names) {
        my $follow_info = $App::MultiModule::Tasks::FollowTail::config->{follows}->{$follow_name};
        my $regex_string = $follow_info->{regex};
    
        if(not $App::MultiModule::Tasks::FollowTail::regex_cache->{$regex_string}) {
            $App::MultiModule::Tasks::FollowTail::regex_cache->{$regex_string} = qr/$regex_string/;
        }
        my $re = $App::MultiModule::Tasks::FollowTail::regex_cache->{$regex_string};
        if($line =~ $re) {
            my $message = {
                line => $line,
                logfile => $logfile,
                follow_name => $follow_name,
                regex_string => $regex_string,
            };
            if(%+) {
                while(my($key, $value) = each %+) {
                    $message->{$key} = $value;
                }
            }
            mtransform $message, $follow_info->{transform}
                if $follow_info->{transform};
            $App::MultiModule::Tasks::FollowTail::self->emit($message);
        }
    }
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    my %args = @_;
    my $root_object = $args{root_object};
    $self->{config} = $config;

    #only the main module will follow any files.
    return unless $root_object->{module} eq 'main';
    #perhaps premature optimization, but this thing has to be *fast*
    $App::MultiModule::Tasks::FollowTail::config = $config;

    if(not $self->{local_state}) {
        $self->{local_state} = {
            following_files => {},
        };
        $App::MultiModule::Tasks::FollowTail::regex_cache = {};
        $App::MultiModule::Tasks::FollowTail::logfile_map = {};
        $App::MultiModule::Tasks::FollowTail::self = $self;
    }
    my $state = $self->{local_state};

    if($config->{follows}) {
        my @follow_names = sort keys %{$config->{follows}};
        foreach my $follow_name (@follow_names) {
            my $follow_info = $config->{follows}->{$follow_name};
            next unless my $logfile = $follow_info->{logfile};
            $App::MultiModule::Tasks::FollowTail::logfile_map->{$logfile}->{$follow_name} = 1;
            next if $state->{following_files}->{$logfile};
            $self->add_session(
                {   inline_states => {
                        _start => sub {
                            $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
                                Filename => $logfile,
                                InputEvent => 'got_log_line',
                                ResetEvent => 'got_log_rollover',
                            );
                        },
                        got_log_line => sub {
                            _got_log_line($logfile, $_[ARG0]);
                        },
                        got_log_rollover => sub {
                        },
                    }
                }
            );
            $state->{following_files}->{$logfile} = 1;
        }
    }
    $self->debug('Router: set_config') if $self->{debug};
}

=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/App-MultiModule-Tasks-FollowTail/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::FollowTail


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/App-MultiModule-Tasks-FollowTail/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-FollowTail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-FollowTail>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::FollowTail>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014,2016 Dana M. Diederich.

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

1; # End of App::MultiModule::Tasks::FollowTail
