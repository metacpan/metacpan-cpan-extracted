package Alien::Ninja;
use v5.40;
use Alien::Base;
use base 'Alien::Base';
use File::Spec;

# Resolve the ninja executable from the plugin's gathered bin_dir. Returns undef until the alien
# has been built (`perl Makefile.PL && make`).
sub exe {
    my $self   = shift;
    my $suffix = $^O eq 'MSWin32' ? '.exe' : '';
    for my $dir ( $self->bin_dir ) {
        my $cand = File::Spec->catfile( $dir, "ninja$suffix" );
        return $cand if -x $cand;
    }
    return undef;
}
1;
