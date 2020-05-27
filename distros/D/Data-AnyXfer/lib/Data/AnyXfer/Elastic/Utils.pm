package Data::AnyXfer::Elastic::Utils;

use v5.16.3;
use strict;
use warnings;

use Carp;
use Sys::Hostname;
use Devel::StackTrace ( );
use Path::Class ();
use Data::AnyXfer ();

=head1 NAME

 Data::AnyXfer::Elastic::Utils - Utility methods for Elasticsearch Modules

=head1 SYNOPSIS

    use aliased 'Data::AnyXfer::Elastic::Utils';
    Utils->_configure_name('interiors');

=head1 DESCRIPTION

 This module provides utility methods to be used within Data::AnyXfer::Elastic.

=head1 METHODS

=head2 C<configure_index_name>

    $name = Utils->configure_index_name('interiors');
    $names = Utils->configure_index_name(['interiors', 'properties']);
    print $name;    # prints e.g. interiors_20141230120001

    # or under test...
    print $name;    # prints e.g. <user>_<hostname>_<package>_interiors_20141230120001

If being executued within a test environment, the index name is made unique
enough to prevent clashes.

=cut

sub configure_index_name {

    my ( $class, $index_name, $hostname, $user ) = @_;

    $index_name = $class->_make_unique_name( $index_name, $hostname, $user );

    return $index_name;
}

=head2 C<configure_alias_name>

    $name = Utils->configure_alias_name('interiors');
    $names = Utils->configure_alias_name(['interiors', 'properties']);
    print $name;    # prints e.g. <user>_<hostname>_<package>_interiors.

If being executued within a test environment, the alias name is made unique
enough to prevent clashes.

=cut

sub configure_alias_name {

    my ( $class, $alias_name, $hostname, $user ) = @_;

    $alias_name = $class->_make_unique_name( $alias_name, $hostname, $user );

    return $alias_name;
}


sub _make_unique_name {

    my ( $class, $name, $hostname, $user, $caller ) = @_;

    return $name unless Data::AnyXfer->test();

    # note: arguement $hostname and $caller are solely for testing purposes
    if ( ref($name) eq 'ARRAY' ) {
        return [
            map { $class->_make_unique_name( $_, $hostname, $user, $caller ) }
                @{$name}
        ];
    } else {
        return $class->make_safe_name( $name, $hostname, $user, $caller );

    }
}

sub make_safe_name {

    my ( $self, $name, $hostname, $user, $package ) = @_;

    croak "name not supplied" unless $name;

    $hostname //= Sys::Hostname::hostname;
    $user     //= getpwuid($>) || $>;
    $package  //= $self->_find_test_package_name;

    my $safe_name
        = join( '_', grep {$_} ( $user, $hostname, $package, $name ) );

    # make the name pretty and easy to type
    $safe_name =~ s/-/_/g;    # some hostnames have dashes in them

    return $safe_name;
}


my $TEST_PKG;

sub _find_test_package_name {
    my ($class) = @_;

    return $TEST_PKG if $TEST_PKG;

    my $trace = Devel::StackTrace->new;
    my $test_frame;

    # search stack for the frame containing the .t test
    while ( my $frame = $trace->prev_frame ) {
        next
            unless $frame->package eq 'main'
            && $frame->filename =~ /\.t$/;
        $test_frame = $frame;
        last;
    }

    return unless $test_frame;    # failed to find it -- bail out

    # found the stack frame containing the .t test
    my $file = Path::Class::file( $test_frame->filename );
    my $dir  = $file->dir->absolute;

    # search up through the dir structure until we find the "t" or "xt" dir
    while () {
        last   if $dir->basename eq "t";
        last   if $dir->basename eq "xt";
        last   if $dir->basename eq "st";
              # selenium tests may not be in a t dir
        last   if $dir->parent->basename =~ /^selenium/;
              # failed -- bail out
        return if $dir eq "/";
        $dir = $dir->parent;
    }

    # found the test's package name
    $TEST_PKG = $dir->parent->basename;

    # make it pretty and easy to type
    $TEST_PKG =~ s/\d+//g;            # maya puts version number in dir name
    $TEST_PKG =~ s/\.//g;             # maya puts version number in dir name
    $TEST_PKG =~ s/-/_/g;             # maya puts dashes in dir name
    $TEST_PKG =~ s/_+/_/g;            # maya problem: just one _
    $TEST_PKG =~ s/_$//g;             # maya problem: don't end with a _
    $TEST_PKG = lc $TEST_PKG;

    $TEST_PKG =~ s/[aeiou]//ig;       # make the pkg name shorter

    return $TEST_PKG;
}



=head2 wait_for_doc_count

    $_->index(@documents) foreach @{$clients};

    $class->wait_for_doc_count(
        target_doc_count => scalar @documents,
        index_name => 'interiors',
        clients => [@clients],
        timeout => 600);

    print "All documents indexed!\n";

Waits for the number of documents visible within an Elasticsearch
index to reach or exceed a desired number. This is useful to synchronise
code, so that we do not continue until an index is ready.

Takes the following named arguments:

=over

=item C<target_doc_count>

The target number of documents expected to be available on the index.

=item C<index_name>

The index or alias name to check

=item C<clients>

An C<ARRAY> ref containing one of more L<Search::Elasticsearch> clients
or  L<Data::AnyXfer::Elastic::Index> instances.

=item C<timeout>

The number of seconds to wait until we give up. Defaults to C<20>.

=back

Returns C<1> on success, otherwise B<dies>.

=cut

sub wait_for_doc_count {

    my ( $class, %args ) = @_;

    # get args
    my $index_name       = $args{index_name};
    my $clients          = $args{clients};
    my $target_doc_count = $args{target_doc_count} || 0;
    my $timeout_value    = $args{timeout} || 20;


    # validate required arguments
    croak q!Required argument 'index_name' not supplied!
        unless $index_name;
    croak q!Required argument 'clients' must be an array containing one or !
        . q!more elements!
        unless $clients
        and ( ref $clients eq 'ARRAY' )
        and @{$clients} > 0;


    # loop until all clients 'ok'
    my %clients_ok   = ();
    my $client_count = scalar @{$clients};
    my $timeout      = time() + $timeout_value;
    my $count        = 0;
    my $first_run    = 1;

    while ( $client_count > grep { $_->{ok} } values %clients_ok ) {

        # pause for a moment so we don't go crazy (except on the first run)
        $first_run
            ? ( $first_run = 0 )
            : select( undef, undef, undef, 0.3 );

        # check the document count on each client
        foreach my $client ( @{$clients} ) {

            my $stats = $clients_ok{"$client"} ||= { ok => 0 };
            eval {
                $count = $stats->{doc_count}
                    = $client->count( index => $index_name )->{count};
            };

            # if there was not an error (the index existed)
            # and the count matches or exceeds our target...
            if ( !$@ and $count >= $target_doc_count ) {
                $clients_ok{"$client"}->{ok} = 1;
            } else {

                # explicitly unset ok
                # we only want to exit when all clients are passing
                # simultaneously
                $clients_ok{"$client"}->{ok} = 0;
            }
        }

        # check the timeout
        if ( time() > $timeout ) {

            # XXX : We don't yet have a good way of describing clients
            #       in messages. For now we simply print the object
            #       signature to uniquely identify it

            my $stats = join(
                '',
                map {
                    sprintf( "%s (DOC_COUNT: %s)\n",
                        $_, $clients_ok{$_}->{doc_count} || 'n/a' )
                    }
                    keys %clients_ok
            );

            croak
                'Document count did not match the expected value within the '
                . "allowed timeframe (${timeout_value} second(s)).\n"
                . "DOCUMENT STATISTICS:\n$stats";
        }
    }
    return 1;
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

