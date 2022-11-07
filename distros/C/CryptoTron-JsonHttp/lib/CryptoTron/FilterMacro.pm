package CryptoTron::FilterMacro;

# Set the VERSION.
$CryptoTron::FilterMacro::VERSION = '0.01';

# Load the Perl pragmas.
use strict;
use warnings;

# Create a new filter.
use Filter::Simple::Compile sub {
    # Remove 1; from the package content. 
    $_ =~ s/1;\s//g;
    # Remove comment lines from the package content. 
    s/#\s+[0-9a-fA-F]+\s*[\n]+//gm;
    # Create the new script content.
    $_ = sprintf(q(
        # Create a new filter.
        use Filter::Simple::Compile sub {
            # Remove comment lines from the package content. 
            s/#\s+[0-9a-fA-F]+\s*[\n]+//g;
            # Create new content.
            $_ = join("\n",
                '#line ' . (__LINE__+1) . ' ' .__FILE__,
                "%s",
                '#line %s %s',
                $_,
            );
        };
        1;
    ), $_, (caller(6))[2]+1, (caller(6))[1]);
};

1;
