package App::NoPAN::Installer;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/root_files/);

sub new {
    my ($klass, %opts) = @_;
    bless {
        %opts,
    }, $klass;
}

sub shell_exec {
    my ($self, $script) = @_;
    
    print "$script\n";
    system($script) == 0
        or die "error:$script failed with exit status:$?";
}

1;
