#+##############################################################################
#                                                                              #
# File: Config/Generator/Random.pm                                             #
#                                                                              #
# Description: Config::Generator pseudo-random support                         #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::Random;
use strict;
use warnings;
our $VERSION  = "1.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Digest::MD5 qw(md5);
use No::Worries::Export qw(export_control);
use No::Worries::File qw(file_read);
use No::Worries::Log qw(log_debug);
use Params::Validate qw(validate_pos :types);
use Config::Generator qw($HomeDir @IncPath);

#
# global variables
#

our($_InitialSeed, $_Seed);

#
# initialize the pseudo-random generator
#

my @random_init_options = (
    { type => SCALAR | UNDEF },
);

sub random_init ($) {
    my($path) = validate_pos(@_, @random_init_options);

    goto use_path if defined($path);
    foreach my $inc (@IncPath, "$HomeDir/cfg") {
        $path = "$inc/random.bin";
        goto use_path if -f $path;
    }
    $_Seed = $_InitialSeed = "";
    return;
  use_path:
    log_debug("using random seed from %s...", $path);
    $_Seed = $_InitialSeed = file_read($path);
}

#
# return a pseudo-random integer between 0 and n-1
#

my @random_integer_options = (
    { type => SCALAR, regex => qr/^\d+$/ },
);

sub random_integer ($@) {
    my($n, @list) = validate_pos(@_, @random_integer_options,
        ({ type => SCALAR }) x (@_ - 1),
    );

    srand(unpack("L", substr(md5($_Seed, @list), 0, 4)));
    return(int(rand($n)));
}

#
# seed the pseudo-random generator
#

my @random_seed_options = (
    { type => SCALAR },
);

sub random_seed ($) {
    my($data) = validate_pos(@_, @random_seed_options);

    random_init(undef) unless defined($_InitialSeed);
    $_Seed = $_InitialSeed . $data;
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{"random_$_"}++, qw(init integer seed));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

=head1 NAME

Config::Generator::Random - Config::Generator pseudo-random support

=head1 DESCRIPTION

This module eases the generation of pseudo-random "data". The goal is to be
able to generate random but reproducible data, for instance to smear times in
crontabs.

The initial seed usually comes from a file named C<random.bin> that can be
created with something like:

  $ dd if=/dev/urandom of=random.bin bs=512 count=1

Then, modules can use the random_seed() function to make sure that what they
generate is different from what other modules generate.

Finally, modules can use the random_integer() function to generate
reproducible pseudo-random integers.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item random_init([PATH])

initialize the pseudo-random generator with the content of the given file or
by using a file named C<random.bin> if it can be located via the usual include
path (the C<@IncPath> variable of the L<Config::Generator> module)

=item random_integer(N, DATA...)

return a pseudo-random integer between 0 and N-1, using the given DATA for
additional seeding

=item random_seed(DATA)

add the given DATA to the initial seed used by the pseudo-random generator

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
