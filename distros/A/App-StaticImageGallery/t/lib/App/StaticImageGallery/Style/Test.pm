package App::StaticImageGallery::Style::Test;
use parent 'App::StaticImageGallery::Base::Style';

=head1 NAME

App::StaticImageGallery::Style::Test - StaticImageGallery style Test

=cut

sub files {
    my $files = [];

    return wantarray ? @$files : $files;
}
1;
__DATA__
__index__
work_dir: [% work_dir %]
link_to_parent_dir: [% link_to_parent_dir %]
dirs:
[% FOREACH dir IN dirs -%]
    - [% dir %]
[% END -%]
images:
[% FOREACH file IN images -%]
    - file_original: [% file.original %]
      file_thumbnail: [% file.thumbnail %]
[% END -%]
version: [% version %]
created_on: [% now.strftime('%F') %]
created_at: [% now.strftime('%T' ) %]


__image__
work_dir: [% work_dir %]
current_original: [% current.original %]
current: [% current.$size %]
size: [% size %]
previous_original: [% previous.original %]
next_origina: [% next.origina %]
metadata:
[% FOREACH meta IN current.metadata -%]
    [%meta.key%]:[%meta.value%]
[% END -%]
version: [% version %]
created_on: [% now.strftime('%F') %]
created_at: [% now.strftime('%T' ) %]


