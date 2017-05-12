#line 1 "inc/Module/Install/MakeMaker.pm - /Library/Perl/5.8.1/Module/Install/MakeMaker.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/MakeMaker.pm $ $Author: autrijus $
# $Revision: #11 $ $Change: 1781 $ $DateTime: 2003/10/22 17:14:03 $ vim: expandtab shiftwidth=4

package Module::Install::MakeMaker;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

$VERSION = '0.01';

use ExtUtils::MakeMaker ();

my $makefile;
sub WriteMakefile {
    my ($self, %args) = @_;
    $makefile = $self->load('Makefile');

    # mapping between MakeMaker and META.yml keys
    $args{MODULE_NAME} = $args{NAME};
    unless ($args{NAME} = $args{DISTNAME} or !$args{MODULE_NAME}) {
        $args{NAME} = $args{MODULE_NAME};
        $args{NAME} =~ s/::/-/g;
    }

    foreach my $key (qw(name module_name version version_from abstract author)) {
        my $value = delete($args{uc($key)}) or next;
        $self->$key($value);
    }

    if (my $prereq = delete($args{PREREQ_PM})) {
        while (my($k,$v) = each %$prereq) {
            $self->requires($k,$v);
        }
    }

    # put the remaining args to makemaker_args
    $self->makemaker_args(%args);
}

END {
    if ($makefile) {
        $makefile->write;
        $makefile->Meta->write;
    }
}

1;
