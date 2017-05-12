use strict;
use warnings;
package inc::MyBumpVersionAfterRelease;

use Moose;
with 'Dist::Zilla::Role::AfterRelease';
use utf8;
use Path::Tiny 0.061;

# this is a smarter version of:
# [Run::AfterRelease]
# run = %x -p -i -e's/^version = 3\.(\d+)\s/sprintf(q(version = %0.( . (length($1)+1) . q(g), atan2(1,1)*4)/x'

sub after_release
{
    my $self = shift;

    # edits dist.ini to add one decimal point to the version

    my $π = atan2(1,1) * 4;
    my $original_version = $self->zilla->version;
    my $length = length($original_version);

    # add another digit if we added a 0, as it will be numerically identical
    do {} while substr($π, $length++, 1) eq '0';

    my $new_version = substr($π, 0, $length);

    # munge dist.ini to edit version line
    my $path = path('dist.ini');
    my $content = $path->slurp_utf8;

    my $delta_length = $length - length($original_version);

    if ($content =~ s/^(version = )$original_version\s{$delta_length}(\s+)/$1$new_version$2/m)
    {
        # append+truncate to preserve file mode
        $path->append_utf8({ truncate => 1 }, $content);
        return 1;
    }

    return;
}

1;
