package Data::STUID;
use strict;
use constant DEBUG => !!$ENV{DATA_STUID_DEBUG};
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Data::STUID - Yet Another Unique ID Generator

=head1 SYNOPSIS

    # see Data::STUID::Server
    #     Data::STUID::Client
    #     Data::STUID::Generator

=head1 DESCRIPTION

Minimalistic unique ID generator. Main logic ported from STF (http://github.com/stf-storage/stf).

The generated IDs are always in 64bit range, and can be ordered sequentially, so it's easy to use for sort operations.

=head1 SAMPLE SERVER SETUP

For programmatic usage, see L<Data::STUID::Server>

=over 4

=item Install dependencies

You can do the regular

    perl Build.PL
    ./Build
    ./Build install

and then execute C<stuid-server> directly, but you could also use C<carton>.

install carton >= 0.9.10, and cpanm >= 1.60002.

    cd /path/to/Data-STUID
    carton install
    # optionally, skip tests: 'PERL_CPANM_OPT=-n carton install'

=item Execute It!

Plain usage would be:

    stuid-server --host_id=1

With carton:

    carton exec -I/path/to/Data-STUID/lib -- \
        /path/to/Data-STUID/script/stuid-server \
        --host_id=1

It might be easier if you wrap the above in a shell script, say server.sh:

    #!/bin/sh
    STUID_HOME=/path/to/Data-STUID
    exec \
        carton exec -I$STUID_HOME/lib -- \
        $STUID_HOME/script/stuid-server $@

Then execute it as:

    ./server.sh --host_id=1

Note that you need pass a unique C<host_id> parameter to each distinct STUID
server instance

=item Tweaks

C<Data::STUID::Server> is a subclass of L<Net::Server::PreFork>. You should be able to pass parameters that the parent class accepts. If the script doesn't, send me a pullreq!

=back

=head1 SAMPLE CLIENT SETUP

For programmatic usage, see L<Data::STUID::Client>

=over 4

=item Install dependencies

See L<SAMPLE SERVER SETUP>

=item Execute it!

Plain usage would be:

    stuid-client --server=127.0.0.1:9001 --server=127.0.0.1:9002 ...

    carton exec -I/path/to/Data-STUID/lib -- \
        /path/to/Data-STUID/script/stuid-client \
             --server=127.0.0.1:9001 --server=127.0.0.1:9002 ...

=back

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=cut
