package Acme::State;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.03';

use B;
use Storable;
use Devel::Caller 'caller_cv';
use IO::Handle;

my @stop_modules = (
    '1' .. '9', ':',
    'SIG', 'stderr', '__ANON__', 'utf8::', 'CORE::', 'DynaLoader::', 'strict::',
    'stdout', 'attributes::', 'stdin', 'ARGV', 'INC', 'Scalar::', 'ENV',
    'Regexp::', 'XSLoader::', 'UNIVERSAL::', 'overload::', 'B::', 'Carp::', 
    'Data::', 'PerlIO::', '0', 'BEGIN', 'STDOUT', 'IO::', '_', 'Dumper',
    'Exporter::', 'bytes::', 'STDERR', 'Internals::', 'STDIN', 'Config::',
    'warnings::', 'DB::',
    'APR::', 'Apache2::', 'Apache::', 'autobox::', 'BSD::', 'CGITempFile::', 'Compress::',
    'Devel::', 'Dos::', 'EPOC::', 'Encode::', 'Fh::', 'File::', 'HTTP::', 'LWP::', 'List::', 'Log::',
    'MIME::', 'Mac::', 'MacPerl::', 'O::', 'POSIX::', 'Scope::', 'Sys::', 'Term::', 'Thread::', 'Time::', 'VMS::',
    'fields::', 'blackhole::', 'Autobox::', 'Module::', 'Win32::', 'MultipartBuffer::', 'q::', 'sort::',
);

sub import {

    my $save_fn = save_file_name();

    if(-f $save_fn) {
        local $Storable::Eval = 1;
        my $save = Storable::retrieve $save_fn;
        sub {
            my $package = shift;
            my $tree = shift;
            no strict 'refs';
            for my $k (keys %$tree) {
                if($k =~ m/::$/) {
                    caller_cv(0)->($package.$k, $tree->{$k});
                } elsif(ref($tree->{$k})) {
                    *{$package.$k} = $tree->{$k};
                } else {
                    die $package.$k . " doesn't contain a ref";
                }
            }
        }->('main::', $save);
    }

}

sub save_file_name {
    my $zero = $0 || 'untitledprogram';
    $zero =~ s{.*/}{};
    return +(getpwuid $<)[7].'/'.$zero.'.store';
}

sub save_state {

    our $wantcoderefs;

    my $tree = sub {
        my $package = shift;
        my $node = shift() || { };
        no strict 'refs';
        for my $k (keys %$package) {
            next if $k =~ m/main::$/;
            next if $k =~ m/[^\w:]/;
            next if grep $_ eq $k, @stop_modules;
            if($k =~ m/::$/) {
                # recurse into that namespace unless it corresponds to a .pm module that got used at some point
                my $modulepath = $package.$k; 
                for($modulepath) { s{^main::}{}; s{::$}{}; s{::}{/}g; $_ .= '.pm'; }
                next if exists $INC{$modulepath};
                $node->{$k} ||= { };
                caller_cv(0)->($package.$k, $node->{$k});
            } elsif( *{$package.$k}{HASH} ) {
                $node->{$k} = *{$package.$k}{HASH};
            } elsif( *{$package.$k}{ARRAY} ) {
                $node->{$k} = *{$package.$k}{ARRAY};
            } elsif( *{$package.$k}{CODE} ) {
                next unless $wantcoderefs;
                # save coderefs but only if they aren't XS (can't serialize those) and weren't exported from elsewhere.
                my $ob = B::svref_2object(*{$package . $k}{CODE});
                my $rootop = $ob->ROOT;
                my $stashname = $$rootop ? $ob->STASH->NAME . '::' : '(none)'; 
                if($$rootop and ($stashname eq $package or 'main::'.$stashname eq $package or $stashname eq 'main::' )) {
                    # when we eval something in code in main::, it comes up as being exported from main::.  *sigh*
                    $node->{$k} = *{$package . $k}{CODE};
                }
            } else {
                $node->{$k} = *{$package.$k}{SCALAR} unless ref(*{$package.$k}{SCALAR}) eq 'GLOB';
            }
        }
        return $node;
    }->('main::');

    # use Data::Dumper; print "debug: ", Data::Dumper::Dumper($tree), "\n";

    local $Storable::Deparse = $wantcoderefs;

    my $save_fn = save_file_name();

    # $save_fn =~ s{/-}{/x}g; warn "saving to: ``$save_fn.new''";

    Storable::nstore $tree, $save_fn.'.new' or die "saving state failed: $!";

    # warn "okay, Storable::nstore done";

    rename $save_fn, $save_fn.'.last'; # it's okay if it fails... file might not exist
    rename $save_fn.'.new', $save_fn or die "renaming new save file into place as ``$save_fn'' failed: $!";

    return 1;
}

END {
    STDERR->print("Acme::State:  Saving program state!\n\n");
    save_state();
};



=head1 NAME

Acme::State - Save application state on exit and restores state on startup

=head1 SYNOPSIS

    use Acme::State; 
    our $t; 
    print "t: $t\n"; 
    $t = int rand 100; 
    print "new t: $t\n"; 

... and then run it again.

=head1 DESCRIPTION

Crawls the package hierarchy looking for C<our> variables.
Stores them all off in a file in the home directory of the user running the script.
When the script using this module starts up, this same file is read in and the 
variables are restored.

Serializes scalars, hashes, and arrays declared using C<our>, C<use vars>, or otherwise
not declared using C<my>. 
Uses L<Storable> to write the data.
The save is placed in the home directory of the user the script is executing as.
The file name is the same as the script's name (C<$0>) plus ".save".
It also keeps one backup around, named C<$0.save.last>, and it may leave a
C<$0.save.new> if interrupted.

Web apps written using L<Continuity> get persistant state, so why shouldn't command
line apps?
Hey, and maybe L<Continuity> apps want to persist some state in case the server implodes.
Who knows.

C<$Acme::State::wantcoderefs>, if set true, takes things a step further and tells 
L<Acme::State> to also serialize subroutines it finds.
Nothing says fun like persisting coderefs from the stash and a 40 of Mickey's.

This code reserves the right to C<die> if anything goes horribly wrong.

=head2 Acme::State::save_state()

Explicitly request a snapshot of state be written to disc.
C<die>s if unable to write the save file or if a sanity check fails.

=head2 Todo

Optionally also use L<Coro> to create an execution context that runs peroidically to save snapshots.

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options

  -A -C -X -b 5.8.0 -c -n Stupid::State

=item 0.02

PAUSE rejected the first one because it didn't like the permissions h2xs left for the
automatically generated META.yml file so it wouldn't index it, but it also wouldn't let me
delete it, so this version is actually identical to 0.01.

=item 0.03

Ooops, actually C<< use IO::Handle >>.  Not every program already does that for us.

=back

=head1 BUGS

What could possibily go wrong?

=head1 SEE ALSO

You *could* use an ORM, and wind up translating all of your data to a relational schema you
don't care about or else have it automatically mapped and completely miss the point of
using a relational database.  
You *could* just store your data in the Ether with Memcached.
You could C<INSERT> and C<UPDATE> manually against a database to store every little tidbit and factoid
as they're computed.
You could use BerekelyDB, including the build-in legacy C<dbmopen> and mangle everything
down to a flat associative list.
You could use L<Data::Dumper> to write a structure to a file and C<eval> that on startup
and keep all of your precious application data in one big datastructure and still not be able to
persist entire objects.
You could use C<dump> and keep waiting for the day that someone finally writes C<undump>.

But what's the fun in that?
None of those are one C<use> line and then never another thought.
That's like work for something.
Work is for suckers.
We're Perl programmers.
If it's not automatic, it's not worth doing.

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

__END__

scraps...

async {
    my $timer = Coro::Event->timer( interval => 2, );
    my $last_save_time = time;
    # my $mod_time = -M __FILE__;

    while(1) {
        $timer->next;
        if(time - $last_save_time > 60*15) {
            $save_db->();
            $last_save_time = time;
        }
    }

};


    #     if(-M __FILE__ != $mod_time) {
    #         $save_db->();
    #         STDERR->print("Exec-ing self!\n\n");
    #         system '/usr/bin/perl', '-c', __FILE__ and do { $mod_time = -M __FILE__; next; };
    #         exec '/usr/bin/perl', __FILE__;
    #     }
                # STDERR->print("deteced code imported from elsewhere: ``$package$k'' was imported from ``$stashname''\n") if $$rootop and ($stashname ne $package and 'main::'.$stashname ne $package and $stashname ne 'main::');
