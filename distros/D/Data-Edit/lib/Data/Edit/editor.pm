package Data::Edit::editor;
use Moose;
use File::Temp qw/ tempfile /;

with qw/ Data::Edit::Role::Editor /;

sub edit {
    my ($self, $file, $orig) = @_;

    system($self->path, $file)==0 or die "editor failed";
    return;
}

1;
