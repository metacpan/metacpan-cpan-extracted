use strict;
use warnings;
package inc::MungeInstallers;

use utf8;
use Moose;
with 'Dist::Zilla::Role::InstallTool';

# TODO - this should really be a separate phase that runs after InstallTool -
# until then, all we can do is die if we are run too soon
sub setup_installer
{
    my $self = shift;

    my @build_files = grep { $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' } @{ $self->zilla->files };

    $self->log_fatal('No Makefile.PL or Build.PL was found. [MungeInstallers] should appear in dist.ini after [MakeMaker] or [ModuleBuild*]!')
        if not @build_files;

    for my $file (@build_files)
    {
        $file->content($file->content . <<'MOVE_MODULE');

use File::Spec::Functions;
use utf8;
rename catfile(qw(lib Acme o_o.pm)), catfile(qw(lib Acme ಠ_ಠ.pm));
MOVE_MODULE
    }
    return;
}

__PACKAGE__->meta->make_immutable;
