#this package is a connector from CPANPLUS to CPAN.
#(A CPANPLUS programmer's interface for CPAN.)

#the commands I use are:
#$cpanp->module_tree()
#$mod->author->cpanid
#$mod->package_name
#$mod->package_version
#$mod->installed_version
#$mod->files();
#$mod->name
#
#
#
#
#
#
#
#
#
#
#$mod->package_is_perl_core
#

package CPANPLUS::Shell::Wx::cpan_connector;
use CPAN;
use base qw(CPAN);
use Cwd;
use Data::Dumper;

sub new{
    my $class=shift;
    my $self = $class->SUPER::new();
    return $self;
}
sub module_tree{
    my $self=shift;
    my $name=shift;

    my $mod=CPAN::Shell->expand("Module",$name);
    $mod=CPANPLUS::Shell::Wx::cpan_connector::Module($mod);
    return $mod;
}

package CPANPLUS::Shell::Wx::cpan_connector::Shell;

package CPANPLUS::Shell::Wx::cpan_connector::Module;

use base qw(CPAN::Module);
use Cwd;
use Data::Dumper;

sub new{
    my $class=shift;
    my $mod=shift;
    my $self = $class->SUPER::new($mod);
#    bless($class,$mod);
    return $self;
}
sub name{
    my $self=shift;
    return $self->{name};
}
sub details{
#not implemented:
#$info->{'Installed File'}
#$info->{'Version Installed'}
    my $self=shift;
    my %ret=();
    $ret{Author}=$self->{RO}->{cpanid};
    $ret{Description}=$self->{RO}->{description};
    $ret{Version on CPAN}=$self->{RO}->{CPAN_VERSION};
    $ret{chapterid}=$self->{RO}->{chapterid};
    $ret{'Development Stage'}=$self->{RO}->{statd};
    $ret{'Support Level'}=$self->{RO}->{stats};
    $ret{'Language Used'}=$self->{RO}->{statl};
    $ret{'Interface Style'}=$self->{RO}->{stati};
    $ret{'Public License'}=$self->{RO}->{statp};
    $ret{dslip}=$self->{RO}->{statd}.$self->{RO}->{stats}.$self->{RO}->{statl}.$self->{RO}->{stati}.$self->{RO}->{statp};
    $ret{Package}=(split('/',$self->{RO}->{CPAN_FILE}))[-1];
    $ret{Description}=$self->{RO}->{description};
    return \%ret;
}
sub readme{
    my $self=shift;
    CPAN::Shell::readme($self->name);
}
1;