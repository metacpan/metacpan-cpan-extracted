###########################################
# CPAN::Unwind -- 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package CPAN::Unwind;
###########################################

use strict;
use warnings;
use CPAN qw();
use File::Temp qw(tempfile tempdir);
use Log::Log4perl qw(:easy);
use Log::Log4perl::Util;
use Data::Dumper;
use LWP::UserAgent;
use Module::Depends::Intrusive;
use Archive::Tar;
use Storable qw(freeze thaw);
use Cache::FileCache;
use Cache::Cache;
use Cwd;

our $VERSION = "0.06";
our $TGZ     = "tar.tgz";

  # These troublemakers are ignored when listed as a dependency
our %BLACKLISTED = map { $_ => 1 } qw(perl);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        add          => [],
        core_include => 0,
        %options,
    };

    if(exists $options{cache}) {
        $options{cache} = CPAN::Unwind::Pseudocache->new() 
          unless $options{cache};
    } else {
        $self->{cache} = Cache::FileCache->new(
                     {namespace           => "cpan_unwind",
                     });
    }

    bless $self, $class;
}

###########################################
sub tarball_url {
###########################################
    my($self, $mname) = @_;

    my $cpan_url;

    eval {
        require CPAN::Config;
        $cpan_url   = $CPAN::Config->{urllist}->[0];
    };

    $cpan_url    ||= "http://search.cpan.org/CPAN";
    $cpan_url     .= "/modules/by-authors/id";

    my ($fh, $filename) = tempfile(CLEANUP => 1);

    local(*STDOUT);
    local(*STDERR);
    open STDOUT, ">$filename" or die "Can't open $filename";
    open STDERR, ">>$filename" or die "Can't open $filename";

    for my $type (qw(Module Distribution)) {

        DEBUG "Expanding $type/$mname";
        my @expands = CPAN::Shell->expand($type, $mname);

        DEBUG Dumper(\@expands);
        next unless @expands;

        for (@expands) {
            my $f = ($type eq "Module") ? $_->cpan_file : $_->id;
            unlink $filename;
            close STDOUT;
            close STDERR;
            return "$cpan_url/$f";
        }
    }

    unlink $filename;
    close STDOUT;
    close STDERR;

    return undef;
}

###########################################
sub lookup {
###########################################
    my($self, @mnames) = @_;

    my %unresolved = map { ($_ => 1) } @mnames;
    my %resolved   = ();
    my @in_core    = ();

    my $result = CPAN::Unwind::Response->new(mname   => [@mnames],
                                             success => 1);
    $result->{dependency_graph} = Algorithm::Dependency::Source::Mem->new();
    $result->{dependents}       = {};

    while(keys %unresolved) {

        my $mname = (keys %unresolved)[0];

        delete $unresolved{$mname};

        $resolved{$mname}++;

        my $resp = $self->lookup_single($mname);

        return $resp unless $resp->is_success();

        if(!$self->{core_include} and $resp->is_core()) {
            # Mark item as taken care of, it's in the core
            $result->{dependency_graph}->item_select($mname);
        }

        my $deps = $resp->dependent_versions();

        $result->{dependency_graph}->item_add($mname, keys %$deps);
        $result->{dependents}->{$mname} = [];

        for(keys %$deps) {
            DEBUG "Adding dependency $_";
            push @{$result->{dependents}->{$mname}}, $_;

            $unresolved{$_} = 1 unless exists $resolved{$_};

            if(exists $result->{dependent_versions}->{$_}) {
                    # Already got that one, only store it if the
                    # required version number is higher
                if($result->{dependent_versions}->{$_} < $deps->{$_}) {
                    $result->{dependent_versions}->{$_} = $deps->{$_};
                }
            } else {
                $result->{dependent_versions}->{$_} = $deps->{$_};
            }
        }
    }

    return $result;
}

###########################################
sub lookup_single {
###########################################
    my($self, $mname) = @_;

    if($self->{cache}) {
        my $cached = $self->{cache}->get($mname);

        if($cached) {
            my $href = thaw($cached);
            DEBUG "Found $mname deps in cache";
            return CPAN::Unwind::Response->new(
                       mname        => $mname,
                       success      => 1,
                       dependent_versions => $href);
        }
    }

    my $url = $self->tarball_url($mname);

    LOGDIE "Couldn't get tarball for $mname from CPAN" unless defined $url;

        # Don't knock yourself out on modules that are part of the core
    if($url =~ m#/perl-\d#) {
        return CPAN::Unwind::Response->new(
                   mname              => $mname,
                   success            => 1,
                   is_core            => 1,
                   dependent_versions => {} );
    }

    return CPAN::Unwind::Response->new(
               mname              => $mname,
               message => "No tarball found for $mname") unless $url;

    my $tempdir = tempdir(
                      CLEANUP => 1
                  );

    DEBUG "Created tempdir $tempdir";

    my $ua = LWP::UserAgent->new();
    my $resp = $ua->get("$url");

    if($resp->is_error()) {
        return CPAN::Unwind::Response->new(
                   mname   => $mname,
                   message => "Fetching tarball $url failed");
    }

    my $tgzfile = "$tempdir/$TGZ";
    open FILE, ">$tgzfile" or LOGDIE "Can't open $tgzfile ($!)";
    print FILE $resp->content();
    close FILE;

    my $cwd = getcwd();
    chdir $tempdir or LOGDIE "Cannot chdir to $tempdir";

    my $deps = {};

    eval {
        my $tar = Archive::Tar->new();
        $tar->read($TGZ, 1);
        $tar->extract() or LOGDIE "Cannot extract";
    
        $deps = Module::Depends::Intrusive->new()->
                  dist_dir(subdir_find("."))->find_modules()->requires();

        DEBUG "Found dependent_versions of $mname: ", Dumper($deps);
    };

    delete $deps->{$_} for keys %BLACKLISTED;

    chdir $cwd or LOGDIE "Cannot chdir to $cwd";

    return CPAN::Unwind::Response->new(
               mname   => $mname,
               message => "Determining dependencies failed") if $@;
 
    if($self->{cache}) {
        DEBUG "Setting cache for $mname";
        $self->{cache}->set($mname, freeze($deps));
    }

    return CPAN::Unwind::Response->new(
               mname              => $mname,
               success            => 1,
               dependent_versions => $deps);
}

###########################################
sub subdir_find {
###########################################
    my($dir) = @_;

    opendir DIR, $dir or LOGDIE "opendir $dir failed ($!)";
    my @dirs = readdir(DIR);
    closedir DIR;

    for(@dirs) {
        next if /^\./;
        next unless -d;
        return $_;
    }

    return undef;
}

###########################################
package CPAN::Unwind::Response;
###########################################
use Algorithm::Dependency::Ordered;
use Log::Log4perl qw(:easy);
use Data::Dumper;

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        is_success         => 0,
        is_core            => 0,
        mname              => [],
        dependent_versions => {},
        message            => "",
        %options,
    };

    bless $self, $class;
}

###########################################
sub is_success { $_[0]->{success} }
###########################################

###########################################
sub is_core { $_[0]->{is_core} }
###########################################

###########################################
sub message { $_[0]->{message} }
###########################################

###########################################
sub dependent_versions { return $_[0]->{dependent_versions} }
###########################################

###########################################
sub dependents { return $_[0]->{dependents} }
###########################################

###########################################
sub missing { 
###########################################
    my($self) = @_;

    my %missing = map { $_ => $self->{dependent_versions}->{$_} }
                  grep { ! Log::Log4perl::Util::module_available($_) }
                       keys %{$self->{dependent_versions}};
    return \%missing;
}

###########################################
sub schedule { 
###########################################
    my($self) = @_;

    DEBUG "Dependency graph: ", Dumper($self->{dependency_graph});

    my $dep = Algorithm::Dependency::Ordered->new(
        source   => $self->{dependency_graph},
        selected => $self->{dependency_graph}->{selected},
    ) or die "Failed to set up dependency algorithm";

    my $schedule = $dep->schedule(@{$self->{mname}});

    LOGDIE "Cannot determine schedule for @{$self->{mname}}" unless $schedule;
    return @$schedule;
}

sub CORE::GLOBAL::exit { }

################################################
package Algorithm::Dependency::Source::Mem;
################################################
use base qw(Algorithm::Dependency::Source);
use Algorithm::Dependency::Item;
use Log::Log4perl qw(:easy);

################################################
sub new {
################################################
    my($class) = @_;

    # Get the basic source object
    my $self = $class->SUPER::new() or return undef;

    # Add our arguments
    $self->{deps} = [];
    $self;
}

#######################################
sub item_add {
#######################################
    my($self, $item, @deps) = @_;

    DEBUG "Adding $item - (", join(', ', @deps), ")";

    push @{$self->{deps}}, [$item, @deps];
}

#######################################
sub item_select {
#######################################
    my($self, $item) = @_;

    DEBUG "Selecting $item";

    push @{$self->{selected}}, $item;
}

#######################################
sub _load_item_list {
#######################################
    my($self) = @_;

    my @items;

    for(@{$self->{deps}}) {
        my $item = Algorithm::Dependency::Item->new(@$_);
        push @items, $item;
    }

    return \@items;
}

###########################################
package CPAN::Unwind::Pseudocache;
###########################################
sub new { bless {}, shift }
sub get { return undef; }
sub set { }

1;

__END__

=head1 NAME

CPAN::Unwind - Recursively determines dependencies of CPAN modules

=head1 SYNOPSIS

    use CPAN::Unwind;
    
    my $agent = CPAN::Unwind->new();
    
    my $resp = $agent->lookup("Log::Log4perl");
    die $resp->message() unless $resp->is_success();
    
    my $deps = $resp->dependent_versions();
    
    for my $module (keys %$deps) {
        printf "%30s: %s\n", $module, $deps->{$module};
    }
        # Prints:
        #
        #  Test::Harness: 2.03
        #     Test::More: 0.45
        #     File::Spec: 0.82
        # File::Basename: 0
        #           Carp: 0

    print "Installation schedule:\n";
    for($resp->schedule()) {
        print "$_\n";
    }
        # Installation schedule:
        # Carp
        # File::Basename
        # File::Spec
        # Test::Harness
        # Test::More
        # Log::Log4perl

=head1 DESCRIPTION

CPAN::Unwind recursively determines dependencies of CPAN modules. It
fetches distribution tarballs from CPAN, unpacks them, and
runs L<Module::Depends::Intrusive> on them. 

SECURITY NOTE: L<CPAN::Unwind> runs all Makefile.PL files (via
C<Module::Depends::Intrusive>) of modules it finds dependencies on. If
you are concerned that any module in the dependency tree on CPAN isn't
trustworthy, only use it in a secured sandbox.

=head2 METHODS

CPAN::Unwind supports the following methods:

=over 4

=item C<my $agent = CPAN::Unwind-E<gt>new();>

Create a new dependency agent. The following options are supported:

=over 4

=item C<cache>

Provide your own C<Cache::Cache> object (see I<Caching>).

=item C<add>

Provide additional dependencies that should be part of the result:

    CPAN::Unwind->new(add => 
        ["Foo", "Bar" => 0.17,
         ...
        ]);

indicates that C<Foo> has a dependency on C<Bar> 0.17, even if it's 
not listed in C<Foo>'s C<Makefile.PL>. This way, you can fix broken 
Makefile.PL files of some CPAN modules, not listing their dependencies
correctly.

=back

=item C<$resp = $agent-E<gt>lookup_single($module_name)>

Goes to CPAN and fetches the tarball containing the module specified
in C<$module_name>. After unpacking the tarball, it will use
L<Module::Depends::Intrusive> to determine the modules it depends on.

Returns a C<CPAN::Unwind::Response> object. 

=item C<$resp = $agent-E<gt>lookup($module_name)>

Calls C<lookup_single> on $module_name recursively, builds a dependency
tree and returns a C<CPAN::Unwind::Response> object containing a
consolidated dependency tree.

=back

CPAN::Unwind::Response supports the following methods:

=over 4

=item C<$resp-E<gt>is_success()>

Returns true if there's a valid response and no error occurred.

=item C<$resp-E<gt>message()>

Returns a response's error message in case C<is_success()> returned
a false value.

=item C<$resp-E<gt>dependent_versions()>

Returns a ref to a hash, containing a mapping between names of
dependent modules and their version numbers: 

    { "Test::More"  =>  0.51,
      "List::Utils" =>  0.38,
      ...
    }

=item C<$resp-E<gt>missing()>

Similar to C<dependent_versions()>, but only modules that are currently
I<not> installed are returned.

=item C<$resp-E<gt>dependents()>

Returns a ref to a hash, mapping module names to their dependencies.

    { "Net::Amazon"  =>  ["Log::Log4perl", "XML::Simple"],
      "List::Utils"  =>  [],
      ...
    }

If an entry holds a ref to an empty array, the module doesn't have
any dependencies.

=item C<$resp-E<gt>schedule()>

Returns an installation schedule, a list of module names 
in the correct order without dependency conflicts. Returns C<undef>
if no schedule can be made due to circular dependencies.

=back

=head2 Caching

To avoid costly downloads, C<CPAN::Unwind> will cache dependencies
in a Cache::FileCache cache, where they are stored indefinitely.
Running it the second time on a module will speed up processing
significantly.

=head2 Turnkey Scripts

C<CPAN::Unwind> comes with a ready-to-use script C<cpan-unwind>,
which gets installed in perl's bin path. It is ready to use, just
call

    $ cpan-unwind Log::Log4perl

to see which modules C<Log::Log4perl> depends on.

C<CPAN::Unwind> requires a valid CPAN configuration.

=head1 EXAMPLES

    $ cpan-unwind Net::Amazon
    Carp Compress::Zlib Data::Dumper Fcntl File::Basename File::Path 
    File::Spec HTML::Tagset IO::Socket MIME::Base64 Socket Test::Harness 
    Test::More Test::Simple Time::HiRes URI XML::NamespaceSupport 
    Digest::base File::Temp HTML::Parser Log::Log4perl Net::FTP 
    XML::SAX XML::Simple Digest::MD5 LWP::UserAgent Net::Amazon

=head1 LEGALESE

Copyright 2005-2011 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
