# NAME

App::FakeCDN - fake CDN server emulator

# SYNOPSIS

    use App::FakeCDN;
    my $fake_cdn = App::FakeCDN->new(root => 'static');
    $fake_cdn->to_app;

# DESCRIPTION

App::FakeCDN launches fake CDN server emulator.

__THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.__

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
