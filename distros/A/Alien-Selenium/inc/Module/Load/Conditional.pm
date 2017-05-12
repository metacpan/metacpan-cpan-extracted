#line 1 "inc/Module/Load/Conditional.pm - /Users/kane/sources/p4/other/module-load-conditional/lib/Module/Load/Conditional.pm"
package Module::Load::Conditional;

use strict;

use Module::Load;
use Params::Check qw[check];
use Locale::Maketext::Simple Style => 'gettext';

use Carp        ();
use File::Spec  ();
use FileHandle  ();

BEGIN {
    use vars        qw[$VERSION @ISA $VERBOSE $CACHE @EXPORT_OK $ERROR];
    use Exporter;
    @ISA        =   qw[Exporter];
    $VERSION    =   0.05;
    $VERBOSE    =   0;

    @EXPORT_OK  =   qw[check_install can_load requires];
}

#line 127

### this checks if a certain module is installed already ###
### if it returns true, the module in question is already installed
### or we found the file, but couldn't open it, OR there was no version
### to be found in the module
### it will return 0 if the version in the module is LOWER then the one
### we are looking for, or if we couldn't find the desired module to begin with
### if the installed version is higher or equal to the one we want, it will return
### a hashref with he module name and version in it.. so 'true' as well.
sub check_install {
    my %hash = @_;

    my $tmpl = {
            version => { default    => '0.0'    },
            module  => { required   => 1        },
            verbose => { default    => $VERBOSE },
    };

    my $args;
    unless( $args = check( $tmpl, \%hash, $VERBOSE ) ) {
        warn loc( q[A problem occurred checking arguments] ) if $VERBOSE;
        return;
    }

    my $file = File::Spec->catfile( split /::/, $args->{module} ) . '.pm';

    ### where we store the return value ###
    my $href = {
            file        => undef,
            version     => undef,
            uptodate    => undef,
    };

    DIR: for my $dir ( @INC ) {

        my( $fh, $filename );

        if ( ref $dir ) {
            ### @INC hook -- we invoke it and get the filehandle back
            ### this is actually documented behaviour as of 5.8 ;)

            if (UNIVERSAL::isa($dir, 'CODE')) {
                ($fh) = $dir->($dir, $file);

            } elsif (UNIVERSAL::isa($dir, 'ARRAY')) {
                ($fh) = $dir->[0]->($dir, $file, @{$dir}{1..$#{$dir}})

            } elsif (UNIVERSAL::can($dir, 'INC')) {
                ($fh) = $dir->INC->($dir, $file);
            }

            if (!UNIVERSAL::isa($fh, 'GLOB')) {
                warn loc(q[Can not open file '%1': %2], $file, $!) 
                        if $args->{verbose};
                next;
            }

            $filename = $INC{$file} || $file;

        } else {
            $filename = File::Spec->catfile($dir, $file);
            next unless -e $filename;

            $fh = new FileHandle;
            if (!$fh->open($filename)) {
                warn loc(q[Can not open file '%1': %2], $file, $!)
                        if $args->{verbose};
                next;
            }
        }

        $href->{file} = $filename;

        while (local $_ = <$fh> ) {

            ### the following regexp comes from the ExtUtils::MakeMaker
            ### documentation.
            if ( /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/ ) {

                ### this will eval the version in to $VERSION if it
                ### was declared as $VERSION in the module.
                ### else the result will be in $res.
                ### this is a fix on skud's Module::InstalledVersion

                local $VERSION;
                my $res = eval $_;

                ### default to '0.0' if there REALLY is no version
                ### all to satisfy warnings
                $href->{version} = $VERSION || $res || '0.0';

                last DIR;
            }
        }
    }

    ### if we couldn't find the file, return undef ###
    return unless defined $href->{file};

    ### only complain if we expected fo find a version higher than 0.0 anyway
    if( !defined $href->{version} ) {

        {   ### don't warn about the 'not numeric' stuff ###
            local $^W;

            ### if we got here, we didn't find the version
            warn loc(q[Could not check version on '%1'], $args->{module} )
                    if $args->{verbose} and $args->{version} > 0;
        }
        $href->{uptodate} = 1;

    } else {
        ### don't warn about the 'not numeric' stuff ###
        local $^W;
        $href->{uptodate} = $args->{version} <= $href->{version} ? 1 : 0;
    }

    return $href;
}

#line 284

sub can_load {
    my %hash = @_;

    my $tmpl = {
        modules     => { default => {}, strict_type => 1 },
        verbose     => { default => $VERBOSE },
        nocache     => { default => 0 },
    };

    my $args;

    unless( $args = check( $tmpl, \%hash, $VERBOSE ) ) {
        $ERROR = loc(q[Problem validating arguments!]);
        warn $ERROR if $VERBOSE;
        return;
    }

    ### layout of $CACHE:
    ### $CACHE = {
    ###     $ module => {
    ###             usable  => BOOL,
    ###             version => \d,
    ###             file    => /path/to/file,
    ###     },
    ### };

    $CACHE ||= {}; # in case it was undef'd

    my $error;
    BLOCK: {
        my $href = $args->{modules};

        my @load;
        for my $mod ( keys %$href ) {

            next if $CACHE->{$mod}->{usable} && !$args->{nocache};

            ### else, check if the hash key is defined already,
            ### meaning $mod => 0,
            ### indicating UNSUCCESSFUL prior attempt of usage
            if (    !$args->{nocache}
                    && defined $CACHE->{$mod}->{usable}
                    && (($CACHE->{$mod}->{version}||0) >= $href->{$mod})
            ) {
                $error = loc( q[Already tried to use '%1', which was unsuccesful], $mod);
                last BLOCK;
            }

            my $mod_data = check_install(
                                    module  => $mod,
                                    version => $href->{$mod}
                                );

            if( !$mod_data or !defined $mod_data->{file} ) {
                $error = loc(q[Could not find or check module '%1'], $mod);
                $CACHE->{$mod}->{usable} = 0;
                last BLOCK;
            }

            map {
                $CACHE->{$mod}->{$_} = $mod_data->{$_}
            } qw[version file uptodate];

            push @load, $mod;
        }

        for my $mod ( @load ) {

            if ( $CACHE->{$mod}->{uptodate} ) {

                eval { load $mod };

                ### in case anything goes wrong, log the error, the fact
                ### we tried to use this module and return 0;
                if( $@ ) {
                    $error = $@;
                    $CACHE->{$mod}->{usable} = 0;
                    last BLOCK;
                } else {
                    $CACHE->{$mod}->{usable} = 1;
                }

            ### module not found in @INC, store the result in
            ### $CACHE and return 0
            } else {

                $error = loc(q[Module '%1' is not uptodate!], $mod);
                $CACHE->{$mod}->{usable} = 0;
                last BLOCK;
            }
        }

    } # BLOCK

    if( defined $error ) {
        $ERROR = $error;
        Carp::carp( loc(q|%1 [THIS MAY BE A PROBLEM!]|,$error) ) if $args->{verbose};
        return undef;
    } else {
        return 1;
    }
}

#line 404

sub requires {
    my $who = shift;

    unless( check_install( module => $who ) ) {
        warn loc(q[You do not have module '%1' installed], $who) if $VERBOSE;
        return undef;
    }

    my $lib = join " ", map { "-I$_" } @INC;
    my $cmd = qq[$^X $lib -M$who -e"print(join(qq[\\n],keys(%INC)))"];
    
    return  sort
                grep { !/^$who$/  }
                map  { chomp; s|/|::|g; $_ }
                grep { s|\.pm$||i; }
            `$cmd`;
}

1;

__END__

=head1 Global Variables

The behaviour of Module::Load::Conditional can be altered by changing the
following global variables:

=head2 $Module::Load::Conditional::VERBOSE

This controls whether Module::Load::Conditional will issue warnings and
explenations as to why certain things may have failed. If you set it
to 0, Module::Load::Conditional will not output any warnings.
The default is 0;

=head2 $Module::Load::Conditional::CACHE

This holds the cache of the C<can_load> function. If you explicitly
want to remove the current cache, you can set this variable to
C<undef>

=head2 $Module::Load::Conditional::ERROR

This holds a string of the last error that happened during a call to
C<can_load>. It is useful to inspect this when C<can_load> returns
C<undef>.

=head1 See Also

C<Module::Load>

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is
copyright (c) 2002 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.
