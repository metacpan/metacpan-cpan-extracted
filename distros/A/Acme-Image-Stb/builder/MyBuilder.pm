package builder::MyBuilder;
use v5.40;
use parent 'Module::Build';
use Affix::Build;
use HTTP::Tiny;
use Path::Tiny;
use Config;

sub ACTION_code ($self) {
    unless ( defined $self->config_data('lib') ) {
        say 'Building embedded C library...';

        # Setup source directory
        my $src_dir = path('_src');
        $src_dir->mkpath;

        # Download headers if missing. In reality, you would probably just bundle the headers with the dist.
        # But this isn't reality.
        my $http = HTTP::Tiny->new;
        for my $file (qw(stb_image.h stb_image_resize2.h stb_image_write.h)) {
            my $path = $src_dir->child($file);
            next if $path->exists;
            say "  Fetching $file...";
            my $res = $http->get("https://raw.githubusercontent.com/nothings/stb/master/$file");
            die "Failed to download $file" unless $res->{success};
            $path->spew_raw( $res->{content} );
        }

        # Determine output path
        # We want the DLL to end up in: blib/arch/auto/Acme/Image/Stb/stb.so.xx.xx
        # This ensures it is installed in the architecture-specific library path.
        my $dist_name = $self->dist_name;    # "Acme-Image-Stb"
        my @parts     = split /-/, $dist_name;
        my $arch_dir  = path( $self->blib, 'arch', 'auto', @parts );
        $arch_dir->mkpath;

        # Compile with Affix
        my $c = Affix::Build->new(
            version   => $self->dist_version,
            name      => 'stb',
            build_dir => $arch_dir,
            flags     => { cflags => "-I$src_dir -O3", ldflags => ( $^O eq 'MSWin32' ? '-Wl,--export-all-symbols' : '' ) }
        );
        $c->add( \<<~'C', lang => 'c' );
        #if defined(_WIN32)
          #define STBIDEF __declspec(dllexport)
          #define STBIWDEF __declspec(dllexport)
          #define STBIRDEF __declspec(dllexport)
        #else
          #define STBIDEF __attribute__((visibility("default")))
          #define STBIWDEF __attribute__((visibility("default")))
          #define STBIRDEF __attribute__((visibility("default")))
        #endif

        #define STB_IMAGE_IMPLEMENTATION
        #define STB_IMAGE_WRITE_IMPLEMENTATION
        #define STB_IMAGE_RESIZE_IMPLEMENTATION

        #include "stb_image.h"
        #include "stb_image_resize2.h"
        #include "stb_image_write.h"
    C
        my $lib_file = $c->link;
        say "  Compiled: $lib_file";
        $self->config_data( lib => $lib_file->basename );
    }

    # Run standard build steps (copying .pm files to blib/)
    $self->SUPER::ACTION_code;
}
1;
