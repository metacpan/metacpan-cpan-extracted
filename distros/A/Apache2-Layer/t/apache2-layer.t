
use strict;
use warnings;

use Test::More tests => 43;
use Test::NoWarnings;
use Test::Httpd::Apache2;

use File::Spec ();
use LWP::UserAgent;

my %hostnames = (
    'default.localdomain' => {
        html => {
            index => 'htdocs/layered/christmas',
            promotions => 'htdocs/layered/newyearseve',
            delivery => 'htdocs/layered/christmas',
            product => 'htdocs/',
        },
    },
    'layers-disabled.localdomain' => {
        html => {
            map { $_ => 'htdocs/' } qw( index promotions delivery product ),
        },
    },
    'layers-enabled-reversed.localdomain' => {
        html => {
            index => 'htdocs/layered/newyearseve',
            promotions => 'htdocs/layered/newyearseve',
            delivery => 'htdocs/layered/newyearseve',
            product => 'htdocs/',
            new_product => 'htdocs/layered/newyearseve',
        },
    },
    'dev.localdomain' => {
        html => {
            index => 'htdocs/layered/dev',
            beta => 'htdocs/layered/dev/beta',
            rc1 => 'htdocs/layered/dev/rc1',
            rc2 => 'htdocs/layered/dev/rc2',
        },
        php => {
            'forms/form' => 'htdocs/layered/dev/php',
            'forms/ng/form' => 'htdocs/layered/dev/php-ng',
        },
        css => {
            'css/style' => 'htdocs/layered/dev',
        },
        png => {
            pix => 'htdocs/layered/dev/new_images',
            pix2 => 'htdocs/layered/dev/images',
        },
    },
    'other-trans-handler.localdomain' => {
        raw => {
            'noargs.php?a=b' => 'htdocs/layered/noargs',
        },
    },
);

my $httpd;

eval {
    $httpd = _make_httpd();

    $httpd->start;
};

SKIP: {
    skip "Could not start HTTPD", 40 if $@;

    my $ua = LWP::UserAgent->new;

    for my $hostname ( sort keys %hostnames ) {
        my $conf = $hostnames{$hostname};
        for my $ext ( sort keys %$conf ) {
            for my $page ( sort keys %{$conf->{$ext}} ) {
                my $path = $conf->{$ext}->{$page};
                my $file = $ext eq 'raw' ? $page : "$page.$ext";

                $ua->default_header( Host => $hostname );
                my $url = sprintf("http://%s/%s",
                    $httpd->listen, $file);
                my $response = $ua->get( $url );

                my $file_content;
                {
                    local $/;
                    my $fpath = $file;
                    if ( $ext eq 'raw' ) {
                        $fpath = 'noargs.php';
                    } elsif ( $ext eq 'php' ) {
                        $fpath = 'form.php';
                    };

                    open(CONTENT, File::Spec->catfile(
                            't', $path, $fpath
                        ));
                    $file_content = <CONTENT>;
                    close(CONTENT);
                };

                is $response->content, $file_content,
                    "Correct page received for http://$hostname/$file";

                if ( $hostname eq 'dev.localdomain' ) {
                    if ( $page eq 'rc2' ) {
                        is $response->header('Content-MD5'), 'FAcGqTwQtkFI0XuU3eAmzA==',
                            "<Directory> set ContentDigest correctly for $page";
                    } else {
                        ok ! $response->header('Content-MD5'),
                            "ContentDigest disabled for $page";
                    }
                } elsif ( $hostname eq 'other-trans-handler.localdomain' ) {
                    is $response->header('X-RemovedArgs'), 'a=b',
                        "other PerlTransHandler run correctly for $file";

                    like $response->header('X-PrevFilename'), qr{htdocs/noargs.php$},
                        "other PerlMapToStorageHandler run correctly for $file";
                }
            }
        }
    }

    $httpd->stop;
    undef $httpd;


    eval {
        $httpd = _make_httpd(q{
        <Files "/wont_work">
            DocumentRootLayers wont_work
        </Files>
        });
        $httpd->start;
    };
    ok $@, "DocumentRootLayers not allowed within <Files>";

    eval {
        $httpd = _make_httpd(q{
        <Files "/wont_work">
            EnableDocumentRootLayers On
        </Files>
        });
        $httpd->start;
    };
    ok $@, "EnableDocumentRootLayers not allowed within <Files>";


    eval {
        $httpd = _make_httpd(q{
        <Directory "/wont_work">
            DocumentRootLayers wont_work
        </Directory>
        });
        $httpd->start;
    };
    ok $@, "DocumentRootLayers not allowed within <Directory>";

    eval {
        $httpd = _make_httpd(q{
        <Directory "/wont_work">
            EnableDocumentRootLayers On
        </Directory>
        });
        $httpd->start;
    };
    ok $@, "EnableDocumentRootLayers not allowed within <Directory>";


    eval {
        $httpd = _make_httpd(q{
        <FilesMatch "^/wont_work">
            DocumentRootLayers wont_work
        </FilesMatch>
        });
        $httpd->start;
    };
    ok $@, "DocumentRootLayers not allowed within <FilesMatch>";

    eval {
        $httpd = _make_httpd(q{
        <FilesMatch "^/wont_work">
            EnableDocumentRootLayers On
        </FilesMatch>
        });
        $httpd->start;
    };
    ok $@, "EnableDocumentRootLayers not allowed within <FilesMatch>";


    eval {
        $httpd = _make_httpd(q{
        <DirectoryMatch "^/wont_work">
            DocumentRootLayers wont_work
        </DirectoryMatch>
        });
        $httpd->start;
    };
    ok $@, "DocumentRootLayers not allowed within <DirectoryMatch>";

    eval {
        $httpd = _make_httpd(q{
        <DirectoryMatch "^/wont_work">
            EnableDocumentRootLayers On
        </DirectoryMatch>
        });
        $httpd->start;
    };
    ok $@, "EnableDocumentRootLayers not allowed within <DirectoryMatch>";



}

sub _make_httpd {
    my $httpdconf = shift || '';

    my $ServerRoot = File::Spec->rel2abs(
        File::Spec->catdir(
            File::Spec->curdir(), "t",
        )
    );

    diag "ServerRoot: $ServerRoot";

    my $httpd = Test::Httpd::Apache2->new(
        auto_start => 0,
        server_root => $ServerRoot,
        required_modules => [qw(
            perl
        )],
    );

    my $HOSTPORT = $httpd->listen;

    $httpd->custom_conf( <<EOC );

    DocumentRoot "$ServerRoot/htdocs"


    PerlSwitches -Ilib -It/lib

    PerlLoadModule Apache2::Layer

    EnableDocumentRootLayers On
    DocumentRootLayersStripLocation Off

    DocumentRootLayers layered/christmas $ServerRoot/htdocs/layered/newyearseve

    $httpdconf

    NameVirtualHost $HOSTPORT

    <VirtualHost $HOSTPORT>
        ServerName default.localdomain
    </VirtualHost>

    <VirtualHost $HOSTPORT>
        ServerName layers-disabled.localdomain
        EnableDocumentRootLayers Off
    </VirtualHost>

    <VirtualHost $HOSTPORT>
        ServerName layers-enabled-reversed.localdomain
        DocumentRootLayers $ServerRoot/htdocs/layered/newyearseve layered/christmas
    </VirtualHost>

    <VirtualHost $HOSTPORT>
        ServerName dev.localdomain
        DocumentRoot $ServerRoot/htdocs/layered/dev

        DocumentRootLayers rc2 rc1 beta

        <Directory $ServerRoot/htdocs/layered/dev/rc2>
            ContentDigest On
        </Directory>

        <Location "/forms/">
            DocumentRootLayersStripLocation On
            DocumentRootLayers php
        </Location>

        <Location "/forms/ng">
            DocumentRootLayers php-ng
        </Location>

        <LocationMatch "\.png\$">
            DocumentRootLayers new_images images
        </LocationMatch>

        <Location "/css/">
            EnableDocumentRootLayers Off
        </Location>

    </VirtualHost>

    <VirtualHost $HOSTPORT>
        ServerName other-trans-handler.localdomain
        PerlOptions +MergeHandlers
        PerlTransHandler Test::Apache2::Layer::RemoveArgs
        PerlMapToStorageHandler Test::Apache2::Layer::MapStorage
        DocumentRootLayers $ServerRoot/htdocs/layered/noargs
    </VirtualHost>


EOC


    return $httpd;
}
