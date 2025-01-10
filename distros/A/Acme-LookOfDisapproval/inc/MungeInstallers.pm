use strict;
use warnings;
package inc::MungeInstallers;
# vim: set ts=8 sts=2 sw=2 tw=100 et :

use utf8;
use Moose;
with 'Dist::Zilla::Role::InstallTool';
use namespace::autoclean;

# TODO - this should really be a separate phase that runs after InstallTool -
# until then, all we can do is die if we are run too soon
sub setup_installer {
    my $self = shift;

    my @build_files = grep $_->name eq 'Build.PL', @{ $self->zilla->files };

    $self->log_fatal('No Build.PL was found to munge!')
        if @build_files != 1;

    for my $file (@build_files) {
        # check for template markers in file content
        $self->log_fatal([ 'ran too soon, before %s template(s) evaluated', $file->name ])
            if $file->content =~ /\{\{/;

        $file->content($file->content . <<'COPY_MODULE');

use utf8;
use File::Spec::Functions;
my $source = catfile(qw(anotherlib Acme o_o.pm));
open my $source_fh, '<', $source or die "cannot open $source for reading: $!";
my $dest = catfile(qw(lib Acme ಠ_ಠ.pm));
open my $dest_fh, '>', $dest or die "cannot create $dest for writing: $!";
local $/;
print $dest_fh (<$source_fh>);
close $source_fh;
close $dest_fh;
COPY_MODULE
    }
    return;
}

__PACKAGE__->meta->make_immutable;
