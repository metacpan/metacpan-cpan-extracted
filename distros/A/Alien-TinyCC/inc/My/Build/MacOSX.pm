########################################################################
                    package My::Build::MacOSX;
########################################################################

use strict;
use warnings;

use parent 'My::Build::Linux';

# Figure out if gcc thinks the 64-bit flags are set, and use that to set
# the cpu type for the config args.
my $extra_config_args = '--cpu=x86';
open my $out_fh, '>', '_test.h';
print $out_fh "\n";
close $out_fh; 
$extra_config_args .= '-64' if `gcc -E -dM _test.h` =~ /__x86_64__/;
unlink '_test.h';
sub extra_config_args { $extra_config_args }

# We might need to munge the environment variables for dumb setups,
# specifically those that are llvm-backed gcc emulators that might not know
# what to do with the -march=native flag.
sub install_to_prefix {
    my ($self, $prefix) = @_;
    
    require File::Which;
    
    # Handle the environment variables and such
    my $compiler = $ENV{cc} || '/usr/bin/gcc';
    while (-l $compiler) {
        $compiler = File::Which::which(readlink $compiler);
        if ($compiler =~ /llvm/) {
            # If we found the llvm compiler, clean out the environment variables
            for my $varname ( qw< CFLAGS CPPFLAGS > ) {
                next unless exists $ENV{$varname};
                if ($ENV{$varname} =~ s/-march=native//) {
                    print "Scrubbing -march=native from $varname\n";
                }
                if ($ENV{$varname} =~ s/-fassociative-math//) {
                    print "Scrubbing -fassociative-math from $varname\n";
                }
            }
        }
    }
    
    # Continue with the rest of the install to prefix
    $self->SUPER::install_to_prefix($prefix);
}

1;
