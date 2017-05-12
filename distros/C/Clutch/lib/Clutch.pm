package Clutch;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.05';

1;
__END__

=head1 NAME

Clutch - distributed job system

=head1 SYNOPSIS

    # worker
    package Your::Worker;
    use strict;
    use warnings;
    use Clutch::Worker;
    
    register_function(
        'echo' => sub {
            my $args = shift;
            $$ .':'. $args; # return worker process response.
        }
    );
    1;

    # worker start script by single process
    #! perl
    use strict;
    use warnings;
    use Your::Worker;
    Your::Worker->new(
        {
            address => "$ip:$port",
        }
    )->run(); # stop by TERM signal to this process

    # client script
    use strict;
    use warnings;
    use Clutch::Client;
    my $args = shift || die 'missing args';
    my $client = Clutch::Client->new(
        servers => [ "$worker_ip:$worker_port" ],
    );
    my $res = $client->request('echo', $args);
    print $res, "\n";

=head1 DESCRIPTION

Clutch is distributed job system. like L<Gearman>.

but Clutch B<no needed exclusive use daemon process>.

the worker process itself receives a request. 

=head1 DEPENDENCIES

L<Parallel::Prefork>

=head1 BUGS & SUPPORT

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

irc: #qudo@irc.perl.org

=head1 SEE ALSO

L<Clutch::Client>

L<Clutch::Worker>

=head1 THANKS

many code stolen from Starlet. kazuhooku++

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Atsushi Kobayashi. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

